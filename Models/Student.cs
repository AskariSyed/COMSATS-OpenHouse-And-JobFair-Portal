using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.Models
{
    public class Student
    {
        [Key]
        public int StudentId { get; set; }
        [Required]
        public int UserId { get; set; }
        [Required]
        public string RegistrationNo { get; set; } = null!; 
        public decimal CGPA { get; set; }
        public string? CVUrl { get; set; }
        public string? ProfilePicUrl { get; set; } 
        public string? FypTitle { get; set; }
        public string? FypDemoUrl { get; set; }
        public string? FypDescription { get; set; }
        public string Department { get; set; } = null!;
        public string[]? Skills { get; set; }
        public string? FcmToken { get; set; }
        public string? LinkedIn { get; set; }
        public string? GitHub { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        public User User { get; set; } = null!;
        public ICollection<InterviewRequest> InterviewRequests { get; set; } = new List<InterviewRequest>();
        public ICollection<Interview> Interviews { get; set; } = new List<Interview>();
    }
}
