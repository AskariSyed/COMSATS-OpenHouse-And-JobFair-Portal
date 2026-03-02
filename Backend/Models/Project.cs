using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.Models
{

    public enum ProjectType
    {
        Semester,
        Freelance,
        FinalYear,
        Other
    }
    public class Project
    {
        [Key]
        public int ProjectId { get; set; }

        [Required]
        public ProjectType Type { get; set; }

        [Required]
        [MaxLength(100)]
        public string Title { get; set; } = null!;

        public string? Description { get; set; }

        [MaxLength(200)]
        public string? Skills { get; set; }

        [Url]
        public string? DemoUrl { get; set; }

        [Url]
        public string? GitHubUrl { get; set; }

        public string? ClientName { get; set; }
        public string? Role { get; set; }      
        public string? Supervisor { get; set; } 

        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public ICollection<StudentProject> StudentProjects { get; set; } = new List<StudentProject>();
    }
}
