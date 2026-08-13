using AutoMapper;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using FinTrack.Application.Common;
using FinTrack.Application.DTOs.Budgets;
using FinTrack.Application.Interfaces;
using FinTrack.Domain.Entities;
using FinTrack.Domain.Enums;

namespace FinTrack.Application.Services;

public class BudgetService : IBudgetService
{
    private readonly IFinTrackDbContext _db;
    private readonly ICurrentUser _currentUser;
    private readonly IDateTimeProvider _clock;
    private readonly IMapper _mapper;
    private readonly IValidator<CreateBudgetRequest> _createValidator;
    private readonly IValidator<UpdateBudgetRequest> _updateValidator;

    public BudgetService(
        IFinTrackDbContext db,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        IMapper mapper,
        IValidator<CreateBudgetRequest> createValidator,
        IValidator<UpdateBudgetRequest> updateValidator)
    {
        _db = db;
        _currentUser = currentUser;
        _clock = clock;
        _mapper = mapper;
        _createValidator = createValidator;
        _updateValidator = updateValidator;
    }

    public async Task<IReadOnlyList<BudgetDto>> GetAsync(BudgetQuery query, CancellationToken cancellationToken = default)
    {
        var now = _clock.UtcNow;
        var month = query.Month ?? now.Month;
        var year = query.Year ?? now.Year;

        var budgets = await _db.Budgets
            .AsNoTracking()
            .Include(b => b.Category)
            .Where(b => b.UserId == _currentUser.UserId && b.Month == month && b.Year == year)
            .OrderBy(b => b.Category.Name)
            .ToListAsync(cancellationToken);

        var spentByCategory = await _db.Transactions
            .AsNoTracking()
            .Where(t => t.UserId == _currentUser.UserId
                        && t.Type == TransactionType.EXPENSE
                        && t.Date.Month == month
                        && t.Date.Year == year)
            .GroupBy(t => t.CategoryId)
            .Select(g => new { CategoryId = g.Key, Spent = g.Sum(t => t.Amount) })
            .ToDictionaryAsync(x => x.CategoryId, x => x.Spent, cancellationToken);

        return budgets.Select(budget => MapBudget(budget, spentByCategory.GetValueOrDefault(budget.CategoryId))).ToList();
    }

    public async Task<BudgetDto> CreateAsync(CreateBudgetRequest request, CancellationToken cancellationToken = default)
    {
        await _createValidator.ValidateAndThrowAppAsync(request, cancellationToken);

        var category = await _db.Categories.FirstOrDefaultAsync(c => c.Id == request.CategoryId, cancellationToken)
                       ?? throw new NotFoundException("Category not found");
        if (category.UserId != _currentUser.UserId)
        {
            throw new ForbiddenException();
        }

        if (category.Type != TransactionType.EXPENSE)
        {
            throw new ValidationAppException(ErrorCodes.CategoryTypeMismatch, "Budgets can only be created for expense categories");
        }

        var exists = await _db.Budgets.AnyAsync(
            b => b.UserId == _currentUser.UserId
                 && b.CategoryId == request.CategoryId
                 && b.Month == request.Month
                 && b.Year == request.Year,
            cancellationToken);

        if (exists)
        {
            throw new ConflictException(ErrorCodes.BudgetAlreadyExists, "A budget already exists for this category and month");
        }

        var now = _clock.UtcNow;
        var budget = new Budget
        {
            Id = Guid.NewGuid(),
            CategoryId = request.CategoryId,
            Amount = decimal.Round(request.Amount, 2),
            Month = request.Month,
            Year = request.Year,
            UserId = _currentUser.UserId,
            CreatedAt = now,
            UpdatedAt = now
        };

        _db.Budgets.Add(budget);
        await _db.SaveChangesAsync(cancellationToken);

        budget.Category = category;
        var spent = await GetSpentAsync(request.CategoryId, request.Month, request.Year, cancellationToken);
        return MapBudget(budget, spent);
    }

    public async Task<BudgetDto> UpdateAsync(Guid id, UpdateBudgetRequest request, CancellationToken cancellationToken = default)
    {
        await _updateValidator.ValidateAndThrowAppAsync(request, cancellationToken);
        var budget = await _db.Budgets.Include(b => b.Category).FirstOrDefaultAsync(b => b.Id == id, cancellationToken)
                     ?? throw new NotFoundException("Budget not found");
        if (budget.UserId != _currentUser.UserId)
        {
            throw new ForbiddenException();
        }

        budget.Amount = decimal.Round(request.Amount, 2);
        budget.UpdatedAt = _clock.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);

        var spent = await GetSpentAsync(budget.CategoryId, budget.Month, budget.Year, cancellationToken);
        return MapBudget(budget, spent);
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var budget = await _db.Budgets.FirstOrDefaultAsync(b => b.Id == id, cancellationToken)
                     ?? throw new NotFoundException("Budget not found");
        if (budget.UserId != _currentUser.UserId)
        {
            throw new ForbiddenException();
        }

        _db.Budgets.Remove(budget);
        await _db.SaveChangesAsync(cancellationToken);
    }

    private async Task<decimal> GetSpentAsync(Guid categoryId, int month, int year, CancellationToken cancellationToken)
    {
        return await _db.Transactions
            .Where(t => t.UserId == _currentUser.UserId
                        && t.CategoryId == categoryId
                        && t.Type == TransactionType.EXPENSE
                        && t.Date.Month == month
                        && t.Date.Year == year)
            .SumAsync(t => t.Amount, cancellationToken);
    }

    private BudgetDto MapBudget(Budget budget, decimal spent)
    {
        var dto = _mapper.Map<BudgetDto>(budget);
        dto.Spent = spent;
        dto.Available = budget.Amount - spent;
        dto.UsedPercentage = budget.Amount == 0 ? 0 : Math.Round(spent / budget.Amount * 100, 2);
        dto.Status = dto.UsedPercentage switch
        {
            > 100 => "EXCEEDED",
            >= 100 => "REACHED",
            >= 80 => "WARNING",
            _ => "OK"
        };
        return dto;
    }
}
