using AutoMapper;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using FinTrack.Application.Common;
using FinTrack.Application.DTOs.Savings;
using FinTrack.Application.Interfaces;
using FinTrack.Domain.Entities;

namespace FinTrack.Application.Services;

public class SavingsGoalService : ISavingsGoalService
{
    private readonly IFinTrackDbContext _db;
    private readonly ICurrentUser _currentUser;
    private readonly IDateTimeProvider _clock;
    private readonly IMapper _mapper;
    private readonly IValidator<CreateSavingsGoalRequest> _createValidator;
    private readonly IValidator<UpdateSavingsGoalRequest> _updateValidator;
    private readonly IValidator<CreateContributionRequest> _contributionValidator;

    public SavingsGoalService(
        IFinTrackDbContext db,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        IMapper mapper,
        IValidator<CreateSavingsGoalRequest> createValidator,
        IValidator<UpdateSavingsGoalRequest> updateValidator,
        IValidator<CreateContributionRequest> contributionValidator)
    {
        _db = db;
        _currentUser = currentUser;
        _clock = clock;
        _mapper = mapper;
        _createValidator = createValidator;
        _updateValidator = updateValidator;
        _contributionValidator = contributionValidator;
    }

    public async Task<IReadOnlyList<SavingsGoalDto>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        var goals = await _db.SavingsGoals
            .AsNoTracking()
            .Where(g => g.UserId == _currentUser.UserId)
            .OrderByDescending(g => g.CreatedAt)
            .ToListAsync(cancellationToken);

        return _mapper.Map<IReadOnlyList<SavingsGoalDto>>(goals);
    }

    public async Task<SavingsGoalDto> CreateAsync(CreateSavingsGoalRequest request, CancellationToken cancellationToken = default)
    {
        await _createValidator.ValidateAndThrowAppAsync(request, cancellationToken);
        var now = _clock.UtcNow;
        var goal = new SavingsGoal
        {
            Id = Guid.NewGuid(),
            Name = request.Name.Trim(),
            Description = string.IsNullOrWhiteSpace(request.Description) ? null : request.Description.Trim(),
            TargetAmount = decimal.Round(request.TargetAmount, 2),
            CurrentAmount = 0,
            TargetDate = request.TargetDate?.ToUniversalTime(),
            UserId = _currentUser.UserId,
            CreatedAt = now,
            UpdatedAt = now
        };

        _db.SavingsGoals.Add(goal);
        await _db.SaveChangesAsync(cancellationToken);
        return _mapper.Map<SavingsGoalDto>(goal);
    }

    public async Task<SavingsGoalDto> UpdateAsync(Guid id, UpdateSavingsGoalRequest request, CancellationToken cancellationToken = default)
    {
        await _updateValidator.ValidateAndThrowAppAsync(request, cancellationToken);
        var goal = await GetOwnedAsync(id, cancellationToken);
        goal.Name = request.Name.Trim();
        goal.Description = string.IsNullOrWhiteSpace(request.Description) ? null : request.Description.Trim();
        goal.TargetAmount = decimal.Round(request.TargetAmount, 2);
        goal.TargetDate = request.TargetDate?.ToUniversalTime();
        goal.UpdatedAt = _clock.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);
        return _mapper.Map<SavingsGoalDto>(goal);
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var goal = await GetOwnedAsync(id, cancellationToken);
        _db.SavingsGoals.Remove(goal);
        await _db.SaveChangesAsync(cancellationToken);
    }

    public async Task<SavingsContributionDto> AddContributionAsync(Guid goalId, CreateContributionRequest request, CancellationToken cancellationToken = default)
    {
        await _contributionValidator.ValidateAndThrowAppAsync(request, cancellationToken);
        var goal = await GetOwnedAsync(goalId, cancellationToken);

        var contribution = new SavingsContribution
        {
            Id = Guid.NewGuid(),
            SavingsGoalId = goal.Id,
            Amount = decimal.Round(request.Amount, 2),
            Date = request.Date.ToUniversalTime(),
            CreatedAt = _clock.UtcNow
        };

        goal.CurrentAmount += contribution.Amount;
        goal.UpdatedAt = _clock.UtcNow;
        _db.SavingsContributions.Add(contribution);
        await _db.SaveChangesAsync(cancellationToken);
        return _mapper.Map<SavingsContributionDto>(contribution);
    }

    public async Task<IReadOnlyList<SavingsContributionDto>> GetContributionsAsync(Guid goalId, CancellationToken cancellationToken = default)
    {
        await GetOwnedAsync(goalId, cancellationToken);
        var contributions = await _db.SavingsContributions
            .AsNoTracking()
            .Where(c => c.SavingsGoalId == goalId)
            .OrderByDescending(c => c.Date)
            .ToListAsync(cancellationToken);

        return _mapper.Map<IReadOnlyList<SavingsContributionDto>>(contributions);
    }

    private async Task<SavingsGoal> GetOwnedAsync(Guid id, CancellationToken cancellationToken)
    {
        var goal = await _db.SavingsGoals.FirstOrDefaultAsync(g => g.Id == id, cancellationToken)
                   ?? throw new NotFoundException("Savings goal not found");
        if (goal.UserId != _currentUser.UserId)
        {
            throw new ForbiddenException();
        }

        return goal;
    }
}
