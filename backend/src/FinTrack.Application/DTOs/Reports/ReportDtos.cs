namespace FinTrack.Application.DTOs.Reports;

public class MonthlyReportDto
{
    public int Month { get; set; }
    public int Year { get; set; }
    public decimal Income { get; set; }
    public decimal Expense { get; set; }
    public decimal Savings { get; set; }
    public decimal Balance { get; set; }
    public IReadOnlyList<CategoryExpenseDto> TopExpenseCategories { get; set; } = [];
}

public class CategoryExpenseDto
{
    public Guid CategoryId { get; set; }
    public string CategoryName { get; set; } = string.Empty;
    public string? CategoryIcon { get; set; }
    public bool CategoryIsDefault { get; set; }
    public decimal Amount { get; set; }
    public decimal Percentage { get; set; }
}

public class IncomeVsExpensesDto
{
    public IReadOnlyList<MonthlyPointDto> Points { get; set; } = [];
}

public class MonthlyPointDto
{
    public int Month { get; set; }
    public int Year { get; set; }
    public decimal Income { get; set; }
    public decimal Expense { get; set; }
    public decimal Savings { get; set; }
}

public class BalanceHistoryDto
{
    public IReadOnlyList<BalancePointDto> Points { get; set; } = [];
}

public class BalancePointDto
{
    public DateTime Date { get; set; }
    public decimal Balance { get; set; }
}
