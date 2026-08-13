using FinTrack.Domain.Enums;

namespace FinTrack.Application.DTOs.Recurring;

public class RecurringTransactionDto
{
    public Guid Id { get; set; }
    public TransactionType Type { get; set; }
    public decimal Amount { get; set; }
    public string Description { get; set; } = string.Empty;
    public Guid CategoryId { get; set; }
    public string CategoryName { get; set; } = string.Empty;
    public string? CategoryIcon { get; set; }
    public bool CategoryIsDefault { get; set; }
    public RecurrenceFrequency Frequency { get; set; }
    public DateTime NextExecutionDate { get; set; }
    public bool Active { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class CreateRecurringTransactionRequest
{
    public TransactionType Type { get; set; }
    public decimal Amount { get; set; }
    public string Description { get; set; } = string.Empty;
    public Guid CategoryId { get; set; }
    public RecurrenceFrequency Frequency { get; set; }
    public DateTime NextExecutionDate { get; set; }
    public bool Active { get; set; } = true;
}

public class UpdateRecurringTransactionRequest
{
    public TransactionType Type { get; set; }
    public decimal Amount { get; set; }
    public string Description { get; set; } = string.Empty;
    public Guid CategoryId { get; set; }
    public RecurrenceFrequency Frequency { get; set; }
    public DateTime NextExecutionDate { get; set; }
    public bool Active { get; set; }
}
