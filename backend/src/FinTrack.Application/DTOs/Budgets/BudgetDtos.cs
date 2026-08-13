namespace FinTrack.Application.DTOs.Budgets;

public class BudgetDto
{
    public Guid Id { get; set; }
    public Guid CategoryId { get; set; }
    public string CategoryName { get; set; } = string.Empty;
    public string? CategoryIcon { get; set; }
    public bool CategoryIsDefault { get; set; }
    public decimal Amount { get; set; }
    public decimal Spent { get; set; }
    public decimal Available { get; set; }
    public decimal UsedPercentage { get; set; }
    public string Status { get; set; } = "OK";
    public int Month { get; set; }
    public int Year { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class CreateBudgetRequest
{
    public Guid CategoryId { get; set; }
    public decimal Amount { get; set; }
    public int Month { get; set; }
    public int Year { get; set; }
}

public class UpdateBudgetRequest
{
    public decimal Amount { get; set; }
}

public class BudgetQuery
{
    public int? Month { get; set; }
    public int? Year { get; set; }
}
