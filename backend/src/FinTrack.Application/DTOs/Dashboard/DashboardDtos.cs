using FinTrack.Application.DTOs.Transactions;

namespace FinTrack.Application.DTOs.Dashboard;

public class DashboardDto
{
    public decimal CurrentBalance { get; set; }
    public decimal MonthlyIncome { get; set; }
    public decimal MonthlyExpense { get; set; }
    public decimal MonthlySavings { get; set; }
    public decimal BudgetUsedPercentage { get; set; }
    public decimal TotalBudget { get; set; }
    public decimal TotalBudgetSpent { get; set; }
    public IReadOnlyList<TransactionDto> RecentTransactions { get; set; } = [];
    public IReadOnlyList<CategoryBreakdownDto> ExpensesByCategory { get; set; } = [];
    public IReadOnlyList<IncomeExpensePointDto> IncomeVsExpenses { get; set; } = [];
}

public class CategoryBreakdownDto
{
    public Guid CategoryId { get; set; }
    public string CategoryName { get; set; } = string.Empty;
    public string? CategoryIcon { get; set; }
    public bool CategoryIsDefault { get; set; }
    public decimal Amount { get; set; }
    public decimal Percentage { get; set; }
}

public class IncomeExpensePointDto
{
    public string Label { get; set; } = string.Empty;
    public int Month { get; set; }
    public int Year { get; set; }
    public decimal Income { get; set; }
    public decimal Expense { get; set; }
}
