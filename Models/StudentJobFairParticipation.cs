using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace JobFairPortal.Models
{
    /// <summary>
    /// Tracks student participation across multiple job fairs
    /// Allows students to participate in multiple job fairs over time
    /// </summary>
    public class StudentJobFairParticipation
    {
        [Key]
        public int ParticipationId { get; set; }

        [Required]
        public int StudentId { get; set; }

        [Required]
        public int JobFairId { get; set; }

        // Participation-specific details
        public bool HasRegistered { get; set; } = true;
        public int InterviewsAttended { get; set; } = 0;
        public int OffersReceived { get; set; } = 0;

        // Tracking
        public DateTime RegisteredAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        [ForeignKey("StudentId")]
        public Student Student { get; set; } = null!;

        [ForeignKey("JobFairId")]
        public JobFair JobFair { get; set; } = null!;

        // Composite unique key to prevent duplicate registrations
        public static void ConfigureModelBuilder(Microsoft.EntityFrameworkCore.ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<StudentJobFairParticipation>()
                .HasIndex(x => new { x.StudentId, x.JobFairId })
                .IsUnique();
        }
    }
}