using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using JobFairPortal.Models;

namespace JobFairPortal.DTOs
{
    public class ProjectAddDto
    {
        [Required]
        [MaxLength(100)]
        public string Title { get; set; } = null!;

        [Required]
        public ProjectType Type { get; set; }

        public string? Description { get; set; }
        public string? Skills { get; set; }
        public string? ClientName { get; set; }
        public string? Supervisor { get; set; }
        public string? DemoUrl { get; set; }
        public string? GitHubUrl { get; set; }

        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
    }

    public class ProjectInviteDto
    {
        [Required]
        public string RegistrationNumber { get; set; } = null!;
    }
    public class ProjectListDto
    {
        public int ProjectId { get; set; }
        public string Title { get; set; } = null!;
        public string? Description { get; set; }
        public string? Skills { get; set; }
        public string? DemoUrl { get; set; }
    }
}
