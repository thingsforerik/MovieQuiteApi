using Microsoft.EntityFrameworkCore;

namespace MovieQuiteApi.Data;

public class MovieDbContext : DbContext
{
    public MovieDbContext(DbContextOptions<MovieDbContext> options)
        : base(options)
    {
    }

    public DbSet<MovieQuite> MovieQuotes { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Seed initial data
        modelBuilder.Entity<MovieQuite>().HasData(
            new MovieQuite { Id = 1, Quote = "May the Force be with you.", Movie = "Star Wars" },
            new MovieQuite { Id = 2, Quote = "I'm going to make him an offer he can't refuse.", Movie = "The Godfather" },
            new MovieQuite { Id = 3, Quote = "Here's looking at you, kid.", Movie = "Casablanca" },
            new MovieQuite { Id = 4, Quote = "You can't handle the truth!", Movie = "A Few Good Men" },
            new MovieQuite { Id = 5, Quote = "I'll be back.", Movie = "The Terminator" }
        );
    }
}
