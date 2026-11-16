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

public class LoanConfiguration : IEntityTypeConfiguration<Loan>
{
    public void Configure(EntityTypeBuilder<Loan> builder)
    {
        builder.ToTable("loans");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Name).HasMaxLength(120).IsRequired();
        builder.Property(x => x.Creditor).HasMaxLength(120).IsRequired();
        builder.Property(x => x.LoanType).HasConversion<string>().HasMaxLength(30).IsRequired();
        builder.Property(x => x.OriginalPrincipal).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.Currency).HasMaxLength(8).IsRequired();
        builder.Property(x => x.AnnualInterestRate).HasColumnType("numeric(9,4)").IsRequired();
        builder.Property(x => x.PaymentFrequency).HasConversion<string>().HasMaxLength(20).IsRequired();
        builder.Property(x => x.AmortizationType).HasConversion<string>().HasMaxLength(20).IsRequired();
        builder.Property(x => x.AssociatedAccountLabel).HasMaxLength(120);
        builder.Property(x => x.AdditionalFees).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.Notes).HasMaxLength(1000);
        builder.Property(x => x.CurrentBalance).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.AccruedInterestPending).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.PeriodicPayment).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.Status).HasConversion<string>().HasMaxLength(20).IsRequired();
        builder.Property(x => x.EarlyPaymentPenaltyRate).HasColumnType("numeric(9,4)").IsRequired();
        builder.Property(x => x.EarlyPaymentPenaltyFixed).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.ReminderDaysCsv).HasMaxLength(100).IsRequired();
        builder.Property(x => x.TotalInterestPaid).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.TotalPrincipalPaid).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.TotalExtraPrincipalPaid).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.TotalInterestSaved).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.TotalFeesPaid).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.TotalPenaltiesPaid).HasColumnType("numeric(18,2)").IsRequired();
        builder.HasOne(x => x.User).WithMany(x => x.Loans).HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne(x => x.DefaultCategory).WithMany().HasForeignKey(x => x.DefaultCategoryId).OnDelete(DeleteBehavior.SetNull);
        builder.HasIndex(x => new { x.UserId, x.Status });
        builder.HasIndex(x => new { x.UserId, x.NextPaymentDate });
    }
}

public class LoanInstallmentConfiguration : IEntityTypeConfiguration<LoanInstallment>
{
    public void Configure(EntityTypeBuilder<LoanInstallment> builder)
    {
        builder.ToTable("loan_installments");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.PrincipalAmount).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.InterestAmount).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.FeeAmount).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.TotalAmount).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.PaidPrincipal).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.PaidInterest).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.PaidFees).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.PaidTotal).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.RemainingBalanceAfter).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.Status).HasConversion<string>().HasMaxLength(30).IsRequired();
        builder.HasOne(x => x.Loan).WithMany(x => x.Installments).HasForeignKey(x => x.LoanId).OnDelete(DeleteBehavior.Cascade);
        builder.HasIndex(x => new { x.LoanId, x.Number }).IsUnique();
        builder.HasIndex(x => new { x.LoanId, x.DueDate });
        builder.HasIndex(x => new { x.LoanId, x.Status });
    }
}

