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
        public int RepsCount { get; set; } = 1;
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

        // One-to-one room
        public Room? Room { get; set; }
        public ICollection<InterviewRequest> InterviewRequests { get; set; } = new List<InterviewRequest>();
        public ICollection<Interview> Interviews { get; set; } = new List<Interview>();
        public ICollection<Survey> Surveys { get; set; } = new List<Survey>();

    }
}
