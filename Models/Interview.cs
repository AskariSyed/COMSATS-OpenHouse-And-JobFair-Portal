using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.Models
{
    public enum InterviewStatus
    {
        Queued,
        InProgress,
        Shortlisted,
        Hired,
        Rejected
    }

    public class Interview
    {
        [Key]
        public int InterviewId { get; set; }
        [Required]
        public int CompanyId { get; set; }
        [Required]
        public int StudentId { get; set; }
        [Required]
        public int? RequestId { get; set; }
        public InterviewStatus Status { get; set; } = InterviewStatus.Queued;
        public DateTime? ScheduledTime { get; set; }
        public int? DurationMinutes { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        public Company Company { get; set; } = null!;
        public Student Student { get; set; } = null!;
        public InterviewRequest? Request { get; set; }
    }

}
