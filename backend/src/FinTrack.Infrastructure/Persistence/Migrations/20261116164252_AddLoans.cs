using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace FinTrack.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddLoans : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "loans",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    Creditor = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    LoanType = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    OriginalPrincipal = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    Currency = table.Column<string>(type: "character varying(8)", maxLength: 8, nullable: false),
                    AnnualInterestRate = table.Column<decimal>(type: "numeric(9,4)", nullable: false),
                    DisbursementDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    FirstInstallmentDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    TermMonths = table.Column<int>(type: "integer", nullable: false),
                    PaymentFrequency = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    AmortizationType = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    AssociatedAccountLabel = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: true),
                    PreferredPaymentDay = table.Column<int>(type: "integer", nullable: true),
                    AdditionalFees = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    Notes = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    CurrentBalance = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    RemainingInstallments = table.Column<int>(type: "integer", nullable: false),
                    AccruedInterestPending = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    NextPaymentDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    PeriodicPayment = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    EarlyPaymentPenaltyRate = table.Column<decimal>(type: "numeric(9,4)", nullable: false),
                    EarlyPaymentPenaltyFixed = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    ReminderDaysCsv = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    RemindOnOverdue = table.Column<bool>(type: "boolean", nullable: false),
                    DefaultCategoryId = table.Column<Guid>(type: "uuid", nullable: true),
                    IsEstimate = table.Column<bool>(type: "boolean", nullable: false),
                    TotalInterestPaid = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    TotalPrincipalPaid = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    TotalExtraPrincipalPaid = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    TotalInterestSaved = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    TotalFeesPaid = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    TotalPenaltiesPaid = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_loans", x => x.Id);
                    table.ForeignKey(
                        name: "FK_loans_categories_DefaultCategoryId",
                        column: x => x.DefaultCategoryId,
                        principalTable: "categories",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_loans_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "loan_change_logs",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    LoanId = table.Column<Guid>(type: "uuid", nullable: false),
                    Description = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Details = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    ChangedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_loan_change_logs", x => x.Id);
                    table.ForeignKey(
                        name: "FK_loan_change_logs_loans_LoanId",
                        column: x => x.LoanId,
                        principalTable: "loans",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "loan_installments",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    LoanId = table.Column<Guid>(type: "uuid", nullable: false),
                    Number = table.Column<int>(type: "integer", nullable: false),
                    DueDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    PrincipalAmount = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    InterestAmount = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    FeeAmount = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    TotalAmount = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    PaidPrincipal = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    PaidInterest = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    PaidFees = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    PaidTotal = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    RemainingBalanceAfter = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    Status = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    IsLocked = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_loan_installments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_loan_installments_loans_LoanId",
                        column: x => x.LoanId,
                        principalTable: "loans",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "loan_payments",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    LoanId = table.Column<Guid>(type: "uuid", nullable: false),
                    InstallmentId = table.Column<Guid>(type: "uuid", nullable: true),
                    Kind = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    Amount = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    PrincipalPortion = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    InterestPortion = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    FeePortion = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    PenaltyPortion = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    Date = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    PaymentMethod = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    CategoryId = table.Column<Guid>(type: "uuid", nullable: true),
                    TransactionId = table.Column<Guid>(type: "uuid", nullable: true),
                    Notes = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_loan_payments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_loan_payments_categories_CategoryId",
                        column: x => x.CategoryId,
                        principalTable: "categories",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_loan_payments_loan_installments_InstallmentId",
                        column: x => x.InstallmentId,
                        principalTable: "loan_installments",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_loan_payments_loans_LoanId",
                        column: x => x.LoanId,
                        principalTable: "loans",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_loan_payments_transactions_TransactionId",
                        column: x => x.TransactionId,
                        principalTable: "transactions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateIndex(
                name: "IX_loan_change_logs_LoanId_ChangedAt",
                table: "loan_change_logs",
                columns: new[] { "LoanId", "ChangedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_loan_installments_LoanId_DueDate",
                table: "loan_installments",
                columns: new[] { "LoanId", "DueDate" });

            migrationBuilder.CreateIndex(
                name: "IX_loan_installments_LoanId_Number",
                table: "loan_installments",
                columns: new[] { "LoanId", "Number" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_loan_installments_LoanId_Status",
                table: "loan_installments",
                columns: new[] { "LoanId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_loan_payments_CategoryId",
                table: "loan_payments",
                column: "CategoryId");

            migrationBuilder.CreateIndex(
                name: "IX_loan_payments_InstallmentId",
                table: "loan_payments",
                column: "InstallmentId");

            migrationBuilder.CreateIndex(
                name: "IX_loan_payments_LoanId_Date",
                table: "loan_payments",
                columns: new[] { "LoanId", "Date" });

            migrationBuilder.CreateIndex(
                name: "IX_loan_payments_TransactionId",
                table: "loan_payments",
                column: "TransactionId",
                unique: true,
                filter: "\"TransactionId\" IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_loans_DefaultCategoryId",
                table: "loans",
                column: "DefaultCategoryId");

            migrationBuilder.CreateIndex(
                name: "IX_loans_UserId_NextPaymentDate",
                table: "loans",
                columns: new[] { "UserId", "NextPaymentDate" });

            migrationBuilder.CreateIndex(
                name: "IX_loans_UserId_Status",
                table: "loans",
                columns: new[] { "UserId", "Status" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "loan_change_logs");

            migrationBuilder.DropTable(
                name: "loan_payments");

            migrationBuilder.DropTable(
                name: "loan_installments");

            migrationBuilder.DropTable(
                name: "loans");
        }
    }
}
