namespace FinTrack.Application.DTOs.Savings;

public class SavingsGoalDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal TargetAmount { get; set; }
    public decimal CurrentAmount { get; set; }
    public decimal ProgressPercentage { get; set; }
    public DateTime? TargetDate { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class CreateSavingsGoalRequest
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal TargetAmount { get; set; }
    public DateTime? TargetDate { get; set; }
}

public class UpdateSavingsGoalRequest
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal TargetAmount { get; set; }
    public DateTime? TargetDate { get; set; }
}

public class SavingsContributionDto
{
    public Guid Id { get; set; }
    public Guid SavingsGoalId { get; set; }
    public decimal Amount { get; set; }
    public DateTime Date { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CreateContributionRequest
{
    public decimal Amount { get; set; }
    public DateTime Date { get; set; }
}
