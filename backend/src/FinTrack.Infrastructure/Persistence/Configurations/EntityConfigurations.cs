using FinTrack.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace FinTrack.Infrastructure.Persistence.Configurations;

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.ToTable("users");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Name).HasMaxLength(120).IsRequired();
        builder.Property(x => x.Email).HasMaxLength(256).IsRequired();
        builder.HasIndex(x => x.Email).IsUnique();
        builder.Property(x => x.PasswordHash).HasMaxLength(512).IsRequired();
        builder.Property(x => x.PreferredLanguage).HasMaxLength(8).HasDefaultValue("es");
        builder.Property(x => x.PreferredCurrency).HasMaxLength(8).HasDefaultValue("DOP");
        builder.Property(x => x.CreatedAt).IsRequired();
        builder.Property(x => x.UpdatedAt).IsRequired();
    }
}

public class CategoryConfiguration : IEntityTypeConfiguration<Category>
{
    public void Configure(EntityTypeBuilder<Category> builder)
    {
        builder.ToTable("categories");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Name).HasMaxLength(80).IsRequired();
        builder.Property(x => x.Icon).HasMaxLength(80);
        builder.Property(x => x.Type).HasConversion<string>().HasMaxLength(20).IsRequired();
        builder.HasOne(x => x.User).WithMany(x => x.Categories).HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
        builder.HasIndex(x => new { x.UserId, x.Type, x.Name });
    }
}

public class TransactionConfiguration : IEntityTypeConfiguration<Transaction>
{
    public void Configure(EntityTypeBuilder<Transaction> builder)
    {
        builder.ToTable("transactions");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Type).HasConversion<string>().HasMaxLength(20).IsRequired();
        builder.Property(x => x.Amount).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.Description).HasMaxLength(200).IsRequired();
        builder.Property(x => x.PaymentMethod).HasConversion<string>().HasMaxLength(30).IsRequired();
        builder.Property(x => x.Notes).HasMaxLength(500);
        builder.HasOne(x => x.User).WithMany(x => x.Transactions).HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne(x => x.Category).WithMany(x => x.Transactions).HasForeignKey(x => x.CategoryId).OnDelete(DeleteBehavior.Restrict);
        builder.HasOne(x => x.RecurringTransaction).WithMany(x => x.GeneratedTransactions).HasForeignKey(x => x.RecurringTransactionId).OnDelete(DeleteBehavior.SetNull);
        builder.HasIndex(x => new { x.UserId, x.Date });
        builder.HasIndex(x => new { x.UserId, x.CategoryId });
        builder.HasIndex(x => new { x.UserId, x.Type });
    }
}

public class BudgetConfiguration : IEntityTypeConfiguration<Budget>
{
    public void Configure(EntityTypeBuilder<Budget> builder)
    {
        builder.ToTable("budgets");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Amount).HasColumnType("numeric(18,2)").IsRequired();
        builder.HasOne(x => x.User).WithMany(x => x.Budgets).HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne(x => x.Category).WithMany(x => x.Budgets).HasForeignKey(x => x.CategoryId).OnDelete(DeleteBehavior.Restrict);
        builder.HasIndex(x => new { x.UserId, x.CategoryId, x.Month, x.Year }).IsUnique();
    }
}

public class SavingsGoalConfiguration : IEntityTypeConfiguration<SavingsGoal>
{
    public void Configure(EntityTypeBuilder<SavingsGoal> builder)
    {
        builder.ToTable("savings_goals");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Name).HasMaxLength(120).IsRequired();
        builder.Property(x => x.Description).HasMaxLength(500);
        builder.Property(x => x.TargetAmount).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.CurrentAmount).HasColumnType("numeric(18,2)").IsRequired();
        builder.HasOne(x => x.User).WithMany(x => x.SavingsGoals).HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
    }
}

public class SavingsContributionConfiguration : IEntityTypeConfiguration<SavingsContribution>
{
    public void Configure(EntityTypeBuilder<SavingsContribution> builder)
    {
        builder.ToTable("savings_contributions");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Amount).HasColumnType("numeric(18,2)").IsRequired();
        builder.HasOne(x => x.SavingsGoal).WithMany(x => x.Contributions).HasForeignKey(x => x.SavingsGoalId).OnDelete(DeleteBehavior.Cascade);
    }
}

public class RecurringTransactionConfiguration : IEntityTypeConfiguration<RecurringTransaction>
{
    public void Configure(EntityTypeBuilder<RecurringTransaction> builder)
    {
        builder.ToTable("recurring_transactions");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Type).HasConversion<string>().HasMaxLength(20).IsRequired();
        builder.Property(x => x.Amount).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.Description).HasMaxLength(200).IsRequired();
        builder.Property(x => x.Frequency).HasConversion<string>().HasMaxLength(20).IsRequired();
        builder.HasOne(x => x.User).WithMany(x => x.RecurringTransactions).HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne(x => x.Category).WithMany(x => x.RecurringTransactions).HasForeignKey(x => x.CategoryId).OnDelete(DeleteBehavior.Restrict);
        builder.HasIndex(x => new { x.UserId, x.Active, x.NextExecutionDate });
    }
}

public class RecurringExecutionConfiguration : IEntityTypeConfiguration<RecurringExecution>
{
    public void Configure(EntityTypeBuilder<RecurringExecution> builder)
    {
        builder.ToTable("recurring_executions");
        builder.HasKey(x => x.Id);
        builder.HasOne(x => x.RecurringTransaction).WithMany(x => x.Executions).HasForeignKey(x => x.RecurringTransactionId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne(x => x.Transaction).WithMany().HasForeignKey(x => x.TransactionId).OnDelete(DeleteBehavior.Restrict);
        builder.HasIndex(x => new { x.RecurringTransactionId, x.ExecutionDate }).IsUnique();
    }
}
