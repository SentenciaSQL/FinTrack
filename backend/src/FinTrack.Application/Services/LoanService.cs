using AutoMapper;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using FinTrack.Application.Common;
using FinTrack.Application.DTOs.Loans;
using FinTrack.Application.Interfaces;
using FinTrack.Domain.Entities;
using FinTrack.Domain.Enums;

namespace FinTrack.Application.Services;

public class LoanService : ILoanService
{
    private readonly IFinTrackDbContext _db;
    private readonly ICurrentUser _currentUser;
    private readonly IDateTimeProvider _clock;
    private readonly IMapper _mapper;
    private readonly IValidator<CreateLoanRequest> _createValidator;
    private readonly IValidator<UpdateLoanRequest> _updateValidator;
    private readonly IValidator<RecordLoanPaymentRequest> _paymentValidator;
    private readonly IValidator<CalculateLoanRequest> _calculateValidator;
    private readonly IValidator<SimulateEarlyPaymentRequest> _simulateValidator;

    public LoanService(
        IFinTrackDbContext db,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        IMapper mapper,
        IValidator<CreateLoanRequest> createValidator,
        IValidator<UpdateLoanRequest> updateValidator,
        IValidator<RecordLoanPaymentRequest> paymentValidator,
        IValidator<CalculateLoanRequest> calculateValidator,
        IValidator<SimulateEarlyPaymentRequest> simulateValidator)
    {
        _db = db;
        _currentUser = currentUser;
        _clock = clock;
        _mapper = mapper;
        _createValidator = createValidator;
        _updateValidator = updateValidator;
        _paymentValidator = paymentValidator;
        _calculateValidator = calculateValidator;
        _simulateValidator = simulateValidator;
    }

