using FinTrack.Application.Common;
using FinTrack.Application.DTOs.Budgets;
using FinTrack.Application.DTOs.Categories;
using FinTrack.Application.DTOs.Dashboard;
using FinTrack.Application.DTOs.Recurring;
using FinTrack.Application.DTOs.Reports;
using FinTrack.Application.DTOs.Savings;
using FinTrack.Application.DTOs.Transactions;

namespace FinTrack.Application.Interfaces;

public interface ICategoryService
{
    Task<IReadOnlyList<CategoryDto>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<CategoryDto> CreateAsync(CreateCategoryRequest request, CancellationToken cancellationToken = default);
    Task<CategoryDto> UpdateAsync(Guid id, UpdateCategoryRequest request, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
}

public interface ITransactionService
{
    Task<PagedResult<TransactionDto>> GetAsync(TransactionQuery query, CancellationToken cancellationToken = default);
    Task<TransactionDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<TransactionDto> CreateAsync(CreateTransactionRequest request, CancellationToken cancellationToken = default);
    Task<TransactionDto> UpdateAsync(Guid id, UpdateTransactionRequest request, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
}

public interface IBudgetService
{
    Task<IReadOnlyList<BudgetDto>> GetAsync(BudgetQuery query, CancellationToken cancellationToken = default);
    Task<BudgetDto> CreateAsync(CreateBudgetRequest request, CancellationToken cancellationToken = default);
    Task<BudgetDto> UpdateAsync(Guid id, UpdateBudgetRequest request, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
}

public interface ISavingsGoalService
{
    Task<IReadOnlyList<SavingsGoalDto>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<SavingsGoalDto> CreateAsync(CreateSavingsGoalRequest request, CancellationToken cancellationToken = default);
    Task<SavingsGoalDto> UpdateAsync(Guid id, UpdateSavingsGoalRequest request, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
    Task<SavingsContributionDto> AddContributionAsync(Guid goalId, CreateContributionRequest request, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<SavingsContributionDto>> GetContributionsAsync(Guid goalId, CancellationToken cancellationToken = default);
}

public interface IRecurringTransactionService
{
    Task<IReadOnlyList<RecurringTransactionDto>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<RecurringTransactionDto> CreateAsync(CreateRecurringTransactionRequest request, CancellationToken cancellationToken = default);
    Task<RecurringTransactionDto> UpdateAsync(Guid id, UpdateRecurringTransactionRequest request, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
}

public interface IDashboardService
{
    Task<DashboardDto> GetAsync(CancellationToken cancellationToken = default);
}

public interface IReportService
{
    Task<MonthlyReportDto> GetMonthlyAsync(int month, int year, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<CategoryExpenseDto>> GetCategoryExpensesAsync(DateTime? startDate, DateTime? endDate, CancellationToken cancellationToken = default);
    Task<IncomeVsExpensesDto> GetIncomeVsExpensesAsync(DateTime? startDate, DateTime? endDate, CancellationToken cancellationToken = default);
    Task<BalanceHistoryDto> GetBalanceHistoryAsync(DateTime? startDate, DateTime? endDate, CancellationToken cancellationToken = default);
}

public interface IDemoDataService
{
    Task SeedAsync(CancellationToken cancellationToken = default);
}
