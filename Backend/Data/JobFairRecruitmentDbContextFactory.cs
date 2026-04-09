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
            // 1) Prefer explicit --connection passed by `dotnet ef ... --connection ...`
            var connectionFromArgs = TryGetConnectionFromArgs(args);
            if (!string.IsNullOrWhiteSpace(connectionFromArgs))
            {
                var optionsFromArgs = new DbContextOptionsBuilder<JobFairRecruitmentDbContext>();
                optionsFromArgs.UseNpgsql(connectionFromArgs);
                return new JobFairRecruitmentDbContext(optionsFromArgs.Options);
            }

            var environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Development";

            var configuration = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json", optional: true)
                .AddJsonFile($"appsettings.{environment}.json", optional: true)
                .AddJsonFile(Path.Combine(AppContext.BaseDirectory, "appsettings.json"), optional: true)
                .AddJsonFile(Path.Combine(AppContext.BaseDirectory, $"appsettings.{environment}.json"), optional: true)
                .AddEnvironmentVariables()
                .Build();

            var connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? configuration["ConnectionStrings:DefaultConnection"]
                ?? Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection");

            if (string.IsNullOrWhiteSpace(connectionString))
            {
                throw new InvalidOperationException("Connection string 'DefaultConnection' was not found for EF design-time operations.");
            }

            var optionsBuilder = new DbContextOptionsBuilder<JobFairRecruitmentDbContext>();
            optionsBuilder.UseNpgsql(connectionString);

            return new JobFairRecruitmentDbContext(optionsBuilder.Options);
        }

        private static string? TryGetConnectionFromArgs(string[] args)
        {
            if (args == null || args.Length == 0) return null;

            for (var i = 0; i < args.Length; i++)
            {
                var arg = args[i] ?? string.Empty;

                if (arg.StartsWith("--connection=", StringComparison.OrdinalIgnoreCase))
                {
                    return arg.Substring("--connection=".Length).Trim();
                }

                if (string.Equals(arg, "--connection", StringComparison.OrdinalIgnoreCase) && i + 1 < args.Length)
                {
                    return (args[i + 1] ?? string.Empty).Trim();
                }

                // Some hosts may pass the raw connection string as a positional arg.
                if (arg.Contains("Host=", StringComparison.OrdinalIgnoreCase)
                    || arg.Contains("Server=", StringComparison.OrdinalIgnoreCase))
                {
                    return arg.Trim();
                }
            }

            return null;
        }
    }
}
