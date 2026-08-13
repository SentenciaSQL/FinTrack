FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY FinTrack.sln ./
COPY src/FinTrack.Domain/FinTrack.Domain.csproj src/FinTrack.Domain/
COPY src/FinTrack.Application/FinTrack.Application.csproj src/FinTrack.Application/
COPY src/FinTrack.Infrastructure/FinTrack.Infrastructure.csproj src/FinTrack.Infrastructure/
COPY src/FinTrack.Api/FinTrack.Api.csproj src/FinTrack.Api/
RUN dotnet restore FinTrack.sln

COPY src/ src/
RUN dotnet publish src/FinTrack.Api/FinTrack.Api.csproj -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "FinTrack.Api.dll"]