    public async Task<IReadOnlyList<LoanDto>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        var loans = await OwnedQuery()
            .AsNoTracking()
            .Include(l => l.Installments)
            .OrderByDescending(l => l.CreatedAt)
            .ToListAsync(cancellationToken);
        RefreshStatuses(loans, persist: false);
        return loans.Select(MapLoan).ToList();
    }

    public async Task<LoanDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var loan = await GetOwnedAsync(id, cancellationToken, tracking: true, includeChildren: true);
        RefreshStatuses([loan], persist: true);
        await _db.SaveChangesAsync(cancellationToken);
        return MapLoan(loan);
    }

    public async Task<LoanDto> CreateAsync(CreateLoanRequest request, CancellationToken cancellationToken = default)
    {
        await _createValidator.ValidateAndThrowAppAsync(request, cancellationToken);
        await EnsureCategoryAsync(request.DefaultCategoryId, cancellationToken);

        var now = _clock.UtcNow;
        var principal = LoanAmortizationCalculator.Round(request.OriginalPrincipal);
        var balance = request.IsExistingLoan && request.CurrentBalance.HasValue
            ? LoanAmortizationCalculator.Round(request.CurrentBalance.Value)
            : principal;

        if (balance <= 0 || balance > principal)
        {
            throw new ValidationAppException(ErrorCodes.InvalidAmount, "Current balance must be greater than 0 and not exceed the original principal.");
        }

        var firstDue = (request.IsExistingLoan && request.NextPaymentDate.HasValue
            ? request.NextPaymentDate.Value
            : request.FirstInstallmentDate).ToUniversalTime().Date;

        var remainingHint = request.IsExistingLoan ? request.RemainingInstallments : null;
        var termForSchedule = remainingHint is > 0
            ? remainingHint.Value
            : request.TermMonths;

        var isEstimate = request.AmortizationType == AmortizationType.CUSTOM
            || (request.IsExistingLoan && (!request.RemainingInstallments.HasValue || !request.CurrentBalance.HasValue));

        var schedule = LoanAmortizationCalculator.BuildSchedule(
            balance,
            request.AnnualInterestRate,
            termForSchedule,
            request.PaymentFrequency,
            request.AmortizationType,
            firstDue,
            request.PreferredPaymentDay,
            request.IsExistingLoan ? 0 : request.AdditionalFees,
            overridePeriodCount: remainingHint,
            overridePeriodicPayment: request.AmortizationType == AmortizationType.CUSTOM
                ? request.CustomPeriodicPayment
                : null,
            isEstimate: isEstimate);

        var loan = new Loan
        {
            Id = Guid.NewGuid(),
            Name = request.Name.Trim(),
            Creditor = request.Creditor.Trim(),
            LoanType = request.LoanType,
            OriginalPrincipal = principal,
            Currency = string.IsNullOrWhiteSpace(request.Currency) ? "DOP" : request.Currency.Trim().ToUpperInvariant(),
            AnnualInterestRate = request.AnnualInterestRate,
            DisbursementDate = request.DisbursementDate.ToUniversalTime().Date,
            FirstInstallmentDate = request.FirstInstallmentDate.ToUniversalTime().Date,
            TermMonths = request.TermMonths,
            PaymentFrequency = request.PaymentFrequency,
            AmortizationType = request.AmortizationType,
            AssociatedAccountLabel = NormalizeOptional(request.AssociatedAccountLabel),
            PreferredPaymentDay = request.PreferredPaymentDay,
            AdditionalFees = LoanAmortizationCalculator.Round(request.AdditionalFees),
            Notes = NormalizeOptional(request.Notes),
            CurrentBalance = balance,
            RemainingInstallments = schedule.PeriodCount,
            AccruedInterestPending = LoanAmortizationCalculator.Round(request.AccruedInterestPending ?? 0),
            NextPaymentDate = schedule.Rows.FirstOrDefault()?.DueDate,
            PeriodicPayment = schedule.PeriodicPayment,
            Status = LoanStatus.ACTIVE,
            EarlyPaymentPenaltyRate = request.EarlyPaymentPenaltyRate,
            EarlyPaymentPenaltyFixed = LoanAmortizationCalculator.Round(request.EarlyPaymentPenaltyFixed),
            ReminderDaysCsv = ToReminderCsv(request.ReminderDays),
            RemindOnOverdue = request.RemindOnOverdue,
            DefaultCategoryId = request.DefaultCategoryId,
            IsEstimate = schedule.IsEstimate,
            UserId = _currentUser.UserId,
            CreatedAt = now,
            UpdatedAt = now
        };

        foreach (var row in schedule.Rows)
        {
            loan.Installments.Add(CreateInstallment(loan.Id, row, now));
        }

        if (request.IsExistingLoan && principal > balance)
        {
            var paidPrincipal = LoanAmortizationCalculator.Round(principal - balance);
            loan.TotalPrincipalPaid = paidPrincipal;
        }

        loan.ChangeLogs.Add(new LoanChangeLog
        {
            Id = Guid.NewGuid(),
            LoanId = loan.Id,
            Description = request.IsExistingLoan ? "Existing loan registered" : "Loan registered",
            Details = $"Balance {loan.CurrentBalance}; periods {loan.RemainingInstallments}",
            ChangedAt = now
        });

        RefreshStatuses([loan], persist: false);
        _db.Loans.Add(loan);
        await _db.SaveChangesAsync(cancellationToken);
        return MapLoan(loan);
    }

    public async Task<LoanDto> UpdateAsync(Guid id, UpdateLoanRequest request, CancellationToken cancellationToken = default)
    {
        await _updateValidator.ValidateAndThrowAppAsync(request, cancellationToken);
        await EnsureCategoryAsync(request.DefaultCategoryId, cancellationToken);

        var loan = await GetOwnedAsync(id, cancellationToken, tracking: true, includeChildren: true);
        if (loan.Status == LoanStatus.CANCELLED)
        {
            throw new ValidationAppException(ErrorCodes.ValidationError, "Cancelled loans cannot be updated.");
        }

        loan.Name = request.Name.Trim();
        loan.Creditor = request.Creditor.Trim();
        loan.LoanType = request.LoanType;
        loan.AnnualInterestRate = request.AnnualInterestRate;
        loan.AssociatedAccountLabel = NormalizeOptional(request.AssociatedAccountLabel);
        loan.PreferredPaymentDay = request.PreferredPaymentDay;
        loan.AdditionalFees = LoanAmortizationCalculator.Round(request.AdditionalFees);
        loan.Notes = NormalizeOptional(request.Notes);
        loan.EarlyPaymentPenaltyRate = request.EarlyPaymentPenaltyRate;
        loan.EarlyPaymentPenaltyFixed = LoanAmortizationCalculator.Round(request.EarlyPaymentPenaltyFixed);
        loan.ReminderDaysCsv = ToReminderCsv(request.ReminderDays);
        loan.RemindOnOverdue = request.RemindOnOverdue;
        loan.DefaultCategoryId = request.DefaultCategoryId;
        loan.UpdatedAt = _clock.UtcNow;

        if (request.CustomPeriodicPayment is > 0)
        {
            loan.PeriodicPayment = LoanAmortizationCalculator.Round(request.CustomPeriodicPayment.Value);
            loan.AmortizationType = AmortizationType.CUSTOM;
            loan.IsEstimate = true;
        }

        if (request.RecalculateFutureSchedule && loan.Status == LoanStatus.ACTIVE && loan.CurrentBalance > 0)
        {
            RecalculateFutureInstallments(loan, loan.PeriodicPayment, keepPeriodCount: true, interestSaved: 0);
            loan.ChangeLogs.Add(new LoanChangeLog
            {
                Id = Guid.NewGuid(),
                LoanId = loan.Id,
                Description = "Future amortization recalculated",
                ChangedAt = _clock.UtcNow
            });
        }

        RefreshStatuses([loan], persist: false);
        await _db.SaveChangesAsync(cancellationToken);
        return MapLoan(loan);
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var loan = await GetOwnedAsync(id, cancellationToken, tracking: true, includeChildren: true);
        if (loan.Payments.Count > 0)
        {
            loan.Status = LoanStatus.CANCELLED;
            loan.UpdatedAt = _clock.UtcNow;
            loan.ChangeLogs.Add(new LoanChangeLog
            {
                Id = Guid.NewGuid(),
                LoanId = loan.Id,
                Description = "Loan cancelled (payments retained)",
                ChangedAt = _clock.UtcNow
            });
            await _db.SaveChangesAsync(cancellationToken);
            return;
        }

        _db.Loans.Remove(loan);
        await _db.SaveChangesAsync(cancellationToken);
    }

    public async Task<AmortizationScheduleDto> CalculateAsync(CalculateLoanRequest request, CancellationToken cancellationToken = default)
    {
        await _calculateValidator.ValidateAndThrowAppAsync(request, cancellationToken);
        var schedule = LoanAmortizationCalculator.BuildSchedule(
            request.Principal,
            request.AnnualInterestRate,
            request.TermMonths,
            request.PaymentFrequency,
            request.AmortizationType,
            request.FirstInstallmentDate.ToUniversalTime().Date,
            request.PreferredPaymentDay,
            request.AdditionalFees,
            overridePeriodicPayment: request.AmortizationType == AmortizationType.CUSTOM
                ? request.CustomPeriodicPayment
                : null,
            isEstimate: request.AmortizationType == AmortizationType.CUSTOM);
        return MapSchedule(schedule);
    }

    public async Task<IReadOnlyList<LoanInstallmentDto>> GetInstallmentsAsync(Guid loanId, CancellationToken cancellationToken = default)
    {
        var loan = await GetOwnedAsync(loanId, cancellationToken, tracking: true, includeChildren: true);
        RefreshStatuses([loan], persist: true);
        await _db.SaveChangesAsync(cancellationToken);
        return loan.Installments.OrderBy(i => i.Number).Select(MapInstallment).ToList();
    }

    public async Task<IReadOnlyList<LoanPaymentDto>> GetPaymentsAsync(Guid loanId, CancellationToken cancellationToken = default)
    {
        await GetOwnedAsync(loanId, cancellationToken, tracking: false);
        var payments = await _db.LoanPayments
            .AsNoTracking()
            .Include(p => p.Category)
            .Where(p => p.LoanId == loanId)
            .OrderByDescending(p => p.Date)
            .ThenByDescending(p => p.CreatedAt)
            .ToListAsync(cancellationToken);
        return payments.Select(MapPayment).ToList();
    }

    public async Task<LoanPaymentDto> RecordPaymentAsync(Guid loanId, RecordLoanPaymentRequest request, CancellationToken cancellationToken = default)
    {
        await _paymentValidator.ValidateAndThrowAppAsync(request, cancellationToken);
        var loan = await GetOwnedAsync(loanId, cancellationToken, tracking: true, includeChildren: true);
        if (loan.Status != LoanStatus.ACTIVE)
        {
            throw new ValidationAppException(ErrorCodes.ValidationError, "Only active loans accept payments.");
        }

        if (request.ExistingTransactionId.HasValue)
        {
            var duplicate = await _db.LoanPayments.AnyAsync(
                p => p.LoanId == loanId && p.TransactionId == request.ExistingTransactionId, cancellationToken);
            if (duplicate)
            {
                throw new ValidationAppException(ErrorCodes.ValidationError, "That transaction is already linked to a loan payment.");
            }
        }

        var categoryId = request.CategoryId ?? loan.DefaultCategoryId;
        if (request.CreateTransaction && categoryId.HasValue)
        {
            await EnsureCategoryAsync(categoryId, cancellationToken);
        }
        else if (request.CreateTransaction && !categoryId.HasValue)
        {
            throw new ValidationAppException(ErrorCodes.CategoryRequired, "A category is required to create a transaction.");
        }

        var amount = LoanAmortizationCalculator.Round(request.Amount);
        var now = _clock.UtcNow;
        var paymentDate = request.Date.ToUniversalTime();

        return request.Kind switch
        {
            LoanPaymentKind.EXTRA_PRINCIPAL => await ApplyExtraPrincipalAsync(loan, request, amount, categoryId, paymentDate, now, cancellationToken),
            LoanPaymentKind.FULL_PAYOFF => await ApplyFullPayoffAsync(loan, request, amount, categoryId, paymentDate, now, cancellationToken),
            LoanPaymentKind.FEE => await ApplyFeePaymentAsync(loan, request, amount, categoryId, paymentDate, now, cancellationToken),
            _ => await ApplyInstallmentPaymentAsync(loan, request, amount, categoryId, paymentDate, now, cancellationToken)
        };
    }

    public async Task<EarlyPaymentScenarioDto> SimulateEarlyPaymentAsync(Guid loanId, SimulateEarlyPaymentRequest request, CancellationToken cancellationToken = default)
    {
        await _simulateValidator.ValidateAndThrowAppAsync(request, cancellationToken);
        var loan = await GetOwnedAsync(loanId, cancellationToken, tracking: false);
        var scenario = BuildScenario(loan, request.ExtraPayment, request.Mode, request.PenaltyRate, request.PenaltyFixed);
        return _mapper.Map<EarlyPaymentScenarioDto>(scenario);
    }

    public async Task<IReadOnlyList<EarlyPaymentScenarioDto>> CompareEarlyPaymentsAsync(Guid loanId, CompareEarlyPaymentsRequest request, CancellationToken cancellationToken = default)
    {
        var loan = await GetOwnedAsync(loanId, cancellationToken, tracking: false);
        var amounts = request.ExtraPayments.Where(a => a > 0).Distinct().OrderBy(a => a).ToList();
        if (amounts.Count == 0)
        {
            throw new ValidationAppException(ErrorCodes.InvalidAmount, "Provide at least one positive extra payment amount.");
        }

        return amounts
            .Select(amount => BuildScenario(loan, amount, request.Mode, request.PenaltyRate, request.PenaltyFixed))
            .Select(s => _mapper.Map<EarlyPaymentScenarioDto>(s))
            .ToList();
    }

    public async Task<LoanDashboardDto> GetDashboardAsync(CancellationToken cancellationToken = default)
    {
        var loans = await OwnedQuery().AsNoTracking().Include(l => l.Installments).Include(l => l.Payments).ToListAsync(cancellationToken);
        RefreshStatuses(loans, persist: false);
        var active = loans.Where(l => l.Status == LoanStatus.ACTIVE).ToList();
        var totalDebt = active.Sum(l => l.CurrentBalance);
        var monthly = active.Sum(ToMonthlyEquivalent);
        var next = active
            .SelectMany(l => l.Installments
                .Where(i => i.Status is LoanInstallmentStatus.PENDING or LoanInstallmentStatus.DUE_SOON or LoanInstallmentStatus.OVERDUE or LoanInstallmentStatus.PARTIALLY_PAID)
                .Select(i => new { Loan = l, Installment = i }))
            .OrderBy(x => x.Installment.DueDate)
            .FirstOrDefault();

        var original = loans.Sum(l => l.OriginalPrincipal);
        var paidPrincipal = loans.Sum(l => l.TotalPrincipalPaid);
        var distribution = active
            .Select(l => new LoanDistributionDto
            {
                LoanId = l.Id,
                Name = l.Name,
                Balance = l.CurrentBalance,
                Percentage = totalDebt == 0 ? 0 : LoanAmortizationCalculator.Round(l.CurrentBalance / totalDebt * 100)
            })
            .OrderByDescending(d => d.Balance)
            .ToList();

        var evolution = BuildDebtEvolution(loans);

        return new LoanDashboardDto
        {
            ActiveLoans = active.Count,
            TotalOutstandingDebt = LoanAmortizationCalculator.Round(totalDebt),
            TotalMonthlyInstallments = LoanAmortizationCalculator.Round(monthly),
            NextDueDate = next?.Installment.DueDate,
            NextDueAmount = next == null ? 0 : LoanAmortizationCalculator.Round(next.Installment.TotalAmount - next.Installment.PaidTotal),
            NextDueLoanName = next?.Loan.Name,
            TotalInterestPaid = LoanAmortizationCalculator.Round(loans.Sum(l => l.TotalInterestPaid)),
            TotalPrincipalPaid = LoanAmortizationCalculator.Round(paidPrincipal),
            TotalExtraPrincipalPaid = LoanAmortizationCalculator.Round(loans.Sum(l => l.TotalExtraPrincipalPaid)),
            TotalInterestSaved = LoanAmortizationCalculator.Round(loans.Sum(l => l.TotalInterestSaved)),
            OverallPaidOffPercentage = original == 0 ? 0 : LoanAmortizationCalculator.Round(paidPrincipal / original * 100),
            DebtEvolution = evolution,
            DebtDistribution = distribution,
            TotalCapitalPaid = LoanAmortizationCalculator.Round(paidPrincipal),
            TotalInterestComponent = LoanAmortizationCalculator.Round(loans.Sum(l => l.TotalInterestPaid))
        };
    }

    public async Task<IReadOnlyList<LoanCalendarItemDto>> GetCalendarAsync(DateTime? from, DateTime? to, CancellationToken cancellationToken = default)
    {
        var start = (from ?? _clock.UtcNow.Date.AddMonths(-1)).ToUniversalTime().Date;
        var end = (to ?? _clock.UtcNow.Date.AddMonths(2)).ToUniversalTime().Date;
        var loans = await OwnedQuery().AsNoTracking().Include(l => l.Installments).Where(l => l.Status != LoanStatus.CANCELLED).ToListAsync(cancellationToken);
        RefreshStatuses(loans, persist: false);

        return loans
            .SelectMany(l => l.Installments
                .Where(i => i.DueDate.Date >= start && i.DueDate.Date <= end)
                .Select(i => new LoanCalendarItemDto
                {
                    LoanId = l.Id,
                    LoanName = l.Name,
                    InstallmentId = i.Id,
                    InstallmentNumber = i.Number,
                    DueDate = i.DueDate,
                    Amount = i.TotalAmount,
                    RemainingAmount = LoanAmortizationCalculator.Round(i.TotalAmount - i.PaidTotal),
                    Status = i.Status,
                    IsExtraPayment = false,
                    Currency = l.Currency
                }))
            .OrderBy(i => i.DueDate)
            .ToList();
    }

    public async Task<IReadOnlyList<LoanChangeLogDto>> GetChangeLogsAsync(Guid loanId, CancellationToken cancellationToken = default)
    {
        await GetOwnedAsync(loanId, cancellationToken, tracking: false);
        var logs = await _db.LoanChangeLogs
            .AsNoTracking()
            .Where(l => l.LoanId == loanId)
            .OrderByDescending(l => l.ChangedAt)
            .ToListAsync(cancellationToken);
        return _mapper.Map<IReadOnlyList<LoanChangeLogDto>>(logs);
    }

    public async Task<LoanDto> UpdateRemindersAsync(Guid loanId, UpdateLoanRemindersRequest request, CancellationToken cancellationToken = default)
    {
        var loan = await GetOwnedAsync(loanId, cancellationToken, tracking: true);
        loan.ReminderDaysCsv = ToReminderCsv(request.ReminderDays);
        loan.RemindOnOverdue = request.RemindOnOverdue;
        loan.UpdatedAt = _clock.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);
        return MapLoan(loan);
    }

    private async Task<LoanPaymentDto> ApplyInstallmentPaymentAsync(
        Loan loan,
        RecordLoanPaymentRequest request,
        decimal amount,
        Guid? categoryId,
        DateTime paymentDate,
        DateTime now,
        CancellationToken cancellationToken)
    {
        var installment = ResolveInstallment(loan, request.InstallmentId);
        var remainingInterest = LoanAmortizationCalculator.Round(installment.InterestAmount - installment.PaidInterest);
        var remainingFees = LoanAmortizationCalculator.Round(installment.FeeAmount - installment.PaidFees);
        var remainingPrincipal = LoanAmortizationCalculator.Round(installment.PrincipalAmount - installment.PaidPrincipal);
        var remainingTotal = LoanAmortizationCalculator.Round(remainingInterest + remainingFees + remainingPrincipal);

        if (remainingTotal <= 0)
        {
            throw new ValidationAppException(ErrorCodes.ValidationError, "The selected installment is already paid.");
        }

        if (amount > remainingTotal)
        {
            throw new ValidationAppException(ErrorCodes.InvalidAmount, "Payment exceeds the remaining installment amount.");
        }

        var interestPart = Math.Min(amount, remainingInterest);
        var afterInterest = amount - interestPart;
        var feePart = Math.Min(afterInterest, remainingFees);
        var principalPart = afterInterest - feePart;

        installment.PaidInterest += interestPart;
        installment.PaidFees += feePart;
        installment.PaidPrincipal += principalPart;
        installment.PaidTotal += amount;
        installment.UpdatedAt = now;
        installment.IsLocked = true;

        loan.CurrentBalance = LoanAmortizationCalculator.Round(Math.Max(0, loan.CurrentBalance - principalPart));
        loan.TotalInterestPaid += interestPart;
        loan.TotalFeesPaid += feePart;
        loan.TotalPrincipalPaid += principalPart;
        loan.UpdatedAt = now;

        var kind = amount < remainingTotal ? LoanPaymentKind.PARTIAL : LoanPaymentKind.REGULAR;
        var payment = CreatePaymentEntity(loan, installment.Id, kind, amount, principalPart, interestPart, feePart, 0, paymentDate, request, categoryId, now);

        UpdateInstallmentStatus(installment, now);
        SyncLoanProgress(loan, now);
        loan.ChangeLogs.Add(new LoanChangeLog
        {
            Id = Guid.NewGuid(),
            LoanId = loan.Id,
            Description = kind == LoanPaymentKind.PARTIAL ? "Partial installment payment" : "Installment payment",
            Details = $"Installment #{installment.Number}: {amount}",
            ChangedAt = now
        });

        await _db.SaveChangesAsync(cancellationToken);
        return MapPayment(payment);
    }

    private async Task<LoanPaymentDto> ApplyExtraPrincipalAsync(
        Loan loan,
        RecordLoanPaymentRequest request,
        decimal amount,
        Guid? categoryId,
        DateTime paymentDate,
        DateTime now,
        CancellationToken cancellationToken)
    {
        if (amount > loan.CurrentBalance)
        {
            throw new ValidationAppException(ErrorCodes.InvalidAmount, "Extra payment cannot exceed the outstanding balance.");
        }

        var mode = request.EarlyPaymentMode ?? EarlyPaymentMode.REDUCE_TERM;
        var scenario = BuildScenario(loan, amount, mode, loan.EarlyPaymentPenaltyRate, loan.EarlyPaymentPenaltyFixed);
        var penalty = request.PenaltyAmount.HasValue
            ? LoanAmortizationCalculator.Round(request.PenaltyAmount.Value)
            : scenario.PenaltyAmount;
        var totalCharged = LoanAmortizationCalculator.Round(amount + penalty);

        var payment = CreatePaymentEntity(
            loan, null, LoanPaymentKind.EXTRA_PRINCIPAL, totalCharged, amount, 0, 0, penalty, paymentDate, request, categoryId, now);

        loan.CurrentBalance = scenario.NewBalance;
        loan.TotalExtraPrincipalPaid += amount;
        loan.TotalPrincipalPaid += amount;
        loan.TotalPenaltiesPaid += penalty;
        loan.TotalInterestSaved += scenario.NetInterestSaved;
        loan.UpdatedAt = now;

        RecalculateFutureInstallments(
            loan,
            mode == EarlyPaymentMode.REDUCE_PAYMENT ? scenario.NewPeriodicPayment : loan.PeriodicPayment,
            keepPeriodCount: mode == EarlyPaymentMode.REDUCE_PAYMENT,
            interestSaved: scenario.NetInterestSaved);

        SyncLoanProgress(loan, now);
        loan.ChangeLogs.Add(new LoanChangeLog
        {
            Id = Guid.NewGuid(),
            LoanId = loan.Id,
            Description = "Extra principal payment confirmed",
            Details = $"Extra {amount}; mode {mode}; saved interest {scenario.NetInterestSaved}",
            ChangedAt = now
        });

        await _db.SaveChangesAsync(cancellationToken);
        return MapPayment(payment);
    }

    private async Task<LoanPaymentDto> ApplyFullPayoffAsync(
        Loan loan,
        RecordLoanPaymentRequest request,
        decimal amount,
        Guid? categoryId,
        DateTime paymentDate,
        DateTime now,
        CancellationToken cancellationToken)
    {
        var penalty = request.PenaltyAmount.HasValue
            ? LoanAmortizationCalculator.Round(request.PenaltyAmount.Value)
            : LoanAmortizationCalculator.Round(loan.CurrentBalance * (loan.EarlyPaymentPenaltyRate / 100m) + loan.EarlyPaymentPenaltyFixed);
        var expected = LoanAmortizationCalculator.Round(loan.CurrentBalance + loan.AccruedInterestPending + penalty);
        if (amount + 0.01m < expected)
        {
            throw new ValidationAppException(ErrorCodes.InvalidAmount, $"Full payoff requires at least {expected}.");
        }

        var principalPart = loan.CurrentBalance;
        var interestPart = loan.AccruedInterestPending;
        var scenario = BuildScenario(loan, principalPart, EarlyPaymentMode.REDUCE_TERM, loan.EarlyPaymentPenaltyRate, loan.EarlyPaymentPenaltyFixed);

        var payment = CreatePaymentEntity(
            loan, null, LoanPaymentKind.FULL_PAYOFF, amount, principalPart, interestPart, 0, penalty, paymentDate, request, categoryId, now);

        foreach (var installment in loan.Installments.Where(i => !i.IsLocked && i.Status != LoanInstallmentStatus.PAID))
        {
            installment.Status = LoanInstallmentStatus.PAID;
            installment.IsLocked = true;
            installment.UpdatedAt = now;
        }

        loan.CurrentBalance = 0;
        loan.AccruedInterestPending = 0;
        loan.RemainingInstallments = 0;
        loan.NextPaymentDate = null;
        loan.Status = LoanStatus.PAID_OFF;
        loan.TotalPrincipalPaid += principalPart;
        loan.TotalExtraPrincipalPaid += principalPart;
        loan.TotalInterestPaid += interestPart;
        loan.TotalPenaltiesPaid += penalty;
        loan.TotalInterestSaved += scenario.InterestWithoutExtra;
        loan.UpdatedAt = now;
        loan.ChangeLogs.Add(new LoanChangeLog
        {
            Id = Guid.NewGuid(),
            LoanId = loan.Id,
            Description = "Loan fully paid off",
            Details = $"Amount {amount}",
            ChangedAt = now
        });

        await _db.SaveChangesAsync(cancellationToken);
        return MapPayment(payment);
    }

    private async Task<LoanPaymentDto> ApplyFeePaymentAsync(
        Loan loan,
        RecordLoanPaymentRequest request,
        decimal amount,
        Guid? categoryId,
        DateTime paymentDate,
        DateTime now,
        CancellationToken cancellationToken)
    {
        var payment = CreatePaymentEntity(
            loan, request.InstallmentId, LoanPaymentKind.FEE, amount, 0, 0, amount, 0, paymentDate, request, categoryId, now);
        loan.TotalFeesPaid += amount;
        loan.UpdatedAt = now;
        await _db.SaveChangesAsync(cancellationToken);
        return MapPayment(payment);
    }

    private LoanPayment CreatePaymentEntity(
        Loan loan,
        Guid? installmentId,
        LoanPaymentKind kind,
        decimal amount,
        decimal principal,
        decimal interest,
        decimal fees,
        decimal penalty,
        DateTime paymentDate,
        RecordLoanPaymentRequest request,
        Guid? categoryId,
        DateTime now)
    {
        Guid? transactionId = request.ExistingTransactionId;
        if (request.CreateTransaction && !transactionId.HasValue && categoryId.HasValue)
        {
            var tx = new Transaction
            {
                Id = Guid.NewGuid(),
                Type = TransactionType.EXPENSE,
                Amount = amount,
                Description = kind switch
                {
                    LoanPaymentKind.EXTRA_PRINCIPAL => $"Abono extra: {loan.Name}",
                    LoanPaymentKind.FULL_PAYOFF => $"Liquidación: {loan.Name}",
                    LoanPaymentKind.FEE => $"Cargo préstamo: {loan.Name}",
                    _ => $"Cuota: {loan.Name}"
                },
                Date = paymentDate,
                CategoryId = categoryId.Value,
                PaymentMethod = request.PaymentMethod,
                Notes = request.Notes,
                UserId = _currentUser.UserId,
                CreatedAt = now,
                UpdatedAt = now
            };
            _db.Transactions.Add(tx);
            transactionId = tx.Id;
        }

        var payment = new LoanPayment
        {
            Id = Guid.NewGuid(),
            LoanId = loan.Id,
            InstallmentId = installmentId,
            Kind = kind,
            Amount = amount,
            PrincipalPortion = principal,
            InterestPortion = interest,
            FeePortion = fees,
            PenaltyPortion = penalty,
            Date = paymentDate,
            PaymentMethod = request.PaymentMethod,
            CategoryId = categoryId,
            TransactionId = transactionId,
            Notes = NormalizeOptional(request.Notes),
            CreatedAt = now
        };
        _db.LoanPayments.Add(payment);
        loan.Payments.Add(payment);
        return payment;
    }

    private void RecalculateFutureInstallments(Loan loan, decimal periodicPayment, bool keepPeriodCount, decimal interestSaved)
    {
        var locked = loan.Installments.Where(i => i.IsLocked || i.Status == LoanInstallmentStatus.PAID).ToList();
        var open = loan.Installments.Where(i => !i.IsLocked && i.Status != LoanInstallmentStatus.PAID).OrderBy(i => i.Number).ToList();
        foreach (var item in open)
        {
            _db.LoanInstallments.Remove(item);
            loan.Installments.Remove(item);
        }

        if (loan.CurrentBalance <= 0)
        {
            loan.RemainingInstallments = 0;
            loan.NextPaymentDate = null;
            loan.Status = LoanStatus.PAID_OFF;
            loan.PeriodicPayment = 0;
            return;
        }

        var startNumber = locked.Count == 0 ? 1 : locked.Max(i => i.Number) + 1;
        var firstDue = open.FirstOrDefault()?.DueDate
            ?? loan.NextPaymentDate
            ?? LoanAmortizationCalculator.NextDueDate(_clock.UtcNow.Date, loan.PaymentFrequency, loan.PreferredPaymentDay);
        var remainingHint = keepPeriodCount
            ? Math.Max(1, open.Count)
            : Math.Max(open.Count, loan.RemainingInstallments);

        var schedule = LoanAmortizationCalculator.BuildSchedule(
            loan.CurrentBalance,
            loan.AnnualInterestRate,
            remainingHint,
            loan.PaymentFrequency,
            loan.AmortizationType == AmortizationType.CUSTOM ? AmortizationType.FRENCH : loan.AmortizationType,
            firstDue,
            loan.PreferredPaymentDay,
            overridePeriodCount: keepPeriodCount ? remainingHint : Math.Max(remainingHint * 3, remainingHint + 120),
            overridePeriodicPayment: keepPeriodCount ? null : periodicPayment);

        var now = _clock.UtcNow;
        foreach (var row in schedule.Rows)
        {
            var installment = CreateInstallment(loan.Id, row, now);
            installment.Number = startNumber++;
            loan.Installments.Add(installment);
        }

        loan.PeriodicPayment = keepPeriodCount ? schedule.PeriodicPayment : periodicPayment;
        loan.RemainingInstallments = schedule.PeriodCount;
        loan.NextPaymentDate = schedule.Rows.FirstOrDefault()?.DueDate;
        if (interestSaved > 0)
        {
            // already accumulated by caller when confirming early payment
        }
    }

    private EarlyPaymentScenario BuildScenario(Loan loan, decimal extra, EarlyPaymentMode mode, decimal? penaltyRate, decimal? penaltyFixed)
    {
        return LoanAmortizationCalculator.SimulateEarlyPayment(
            loan.CurrentBalance,
            loan.AnnualInterestRate,
            loan.PaymentFrequency,
            loan.AmortizationType,
            loan.PeriodicPayment,
            Math.Max(1, loan.RemainingInstallments),
            loan.NextPaymentDate,
            extra,
            mode,
            penaltyRate ?? loan.EarlyPaymentPenaltyRate,
            penaltyFixed ?? loan.EarlyPaymentPenaltyFixed,
            loan.PreferredPaymentDay);
    }

    private LoanInstallment ResolveInstallment(Loan loan, Guid? installmentId)
    {
        LoanInstallment? installment;
        if (installmentId.HasValue)
        {
            installment = loan.Installments.FirstOrDefault(i => i.Id == installmentId.Value)
                ?? throw new NotFoundException("Installment not found");
        }
        else
        {
            installment = loan.Installments
                .Where(i => i.Status is LoanInstallmentStatus.PENDING or LoanInstallmentStatus.DUE_SOON or LoanInstallmentStatus.OVERDUE or LoanInstallmentStatus.PARTIALLY_PAID)
                .OrderBy(i => i.DueDate)
                .FirstOrDefault()
                ?? throw new ValidationAppException(ErrorCodes.ValidationError, "No pending installments found.");
        }

        return installment;
    }

    private void SyncLoanProgress(Loan loan, DateTime now)
    {
        var pending = loan.Installments
            .Where(i => i.Status is not LoanInstallmentStatus.PAID)
            .OrderBy(i => i.DueDate)
            .ToList();
        loan.RemainingInstallments = pending.Count;
        loan.NextPaymentDate = pending.FirstOrDefault()?.DueDate;
        if (loan.CurrentBalance <= 0 || pending.Count == 0)
        {
            loan.CurrentBalance = 0;
            loan.Status = LoanStatus.PAID_OFF;
            loan.RemainingInstallments = 0;
            loan.NextPaymentDate = null;
        }

        RefreshStatuses([loan], persist: false);
        loan.UpdatedAt = now;
    }

    private void RefreshStatuses(IEnumerable<Loan> loans, bool persist)
    {
        var today = _clock.UtcNow.Date;
        foreach (var loan in loans)
        {
            foreach (var installment in loan.Installments)
            {
                UpdateInstallmentStatus(installment, today);
                if (persist)
                {
                    installment.UpdatedAt = _clock.UtcNow;
                }
            }
        }
    }

    private static void UpdateInstallmentStatus(LoanInstallment installment, DateTime now)
    {
        var remaining = LoanAmortizationCalculator.Round(installment.TotalAmount - installment.PaidTotal);
        if (remaining <= 0)
        {
            installment.Status = LoanInstallmentStatus.PAID;
            installment.IsLocked = true;
            return;
        }

        if (installment.PaidTotal > 0)
        {
            installment.Status = LoanInstallmentStatus.PARTIALLY_PAID;
            return;
        }

        var due = installment.DueDate.Date;
        if (due < now.Date)
        {
            installment.Status = LoanInstallmentStatus.OVERDUE;
        }
        else if (due <= now.Date.AddDays(3))
        {
            installment.Status = LoanInstallmentStatus.DUE_SOON;
        }
        else
        {
            installment.Status = LoanInstallmentStatus.PENDING;
        }
    }

    private async Task EnsureCategoryAsync(Guid? categoryId, CancellationToken cancellationToken)
    {
        if (!categoryId.HasValue)
        {
            return;
        }

        var category = await _db.Categories.FirstOrDefaultAsync(c => c.Id == categoryId.Value, cancellationToken)
            ?? throw new NotFoundException("Category not found");
        if (category.UserId != _currentUser.UserId)
        {
            throw new ForbiddenException();
        }

        if (category.Type != TransactionType.EXPENSE)
        {
            throw new ValidationAppException(ErrorCodes.CategoryTypeMismatch, "Loan payments require an expense category.");
        }
    }

    private IQueryable<Loan> OwnedQuery() =>
        _db.Loans.Include(l => l.DefaultCategory).Where(l => l.UserId == _currentUser.UserId);

    private async Task<Loan> GetOwnedAsync(Guid id, CancellationToken cancellationToken, bool tracking, bool includeChildren = false)
    {
        IQueryable<Loan> query = tracking ? _db.Loans : _db.Loans.AsNoTracking();
        query = query.Include(l => l.DefaultCategory);
        if (includeChildren)
        {
            query = query.Include(l => l.Installments).Include(l => l.Payments).Include(l => l.ChangeLogs);
        }

        var loan = await query.FirstOrDefaultAsync(l => l.Id == id, cancellationToken)
            ?? throw new NotFoundException("Loan not found");
        if (loan.UserId != _currentUser.UserId)
        {
            throw new ForbiddenException();
        }

        return loan;
    }

    private static LoanInstallment CreateInstallment(Guid loanId, AmortizationRow row, DateTime now) => new()
    {
        Id = Guid.NewGuid(),
        LoanId = loanId,
        Number = row.Number,
        DueDate = row.DueDate,
        PrincipalAmount = row.Principal,
        InterestAmount = row.Interest,
        FeeAmount = row.Fee,
        TotalAmount = row.Payment,
        RemainingBalanceAfter = row.RemainingBalance,
        Status = LoanInstallmentStatus.PENDING,
        CreatedAt = now,
        UpdatedAt = now
    };

    private LoanDto MapLoan(Loan loan)
    {
        var dto = _mapper.Map<LoanDto>(loan);
        dto.ReminderDays = ParseReminderDays(loan.ReminderDaysCsv);
        dto.PaidOffPercentage = loan.OriginalPrincipal == 0
            ? 0
            : LoanAmortizationCalculator.Round(loan.TotalPrincipalPaid / loan.OriginalPrincipal * 100);
        dto.DefaultCategoryName = loan.DefaultCategory?.Name;
        return dto;
    }

    private static LoanInstallmentDto MapInstallment(LoanInstallment installment) => new()
    {
        Id = installment.Id,
        LoanId = installment.LoanId,
        Number = installment.Number,
        DueDate = installment.DueDate,
        PrincipalAmount = installment.PrincipalAmount,
        InterestAmount = installment.InterestAmount,
        FeeAmount = installment.FeeAmount,
        TotalAmount = installment.TotalAmount,
        PaidPrincipal = installment.PaidPrincipal,
        PaidInterest = installment.PaidInterest,
        PaidFees = installment.PaidFees,
        PaidTotal = installment.PaidTotal,
        RemainingAmount = LoanAmortizationCalculator.Round(installment.TotalAmount - installment.PaidTotal),
        RemainingBalanceAfter = installment.RemainingBalanceAfter,
        Status = installment.Status,
        IsLocked = installment.IsLocked
    };

    private static LoanPaymentDto MapPayment(LoanPayment payment) => new()
    {
        Id = payment.Id,
        LoanId = payment.LoanId,
        InstallmentId = payment.InstallmentId,
        Kind = payment.Kind,
        Amount = payment.Amount,
        PrincipalPortion = payment.PrincipalPortion,
        InterestPortion = payment.InterestPortion,
        FeePortion = payment.FeePortion,
        PenaltyPortion = payment.PenaltyPortion,
        Date = payment.Date,
        PaymentMethod = payment.PaymentMethod,
        CategoryId = payment.CategoryId,
        CategoryName = payment.Category?.Name,
        TransactionId = payment.TransactionId,
        Notes = payment.Notes,
        CreatedAt = payment.CreatedAt
    };

    private static AmortizationScheduleDto MapSchedule(AmortizationSchedule schedule) => new()
    {
        PeriodicPayment = schedule.PeriodicPayment,
        TotalInterest = schedule.TotalInterest,
        TotalPayment = schedule.TotalPayment,
        TotalPrincipal = schedule.TotalPrincipal,
        EstimatedEndDate = schedule.EstimatedEndDate,
        PeriodCount = schedule.PeriodCount,
        IsEstimate = schedule.IsEstimate,
        Rows = schedule.Rows.Select(r => new AmortizationRowDto
        {
            Number = r.Number,
            DueDate = r.DueDate,
            Principal = r.Principal,
            Interest = r.Interest,
            Fee = r.Fee,
            Payment = r.Payment,
            RemainingBalance = r.RemainingBalance
        }).ToList()
    };

    private static IReadOnlyList<LoanBalancePointDto> BuildDebtEvolution(IReadOnlyList<Loan> loans)
    {
        var points = new List<LoanBalancePointDto>();
        foreach (var loan in loans.Where(l => l.Status != LoanStatus.CANCELLED))
        {
            var running = loan.OriginalPrincipal;
            points.Add(new LoanBalancePointDto { Date = loan.DisbursementDate.Date, Balance = running });
            foreach (var payment in loan.Payments.OrderBy(p => p.Date))
            {
                if (payment.PrincipalPortion <= 0)
                {
                    continue;
                }

                running = LoanAmortizationCalculator.Round(Math.Max(0, running - payment.PrincipalPortion));
                points.Add(new LoanBalancePointDto { Date = payment.Date.Date, Balance = running });
            }
        }

        return points
            .GroupBy(p => p.Date.Date)
            .Select(g => new LoanBalancePointDto
            {
                Date = g.Key,
                Balance = LoanAmortizationCalculator.Round(g.Sum(x => x.Balance))
            })
            .OrderBy(p => p.Date)
            .ToList();
    }

    private static decimal ToMonthlyEquivalent(Loan loan) => loan.PaymentFrequency switch
    {
        LoanPaymentFrequency.WEEKLY => LoanAmortizationCalculator.Round(loan.PeriodicPayment * 52 / 12),
        LoanPaymentFrequency.BIWEEKLY => LoanAmortizationCalculator.Round(loan.PeriodicPayment * 26 / 12),
        _ => loan.PeriodicPayment
    };

    private static string ToReminderCsv(IReadOnlyList<int>? days)
    {
        var values = (days ?? new[] { 7, 3, 1, 0 })
            .Where(d => d >= 0 && d <= 365)
            .Distinct()
            .OrderByDescending(d => d)
            .ToList();
        return values.Count == 0 ? "7,3,1,0" : string.Join(',', values);
    }

    private static IReadOnlyList<int> ParseReminderDays(string csv) =>
        (csv ?? string.Empty)
            .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(part => int.TryParse(part, out var value) ? value : (int?)null)
            .Where(v => v.HasValue)
            .Select(v => v!.Value)
            .ToList();

    private static string? NormalizeOptional(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}
