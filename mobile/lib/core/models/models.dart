class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.preferredLanguage,
    required this.preferredCurrency,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final String preferredLanguage;
  final String preferredCurrency;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'].toString(),
        name: json['name'] as String,
        email: json['email'] as String,
        preferredLanguage: json['preferredLanguage'] as String,
        preferredCurrency: json['preferredCurrency'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final UserProfile user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['accessToken'] as String,
        tokenType: json['tokenType'] as String,
        expiresIn: json['expiresIn'] as int,
        user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
      );
}

class Category {
  const Category({
    required this.id,
    required this.name,
    this.icon,
    required this.type,
    required this.isDefault,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? icon;
  final String type;
  final bool isDefault;
  final DateTime createdAt;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'].toString(),
        name: json['name'] as String,
        icon: json['icon'] as String?,
        type: json['type'] as String,
        isDefault: json['isDefault'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class Transaction {
  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
    required this.categoryIsDefault,
    required this.paymentMethod,
    this.notes,
    this.recurringTransactionId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String type;
  final double amount;
  final String description;
  final DateTime date;
  final String categoryId;
  final String categoryName;
  final String? categoryIcon;
  final bool categoryIsDefault;
  final String paymentMethod;
  final String? notes;
  final String? recurringTransactionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'].toString(),
        type: json['type'] as String,
        amount: (json['amount'] as num).toDouble(),
        description: json['description'] as String,
        date: DateTime.parse(json['date'] as String),
        categoryId: json['categoryId'].toString(),
        categoryName: json['categoryName'] as String,
        categoryIcon: json['categoryIcon'] as String?,
        categoryIsDefault: json['categoryIsDefault'] as bool,
        paymentMethod: json['paymentMethod'] as String,
        notes: json['notes'] as String?,
        recurringTransactionId: json['recurringTransactionId']?.toString(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class PagedTransactions {
  const PagedTransactions({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  final List<Transaction> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  factory PagedTransactions.fromJson(Map<String, dynamic> json) => PagedTransactions(
        items: (json['items'] as List<dynamic>).map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList(),
        page: json['page'] as int,
        pageSize: json['pageSize'] as int,
        totalCount: json['totalCount'] as int,
        totalPages: json['totalPages'] as int,
      );
}

class Budget {
  const Budget({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
    required this.categoryIsDefault,
    required this.amount,
    required this.spent,
    required this.available,
    required this.usedPercentage,
    required this.status,
    required this.month,
    required this.year,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String categoryId;
  final String categoryName;
  final String? categoryIcon;
  final bool categoryIsDefault;
  final double amount;
  final double spent;
  final double available;
  final double usedPercentage;
  final String status;
  final int month;
  final int year;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        id: json['id'].toString(),
        categoryId: json['categoryId'].toString(),
        categoryName: json['categoryName'] as String,
        categoryIcon: json['categoryIcon'] as String?,
        categoryIsDefault: json['categoryIsDefault'] as bool,
        amount: (json['amount'] as num).toDouble(),
        spent: (json['spent'] as num).toDouble(),
        available: (json['available'] as num).toDouble(),
        usedPercentage: (json['usedPercentage'] as num).toDouble(),
        status: json['status'] as String,
        month: json['month'] as int,
        year: json['year'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.name,
    this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.progressPercentage,
    this.targetDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final double progressPercentage;
  final DateTime? targetDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SavingsGoal.fromJson(Map<String, dynamic> json) => SavingsGoal(
        id: json['id'].toString(),
        name: json['name'] as String,
        description: json['description'] as String?,
        targetAmount: (json['targetAmount'] as num).toDouble(),
        currentAmount: (json['currentAmount'] as num).toDouble(),
        progressPercentage: (json['progressPercentage'] as num).toDouble(),
        targetDate: json['targetDate'] == null ? null : DateTime.parse(json['targetDate'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class SavingsContribution {
  const SavingsContribution({
    required this.id,
    required this.savingsGoalId,
    required this.amount,
    required this.date,
    required this.createdAt,
  });

  final String id;
  final String savingsGoalId;
  final double amount;
  final DateTime date;
  final DateTime createdAt;

  factory SavingsContribution.fromJson(Map<String, dynamic> json) => SavingsContribution(
        id: json['id'].toString(),
        savingsGoalId: json['savingsGoalId'].toString(),
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class RecurringTransaction {
  const RecurringTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
    required this.categoryIsDefault,
    required this.frequency,
    required this.nextExecutionDate,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String type;
  final double amount;
  final String description;
  final String categoryId;
  final String categoryName;
  final String? categoryIcon;
  final bool categoryIsDefault;
  final String frequency;
  final DateTime nextExecutionDate;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) => RecurringTransaction(
        id: json['id'].toString(),
        type: json['type'] as String,
        amount: (json['amount'] as num).toDouble(),
        description: json['description'] as String,
        categoryId: json['categoryId'].toString(),
        categoryName: json['categoryName'] as String,
        categoryIcon: json['categoryIcon'] as String?,
        categoryIsDefault: json['categoryIsDefault'] as bool,
        frequency: json['frequency'] as String,
        nextExecutionDate: DateTime.parse(json['nextExecutionDate'] as String),
        active: json['active'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class CategoryBreakdown {
  const CategoryBreakdown({
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
    required this.categoryIsDefault,
    required this.amount,
    required this.percentage,
  });

  final String categoryId;
  final String categoryName;
  final String? categoryIcon;
  final bool categoryIsDefault;
  final double amount;
  final double percentage;

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) => CategoryBreakdown(
        categoryId: json['categoryId'].toString(),
        categoryName: json['categoryName'] as String,
        categoryIcon: json['categoryIcon'] as String?,
        categoryIsDefault: json['categoryIsDefault'] as bool,
        amount: (json['amount'] as num).toDouble(),
        percentage: (json['percentage'] as num).toDouble(),
      );
}

class IncomeExpensePoint {
  const IncomeExpensePoint({
    required this.label,
    required this.month,
    required this.year,
    required this.income,
    required this.expense,
  });

  final String label;
  final int month;
  final int year;
  final double income;
  final double expense;

  factory IncomeExpensePoint.fromJson(Map<String, dynamic> json) => IncomeExpensePoint(
        label: json['label'] as String? ?? '',
        month: json['month'] as int,
        year: json['year'] as int,
        income: (json['income'] as num).toDouble(),
        expense: (json['expense'] as num).toDouble(),
      );
}

class DashboardData {
  const DashboardData({
    required this.currentBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.monthlySavings,
    required this.budgetUsedPercentage,
    required this.totalBudget,
    required this.totalBudgetSpent,
    required this.recentTransactions,
    required this.expensesByCategory,
    required this.incomeVsExpenses,
  });

  final double currentBalance;
  final double monthlyIncome;
  final double monthlyExpense;
  final double monthlySavings;
  final double budgetUsedPercentage;
  final double totalBudget;
  final double totalBudgetSpent;
  final List<Transaction> recentTransactions;
  final List<CategoryBreakdown> expensesByCategory;
  final List<IncomeExpensePoint> incomeVsExpenses;

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
        currentBalance: (json['currentBalance'] as num).toDouble(),
        monthlyIncome: (json['monthlyIncome'] as num).toDouble(),
        monthlyExpense: (json['monthlyExpense'] as num).toDouble(),
        monthlySavings: (json['monthlySavings'] as num).toDouble(),
        budgetUsedPercentage: (json['budgetUsedPercentage'] as num).toDouble(),
        totalBudget: (json['totalBudget'] as num).toDouble(),
        totalBudgetSpent: (json['totalBudgetSpent'] as num).toDouble(),
        recentTransactions: (json['recentTransactions'] as List<dynamic>).map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList(),
        expensesByCategory: (json['expensesByCategory'] as List<dynamic>).map((e) => CategoryBreakdown.fromJson(e as Map<String, dynamic>)).toList(),
        incomeVsExpenses: (json['incomeVsExpenses'] as List<dynamic>).map((e) => IncomeExpensePoint.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class MonthlyReport {
  const MonthlyReport({
    required this.month,
    required this.year,
    required this.income,
    required this.expense,
    required this.savings,
    required this.balance,
    required this.topExpenseCategories,
  });

  final int month;
  final int year;
  final double income;
  final double expense;
  final double savings;
  final double balance;
  final List<CategoryBreakdown> topExpenseCategories;

  factory MonthlyReport.fromJson(Map<String, dynamic> json) => MonthlyReport(
        month: json['month'] as int,
        year: json['year'] as int,
        income: (json['income'] as num).toDouble(),
        expense: (json['expense'] as num).toDouble(),
        savings: (json['savings'] as num).toDouble(),
        balance: (json['balance'] as num).toDouble(),
        topExpenseCategories: (json['topExpenseCategories'] as List<dynamic>).map((e) => CategoryBreakdown.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class MonthlyPoint {
  const MonthlyPoint({
    required this.month,
    required this.year,
    required this.income,
    required this.expense,
    required this.savings,
  });

  final int month;
  final int year;
  final double income;
  final double expense;
  final double savings;

  factory MonthlyPoint.fromJson(Map<String, dynamic> json) => MonthlyPoint(
        month: json['month'] as int,
        year: json['year'] as int,
        income: (json['income'] as num).toDouble(),
        expense: (json['expense'] as num).toDouble(),
        savings: (json['savings'] as num).toDouble(),
      );
}

class IncomeVsExpenses {
  const IncomeVsExpenses({required this.points});
  final List<MonthlyPoint> points;

  factory IncomeVsExpenses.fromJson(Map<String, dynamic> json) => IncomeVsExpenses(
        points: (json['points'] as List<dynamic>).map((e) => MonthlyPoint.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class BalancePoint {
  const BalancePoint({required this.date, required this.balance});
  final DateTime date;
  final double balance;

  factory BalancePoint.fromJson(Map<String, dynamic> json) => BalancePoint(
        date: DateTime.parse(json['date'] as String),
        balance: (json['balance'] as num).toDouble(),
      );
}

class BalanceHistory {
  const BalanceHistory({required this.points});
  final List<BalancePoint> points;

  factory BalanceHistory.fromJson(Map<String, dynamic> json) => BalanceHistory(
        points: (json['points'] as List<dynamic>).map((e) => BalancePoint.fromJson(e as Map<String, dynamic>)).toList(),
      );
}
