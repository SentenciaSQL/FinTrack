using AutoMapper;
using Microsoft.EntityFrameworkCore;
using FinTrack.Application.DTOs.Dashboard;
using FinTrack.Application.DTOs.Transactions;
using FinTrack.Application.Interfaces;
using FinTrack.Domain.Enums;

namespace FinTrack.Application.Services;

public class DashboardService : IDashboardService
{
    private readonly IFinTrackDbContext _db;
    private readonly ICurrentUser _currentUser;
    private readonly IDateTimeProvider _clock;
    private readonly IMapper _mapper;

    public DashboardService(IFinTrackDbContext db, ICurrentUser currentUser, IDateTimeProvider clock, IMapper mapper)
    {
        _db = db;
        _currentUser = currentUser;
        _clock = clock;
        _mapper = mapper;
    }

    public async Task<DashboardDto> GetAsync(CancellationToken cancellationToken = default)
    {
        var userId = _currentUser.UserId;
        var now = _clock.UtcNow;
        var month = now.Month;
        var year = now.Year;

        var transactions = _db.Transactions.AsNoTracking().Where(t => t.UserId == userId);

        var incomeTotal = await transactions.Where(t => t.Type == TransactionType.INCOME).SumAsync(t => t.Amount, cancellationToken);
        var expenseTotal = await transactions.Where(t => t.Type == TransactionType.EXPENSE).SumAsync(t => t.Amount, cancellationToken);

        var monthlyIncome = await transactions
            .Where(t => t.Type == TransactionType.INCOME && t.Date.Month == month && t.Date.Year == year)
            .SumAsync(t => t.Amount, cancellationToken);

        var monthlyExpense = await transactions
            .Where(t => t.Type == TransactionType.EXPENSE && t.Date.Month == month && t.Date.Year == year)
            .SumAsync(t => t.Amount, cancellationToken);

        var totalBudget = await _db.Budgets
            .Where(b => b.UserId == userId && b.Month == month && b.Year == year)
            .SumAsync(b => b.Amount, cancellationToken);

        var recent = await _db.Transactions
            .AsNoTracking()
            .Include(t => t.Category)
            .Where(t => t.UserId == userId)
            .OrderByDescending(t => t.Date)
            .ThenByDescending(t => t.CreatedAt)
            .Take(8)
            .ToListAsync(cancellationToken);

        var categoryGroups = await _db.Transactions
            .AsNoTracking()
            .Include(t => t.Category)
            .Where(t => t.UserId == userId && t.Type == TransactionType.EXPENSE && t.Date.Month == month && t.Date.Year == year)
            .GroupBy(t => new { t.CategoryId, t.Category.Name, t.Category.Icon, t.Category.IsDefault })
            .Select(g => new CategoryBreakdownDto
            {
                CategoryId = g.Key.CategoryId,
                CategoryName = g.Key.Name,
                CategoryIcon = g.Key.Icon,
                CategoryIsDefault = g.Key.IsDefault,
                Amount = g.Sum(t => t.Amount)
            })
            .OrderByDescending(x => x.Amount)
            .ToListAsync(cancellationToken);

        foreach (var item in categoryGroups)
        {
            item.Percentage = monthlyExpense == 0 ? 0 : Math.Round(item.Amount / monthlyExpense * 100, 2);
        }

        var start = new DateTime(year, month, 1, 0, 0, 0, DateTimeKind.Utc).AddMonths(-5);
        var history = await transactions
            .Where(t => t.Date >= start)
            .GroupBy(t => new { t.Date.Year, t.Date.Month })
            .Select(g => new IncomeExpensePointDto
            {
                Year = g.Key.Year,
                Month = g.Key.Month,
                Income = g.Where(t => t.Type == TransactionType.INCOME).Sum(t => t.Amount),
                Expense = g.Where(t => t.Type == TransactionType.EXPENSE).Sum(t => t.Amount)
            })
            .ToListAsync(cancellationToken);

        var points = Enumerable.Range(0, 6)
            .Select(i => start.AddMonths(i))
            .Select(d =>
            {
                var match = history.FirstOrDefault(h => h.Year == d.Year && h.Month == d.Month);
                return new IncomeExpensePointDto
                {
                    Year = d.Year,
                    Month = d.Month,
                    Label = d.ToString("MMM"),
                    Income = match?.Income ?? 0,
                    Expense = match?.Expense ?? 0
                };
            })
            .ToList();

        return new DashboardDto
        {
            CurrentBalance = incomeTotal - expenseTotal,
            MonthlyIncome = monthlyIncome,
            MonthlyExpense = monthlyExpense,
            MonthlySavings = monthlyIncome - monthlyExpense,
            TotalBudget = totalBudget,
            TotalBudgetSpent = monthlyExpense,
            BudgetUsedPercentage = totalBudget == 0 ? 0 : Math.Round(monthlyExpense / totalBudget * 100, 2),
            RecentTransactions = _mapper.Map<IReadOnlyList<TransactionDto>>(recent),
            ExpensesByCategory = categoryGroups,
            IncomeVsExpenses = points
        };
    }
}
