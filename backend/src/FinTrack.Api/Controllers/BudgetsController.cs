using FinTrack.Application.DTOs.Budgets;
using FinTrack.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FinTrack.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/budgets")]
public class BudgetsController : ControllerBase
{
    private readonly IBudgetService _budgetService;

    public BudgetsController(IBudgetService budgetService)
    {
        _budgetService = budgetService;
    }

    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<BudgetDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<BudgetDto>>> Get([FromQuery] BudgetQuery query, CancellationToken cancellationToken)
    {
        return Ok(await _budgetService.GetAsync(query, cancellationToken));
    }

    [HttpPost]
    [ProducesResponseType(typeof(BudgetDto), StatusCodes.Status201Created)]
    public async Task<ActionResult<BudgetDto>> Create([FromBody] CreateBudgetRequest request, CancellationToken cancellationToken)
    {
        var created = await _budgetService.CreateAsync(request, cancellationToken);
        return CreatedAtAction(nameof(Get), new { id = created.Id }, created);
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(BudgetDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<BudgetDto>> Update(Guid id, [FromBody] UpdateBudgetRequest request, CancellationToken cancellationToken)
    {
        return Ok(await _budgetService.UpdateAsync(id, request, cancellationToken));
    }

    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        await _budgetService.DeleteAsync(id, cancellationToken);
        return NoContent();
    }
}
