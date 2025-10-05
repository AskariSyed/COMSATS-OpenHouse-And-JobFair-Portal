using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.Models
{
    public enum JobType
    {
        FullTime,
        Internship,
        PartTime,
        Remote
    }

    public class Job
    {
        [Key]
        public int JobId { get; set; }
        [Required]
        public int CompanyId { get; set; }
        [Required]
        public string JobTitle { get; set; } = null!;
        public JobType JobType { get; set; }
        public string? JobDescription { get; set; }
        public string[]? RequiredSkills { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        public Company Company { get; set; } = null!;

    }

}
