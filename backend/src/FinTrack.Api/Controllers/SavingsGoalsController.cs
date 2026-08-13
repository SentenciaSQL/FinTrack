using FinTrack.Application.DTOs.Savings;
using FinTrack.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FinTrack.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/savings-goals")]
public class SavingsGoalsController : ControllerBase
{
    private readonly ISavingsGoalService _savingsGoalService;

    public SavingsGoalsController(ISavingsGoalService savingsGoalService)
    {
        _savingsGoalService = savingsGoalService;
    }

    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<SavingsGoalDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<SavingsGoalDto>>> GetAll(CancellationToken cancellationToken)
    {
        return Ok(await _savingsGoalService.GetAllAsync(cancellationToken));
    }

    [HttpPost]
    [ProducesResponseType(typeof(SavingsGoalDto), StatusCodes.Status201Created)]
    public async Task<ActionResult<SavingsGoalDto>> Create([FromBody] CreateSavingsGoalRequest request, CancellationToken cancellationToken)
    {
        var created = await _savingsGoalService.CreateAsync(request, cancellationToken);
        return CreatedAtAction(nameof(GetAll), new { id = created.Id }, created);
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(SavingsGoalDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<SavingsGoalDto>> Update(Guid id, [FromBody] UpdateSavingsGoalRequest request, CancellationToken cancellationToken)
    {
        return Ok(await _savingsGoalService.UpdateAsync(id, request, cancellationToken));
    }

    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        await _savingsGoalService.DeleteAsync(id, cancellationToken);
        return NoContent();
    }

    [HttpPost("{id:guid}/contributions")]
    [ProducesResponseType(typeof(SavingsContributionDto), StatusCodes.Status201Created)]
    public async Task<ActionResult<SavingsContributionDto>> AddContribution(Guid id, [FromBody] CreateContributionRequest request, CancellationToken cancellationToken)
    {
        var created = await _savingsGoalService.AddContributionAsync(id, request, cancellationToken);
        return CreatedAtAction(nameof(GetContributions), new { id }, created);
    }

    [HttpGet("{id:guid}/contributions")]
    [ProducesResponseType(typeof(IReadOnlyList<SavingsContributionDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<SavingsContributionDto>>> GetContributions(Guid id, CancellationToken cancellationToken)
    {
        return Ok(await _savingsGoalService.GetContributionsAsync(id, cancellationToken));
    }
}
