# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj and restore dependencies
COPY MovieQuiteApi.csproj .
RUN dotnet restore

# Copy remaining source code
COPY . .

# Build and publish the application
RUN dotnet publish -c Release -o /app/publish

# Runtime stage - using chiseled Ubuntu (distroless-like) image
FROM mcr.microsoft.com/dotnet/aspnet:8.0-jammy-chiseled AS runtime

# Create a non-root user
USER $APP_UID

WORKDIR /app

# Copy the published app from build stage
COPY --from=build /app/publish .

# Expose port 8080
EXPOSE 8080

# Set environment variable for ASP.NET Core to listen on port 8080
ENV ASPNETCORE_URLS=http://+:8080

# Run the application
ENTRYPOINT ["dotnet", "MovieQuiteApi.dll"]
