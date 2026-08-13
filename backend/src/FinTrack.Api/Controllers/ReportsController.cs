using FinTrack.Application.DTOs.Reports;
using FinTrack.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FinTrack.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/reports")]
public class ReportsController : ControllerBase
{
    private readonly IReportService _reportService;

    public ReportsController(IReportService reportService)
    {
        _reportService = reportService;
    }

    [HttpGet("monthly")]
    [ProducesResponseType(typeof(MonthlyReportDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<MonthlyReportDto>> Monthly([FromQuery] int? month, [FromQuery] int? year, CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;
        return Ok(await _reportService.GetMonthlyAsync(month ?? now.Month, year ?? now.Year, cancellationToken));
    }

    [HttpGet("category-expenses")]
    [ProducesResponseType(typeof(IReadOnlyList<CategoryExpenseDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<CategoryExpenseDto>>> CategoryExpenses(
        [FromQuery] DateTime? startDate,
        [FromQuery] DateTime? endDate,
        [FromQuery] int? month,
        [FromQuery] int? year,
        CancellationToken cancellationToken)
    {
        var (start, end) = Resolve(startDate, endDate, month, year);
        return Ok(await _reportService.GetCategoryExpensesAsync(start, end, cancellationToken));
    }

    [HttpGet("income-vs-expenses")]
    [ProducesResponseType(typeof(IncomeVsExpensesDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<IncomeVsExpensesDto>> IncomeVsExpenses(
        [FromQuery] DateTime? startDate,
        [FromQuery] DateTime? endDate,
        [FromQuery] int? month,
        [FromQuery] int? year,
        CancellationToken cancellationToken)
    {
        var (start, end) = Resolve(startDate, endDate, month, year);
        return Ok(await _reportService.GetIncomeVsExpensesAsync(start, end, cancellationToken));
    }

    [HttpGet("balance-history")]
    [ProducesResponseType(typeof(BalanceHistoryDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<BalanceHistoryDto>> BalanceHistory(
        [FromQuery] DateTime? startDate,
        [FromQuery] DateTime? endDate,
        [FromQuery] int? month,
        [FromQuery] int? year,
        CancellationToken cancellationToken)
    {
        var (start, end) = Resolve(startDate, endDate, month, year);
        return Ok(await _reportService.GetBalanceHistoryAsync(start, end, cancellationToken));
    }

    private static (DateTime? Start, DateTime? End) Resolve(DateTime? startDate, DateTime? endDate, int? month, int? year)
    {
        if (startDate.HasValue || endDate.HasValue)
        {
            return (startDate, endDate);
        }

        if (month.HasValue && year.HasValue)
        {
            var start = new DateTime(year.Value, month.Value, 1, 0, 0, 0, DateTimeKind.Utc);
            return (start, start.AddMonths(1).AddTicks(-1));
        }

        return (null, null);
    }
}
