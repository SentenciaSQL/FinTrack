using FinTrack.Domain.Enums;

namespace FinTrack.Domain.Entities;

public class Transaction
{
    public Guid Id { get; set; }
    public TransactionType Type { get; set; }
    public decimal Amount { get; set; }
    public string Description { get; set; } = string.Empty;
    public DateTime Date { get; set; }
    public Guid CategoryId { get; set; }
    public PaymentMethod PaymentMethod { get; set; }
    public string? Notes { get; set; }
    public Guid UserId { get; set; }
    public Guid? RecurringTransactionId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public User User { get; set; } = null!;
    public Category Category { get; set; } = null!;
    public RecurringTransaction? RecurringTransaction { get; set; }
}
