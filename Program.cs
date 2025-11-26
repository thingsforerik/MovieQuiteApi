using Microsoft.EntityFrameworkCore;
using MovieQuiteApi.Data;

var builder = WebApplication.CreateBuilder(args);

// Add MySQL DbContext
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? "Server=localhost;Port=3306;Database=moviequotes;User=root;Password=password;";

builder.Services.AddDbContext<MovieDbContext>(options =>
    options.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString)));

// Add CORS for API Gateway integration
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Auto-migrate database on startup
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<MovieDbContext>();
    db.Database.Migrate();
}

// Enable CORS
app.UseCors();

// Health Check Endpoints
app.MapGet("/healthz", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }))
   .WithName("HealthCheck")
   .WithTags("Health");

app.MapGet("/ready", () => Results.Ok(new { status = "ready", timestamp = DateTime.UtcNow }))
   .WithName("ReadinessCheck")
   .WithTags("Health");

// API Endpoints using MySQL database

// GET all quotes
app.MapGet("/api/quotes", async (MovieDbContext db) =>
{
    return await db.MovieQuotes.ToListAsync();
});

// GET quote by ID
app.MapGet("/api/quotes/{id}", async (int id, MovieDbContext db) =>
{
    var quote = await db.MovieQuotes.FindAsync(id);
    return quote is not null ? Results.Ok(quote) : Results.NotFound();
});

// GET random quote
app.MapGet("/api/quotes/random", async (MovieDbContext db) =>
{
    var count = await db.MovieQuotes.CountAsync();
    if (count == 0)
        return Results.NotFound();

    var random = new Random();
    int skip = random.Next(count);
    var quote = await db.MovieQuotes.Skip(skip).FirstAsync();
    return Results.Ok(quote);
});

// POST create new quote
app.MapPost("/api/quotes", async (MovieQuite newQuote, MovieDbContext db) =>
{
    db.MovieQuotes.Add(newQuote);
    await db.SaveChangesAsync();
    return Results.Created($"/api/quotes/{newQuote.Id}", newQuote);
});

// PUT update existing quote
app.MapPut("/api/quotes/{id}", async (int id, MovieQuite updatedQuote, MovieDbContext db) =>
{
    var quote = await db.MovieQuotes.FindAsync(id);
    if (quote is null)
        return Results.NotFound();

    quote.Quote = updatedQuote.Quote;
    quote.Movie = updatedQuote.Movie;
    await db.SaveChangesAsync();
    return Results.Ok(quote);
});

// DELETE quote
app.MapDelete("/api/quotes/{id}", async (int id, MovieDbContext db) =>
{
    var quote = await db.MovieQuotes.FindAsync(id);
    if (quote is null)
        return Results.NotFound();

    db.MovieQuotes.Remove(quote);
    await db.SaveChangesAsync();
    return Results.NoContent();
});

app.MapGet("/", () => "Hello World!");

app.Run();

// 3. The Model: A simple class to represent a movie quote
public class MovieQuite
{
    public int Id { get; set; }
    public required string Quote { get; set; }
    public required string Movie { get; set; }
}