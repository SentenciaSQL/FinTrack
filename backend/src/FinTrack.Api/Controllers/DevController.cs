using FinTrack.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FinTrack.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/dev")]
public class DevController : ControllerBase
{
    private readonly IDemoDataService _demoDataService;
    private readonly IHostEnvironment _environment;

    public DevController(IDemoDataService demoDataService, IHostEnvironment environment)
    {
        _demoDataService = demoDataService;
        _environment = environment;
    }

    [HttpPost("demo-data")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Seed(CancellationToken cancellationToken)
    {
        if (!_environment.IsDevelopment())
        {
            return NotFound();
        }

        await _demoDataService.SeedAsync(cancellationToken);
        return NoContent();
    }
}
