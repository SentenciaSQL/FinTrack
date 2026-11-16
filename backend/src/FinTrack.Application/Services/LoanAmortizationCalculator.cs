using FinTrack.Domain.Enums;

namespace FinTrack.Application.Services;

public sealed class AmortizationRow
{
    public int Number { get; init; }
    public DateTime DueDate { get; init; }
    public decimal Principal { get; init; }
    public decimal Interest { get; init; }
    public decimal Fee { get; init; }
    public decimal Payment { get; init; }
    public decimal RemainingBalance { get; init; }
}

public sealed class AmortizationSchedule
{
    public decimal PeriodicPayment { get; init; }
    public decimal TotalInterest { get; init; }
    public decimal TotalPayment { get; init; }
    public decimal TotalPrincipal { get; init; }
    public DateTime EstimatedEndDate { get; init; }
    public int PeriodCount { get; init; }
    public bool IsEstimate { get; init; }
    public IReadOnlyList<AmortizationRow> Rows { get; init; } = Array.Empty<AmortizationRow>();
}

public sealed class EarlyPaymentScenario
{
    public EarlyPaymentMode Mode { get; init; }
    public decimal ExtraPayment { get; init; }
    public decimal PenaltyAmount { get; init; }
    public decimal NewBalance { get; init; }
    public decimal PreviousPeriodicPayment { get; init; }
    public decimal NewPeriodicPayment { get; init; }
    public decimal PaymentReduction { get; init; }
    public int PreviousRemainingPeriods { get; init; }
    public int NewRemainingPeriods { get; init; }
    public int PeriodsSaved { get; init; }
    public DateTime? PreviousEndDate { get; init; }
    public DateTime? NewEndDate { get; init; }
    public int DaysSaved { get; init; }
    public decimal InterestWithoutExtra { get; init; }
    public decimal InterestWithExtra { get; init; }
    public decimal GrossInterestSaved { get; init; }
    public decimal NetInterestSaved { get; init; }
}

public static class LoanAmortizationCalculator
{
    public static int PeriodsPerYear(LoanPaymentFrequency frequency) => frequency switch
    {
        LoanPaymentFrequency.WEEKLY => 52,
        LoanPaymentFrequency.BIWEEKLY => 26,
        _ => 12
    };

    public static int TotalPeriods(int termMonths, LoanPaymentFrequency frequency) => frequency switch
    {
        LoanPaymentFrequency.WEEKLY => Math.Max(1, (int)Math.Round(termMonths * 52.0 / 12.0)),
        LoanPaymentFrequency.BIWEEKLY => Math.Max(1, (int)Math.Round(termMonths * 26.0 / 12.0)),
        _ => Math.Max(1, termMonths)
    };

    public static decimal PeriodicRate(decimal annualRatePercent, LoanPaymentFrequency frequency)
    {
        var annual = annualRatePercent / 100m;
        return annual / PeriodsPerYear(frequency);
    }

    public static DateTime NextDueDate(DateTime from, LoanPaymentFrequency frequency, int? preferredDay = null)
    {
        var next = frequency switch
        {
            LoanPaymentFrequency.WEEKLY => from.AddDays(7),
            LoanPaymentFrequency.BIWEEKLY => from.AddDays(14),
            _ => from.AddMonths(1)
        };

        if (frequency == LoanPaymentFrequency.MONTHLY && preferredDay is >= 1 and <= 28)
        {
            var day = Math.Min(preferredDay.Value, DateTime.DaysInMonth(next.Year, next.Month));
            next = new DateTime(next.Year, next.Month, day, 0, 0, 0, DateTimeKind.Utc);
        }

        return DateTime.SpecifyKind(next.Date, DateTimeKind.Utc);
    }

    public static decimal FrenchPayment(decimal principal, decimal periodicRate, int periods)
    {
        if (principal <= 0 || periods <= 0)
        {
            return 0;
        }

        if (periodicRate == 0)
        {
            return Round(principal / periods);
        }

        var r = (double)periodicRate;
        var n = periods;
        var factor = Math.Pow(1 + r, n);
        var payment = (double)principal * r * factor / (factor - 1);
        return Round((decimal)payment);
    }

