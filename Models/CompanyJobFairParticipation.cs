using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace JobFairPortal.Models
{
    /// <summary>
    /// Tracks company participation across multiple job fairs
    /// Allows companies to participate in multiple job fairs over time
    /// </summary>
    public class CompanyJobFairParticipation
    {
        [Key]
        public int ParticipationId { get; set; }

        [Required]
        public int CompanyId { get; set; }

        [Required]
        public int JobFairId { get; set; }

        // Participation-specific details
        public ArrivalStatus ArrivalStatus { get; set; } = ArrivalStatus.Pending; // ? Changed default to Pending
        public bool IsPresent { get; set; } = false;    
        public int RepsCount { get; set; } = 1;
        public int InterviewDurationMinutes { get; set; } = 30;
        public int? RoomId { get; set; }

        // Tracking
        public DateTime RegisteredAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        [ForeignKey("CompanyId")]
        public Company Company { get; set; } = null!;

        [ForeignKey("JobFairId")]
        public JobFair JobFair { get; set; } = null!;

        [ForeignKey("RoomId")]
        public Room? Room { get; set; }

        [MaxLength(200)]
        public string? AttendanceToken { get; set; }

        // Token expiry (typically end of job fair day)
        public DateTime? AttendanceTokenExpiry { get; set; }


        // Composite unique key to prevent duplicate registrations
        public static void ConfigureModelBuilder(Microsoft.EntityFrameworkCore.ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<CompanyJobFairParticipation>()
                .HasIndex(x => new { x.CompanyId, x.JobFairId })
                .IsUnique();
        }
    }
}