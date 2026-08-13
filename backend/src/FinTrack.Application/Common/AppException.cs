namespace FinTrack.Application.Common;

public class AppException : Exception
{
    public int StatusCode { get; }
    public string Code { get; }

    public AppException(string code, string message, int statusCode = 400) : base(message)
    {
        Code = code;
        StatusCode = statusCode;
    }
}

public class NotFoundException : AppException
{
    public NotFoundException(string message = "Resource not found")
        : base(ErrorCodes.ResourceNotFound, message, 404)
    {
    }
}

public class ForbiddenException : AppException
{
    public ForbiddenException(string message = "You are not allowed to access this resource")
        : base(ErrorCodes.Forbidden, message, 403)
    {
    }
}

public class ConflictException : AppException
{
    public ConflictException(string code, string message)
        : base(code, message, 409)
    {
    }
}

public class UnauthorizedException : AppException
{
    public UnauthorizedException(string message = "Invalid credentials")
        : base(ErrorCodes.InvalidCredentials, message, 401)
    {
    }
}

public class ValidationAppException : AppException
{
    public IDictionary<string, string[]> Errors { get; }

    public ValidationAppException(string code, string message, IDictionary<string, string[]>? errors = null)
        : base(code, message, 400)
    {
        Errors = errors ?? new Dictionary<string, string[]>();
    }
}
