using Microsoft.AspNetCore.Http;
using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.DTOs
{
    public class CompanySignupDto
    {
        [Required]
        public string Name { get; set; }
        public string? Description { get; set; }
        [Required]
        public int RepsCount { get; set; }
        [Required, EmailAddress]
        public string RepEmail { get; set; }
        [Required, Phone]
        public string RepPhone { get; set; }
        [Required]
        public string Address { get; set; }
        [Required]
        public int InterviewDurationMinutes { get; set; }
        public string? Industry { get; set; }
        public IFormFile? Logo { get; set; }
        [Required]
        public string UserEmail { get; set; }
        [Required]
        public string UserFullName { get; set; }
        [Required]
        public string UserPassword { get; set; }
        public List<JobCreateDto> JobOfferings { get; set; } = new();
    }

    public class JobCreateDto
    {
        [Required]
        public string JobTitle { get; set; }
        public string? JobDescription { get; set; }
        public string[]? RequiredSkills { get; set; }
    }
}