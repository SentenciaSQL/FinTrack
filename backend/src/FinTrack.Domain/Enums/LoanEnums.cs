using System.Text.Json.Serialization;

namespace FinTrack.Domain.Enums;

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum LoanType
{
    PERSONAL = 1,
    MORTGAGE = 2,
    VEHICLE = 3,
    COMMERCIAL = 4,
    CREDIT_CARD = 5,
    OTHER = 6
}

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum LoanPaymentFrequency
{
    WEEKLY = 1,
    BIWEEKLY = 2,
    MONTHLY = 3
}

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum AmortizationType
{
    FRENCH = 1,
    GERMAN = 2,
    CUSTOM = 3
}

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum LoanStatus
{
    ACTIVE = 1,
    PAID_OFF = 2,
    CANCELLED = 3
}

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum LoanInstallmentStatus
{
    PENDING = 1,
    DUE_SOON = 2,
    OVERDUE = 3,
    PAID = 4,
    PARTIALLY_PAID = 5
}

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum LoanPaymentKind
{
    REGULAR = 1,
    PARTIAL = 2,
    EXTRA_PRINCIPAL = 3,
    FULL_PAYOFF = 4,
    FEE = 5
}

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum EarlyPaymentMode
{
    REDUCE_PAYMENT = 1,
    REDUCE_TERM = 2
}
