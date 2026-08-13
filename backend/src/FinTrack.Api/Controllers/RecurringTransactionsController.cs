using FinTrack.Application.DTOs.Recurring;
using FinTrack.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FinTrack.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/recurring-transactions")]
public class RecurringTransactionsController : ControllerBase
{
    private readonly IRecurringTransactionService _service;

    public RecurringTransactionsController(IRecurringTransactionService service)
    {
        _service = service;
    }

    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<RecurringTransactionDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<RecurringTransactionDto>>> GetAll(CancellationToken cancellationToken)
    {
        return Ok(await _service.GetAllAsync(cancellationToken));
    }

    [HttpPost]
    [ProducesResponseType(typeof(RecurringTransactionDto), StatusCodes.Status201Created)]
    public async Task<ActionResult<RecurringTransactionDto>> Create([FromBody] CreateRecurringTransactionRequest request, CancellationToken cancellationToken)
    {
        var created = await _service.CreateAsync(request, cancellationToken);
        return CreatedAtAction(nameof(GetAll), new { id = created.Id }, created);
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(RecurringTransactionDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<RecurringTransactionDto>> Update(Guid id, [FromBody] UpdateRecurringTransactionRequest request, CancellationToken cancellationToken)
    {
        return Ok(await _service.UpdateAsync(id, request, cancellationToken));
    }

    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        await _service.DeleteAsync(id, cancellationToken);
        return NoContent();
    }
}
