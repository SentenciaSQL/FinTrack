using FinTrack.Domain.Enums;

namespace FinTrack.Application.DTOs.Transactions;

public class TransactionDto
{
    public Guid Id { get; set; }
    public TransactionType Type { get; set; }
    public decimal Amount { get; set; }
    public string Description { get; set; } = string.Empty;
    public DateTime Date { get; set; }
    public Guid CategoryId { get; set; }
    public string CategoryName { get; set; } = string.Empty;
    public string? CategoryIcon { get; set; }
    public bool CategoryIsDefault { get; set; }
    public PaymentMethod PaymentMethod { get; set; }
    public string? Notes { get; set; }
    public Guid? RecurringTransactionId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class CreateTransactionRequest
{
    public TransactionType Type { get; set; }
    public decimal Amount { get; set; }
    public string Description { get; set; } = string.Empty;
    public DateTime Date { get; set; }
    public Guid CategoryId { get; set; }
    public PaymentMethod PaymentMethod { get; set; }
    public string? Notes { get; set; }
}

public class UpdateTransactionRequest
{
    public TransactionType Type { get; set; }
    public decimal Amount { get; set; }
    public string Description { get; set; } = string.Empty;
    public DateTime Date { get; set; }
    public Guid CategoryId { get; set; }
    public PaymentMethod PaymentMethod { get; set; }
    public string? Notes { get; set; }
}

public class TransactionQuery
{
    public TransactionType? Type { get; set; }
    public Guid? CategoryId { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public decimal? MinAmount { get; set; }
    public decimal? MaxAmount { get; set; }
    public string? Search { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
    public string SortBy { get; set; } = "date";
    public string SortDirection { get; set; } = "desc";
}
