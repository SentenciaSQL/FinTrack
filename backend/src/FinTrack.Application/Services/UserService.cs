using AutoMapper;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using FinTrack.Application.Common;
using FinTrack.Application.DTOs.Auth;
using FinTrack.Application.Interfaces;

namespace FinTrack.Application.Services;

public class UserService : IUserService
{
    private readonly IFinTrackDbContext _db;
    private readonly ICurrentUser _currentUser;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IDateTimeProvider _clock;
    private readonly IMapper _mapper;
    private readonly IValidator<UpdateProfileRequest> _updateValidator;
    private readonly IValidator<ChangePasswordRequest> _passwordValidator;

    public UserService(
        IFinTrackDbContext db,
        ICurrentUser currentUser,
        IPasswordHasher passwordHasher,
        IDateTimeProvider clock,
        IMapper mapper,
        IValidator<UpdateProfileRequest> updateValidator,
        IValidator<ChangePasswordRequest> passwordValidator)
    {
        _db = db;
        _currentUser = currentUser;
        _passwordHasher = passwordHasher;
        _clock = clock;
        _mapper = mapper;
        _updateValidator = updateValidator;
        _passwordValidator = passwordValidator;
    }

    public async Task<UserProfileDto> GetCurrentAsync(CancellationToken cancellationToken = default)
    {
        var user = await GetUserAsync(cancellationToken);
        return _mapper.Map<UserProfileDto>(user);
    }

    public async Task<UserProfileDto> UpdateCurrentAsync(UpdateProfileRequest request, CancellationToken cancellationToken = default)
    {
        await _updateValidator.ValidateAndThrowAppAsync(request, cancellationToken);
        var user = await GetUserAsync(cancellationToken);
        user.Name = request.Name.Trim();
        if (!string.IsNullOrWhiteSpace(request.PreferredLanguage))
        {
            user.PreferredLanguage = request.PreferredLanguage;
        }

        if (!string.IsNullOrWhiteSpace(request.PreferredCurrency))
        {
            user.PreferredCurrency = request.PreferredCurrency;
        }

        user.UpdatedAt = _clock.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);
        return _mapper.Map<UserProfileDto>(user);
    }

    public async Task ChangePasswordAsync(ChangePasswordRequest request, CancellationToken cancellationToken = default)
    {
        await _passwordValidator.ValidateAndThrowAppAsync(request, cancellationToken);
        var user = await GetUserAsync(cancellationToken);
        if (!_passwordHasher.Verify(request.CurrentPassword, user.PasswordHash))
        {
            throw new ValidationAppException(ErrorCodes.CurrentPasswordIncorrect, "Current password is incorrect");
        }

        user.PasswordHash = _passwordHasher.Hash(request.NewPassword);
        user.UpdatedAt = _clock.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);
    }

    private async Task<Domain.Entities.User> GetUserAsync(CancellationToken cancellationToken)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == _currentUser.UserId, cancellationToken);
        return user ?? throw new NotFoundException("User not found");
    }
}