public class LoanPaymentConfiguration : IEntityTypeConfiguration<LoanPayment>
{
    public void Configure(EntityTypeBuilder<LoanPayment> builder)
    {
        builder.ToTable("loan_payments");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Kind).HasConversion<string>().HasMaxLength(30).IsRequired();
        builder.Property(x => x.Amount).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.PrincipalPortion).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.InterestPortion).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.FeePortion).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.PenaltyPortion).HasColumnType("numeric(18,2)").IsRequired();
        builder.Property(x => x.PaymentMethod).HasConversion<string>().HasMaxLength(30).IsRequired();
        builder.Property(x => x.Notes).HasMaxLength(500);
        builder.HasOne(x => x.Loan).WithMany(x => x.Payments).HasForeignKey(x => x.LoanId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne(x => x.Installment).WithMany(x => x.Payments).HasForeignKey(x => x.InstallmentId).OnDelete(DeleteBehavior.SetNull);
        builder.HasOne(x => x.Category).WithMany().HasForeignKey(x => x.CategoryId).OnDelete(DeleteBehavior.SetNull);
        builder.HasOne(x => x.Transaction).WithMany().HasForeignKey(x => x.TransactionId).OnDelete(DeleteBehavior.SetNull);
        builder.HasIndex(x => new { x.LoanId, x.Date });
        builder.HasIndex(x => x.TransactionId).IsUnique().HasFilter("\"TransactionId\" IS NOT NULL");
    }
}

public class LoanChangeLogConfiguration : IEntityTypeConfiguration<LoanChangeLog>
{
    public void Configure(EntityTypeBuilder<LoanChangeLog> builder)
    {
        builder.ToTable("loan_change_logs");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Description).HasMaxLength(200).IsRequired();
        builder.Property(x => x.Details).HasMaxLength(1000);
        builder.HasOne(x => x.Loan).WithMany(x => x.ChangeLogs).HasForeignKey(x => x.LoanId).OnDelete(DeleteBehavior.Cascade);
        builder.HasIndex(x => new { x.LoanId, x.ChangedAt });
    }
}

public class ExternalLoginConfiguration : IEntityTypeConfiguration<ExternalLogin>
{
    public void Configure(EntityTypeBuilder<ExternalLogin> builder)
    {
        builder.ToTable("external_logins");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Provider).HasMaxLength(32).IsRequired();
        builder.Property(x => x.Issuer).HasMaxLength(500).IsRequired();
        builder.Property(x => x.Subject).HasMaxLength(450).IsRequired();
        builder.Property(x => x.Email).HasMaxLength(256);
        builder.HasOne(x => x.User).WithMany(x => x.ExternalLogins).HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
        builder.HasIndex(x => new { x.Issuer, x.Subject }).IsUnique();
        builder.HasIndex(x => new { x.UserId, x.Provider }).IsUnique();
    }
}

public class SsoChallengeConfiguration : IEntityTypeConfiguration<SsoChallenge>
{
    public void Configure(EntityTypeBuilder<SsoChallenge> builder)
    {
        builder.ToTable("sso_challenges");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.StateHash).HasMaxLength(64).IsRequired();
        builder.Property(x => x.Nonce).HasMaxLength(128).IsRequired();
        builder.Property(x => x.CodeVerifier).HasMaxLength(128).IsRequired();
        builder.Property(x => x.Provider).HasMaxLength(32).IsRequired();
        builder.Property(x => x.Intent).HasMaxLength(16).IsRequired();
        builder.Property(x => x.ReturnPath).HasMaxLength(200);
        builder.Property(x => x.PreferredLanguage).HasMaxLength(8).IsRequired();
        builder.Property(x => x.PreferredCurrency).HasMaxLength(8).IsRequired();
        builder.Property(x => x.ExchangeCodeHash).HasMaxLength(64);
        builder.Property(x => x.LinkTokenHash).HasMaxLength(64);
        builder.Property(x => x.Outcome).HasMaxLength(32).IsRequired();
        builder.Property(x => x.ErrorCode).HasMaxLength(64);
        builder.Property(x => x.Issuer).HasMaxLength(500);
        builder.Property(x => x.Subject).HasMaxLength(450);
        builder.Property(x => x.Email).HasMaxLength(256);
        builder.Property(x => x.DisplayName).HasMaxLength(120);
        builder.HasIndex(x => x.StateHash).IsUnique();
        builder.HasIndex(x => x.ExchangeCodeHash).IsUnique();
        builder.HasIndex(x => x.LinkTokenHash).IsUnique();
        builder.HasIndex(x => x.ExpiresAt);
    }
}
