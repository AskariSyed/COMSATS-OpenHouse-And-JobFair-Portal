using JobFairPortal.Models;
using System;
using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.DTOs
{
    public class ExperienceAddDto
    {
        [Required]
        [MaxLength(100)]
        public string CompanyName { get; set; } = null!;

        [Required]
        [MaxLength(100)]
        public string Role { get; set; } = null!;

        [MaxLength(100)]
        public string? Location { get; set; }

        [MaxLength(1000)]
        public string? Description { get; set; }

        [Required]
        public DateTime StartDate { get; set; }

        public DateTime? EndDate { get; set; }

        [Required]
        public bool IsCurrent { get; set; }
    }
    public class ExperienceUpdateDto
    {
        [MaxLength(100)]
        public string? CompanyName { get; set; }

        [MaxLength(100)]
        public string? Role { get; set; }

        [MaxLength(100)]
        public string? Location { get; set; }

        [MaxLength(1000)]
        public string? Description { get; set; }

        public DateTime? StartDate { get; set; }

        public DateTime? EndDate { get; set; }

        public bool? IsCurrent { get; set; }
    }
    public class ExperienceDto
    {
        public int ExperienceId { get; set; }
        public string Title { get; set; } = null!;
        public string CompanyName { get; set; } = null!;
        public string Role { get; set; } = null!;
        public string? Description { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public bool IsCurrent { get; set; }
        public string? Location { get; set; }
    }
}
