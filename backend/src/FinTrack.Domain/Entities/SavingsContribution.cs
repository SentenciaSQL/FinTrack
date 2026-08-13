namespace FinTrack.Domain.Entities;

public class SavingsContribution
{
    public Guid Id { get; set; }
    public Guid SavingsGoalId { get; set; }
    public decimal Amount { get; set; }
    public DateTime Date { get; set; }
    public DateTime CreatedAt { get; set; }

    public SavingsGoal SavingsGoal { get; set; } = null!;
}
