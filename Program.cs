var builder = WebApplication.CreateBuilder(args);

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

// Enable CORS
app.UseCors();

// Health Check Endpoints
app.MapGet("/healthz", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }))
   .WithName("HealthCheck")
   .WithTags("Health");

app.MapGet("/ready", () => Results.Ok(new { status = "ready", timestamp = DateTime.UtcNow }))
   .WithName("ReadinessCheck")
   .WithTags("Health");

// 1. The Data: A hardcoded list of quotes
var quotes = new List<MovieQuite>
{
    new MovieQuite { Id = 1, Quote = "May the Force be with you.", Movie = "Star Wars" },
    new MovieQuite { Id = 2, Quote = "I'm going to make him an offer he can't refuse.", Movie = "The Godfather" },
    new MovieQuite { Id = 3, Quote = "Here's looking at you, kid.", Movie = "Casablanca" },
    new MovieQuite { Id = 4, Quote = "You can't handle the truth!", Movie = "A Few Good Men" },
    new MovieQuite { Id = 5, Quote = "I'll be back.", Movie = "The Terminator" }
};

// 2. The Endpoints: CRUD API endpoints

// GET all quotes
app.MapGet("/api/quotes", () =>
{
    return quotes;
});

// GET quote by ID
app.MapGet("/api/quotes/{id}", (int id) =>
{
    var quote = quotes.FirstOrDefault(q => q.Id == id);
    return quote is not null ? Results.Ok(quote) : Results.NotFound();
});

// GET random quote
app.MapGet("/api/quotes/random", () =>
{
    var random = new Random();
    int index = random.Next(quotes.Count);
    return quotes[index];
});

// POST create new quote
app.MapPost("/api/quotes", (MovieQuite newQuote) =>
{
    newQuote.Id = quotes.Max(q => q.Id) + 1;
    quotes.Add(newQuote);
    return Results.Created($"/api/quotes/{newQuote.Id}", newQuote);
});

// PUT update existing quote
app.MapPut("/api/quotes/{id}", (int id, MovieQuite updatedQuote) =>
{
    var quote = quotes.FirstOrDefault(q => q.Id == id);
    if (quote is null)
        return Results.NotFound();
    
    quote.Quote = updatedQuote.Quote;
    quote.Movie = updatedQuote.Movie;
    return Results.Ok(quote);
});

// DELETE quote
app.MapDelete("/api/quotes/{id}", (int id) =>
{
    var quote = quotes.FirstOrDefault(q => q.Id == id);
    if (quote is null)
        return Results.NotFound();
    
    quotes.Remove(quote);
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