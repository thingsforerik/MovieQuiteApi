using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Metadata;
using MovieQuiteApi.Data;

#nullable disable

namespace MovieQuiteApi.Data.Migrations
{
    [DbContext(typeof(MovieDbContext))]
    partial class MovieDbContextModelSnapshot : ModelSnapshot
    {
        protected override void BuildModel(ModelBuilder modelBuilder)
        {
#pragma warning disable 612, 618
            modelBuilder
                .HasAnnotation("ProductVersion", "9.0.0")
                .HasAnnotation("Relational:MaxIdentifierLength", 64);

            MySqlModelBuilderExtensions.AutoIncrementColumns(modelBuilder);

            modelBuilder.Entity("MovieQuite", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    MySqlPropertyBuilderExtensions.UseMySqlIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("Movie")
                        .IsRequired()
                        .HasColumnType("longtext");

                    b.Property<string>("Quote")
                        .IsRequired()
                        .HasColumnType("longtext");

                    b.HasKey("Id");

                    b.ToTable("MovieQuotes");

                    b.HasData(
                        new
                        {
                            Id = 1,
                            Movie = "Star Wars",
                            Quote = "May the Force be with you."
                        },
                        new
                        {
                            Id = 2,
                            Movie = "The Godfather",
                            Quote = "I'm going to make him an offer he can't refuse."
                        },
                        new
                        {
                            Id = 3,
                            Movie = "Casablanca",
                            Quote = "Here's looking at you, kid."
                        },
                        new
                        {
                            Id = 4,
                            Movie = "A Few Good Men",
                            Quote = "You can't handle the truth!"
                        },
                        new
                        {
                            Id = 5,
                            Movie = "The Terminator",
                            Quote = "I'll be back."
                        });
                });
#pragma warning restore 612, 618
        }
    }
}
