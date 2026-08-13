using AutoMapper;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using FinTrack.Application.Common;
using FinTrack.Application.DTOs.Recurring;
using FinTrack.Application.Interfaces;
using FinTrack.Domain.Entities;

namespace FinTrack.Application.Services;

public class RecurringTransactionService : IRecurringTransactionService
{
    private readonly IFinTrackDbContext _db;
    private readonly ICurrentUser _currentUser;
    private readonly IDateTimeProvider _clock;
    private readonly IMapper _mapper;
    private readonly IValidator<CreateRecurringTransactionRequest> _createValidator;
    private readonly IValidator<UpdateRecurringTransactionRequest> _updateValidator;

    public RecurringTransactionService(
        IFinTrackDbContext db,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        IMapper mapper,
        IValidator<CreateRecurringTransactionRequest> createValidator,
        IValidator<UpdateRecurringTransactionRequest> updateValidator)
    {
        _db = db;
        _currentUser = currentUser;
        _clock = clock;
        _mapper = mapper;
        _createValidator = createValidator;
        _updateValidator = updateValidator;
    }

    public async Task<IReadOnlyList<RecurringTransactionDto>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        var items = await _db.RecurringTransactions
            .AsNoTracking()
            .Include(r => r.Category)
            .Where(r => r.UserId == _currentUser.UserId)
            .OrderBy(r => r.NextExecutionDate)
            .ToListAsync(cancellationToken);

        return _mapper.Map<IReadOnlyList<RecurringTransactionDto>>(items);
    }

    public async Task<RecurringTransactionDto> CreateAsync(CreateRecurringTransactionRequest request, CancellationToken cancellationToken = default)
    {
        await _createValidator.ValidateAndThrowAppAsync(request, cancellationToken);
        await EnsureCategoryAsync(request.CategoryId, request.Type, cancellationToken);

        var now = _clock.UtcNow;
        var entity = new RecurringTransaction
        {
            Id = Guid.NewGuid(),
            Type = request.Type,
            Amount = decimal.Round(request.Amount, 2),
            Description = request.Description.Trim(),
            CategoryId = request.CategoryId,
            Frequency = request.Frequency,
            NextExecutionDate = request.NextExecutionDate.ToUniversalTime().Date,
            Active = request.Active,
            UserId = _currentUser.UserId,
            CreatedAt = now,
            UpdatedAt = now
        };

        _db.RecurringTransactions.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return (await GetAllAsync(cancellationToken)).First(r => r.Id == entity.Id);
    }

    public async Task<RecurringTransactionDto> UpdateAsync(Guid id, UpdateRecurringTransactionRequest request, CancellationToken cancellationToken = default)
    {
        await _updateValidator.ValidateAndThrowAppAsync(request, cancellationToken);
        var entity = await _db.RecurringTransactions.Include(r => r.Category)
                         .FirstOrDefaultAsync(r => r.Id == id, cancellationToken)
                     ?? throw new NotFoundException("Recurring transaction not found");

        if (entity.UserId != _currentUser.UserId)
        {
            throw new ForbiddenException();
        }

        await EnsureCategoryAsync(request.CategoryId, request.Type, cancellationToken);

        entity.Type = request.Type;
        entity.Amount = decimal.Round(request.Amount, 2);
        entity.Description = request.Description.Trim();
        entity.CategoryId = request.CategoryId;
        entity.Frequency = request.Frequency;
        entity.NextExecutionDate = request.NextExecutionDate.ToUniversalTime().Date;
        entity.Active = request.Active;
        entity.UpdatedAt = _clock.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);

        return _mapper.Map<RecurringTransactionDto>(entity);
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var entity = await _db.RecurringTransactions.FirstOrDefaultAsync(r => r.Id == id, cancellationToken)
                     ?? throw new NotFoundException("Recurring transaction not found");
        if (entity.UserId != _currentUser.UserId)
        {
            throw new ForbiddenException();
        }

        _db.RecurringTransactions.Remove(entity);
        await _db.SaveChangesAsync(cancellationToken);
    }

    private async Task EnsureCategoryAsync(Guid categoryId, Domain.Enums.TransactionType type, CancellationToken cancellationToken)
    {
        var category = await _db.Categories.FirstOrDefaultAsync(c => c.Id == categoryId, cancellationToken)
                       ?? throw new NotFoundException("Category not found");
        if (category.UserId != _currentUser.UserId)
        {
            throw new ForbiddenException();
        }

        if (category.Type != type)
        {
            throw new ValidationAppException(ErrorCodes.CategoryTypeMismatch, "Category type does not match the transaction type");
        }
    }
}
