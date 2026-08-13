import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/core/models/models.dart';
import 'package:fintrack/core/network/dio_provider.dart';

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository(ref.watch(dioProvider));
});

class FinanceRepository {
  FinanceRepository(this._dio);
  final Dio _dio;

  Future<DashboardData> dashboard() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/dashboard');
      return DashboardData.fromJson(res.data!);
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<Category>> categories() async {
    try {
      final res = await _dio.get<List<dynamic>>('/categories');
      return res.data!.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<Category> createCategory({required String name, required String type, String? icon}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/categories', data: {
        'name': name,
        'type': type,
        'icon': icon,
      });
      return Category.fromJson(res.data!);
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _dio.delete('/categories/$id');
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<PagedTransactions> transactions({
    String? type,
    String? categoryId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    int page = 1,
    String sortBy = 'date',
    String sortDirection = 'desc',
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/transactions', queryParameters: {
        if (type != null) 'type': type,
        if (categoryId != null) 'categoryId': categoryId,
        if (search != null && search.isNotEmpty) 'search': search,
        if (startDate != null) 'startDate': startDate.toUtc().toIso8601String(),
        if (endDate != null) 'endDate': endDate.toUtc().toIso8601String(),
        if (minAmount != null) 'minAmount': minAmount,
        if (maxAmount != null) 'maxAmount': maxAmount,
        'page': page,
        'pageSize': 20,
        'sortBy': sortBy,
        'sortDirection': sortDirection,
      });
      return PagedTransactions.fromJson(res.data!);
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<Transaction> transaction(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/transactions/$id');
      return Transaction.fromJson(res.data!);
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<Transaction> saveTransaction({
    String? id,
    required String type,
    required double amount,
    required String description,
    required DateTime date,
    required String categoryId,
    required String paymentMethod,
    String? notes,
  }) async {
    final payload = {
      'type': type,
      'amount': amount,
      'description': description,
      'date': date.toUtc().toIso8601String(),
      'categoryId': categoryId,
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
    try {
      final res = id == null
          ? await _dio.post<Map<String, dynamic>>('/transactions', data: payload)
          : await _dio.put<Map<String, dynamic>>('/transactions/$id', data: payload);
      return Transaction.fromJson(res.data!);
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _dio.delete('/transactions/$id');
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<Budget>> budgets({int? month, int? year}) async {
    try {
      final res = await _dio.get<List<dynamic>>('/budgets', queryParameters: {
        if (month != null) 'month': month,
        if (year != null) 'year': year,
      });
      return res.data!.map((e) => Budget.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<Budget> saveBudget({
    String? id,
    required String categoryId,
    required double amount,
    required int month,
    required int year,
  }) async {
    try {
      final res = id == null
          ? await _dio.post<Map<String, dynamic>>('/budgets', data: {
              'categoryId': categoryId,
              'amount': amount,
              'month': month,
              'year': year,
            })
          : await _dio.put<Map<String, dynamic>>('/budgets/$id', data: {'amount': amount});
      return Budget.fromJson(res.data!);
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      await _dio.delete('/budgets/$id');
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<SavingsGoal>> goals() async {
    try {
      final res = await _dio.get<List<dynamic>>('/savings-goals');
      return res.data!.map((e) => SavingsGoal.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<SavingsGoal> saveGoal({
    String? id,
    required String name,
    String? description,
    required double targetAmount,
    DateTime? targetDate,
  }) async {
    final payload = {
      'name': name,
      'description': description,
      'targetAmount': targetAmount,
      'targetDate': targetDate?.toUtc().toIso8601String(),
    };
    try {
      final res = id == null
          ? await _dio.post<Map<String, dynamic>>('/savings-goals', data: payload)
          : await _dio.put<Map<String, dynamic>>('/savings-goals/$id', data: payload);
      return SavingsGoal.fromJson(res.data!);
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await _dio.delete('/savings-goals/$id');
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<SavingsContribution>> contributions(String goalId) async {
    try {
      final res = await _dio.get<List<dynamic>>('/savings-goals/$goalId/contributions');
      return res.data!.map((e) => SavingsContribution.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> addContribution(String goalId, double amount, DateTime date) async {
    try {
      await _dio.post('/savings-goals/$goalId/contributions', data: {
        'amount': amount,
        'date': date.toUtc().toIso8601String(),
      });
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<RecurringTransaction>> recurring() async {
    try {
      final res = await _dio.get<List<dynamic>>('/recurring-transactions');
      return res.data!.map((e) => RecurringTransaction.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<RecurringTransaction> saveRecurring({
    String? id,
    required String type,
    required double amount,
    required String description,
    required String categoryId,
    required String frequency,
    required DateTime nextExecutionDate,
    required bool active,
  }) async {
    final payload = {
      'type': type,
      'amount': amount,
      'description': description,
      'categoryId': categoryId,
      'frequency': frequency,
      'nextExecutionDate': nextExecutionDate.toUtc().toIso8601String(),
      'active': active,
    };
    try {
      final res = id == null
          ? await _dio.post<Map<String, dynamic>>('/recurring-transactions', data: payload)
          : await _dio.put<Map<String, dynamic>>('/recurring-transactions/$id', data: payload);
      return RecurringTransaction.fromJson(res.data!);
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> deleteRecurring(String id) async {
    try {
      await _dio.delete('/recurring-transactions/$id');
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<MonthlyReport> monthlyReport(int month, int year) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/reports/monthly', queryParameters: {
        'month': month,
        'year': year,
      });
      return MonthlyReport.fromJson(res.data!);
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<CategoryBreakdown>> categoryExpenses(int month, int year) async {
    try {
      final res = await _dio.get<List<dynamic>>('/reports/category-expenses', queryParameters: {
        'month': month,
        'year': year,
      });
      return res.data!.map((e) => CategoryBreakdown.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<IncomeVsExpenses> incomeVsExpenses() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/reports/income-vs-expenses');
      return IncomeVsExpenses.fromJson(res.data!);
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<BalanceHistory> balanceHistory() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/reports/balance-history');
      return BalanceHistory.fromJson(res.data!);
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> loadDemoData() async {
    try {
      await _dio.post('/dev/demo-data');
    } catch (e) {
      throw toApiException(e);
    }
  }
}
