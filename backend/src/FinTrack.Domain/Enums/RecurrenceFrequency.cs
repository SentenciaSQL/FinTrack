using System.Text.Json.Serialization;

namespace FinTrack.Domain.Enums;

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum RecurrenceFrequency
{
    WEEKLY = 1,
    BIWEEKLY = 2,
    MONTHLY = 3,
    YEARLY = 4
}
