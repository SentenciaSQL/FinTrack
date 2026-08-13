using AutoMapper;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using FinTrack.Application.Common;
using FinTrack.Application.DTOs.Transactions;
using FinTrack.Application.Interfaces;
using FinTrack.Domain.Entities;
using FinTrack.Domain.Enums;

namespace FinTrack.Application.Services;

public class TransactionService : ITransactionService
{
    private readonly IFinTrackDbContext _db;
    private readonly ICurrentUser _currentUser;
    private readonly IDateTimeProvider _clock;
    private readonly IMapper _mapper;
    private readonly IValidator<CreateTransactionRequest> _createValidator;
    private readonly IValidator<UpdateTransactionRequest> _updateValidator;

    public TransactionService(
        IFinTrackDbContext db,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        IMapper mapper,
        IValidator<CreateTransactionRequest> createValidator,
        IValidator<UpdateTransactionRequest> updateValidator)
    {
        _db = db;
        _currentUser = currentUser;
        _clock = clock;
        _mapper = mapper;
        _createValidator = createValidator;
        _updateValidator = updateValidator;
    }

    public async Task<PagedResult<TransactionDto>> GetAsync(TransactionQuery query, CancellationToken cancellationToken = default)
    {
        var page = query.Page < 1 ? 1 : query.Page;
        var pageSize = query.PageSize is < 1 or > 100 ? 20 : query.PageSize;

        var source = _db.Transactions
            .AsNoTracking()
            .Include(t => t.Category)
            .Where(t => t.UserId == _currentUser.UserId);

        if (query.Type.HasValue)
        {
            source = source.Where(t => t.Type == query.Type);
        }

        if (query.CategoryId.HasValue)
        {
            source = source.Where(t => t.CategoryId == query.CategoryId);
        }

        if (query.StartDate.HasValue)
        {
            source = source.Where(t => t.Date >= query.StartDate.Value.ToUniversalTime());
        }

        if (query.EndDate.HasValue)
        {
            var end = query.EndDate.Value.ToUniversalTime().Date.AddDays(1).AddTicks(-1);
            source = source.Where(t => t.Date <= end);
        }

        if (query.MinAmount.HasValue)
        {
            source = source.Where(t => t.Amount >= query.MinAmount);
        }

        if (query.MaxAmount.HasValue)
        {
            source = source.Where(t => t.Amount <= query.MaxAmount);
        }

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var term = query.Search.Trim().ToLower();
            source = source.Where(t =>
                t.Description.ToLower().Contains(term) ||
                (t.Notes != null && t.Notes.ToLower().Contains(term)));
        }

        source = ApplySort(source, query.SortBy, query.SortDirection);

        var total = await source.CountAsync(cancellationToken);
        var items = await source
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        return PagedResult<TransactionDto>.Create(_mapper.Map<IReadOnlyList<TransactionDto>>(items), page, pageSize, total);
    }

    public async Task<TransactionDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var transaction = await _db.Transactions
            .AsNoTracking()
            .Include(t => t.Category)
            .FirstOrDefaultAsync(t => t.Id == id, cancellationToken) ?? throw new NotFoundException("Transaction not found");

        EnsureOwner(transaction.UserId);
        return _mapper.Map<TransactionDto>(transaction);
    }

    public async Task<TransactionDto> CreateAsync(CreateTransactionRequest request, CancellationToken cancellationToken = default)
    {
        await _createValidator.ValidateAndThrowAppAsync(request, cancellationToken);
        await EnsureCategoryAsync(request.CategoryId, request.Type, cancellationToken);

        var now = _clock.UtcNow;
        var transaction = new Transaction
        {
            Id = Guid.NewGuid(),
            Type = request.Type,
            Amount = decimal.Round(request.Amount, 2),
            Description = request.Description.Trim(),
            Date = request.Date.ToUniversalTime(),
            CategoryId = request.CategoryId,
            PaymentMethod = request.PaymentMethod,
            Notes = string.IsNullOrWhiteSpace(request.Notes) ? null : request.Notes.Trim(),
            UserId = _currentUser.UserId,
            CreatedAt = now,
            UpdatedAt = now
        };

        _db.Transactions.Add(transaction);
        await _db.SaveChangesAsync(cancellationToken);

        return await GetByIdAsync(transaction.Id, cancellationToken);
    }

    public async Task<TransactionDto> UpdateAsync(Guid id, UpdateTransactionRequest request, CancellationToken cancellationToken = default)
    {
        await _updateValidator.ValidateAndThrowAppAsync(request, cancellationToken);
        var transaction = await _db.Transactions.FirstOrDefaultAsync(t => t.Id == id, cancellationToken)
                          ?? throw new NotFoundException("Transaction not found");
        EnsureOwner(transaction.UserId);
        await EnsureCategoryAsync(request.CategoryId, request.Type, cancellationToken);

        transaction.Type = request.Type;
        transaction.Amount = decimal.Round(request.Amount, 2);
        transaction.Description = request.Description.Trim();
        transaction.Date = request.Date.ToUniversalTime();
        transaction.CategoryId = request.CategoryId;
        transaction.PaymentMethod = request.PaymentMethod;
        transaction.Notes = string.IsNullOrWhiteSpace(request.Notes) ? null : request.Notes.Trim();
        transaction.UpdatedAt = _clock.UtcNow;

        await _db.SaveChangesAsync(cancellationToken);
        return await GetByIdAsync(id, cancellationToken);
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var transaction = await _db.Transactions.FirstOrDefaultAsync(t => t.Id == id, cancellationToken)
                          ?? throw new NotFoundException("Transaction not found");
        EnsureOwner(transaction.UserId);
        _db.Transactions.Remove(transaction);
        await _db.SaveChangesAsync(cancellationToken);
    }

    private async Task EnsureCategoryAsync(Guid categoryId, TransactionType type, CancellationToken cancellationToken)
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

    private void EnsureOwner(Guid userId)
    {
        if (userId != _currentUser.UserId)
        {
            throw new ForbiddenException();
        }
    }

    private static IQueryable<Transaction> ApplySort(IQueryable<Transaction> source, string sortBy, string sortDirection)
    {
        var desc = !string.Equals(sortDirection, "asc", StringComparison.OrdinalIgnoreCase);
        return sortBy.ToLowerInvariant() switch
        {
            "amount" => desc ? source.OrderByDescending(t => t.Amount) : source.OrderBy(t => t.Amount),
            "description" => desc ? source.OrderByDescending(t => t.Description) : source.OrderBy(t => t.Description),
            "createdat" => desc ? source.OrderByDescending(t => t.CreatedAt) : source.OrderBy(t => t.CreatedAt),
            _ => desc ? source.OrderByDescending(t => t.Date).ThenByDescending(t => t.CreatedAt)
                      : source.OrderBy(t => t.Date).ThenBy(t => t.CreatedAt)
        };
    }
}