    public static AmortizationSchedule BuildSchedule(
        decimal principal,
        decimal annualRatePercent,
        int termMonths,
        LoanPaymentFrequency frequency,
        AmortizationType amortizationType,
        DateTime firstDueDate,
        int? preferredPaymentDay = null,
        decimal additionalFeesDistributed = 0,
        int? overridePeriodCount = null,
        decimal? overridePeriodicPayment = null,
        bool isEstimate = false)
    {
        var periods = overridePeriodCount ?? TotalPeriods(termMonths, frequency);
        var rate = PeriodicRate(annualRatePercent, frequency);
        var feePerPeriod = periods > 0 ? Round(additionalFeesDistributed / periods) : 0m;

        decimal payment;
        if (overridePeriodicPayment.HasValue)
        {
            payment = Round(overridePeriodicPayment.Value);
        }
        else if (amortizationType == AmortizationType.GERMAN)
        {
            payment = 0;
        }
        else
        {
            payment = FrenchPayment(principal, rate, periods);
        }

        var rows = new List<AmortizationRow>(periods);
        var balance = Round(principal);
        var totalInterest = 0m;
        var totalPayment = 0m;
        var totalPrincipal = 0m;
        var due = DateTime.SpecifyKind(firstDueDate.Date, DateTimeKind.Utc);

        for (var i = 1; i <= periods && balance > 0; i++)
        {
            var interest = Round(balance * rate);
            decimal principalPart;
            decimal installmentPayment;

            if (amortizationType == AmortizationType.GERMAN)
            {
                principalPart = Round(principal / periods);
                if (i == periods || principalPart > balance)
                {
                    principalPart = balance;
                }

                installmentPayment = Round(principalPart + interest + feePerPeriod);
            }
            else
            {
                installmentPayment = payment;
                if (i == periods || installmentPayment > balance + interest + feePerPeriod)
                {
                    principalPart = balance;
                    installmentPayment = Round(principalPart + interest + feePerPeriod);
                }
                else
                {
                    principalPart = Round(installmentPayment - interest - feePerPeriod);
                    if (principalPart > balance)
                    {
                        principalPart = balance;
                        installmentPayment = Round(principalPart + interest + feePerPeriod);
                    }
                }
            }

            balance = Round(balance - principalPart);
            if (balance < 0.01m)
            {
                balance = 0;
            }

            totalInterest += interest;
            totalPayment += installmentPayment;
            totalPrincipal += principalPart;

            rows.Add(new AmortizationRow
            {
                Number = i,
                DueDate = due,
                Principal = principalPart,
                Interest = interest,
                Fee = feePerPeriod,
                Payment = installmentPayment,
                RemainingBalance = balance
            });

            due = NextDueDate(due, frequency, preferredPaymentDay);
        }

        return new AmortizationSchedule
        {
            PeriodicPayment = rows.Count == 0 ? 0 : (amortizationType == AmortizationType.GERMAN
                ? rows[0].Payment
                : rows.Select(r => r.Payment).DefaultIfEmpty(0).Max()),
            TotalInterest = Round(totalInterest),
            TotalPayment = Round(totalPayment),
            TotalPrincipal = Round(totalPrincipal),
            EstimatedEndDate = rows.Count == 0 ? firstDueDate : rows[^1].DueDate,
            PeriodCount = rows.Count,
            IsEstimate = isEstimate || amortizationType == AmortizationType.CUSTOM,
            Rows = rows
        };
    }

