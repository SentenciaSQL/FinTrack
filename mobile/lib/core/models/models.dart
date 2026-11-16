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

class Loan {
  const Loan({
    required this.id,
    required this.name,
    required this.creditor,
    required this.loanType,
    required this.originalPrincipal,
    required this.currency,
    required this.annualInterestRate,
    required this.disbursementDate,
    required this.firstInstallmentDate,
    required this.termMonths,
    required this.paymentFrequency,
    required this.amortizationType,
    this.associatedAccountLabel,
    this.preferredPaymentDay,
    required this.additionalFees,
    this.notes,
    required this.currentBalance,
    required this.remainingInstallments,
    required this.accruedInterestPending,
    this.nextPaymentDate,
    required this.periodicPayment,
    required this.status,
    required this.earlyPaymentPenaltyRate,
    required this.earlyPaymentPenaltyFixed,
    required this.reminderDays,
    required this.remindOnOverdue,
    this.defaultCategoryId,
    this.defaultCategoryName,
    required this.isEstimate,
    required this.totalInterestPaid,
    required this.totalPrincipalPaid,
    required this.totalExtraPrincipalPaid,
    required this.totalInterestSaved,
    required this.totalFeesPaid,
    required this.totalPenaltiesPaid,
    required this.paidOffPercentage,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String creditor;
  final String loanType;
  final double originalPrincipal;
  final String currency;
  final double annualInterestRate;
  final DateTime disbursementDate;
  final DateTime firstInstallmentDate;
  final int termMonths;
  final String paymentFrequency;
  final String amortizationType;
  final String? associatedAccountLabel;
  final int? preferredPaymentDay;
  final double additionalFees;
  final String? notes;
  final double currentBalance;
  final int remainingInstallments;
  final double accruedInterestPending;
  final DateTime? nextPaymentDate;
  final double periodicPayment;
  final String status;
  final double earlyPaymentPenaltyRate;
  final double earlyPaymentPenaltyFixed;
  final List<int> reminderDays;
  final bool remindOnOverdue;
  final String? defaultCategoryId;
  final String? defaultCategoryName;
  final bool isEstimate;
  final double totalInterestPaid;
  final double totalPrincipalPaid;
  final double totalExtraPrincipalPaid;
  final double totalInterestSaved;
  final double totalFeesPaid;
  final double totalPenaltiesPaid;
  final double paidOffPercentage;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Loan.fromJson(Map<String, dynamic> json) => Loan(
        id: json['id'].toString(),
        name: json['name'] as String,
        creditor: json['creditor'] as String,
        loanType: json['loanType'] as String? ?? 'PERSONAL',
        originalPrincipal: (json['originalPrincipal'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'DOP',
        annualInterestRate: (json['annualInterestRate'] as num).toDouble(),
        disbursementDate: DateTime.parse(json['disbursementDate'] as String),
        firstInstallmentDate: DateTime.parse(json['firstInstallmentDate'] as String),
        termMonths: json['termMonths'] as int,
        paymentFrequency: json['paymentFrequency'] as String? ?? 'MONTHLY',
        amortizationType: json['amortizationType'] as String? ?? 'FRENCH',
        associatedAccountLabel: json['associatedAccountLabel'] as String?,
        preferredPaymentDay: json['preferredPaymentDay'] as int?,
        additionalFees: (json['additionalFees'] as num?)?.toDouble() ?? 0,
        notes: json['notes'] as String?,
        currentBalance: (json['currentBalance'] as num).toDouble(),
        remainingInstallments: json['remainingInstallments'] as int? ?? 0,
        accruedInterestPending: (json['accruedInterestPending'] as num?)?.toDouble() ?? 0,
        nextPaymentDate: json['nextPaymentDate'] == null ? null : DateTime.parse(json['nextPaymentDate'] as String),
        periodicPayment: (json['periodicPayment'] as num).toDouble(),
        status: json['status'] as String? ?? 'ACTIVE',
        earlyPaymentPenaltyRate: (json['earlyPaymentPenaltyRate'] as num?)?.toDouble() ?? 0,
        earlyPaymentPenaltyFixed: (json['earlyPaymentPenaltyFixed'] as num?)?.toDouble() ?? 0,
        reminderDays: (json['reminderDays'] as List<dynamic>? ?? const []).map((e) => e as int).toList(),
        remindOnOverdue: json['remindOnOverdue'] as bool? ?? true,
        defaultCategoryId: json['defaultCategoryId']?.toString(),
        defaultCategoryName: json['defaultCategoryName'] as String?,
        isEstimate: json['isEstimate'] as bool? ?? false,
        totalInterestPaid: (json['totalInterestPaid'] as num?)?.toDouble() ?? 0,
        totalPrincipalPaid: (json['totalPrincipalPaid'] as num?)?.toDouble() ?? 0,
        totalExtraPrincipalPaid: (json['totalExtraPrincipalPaid'] as num?)?.toDouble() ?? 0,
        totalInterestSaved: (json['totalInterestSaved'] as num?)?.toDouble() ?? 0,
        totalFeesPaid: (json['totalFeesPaid'] as num?)?.toDouble() ?? 0,
        totalPenaltiesPaid: (json['totalPenaltiesPaid'] as num?)?.toDouble() ?? 0,
        paidOffPercentage: (json['paidOffPercentage'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class LoanInstallment {
  const LoanInstallment({
    required this.id,
    required this.loanId,
    required this.number,
    required this.dueDate,
    required this.principalAmount,
    required this.interestAmount,
    required this.feeAmount,
    required this.totalAmount,
    required this.paidPrincipal,
    required this.paidInterest,
    required this.paidFees,
    required this.paidTotal,
    required this.remainingAmount,
    required this.remainingBalanceAfter,
    required this.status,
    required this.isLocked,
  });

  final String id;
  final String loanId;
  final int number;
  final DateTime dueDate;
  final double principalAmount;
  final double interestAmount;
  final double feeAmount;
  final double totalAmount;
  final double paidPrincipal;
  final double paidInterest;
  final double paidFees;
  final double paidTotal;
  final double remainingAmount;
  final double remainingBalanceAfter;
  final String status;
  final bool isLocked;

  factory LoanInstallment.fromJson(Map<String, dynamic> json) => LoanInstallment(
        id: json['id'].toString(),
        loanId: json['loanId'].toString(),
        number: json['number'] as int,
        dueDate: DateTime.parse(json['dueDate'] as String),
        principalAmount: (json['principalAmount'] as num).toDouble(),
        interestAmount: (json['interestAmount'] as num).toDouble(),
        feeAmount: (json['feeAmount'] as num?)?.toDouble() ?? 0,
        totalAmount: (json['totalAmount'] as num).toDouble(),
        paidPrincipal: (json['paidPrincipal'] as num?)?.toDouble() ?? 0,
        paidInterest: (json['paidInterest'] as num?)?.toDouble() ?? 0,
        paidFees: (json['paidFees'] as num?)?.toDouble() ?? 0,
        paidTotal: (json['paidTotal'] as num?)?.toDouble() ?? 0,
        remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0,
        remainingBalanceAfter: (json['remainingBalanceAfter'] as num).toDouble(),
        status: json['status'] as String? ?? 'PENDING',
        isLocked: json['isLocked'] as bool? ?? false,
      );
}

class LoanPaymentRecord {
  const LoanPaymentRecord({
    required this.id,
    required this.loanId,
    this.installmentId,
    required this.kind,
    required this.amount,
    required this.principalPortion,
    required this.interestPortion,
    required this.feePortion,
    required this.penaltyPortion,
    required this.date,
    required this.paymentMethod,
    this.categoryId,
    this.categoryName,
    this.transactionId,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String loanId;
  final String? installmentId;
  final String kind;
  final double amount;
  final double principalPortion;
  final double interestPortion;
  final double feePortion;
  final double penaltyPortion;
  final DateTime date;
  final String paymentMethod;
  final String? categoryId;
  final String? categoryName;
  final String? transactionId;
  final String? notes;
  final DateTime createdAt;

  factory LoanPaymentRecord.fromJson(Map<String, dynamic> json) => LoanPaymentRecord(
        id: json['id'].toString(),
        loanId: json['loanId'].toString(),
        installmentId: json['installmentId']?.toString(),
        kind: json['kind'] as String? ?? 'REGULAR',
        amount: (json['amount'] as num).toDouble(),
        principalPortion: (json['principalPortion'] as num?)?.toDouble() ?? 0,
        interestPortion: (json['interestPortion'] as num?)?.toDouble() ?? 0,
        feePortion: (json['feePortion'] as num?)?.toDouble() ?? 0,
        penaltyPortion: (json['penaltyPortion'] as num?)?.toDouble() ?? 0,
        date: DateTime.parse(json['date'] as String),
        paymentMethod: json['paymentMethod'] as String? ?? 'OTHER',
        categoryId: json['categoryId']?.toString(),
        categoryName: json['categoryName'] as String?,
        transactionId: json['transactionId']?.toString(),
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class AmortizationSchedule {
  const AmortizationSchedule({
    required this.periodicPayment,
    required this.totalInterest,
    required this.totalPayment,
    required this.totalPrincipal,
    required this.estimatedEndDate,
    required this.periodCount,
    required this.isEstimate,
    required this.rows,
  });

  final double periodicPayment;
  final double totalInterest;
  final double totalPayment;
  final double totalPrincipal;
  final DateTime estimatedEndDate;
  final int periodCount;
  final bool isEstimate;
  final List<AmortizationRow> rows;

  factory AmortizationSchedule.fromJson(Map<String, dynamic> json) => AmortizationSchedule(
        periodicPayment: (json['periodicPayment'] as num).toDouble(),
        totalInterest: (json['totalInterest'] as num).toDouble(),
        totalPayment: (json['totalPayment'] as num).toDouble(),
        totalPrincipal: (json['totalPrincipal'] as num).toDouble(),
        estimatedEndDate: DateTime.parse(json['estimatedEndDate'] as String),
        periodCount: json['periodCount'] as int,
        isEstimate: json['isEstimate'] as bool? ?? false,
        rows: (json['rows'] as List<dynamic>).map((e) => AmortizationRow.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class AmortizationRow {
  const AmortizationRow({
    required this.number,
    required this.dueDate,
    required this.principal,
    required this.interest,
    required this.fee,
    required this.payment,
    required this.remainingBalance,
  });

  final int number;
  final DateTime dueDate;
  final double principal;
  final double interest;
  final double fee;
  final double payment;
  final double remainingBalance;

  factory AmortizationRow.fromJson(Map<String, dynamic> json) => AmortizationRow(
        number: json['number'] as int,
        dueDate: DateTime.parse(json['dueDate'] as String),
        principal: (json['principal'] as num).toDouble(),
        interest: (json['interest'] as num).toDouble(),
        fee: (json['fee'] as num?)?.toDouble() ?? 0,
        payment: (json['payment'] as num).toDouble(),
        remainingBalance: (json['remainingBalance'] as num).toDouble(),
      );
}

class EarlyPaymentScenario {
  const EarlyPaymentScenario({
    required this.mode,
    required this.extraPayment,
    required this.penaltyAmount,
    required this.newBalance,
    required this.previousPeriodicPayment,
    required this.newPeriodicPayment,
    required this.paymentReduction,
    required this.previousRemainingPeriods,
    required this.newRemainingPeriods,
    required this.periodsSaved,
    this.previousEndDate,
    this.newEndDate,
    required this.daysSaved,
    required this.interestWithoutExtra,
    required this.interestWithExtra,
    required this.grossInterestSaved,
    required this.netInterestSaved,
  });

  final String mode;
  final double extraPayment;
  final double penaltyAmount;
  final double newBalance;
  final double previousPeriodicPayment;
  final double newPeriodicPayment;
  final double paymentReduction;
  final int previousRemainingPeriods;
  final int newRemainingPeriods;
  final int periodsSaved;
  final DateTime? previousEndDate;
  final DateTime? newEndDate;
  final int daysSaved;
  final double interestWithoutExtra;
  final double interestWithExtra;
  final double grossInterestSaved;
  final double netInterestSaved;

  factory EarlyPaymentScenario.fromJson(Map<String, dynamic> json) => EarlyPaymentScenario(
        mode: json['mode'] as String? ?? 'REDUCE_TERM',
        extraPayment: (json['extraPayment'] as num).toDouble(),
        penaltyAmount: (json['penaltyAmount'] as num?)?.toDouble() ?? 0,
        newBalance: (json['newBalance'] as num).toDouble(),
        previousPeriodicPayment: (json['previousPeriodicPayment'] as num).toDouble(),
        newPeriodicPayment: (json['newPeriodicPayment'] as num).toDouble(),
        paymentReduction: (json['paymentReduction'] as num?)?.toDouble() ?? 0,
        previousRemainingPeriods: json['previousRemainingPeriods'] as int? ?? 0,
        newRemainingPeriods: json['newRemainingPeriods'] as int? ?? 0,
        periodsSaved: json['periodsSaved'] as int? ?? 0,
        previousEndDate: json['previousEndDate'] == null ? null : DateTime.parse(json['previousEndDate'] as String),
        newEndDate: json['newEndDate'] == null ? null : DateTime.parse(json['newEndDate'] as String),
        daysSaved: json['daysSaved'] as int? ?? 0,
        interestWithoutExtra: (json['interestWithoutExtra'] as num).toDouble(),
        interestWithExtra: (json['interestWithExtra'] as num).toDouble(),
        grossInterestSaved: (json['grossInterestSaved'] as num).toDouble(),
        netInterestSaved: (json['netInterestSaved'] as num).toDouble(),
      );
}

class LoanDashboard {
  const LoanDashboard({
    required this.activeLoans,
    required this.totalOutstandingDebt,
    required this.totalMonthlyInstallments,
    this.nextDueDate,
    required this.nextDueAmount,
    this.nextDueLoanName,
    required this.totalInterestPaid,
    required this.totalPrincipalPaid,
    required this.totalExtraPrincipalPaid,
    required this.totalInterestSaved,
    required this.overallPaidOffPercentage,
    required this.debtEvolution,
    required this.debtDistribution,
    required this.totalCapitalPaid,
    required this.totalInterestComponent,
  });

  final int activeLoans;
  final double totalOutstandingDebt;
  final double totalMonthlyInstallments;
  final DateTime? nextDueDate;
  final double nextDueAmount;
  final String? nextDueLoanName;
  final double totalInterestPaid;
  final double totalPrincipalPaid;
  final double totalExtraPrincipalPaid;
  final double totalInterestSaved;
  final double overallPaidOffPercentage;
  final List<LoanBalancePoint> debtEvolution;
  final List<LoanDistribution> debtDistribution;
  final double totalCapitalPaid;
  final double totalInterestComponent;

  factory LoanDashboard.fromJson(Map<String, dynamic> json) => LoanDashboard(
        activeLoans: json['activeLoans'] as int? ?? 0,
        totalOutstandingDebt: (json['totalOutstandingDebt'] as num).toDouble(),
        totalMonthlyInstallments: (json['totalMonthlyInstallments'] as num).toDouble(),
        nextDueDate: json['nextDueDate'] == null ? null : DateTime.parse(json['nextDueDate'] as String),
        nextDueAmount: (json['nextDueAmount'] as num?)?.toDouble() ?? 0,
        nextDueLoanName: json['nextDueLoanName'] as String?,
        totalInterestPaid: (json['totalInterestPaid'] as num?)?.toDouble() ?? 0,
        totalPrincipalPaid: (json['totalPrincipalPaid'] as num?)?.toDouble() ?? 0,
        totalExtraPrincipalPaid: (json['totalExtraPrincipalPaid'] as num?)?.toDouble() ?? 0,
        totalInterestSaved: (json['totalInterestSaved'] as num?)?.toDouble() ?? 0,
        overallPaidOffPercentage: (json['overallPaidOffPercentage'] as num?)?.toDouble() ?? 0,
        debtEvolution: (json['debtEvolution'] as List<dynamic>? ?? const []).map((e) => LoanBalancePoint.fromJson(e as Map<String, dynamic>)).toList(),
        debtDistribution: (json['debtDistribution'] as List<dynamic>? ?? const []).map((e) => LoanDistribution.fromJson(e as Map<String, dynamic>)).toList(),
        totalCapitalPaid: (json['totalCapitalPaid'] as num?)?.toDouble() ?? 0,
        totalInterestComponent: (json['totalInterestComponent'] as num?)?.toDouble() ?? 0,
      );
}

class LoanBalancePoint {
  const LoanBalancePoint({required this.date, required this.balance});
  final DateTime date;
  final double balance;

  factory LoanBalancePoint.fromJson(Map<String, dynamic> json) => LoanBalancePoint(
        date: DateTime.parse(json['date'] as String),
        balance: (json['balance'] as num).toDouble(),
      );
}

class LoanDistribution {
  const LoanDistribution({
    required this.loanId,
    required this.name,
    required this.balance,
    required this.percentage,
  });

  final String loanId;
  final String name;
  final double balance;
  final double percentage;

  factory LoanDistribution.fromJson(Map<String, dynamic> json) => LoanDistribution(
        loanId: json['loanId'].toString(),
        name: json['name'] as String,
        balance: (json['balance'] as num).toDouble(),
        percentage: (json['percentage'] as num).toDouble(),
      );
}

class LoanCalendarItem {
  const LoanCalendarItem({
    required this.loanId,
    required this.loanName,
    this.installmentId,
    this.installmentNumber,
    required this.dueDate,
    required this.amount,
    required this.remainingAmount,
    required this.status,
    required this.isExtraPayment,
    required this.currency,
  });

  final String loanId;
  final String loanName;
  final String? installmentId;
  final int? installmentNumber;
  final DateTime dueDate;
  final double amount;
  final double remainingAmount;
  final String status;
  final bool isExtraPayment;
  final String currency;

  factory LoanCalendarItem.fromJson(Map<String, dynamic> json) => LoanCalendarItem(
        loanId: json['loanId'].toString(),
        loanName: json['loanName'] as String,
        installmentId: json['installmentId']?.toString(),
        installmentNumber: json['installmentNumber'] as int?,
        dueDate: DateTime.parse(json['dueDate'] as String),
        amount: (json['amount'] as num).toDouble(),
        remainingAmount: (json['remainingAmount'] as num).toDouble(),
        status: json['status'] as String? ?? 'PENDING',
        isExtraPayment: json['isExtraPayment'] as bool? ?? false,
        currency: json['currency'] as String? ?? 'DOP',
      );
}

