using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

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
        [ForeignKey("User")]
        public int UserId { get; set; }

        [Required]
        public string Name { get; set; } = null!;
        public string? LogoUrl { get; set; }
        public string? Description { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "RepsCount must be at least 1.")]
        public int RepsCount { get; set; } = 1;
        [Required]
        public string FocalPersonName { get; set; } = null!;

        [Required, EmailAddress]
        public string FocalPersonEmail { get; set; } = null!;

        [Required, Phone]
        public string FocalPersonPhone { get; set; } = null!;
        [EmailAddress]
        public string? CompanyEmail { get; set; }   

        [Phone]
        public string? CompanyPhone { get; set; }
        public string? FcmToken { get; set; }

        public string? Address { get; set; }         

        [Url]
        public string? Website { get; set; }        

        public string? Industry { get; set; }

        [Range(1, 60, ErrorMessage = "Interview duration must be between 1 and 480 minutes.")]
        public int InterviewDurationMinutes { get; set; }

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
        public ICollection<CompanyContactLink> CompanyContactLinks { get; set; } = new List<CompanyContactLink>();

        public int JobFairId { get; set; }
        public JobFair JobFair { get; set; } = null!;
    }
}
