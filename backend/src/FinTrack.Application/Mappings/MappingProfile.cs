using AutoMapper;
using FinTrack.Application.DTOs.Auth;
using FinTrack.Application.DTOs.Budgets;
using FinTrack.Application.DTOs.Categories;
using FinTrack.Application.DTOs.Recurring;
using FinTrack.Application.DTOs.Savings;
using FinTrack.Application.DTOs.Transactions;
using FinTrack.Domain.Entities;

namespace FinTrack.Application.Mappings;

public class MappingProfile : Profile
{
    public MappingProfile()
    {
        CreateMap<User, UserProfileDto>();

        CreateMap<Category, CategoryDto>();

        CreateMap<Transaction, TransactionDto>()
            .ForMember(d => d.CategoryName, o => o.MapFrom(s => s.Category.Name))
            .ForMember(d => d.CategoryIcon, o => o.MapFrom(s => s.Category.Icon))
            .ForMember(d => d.CategoryIsDefault, o => o.MapFrom(s => s.Category.IsDefault));

        CreateMap<Budget, BudgetDto>()
            .ForMember(d => d.CategoryName, o => o.MapFrom(s => s.Category.Name))
            .ForMember(d => d.CategoryIcon, o => o.MapFrom(s => s.Category.Icon))
            .ForMember(d => d.CategoryIsDefault, o => o.MapFrom(s => s.Category.IsDefault))
            .ForMember(d => d.Spent, o => o.Ignore())
            .ForMember(d => d.Available, o => o.Ignore())
            .ForMember(d => d.UsedPercentage, o => o.Ignore())
            .ForMember(d => d.Status, o => o.Ignore());

        CreateMap<SavingsGoal, SavingsGoalDto>()
            .ForMember(d => d.ProgressPercentage, o => o.MapFrom(s =>
                s.TargetAmount == 0 ? 0 : Math.Round(s.CurrentAmount / s.TargetAmount * 100, 2)));

        CreateMap<SavingsContribution, SavingsContributionDto>();

        CreateMap<RecurringTransaction, RecurringTransactionDto>()
            .ForMember(d => d.CategoryName, o => o.MapFrom(s => s.Category.Name))
            .ForMember(d => d.CategoryIcon, o => o.MapFrom(s => s.Category.Icon))
            .ForMember(d => d.CategoryIsDefault, o => o.MapFrom(s => s.Category.IsDefault));
    }
}
