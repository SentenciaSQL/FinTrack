using System.Text.Json.Serialization;

namespace FinTrack.Domain.Enums;

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum TransactionType
{
    INCOME = 1,
    EXPENSE = 2
}
