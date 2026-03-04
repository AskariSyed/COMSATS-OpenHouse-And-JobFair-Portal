using JobFairPortal.Models;
using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.DTOs
{
    public class CreateJobDto
    {
        [Required]
        [MaxLength(200)]
        public string JobTitle { get; set; } = null!;

        [Required]
        [MaxLength(2000)]
        public string JobDescription { get; set; } = null!;

        public List<string>? RequiredSkills { get; set; }

        [Required]
        public JobType JobType { get; set; }

        [Required]
        [Range(1, int.MaxValue)]
        public int NumberOfJobs { get; set; }
    }
    public class UpdateJobDto
    {
        [MaxLength(200)]
        public string? JobTitle { get; set; }

        [MaxLength(2000)]
        public string? JobDescription { get; set; }

        public List<string>? RequiredSkills { get; set; }

        public JobType? JobType { get; set; }

        [Range(1, int.MaxValue)]
        public int? NumberOfJobs { get; set; }
    }
    public class EditCompanyProfileDto
    {
        [MaxLength(500)]
        public string? Description { get; set; }

        [MaxLength(200)]
        public string? Website { get; set; }

        [EmailAddress]
        public string? CompanyEmail { get; set; }

        [Phone]
        public string? CompanyPhone { get; set; }

        [MaxLength(300)]
        public string? Address { get; set; }

        [Phone]
        public string? UserPhone { get; set; }

        [Range(5, 240)]
        public int? InterviewDurationMinutes { get; set; }

        [Range(1, 100)]
        public int? RepsCount { get; set; }

        public IFormFile? Logo { get; set; }
    }
    public class AddContactLinkDto
    {
        [Required]
        public CompanyContactPlatform Platform { get; set; }

        [Required]
        [Url]
        [MaxLength(500)]
        public string Url { get; set; } = null!;
    }
    public class UpdateContactLinkDto
    {
        [Url]
        [MaxLength(500)]
        public string? Url { get; set; }

        public CompanyContactPlatform? Platform { get; set; }
    }
}
