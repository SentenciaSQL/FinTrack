using AutoMapper;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using FinTrack.Application.Common;
using FinTrack.Application.DTOs.Categories;
using FinTrack.Application.Interfaces;
using FinTrack.Domain.Entities;

namespace FinTrack.Application.Services;

public class CategoryService : ICategoryService
{
    private readonly IFinTrackDbContext _db;
    private readonly ICurrentUser _currentUser;
    private readonly IDateTimeProvider _clock;
    private readonly IMapper _mapper;
    private readonly IValidator<CreateCategoryRequest> _createValidator;
    private readonly IValidator<UpdateCategoryRequest> _updateValidator;

    public CategoryService(
        IFinTrackDbContext db,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        IMapper mapper,
        IValidator<CreateCategoryRequest> createValidator,
        IValidator<UpdateCategoryRequest> updateValidator)
    {
        _db = db;
        _currentUser = currentUser;
        _clock = clock;
        _mapper = mapper;
        _createValidator = createValidator;
        _updateValidator = updateValidator;
    }

    public async Task<IReadOnlyList<CategoryDto>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        var categories = await _db.Categories
            .AsNoTracking()
            .Where(c => c.UserId == _currentUser.UserId)
            .OrderBy(c => c.Type)
            .ThenBy(c => c.Name)
            .ToListAsync(cancellationToken);

        return _mapper.Map<IReadOnlyList<CategoryDto>>(categories);
    }

    public async Task<CategoryDto> CreateAsync(CreateCategoryRequest request, CancellationToken cancellationToken = default)
    {
        await _createValidator.ValidateAndThrowAppAsync(request, cancellationToken);

        var category = new Category
        {
            Id = Guid.NewGuid(),
            Name = request.Name.Trim(),
            Icon = request.Icon,
            Type = request.Type,
            UserId = _currentUser.UserId,
            IsDefault = false,
            CreatedAt = _clock.UtcNow
        };

        _db.Categories.Add(category);
        await _db.SaveChangesAsync(cancellationToken);
        return _mapper.Map<CategoryDto>(category);
    }

    public async Task<CategoryDto> UpdateAsync(Guid id, UpdateCategoryRequest request, CancellationToken cancellationToken = default)
    {
        await _updateValidator.ValidateAndThrowAppAsync(request, cancellationToken);
        var category = await GetOwnedAsync(id, cancellationToken);
        category.Name = request.Name.Trim();
        category.Icon = request.Icon;
        await _db.SaveChangesAsync(cancellationToken);
        return _mapper.Map<CategoryDto>(category);
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var category = await GetOwnedAsync(id, cancellationToken);
        if (category.IsDefault)
        {
            throw new ValidationAppException(ErrorCodes.CannotDeleteDefaultCategory, "Default categories cannot be deleted");
        }

        var inUse = await _db.Transactions.AnyAsync(t => t.CategoryId == id, cancellationToken)
                    || await _db.Budgets.AnyAsync(b => b.CategoryId == id, cancellationToken)
                    || await _db.RecurringTransactions.AnyAsync(r => r.CategoryId == id, cancellationToken);
        if (inUse)
        {
            throw new ValidationAppException(ErrorCodes.ValidationError, "Category is in use and cannot be deleted");
        }

        _db.Categories.Remove(category);
        await _db.SaveChangesAsync(cancellationToken);
    }

    private async Task<Category> GetOwnedAsync(Guid id, CancellationToken cancellationToken)
    {
        var category = await _db.Categories.FirstOrDefaultAsync(c => c.Id == id, cancellationToken)
                       ?? throw new NotFoundException("Category not found");

        if (category.UserId != _currentUser.UserId)
        {
            throw new ForbiddenException();
        }

        return category;
    }
}
