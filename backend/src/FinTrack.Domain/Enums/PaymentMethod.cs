using System.Text.Json.Serialization;

namespace FinTrack.Domain.Enums;

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum PaymentMethod
{
    CASH = 1,
    DEBIT_CARD = 2,
    CREDIT_CARD = 3,
    BANK_TRANSFER = 4,
    OTHER = 5
}
