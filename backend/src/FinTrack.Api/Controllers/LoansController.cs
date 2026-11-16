using FinTrack.Application.DTOs.Loans;
using FinTrack.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FinTrack.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/loans")]
public class LoansController : ControllerBase
{
    private readonly ILoanService _loanService;

    public LoansController(ILoanService loanService)
    {
        _loanService = loanService;
    }

    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<LoanDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<LoanDto>>> GetAll(CancellationToken cancellationToken)
    {
        return Ok(await _loanService.GetAllAsync(cancellationToken));
    }

    [HttpGet("dashboard")]
    [ProducesResponseType(typeof(LoanDashboardDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<LoanDashboardDto>> Dashboard(CancellationToken cancellationToken)
    {
        return Ok(await _loanService.GetDashboardAsync(cancellationToken));
    }

    [HttpGet("calendar")]
    [ProducesResponseType(typeof(IReadOnlyList<LoanCalendarItemDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<LoanCalendarItemDto>>> Calendar(
        [FromQuery] DateTime? from,
        [FromQuery] DateTime? to,
        CancellationToken cancellationToken)
    {
        return Ok(await _loanService.GetCalendarAsync(from, to, cancellationToken));
    }

    [HttpPost("calculate")]
    [ProducesResponseType(typeof(AmortizationScheduleDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<AmortizationScheduleDto>> Calculate(
        [FromBody] CalculateLoanRequest request,
        CancellationToken cancellationToken)
    {
        return Ok(await _loanService.CalculateAsync(request, cancellationToken));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(LoanDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<LoanDto>> GetById(Guid id, CancellationToken cancellationToken)
    {
        return Ok(await _loanService.GetByIdAsync(id, cancellationToken));
    }

    [HttpPost]
    [ProducesResponseType(typeof(LoanDto), StatusCodes.Status201Created)]
    public async Task<ActionResult<LoanDto>> Create([FromBody] CreateLoanRequest request, CancellationToken cancellationToken)
    {
        var created = await _loanService.CreateAsync(request, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(LoanDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<LoanDto>> Update(Guid id, [FromBody] UpdateLoanRequest request, CancellationToken cancellationToken)
    {
        return Ok(await _loanService.UpdateAsync(id, request, cancellationToken));
    }

    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        await _loanService.DeleteAsync(id, cancellationToken);
        return NoContent();
    }

    [HttpGet("{id:guid}/installments")]
    [ProducesResponseType(typeof(IReadOnlyList<LoanInstallmentDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<LoanInstallmentDto>>> Installments(Guid id, CancellationToken cancellationToken)
    {
        return Ok(await _loanService.GetInstallmentsAsync(id, cancellationToken));
    }

    [HttpGet("{id:guid}/payments")]
    [ProducesResponseType(typeof(IReadOnlyList<LoanPaymentDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<LoanPaymentDto>>> Payments(Guid id, CancellationToken cancellationToken)
    {
        return Ok(await _loanService.GetPaymentsAsync(id, cancellationToken));
    }

    [HttpPost("{id:guid}/payments")]
    [ProducesResponseType(typeof(LoanPaymentDto), StatusCodes.Status201Created)]
    public async Task<ActionResult<LoanPaymentDto>> RecordPayment(
        Guid id,
        [FromBody] RecordLoanPaymentRequest request,
        CancellationToken cancellationToken)
    {
        var created = await _loanService.RecordPaymentAsync(id, request, cancellationToken);
        return CreatedAtAction(nameof(Payments), new { id }, created);
    }

    [HttpPost("{id:guid}/simulate-early-payment")]
    [ProducesResponseType(typeof(EarlyPaymentScenarioDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<EarlyPaymentScenarioDto>> Simulate(
        Guid id,
        [FromBody] SimulateEarlyPaymentRequest request,
        CancellationToken cancellationToken)
    {
        return Ok(await _loanService.SimulateEarlyPaymentAsync(id, request, cancellationToken));
    }

    [HttpPost("{id:guid}/compare-early-payments")]
    [ProducesResponseType(typeof(IReadOnlyList<EarlyPaymentScenarioDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<EarlyPaymentScenarioDto>>> Compare(
        Guid id,
        [FromBody] CompareEarlyPaymentsRequest request,
        CancellationToken cancellationToken)
    {
        return Ok(await _loanService.CompareEarlyPaymentsAsync(id, request, cancellationToken));
    }

    [HttpGet("{id:guid}/change-logs")]
    [ProducesResponseType(typeof(IReadOnlyList<LoanChangeLogDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<LoanChangeLogDto>>> ChangeLogs(Guid id, CancellationToken cancellationToken)
    {
        return Ok(await _loanService.GetChangeLogsAsync(id, cancellationToken));
    }

    [HttpPut("{id:guid}/reminders")]
    [ProducesResponseType(typeof(LoanDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<LoanDto>> UpdateReminders(
        Guid id,
        [FromBody] UpdateLoanRemindersRequest request,
        CancellationToken cancellationToken)
    {
        return Ok(await _loanService.UpdateRemindersAsync(id, request, cancellationToken));
    }
}
