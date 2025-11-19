using JobFairPortal.Models;
using Microsoft.AspNetCore.Http;
using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.DTOs
{
    public class CompanySignupDto
    {
        // --- User Account Fields ---
        [Required]
        [EmailAddress]
        public string UserEmail { get; set; } = null!;

        [Required]
        public string UserFullName { get; set; } = null!;

        [Required]
        [MinLength(8, ErrorMessage = "Password must be at least 8 characters long.")]
        public string UserPassword { get; set; } = null!;

        // --- Company Core Fields ---
        [Required]
        public string Name { get; set; } = null!;

        public string? Description { get; set; }

        public IFormFile? Logo { get; set; } // Used for [FromForm] in controller

        // --- Focal Person Fields ---
        [Required]
        public string FocalPersonName { get; set; } = null!;

        [Required]
        [EmailAddress]
        public string FocalPersonEmail { get; set; } = null!;

        [Required]
        [Phone]
        public string FocalPersonPhone { get; set; } = null!;

        [Range(1, int.MaxValue, ErrorMessage = "RepsCount must be at least 1.")]
        public int RepsCount { get; set; } = 1;

        [EmailAddress]
        public string? CompanyEmail { get; set; }

        [Phone]
        public string? CompanyPhone { get; set; }

        public string? Address { get; set; }

        [Url]
        public string? Website { get; set; }

        public string? Industry { get; set; }

        [Range(1, 60, ErrorMessage = "Interview duration must be between 1 and 60 minutes.")]
        public int InterviewDurationMinutes { get; set; } = 15;

        // --- Job Offerings ---
        public List<JobOfferingDto> JobOfferings { get; set; } = new List<JobOfferingDto>();

        // --- Company Contact Links ---
        public List<CompanyContactLinkDto> ContactLinks { get; set; } = new List<CompanyContactLinkDto>();
    }

    public class JobOfferingDto
    {
        [Required]
        public string JobTitle { get; set; } = null!;

        public string? JobDescription { get; set; }

        public string? RequiredSkills { get; set; }
        public int JobCount { get; set; }

        [Required]
        public JobType Type { get; set; }
    }

    public class CompanyContactLinkDto
    {
        [Required]
        public CompanyContactPlatform Platform { get; set; }

        [Required]
        [Url]
        public string Url { get; set; } = null!;
    }
}
