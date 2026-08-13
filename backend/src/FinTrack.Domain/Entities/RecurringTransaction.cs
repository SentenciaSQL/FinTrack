using FinTrack.Domain.Enums;

namespace FinTrack.Domain.Entities;

public class RecurringTransaction
{
    public Guid Id { get; set; }
    public TransactionType Type { get; set; }
    public decimal Amount { get; set; }
    public string Description { get; set; } = string.Empty;
    public Guid CategoryId { get; set; }
    public RecurrenceFrequency Frequency { get; set; }
    public DateTime NextExecutionDate { get; set; }
    public bool Active { get; set; } = true;
    public Guid UserId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public User User { get; set; } = null!;
    public Category Category { get; set; } = null!;
    public ICollection<RecurringExecution> Executions { get; set; } = new List<RecurringExecution>();
    public ICollection<Transaction> GeneratedTransactions { get; set; } = new List<Transaction>();
}
