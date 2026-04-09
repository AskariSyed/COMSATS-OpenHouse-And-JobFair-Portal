using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;

namespace JobFairPortal.Data
{
    /// <summary>
    /// Design-time factory for EF Core tools (migrations/bundle).
    /// This avoids booting Program.cs and runtime-only services such as Firebase.
    /// </summary>
    public class JobFairRecruitmentDbContextFactory : IDesignTimeDbContextFactory<JobFairRecruitmentDbContext>
    {
        public JobFairRecruitmentDbContext CreateDbContext(string[] args)
        {
            var environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Development";

            var configuration = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json", optional: true)
                .AddJsonFile($"appsettings.{environment}.json", optional: true)
                .AddEnvironmentVariables()
                .Build();

            var connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? configuration["ConnectionStrings:DefaultConnection"];

            if (string.IsNullOrWhiteSpace(connectionString))
            {
                throw new InvalidOperationException("Connection string 'DefaultConnection' was not found for EF design-time operations.");
            }

            var optionsBuilder = new DbContextOptionsBuilder<JobFairRecruitmentDbContext>();
            optionsBuilder.UseNpgsql(connectionString);

            return new JobFairRecruitmentDbContext(optionsBuilder.Options);
        }
    }
}
