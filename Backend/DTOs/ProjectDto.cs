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

    public class FypJoinRequestDto
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
    public class ProjectUpdateDto
    {
        [MaxLength(100)]
        public string? Title { get; set; }

        public string? Description { get; set; }

        [MaxLength(200)]
        public string? Skills { get; set; }

        public ProjectType? Type { get; set; }

        public string? ClientName { get; set; }

        public string? Supervisor { get; set; }

        [Url]
        public string? DemoUrl { get; set; }

        [Url]
        public string? GitHubUrl { get; set; }

        public DateTime? StartDate { get; set; }

        public DateTime? EndDate { get; set; }
    }
}
