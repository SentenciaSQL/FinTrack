using FluentValidation;
using FinTrack.Application.Common;

namespace FinTrack.Application.Common;

public static class ValidationExtensions
{
    public static async Task ValidateAndThrowAppAsync<T>(this IValidator<T> validator, T instance, CancellationToken cancellationToken = default)
    {
        var result = await validator.ValidateAsync(instance, cancellationToken);
        if (result.IsValid)
        {
            return;
        }

        var errors = result.Errors
            .GroupBy(e => e.PropertyName)
            .ToDictionary(g => g.Key, g => g.Select(e => e.ErrorMessage).ToArray());

        var first = result.Errors[0];
        var code = string.IsNullOrWhiteSpace(first.ErrorCode) || first.ErrorCode == "NotEmptyValidator"
            ? ErrorCodes.ValidationError
            : first.ErrorCode;

        throw new ValidationAppException(code, first.ErrorMessage, errors);
    }
}
