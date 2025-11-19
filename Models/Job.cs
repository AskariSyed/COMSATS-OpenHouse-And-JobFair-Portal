using System;
using System.ComponentModel.DataAnnotations;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;

namespace JobFairPortal.Models
{
    public enum JobType
    {
        FullTime,
        Internship,
        PartTime,
        Remote,
        Onsite
    }

    public class Job
    {
        [Key]
        public int JobId { get; set; }

        [Required]
        public int CompanyId { get; set; }


        [Required]
        [MaxLength(200)]
        public string JobTitle { get; set; } = null!;

        public JobType JobType { get; set; } = JobType.FullTime;

        [MaxLength(2000)]
        public string? JobDescription { get; set; }
        [Required]
        public int NumberOfJobs { get; set; }


        // Store array as JSON in the DB
        public string[]? RequiredSkills { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation property
        public Company Company { get; set; } = null!;
    }

    // In DbContext, map RequiredSkills as JSON
    public static class JobModelBuilderExtensions
    {
        public static void ConfigureJob(this ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Job>()
                .Property(j => j.RequiredSkills)
                .HasConversion(
                    v => JsonSerializer.Serialize(v, (JsonSerializerOptions?)null),
                    v => JsonSerializer.Deserialize<string[]>(v, (JsonSerializerOptions?)null)
                )
                .HasColumnType("jsonb"); 
        }
    }
}
