using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.Models
{
    public enum ArrivalStatus
    {
        PreRegistered,
        OnSpot
    }

    public class Company
    {
        [Key]
        public int CompanyId { get; set; }

        [Required]
        public int UserId { get; set; }

        [Required]
        public string Name { get; set; } = null!;
        public string? LogoUrl { get; set; }
        public string? Description { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "RepsCount must be at least 1.")]
        public int RepsCount { get; set; } = 1;

        [Required, EmailAddress]
        public string RepEmail { get; set; } = null!;

        [Required, Phone]
        public string RepPhone { get; set; } = null!;

        [Required]
        public string Address { get; set; } = null!;

        [Range(1, 480, ErrorMessage = "Interview duration must be between 1 and 480 minutes.")]
        public int InterviewDurationMinutes { get; set; }

        public string? Industry { get; set; }

        public ArrivalStatus ArrivalStatus { get; set; } = ArrivalStatus.OnSpot;
        public bool IsPresent { get; set; } = false;
        public string? SecretKey { get; set; }
        public bool KeyUsed { get; set; } = false;
        public DateTime? KeyExpiry { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        public User User { get; set; } = null!;
        public ICollection<Job> Jobs { get; set; } = new List<Job>();
        public Room? Room { get; set; }
        public ICollection<InterviewRequest> InterviewRequests { get; set; } = new List<InterviewRequest>();
        public ICollection<Interview> Interviews { get; set; } = new List<Interview>();
        public ICollection<Survey> Surveys { get; set; } = new List<Survey>();
    }
}