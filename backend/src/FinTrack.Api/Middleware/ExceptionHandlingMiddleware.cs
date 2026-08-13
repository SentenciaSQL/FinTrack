using System.Net;
using System.Text.Json;
using FinTrack.Application.Common;
using Microsoft.AspNetCore.Mvc;

namespace FinTrack.Api.Middleware;

public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;

    public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            await WriteErrorAsync(context, ex);
        }
    }

    private async Task WriteErrorAsync(HttpContext context, Exception exception)
    {
        var (status, code, message, errors) = exception switch
        {
            ValidationAppException validation => (validation.StatusCode, validation.Code, validation.Message, validation.Errors),
            AppException app => (app.StatusCode, app.Code, app.Message, null),
            _ => (StatusCodes.Status500InternalServerError, ErrorCodes.InternalError, "An unexpected error occurred", null)
        };

        if (status >= 500)
        {
            _logger.LogError(exception, "Unhandled exception");
        }
        else
        {
            _logger.LogWarning(exception, "Request failed with {Code}", code);
        }

        context.Response.StatusCode = status;
        context.Response.ContentType = "application/problem+json";

        var problem = new ProblemDetails
        {
            Status = status,
            Title = ((HttpStatusCode)status).ToString(),
            Detail = message,
            Instance = context.Request.Path,
            Type = $"https://httpstatuses.com/{status}"
        };
        problem.Extensions["timestamp"] = DateTime.UtcNow.ToString("O");
        problem.Extensions["error"] = ((HttpStatusCode)status).ToString();
        problem.Extensions["code"] = code;
        problem.Extensions["message"] = message;
        problem.Extensions["path"] = context.Request.Path.Value;
        if (errors is not null)
        {
            problem.Extensions["errors"] = errors;
        }

        await context.Response.WriteAsync(JsonSerializer.Serialize(problem, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        }));
    }
}
