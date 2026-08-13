using FinTrack.Domain.Enums;

namespace FinTrack.Domain.Common;

public static class DefaultCategories
{
    public static readonly IReadOnlyList<(string Code, TransactionType Type, string Icon)> All =
    [
        ("FOOD", TransactionType.EXPENSE, "restaurant"),
        ("TRANSPORTATION", TransactionType.EXPENSE, "directions_car"),
        ("HOUSING", TransactionType.EXPENSE, "home"),
        ("UTILITIES", TransactionType.EXPENSE, "bolt"),
        ("HEALTH", TransactionType.EXPENSE, "favorite"),
        ("EDUCATION", TransactionType.EXPENSE, "school"),
        ("ENTERTAINMENT", TransactionType.EXPENSE, "movie"),
        ("SHOPPING", TransactionType.EXPENSE, "shopping_bag"),
        ("SUBSCRIPTIONS", TransactionType.EXPENSE, "subscriptions"),
        ("TRAVEL", TransactionType.EXPENSE, "flight"),
        ("OTHER", TransactionType.EXPENSE, "more_horiz"),
        ("SALARY", TransactionType.INCOME, "payments"),
        ("FREELANCE", TransactionType.INCOME, "laptop"),
        ("BUSINESS", TransactionType.INCOME, "storefront"),
        ("INVESTMENTS", TransactionType.INCOME, "trending_up"),
        ("GIFTS", TransactionType.INCOME, "card_giftcard"),
        ("OTHER", TransactionType.INCOME, "more_horiz")
    ];
}
