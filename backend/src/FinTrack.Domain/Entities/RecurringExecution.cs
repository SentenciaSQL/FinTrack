namespace FinTrack.Domain.Entities;

public class RecurringExecution
{
    public Guid Id { get; set; }
    public Guid RecurringTransactionId { get; set; }
    public DateTime ExecutionDate { get; set; }
    public Guid TransactionId { get; set; }
    public DateTime CreatedAt { get; set; }

    public RecurringTransaction RecurringTransaction { get; set; } = null!;
    public Transaction Transaction { get; set; } = null!;
}