    public static EarlyPaymentScenario SimulateEarlyPayment(
        decimal currentBalance,
        decimal annualRatePercent,
        LoanPaymentFrequency frequency,
        AmortizationType amortizationType,
        decimal currentPeriodicPayment,
        int remainingPeriods,
        DateTime? nextPaymentDate,
        decimal extraPayment,
        EarlyPaymentMode mode,
        decimal penaltyRatePercent = 0,
        decimal penaltyFixed = 0,
        int? preferredPaymentDay = null)
    {
        var balance = Round(currentBalance);
        var penalty = Round(Math.Max(0, balance * (penaltyRatePercent / 100m) + penaltyFixed));
        var appliedExtra = Round(Math.Max(0, Math.Min(extraPayment, balance)));
        var newBalance = Round(Math.Max(0, balance - appliedExtra));

        var without = BuildSchedule(
            balance,
            annualRatePercent,
            remainingPeriods,
            frequency,
            amortizationType == AmortizationType.CUSTOM ? AmortizationType.FRENCH : amortizationType,
            nextPaymentDate ?? DateTime.UtcNow.Date,
            preferredPaymentDay,
            overridePeriodCount: remainingPeriods,
            overridePeriodicPayment: amortizationType == AmortizationType.GERMAN ? null : currentPeriodicPayment);

        AmortizationSchedule with;
        if (newBalance <= 0)
        {
            with = new AmortizationSchedule
            {
                PeriodicPayment = 0,
                TotalInterest = 0,
                TotalPayment = 0,
                TotalPrincipal = 0,
                EstimatedEndDate = nextPaymentDate ?? DateTime.UtcNow.Date,
                PeriodCount = 0,
                Rows = Array.Empty<AmortizationRow>()
            };
        }
        else if (mode == EarlyPaymentMode.REDUCE_PAYMENT)
        {
            with = BuildSchedule(
                newBalance,
                annualRatePercent,
                remainingPeriods,
                frequency,
                amortizationType == AmortizationType.CUSTOM ? AmortizationType.FRENCH : amortizationType,
                nextPaymentDate ?? DateTime.UtcNow.Date,
                preferredPaymentDay,
                overridePeriodCount: remainingPeriods);
        }
        else
        {
            // Keep the original installment; allow enough periods for the balance to reach zero.
            with = BuildSchedule(
                newBalance,
                annualRatePercent,
                remainingPeriods,
                frequency,
                amortizationType == AmortizationType.CUSTOM ? AmortizationType.FRENCH : amortizationType,
                nextPaymentDate ?? DateTime.UtcNow.Date,
                preferredPaymentDay,
                overridePeriodCount: Math.Max(remainingPeriods * 3, remainingPeriods + 120),
                overridePeriodicPayment: currentPeriodicPayment);
        }

        var grossSaved = Round(Math.Max(0, without.TotalInterest - with.TotalInterest));
        var previousEnd = without.Rows.Count == 0 ? nextPaymentDate : without.EstimatedEndDate;
        var newEnd = with.Rows.Count == 0 ? nextPaymentDate : with.EstimatedEndDate;
        var daysSaved = previousEnd.HasValue && newEnd.HasValue
            ? Math.Max(0, (int)(previousEnd.Value.Date - newEnd.Value.Date).TotalDays)
            : 0;

        return new EarlyPaymentScenario
        {
            Mode = mode,
            ExtraPayment = appliedExtra,
            PenaltyAmount = penalty,
            NewBalance = newBalance,
            PreviousPeriodicPayment = Round(currentPeriodicPayment),
            NewPeriodicPayment = with.PeriodicPayment,
            PaymentReduction = Round(Math.Max(0, currentPeriodicPayment - with.PeriodicPayment)),
            PreviousRemainingPeriods = remainingPeriods,
            NewRemainingPeriods = with.PeriodCount,
            PeriodsSaved = Math.Max(0, remainingPeriods - with.PeriodCount),
            PreviousEndDate = previousEnd,
            NewEndDate = newEnd,
            DaysSaved = daysSaved,
            InterestWithoutExtra = without.TotalInterest,
            InterestWithExtra = with.TotalInterest,
            GrossInterestSaved = grossSaved,
            NetInterestSaved = Round(Math.Max(0, grossSaved - penalty))
        };
    }

    public static decimal Round(decimal value) => decimal.Round(value, 2, MidpointRounding.AwayFromZero);
}
