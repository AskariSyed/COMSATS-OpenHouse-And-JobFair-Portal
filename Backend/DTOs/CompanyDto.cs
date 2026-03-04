using JobFairPortal.Models;
using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.DTOs
{
    public class CompanyDto
    {
        public int CompanyId { get; set; }
        public string Name { get; set; }
        public string? Email { get; set; }
        public bool IsPresent { get; set; }
        public string? RoomName { get; set; }
    }
    public class CompanyCreateDto
    {
        [Required]
        public string Name { get; set; } = null!;

        [Required]
        public string Industry { get; set; } = null!;

        [Required]
        public string FocalPersonName { get; set; } = null!;

        [Required, EmailAddress]
        public string Email { get; set; } = null!;

        [Required, Phone]
        public string FocalPersonPhone { get; set; } = null!;

        [Range(1, 20)]
        public int RepsCount { get; set; } = 1;
    }

    public class CompanyResponseDto
    {
        public int CompanyId { get; set; }
        public string Name { get; set; } = null!;
        public string? Industry { get; set; }
        public string? UserEmail { get; set; }
        public string? RoomName { get; set; }
    }
    public class CompanyOverviewDto
    {
        public int CompanyId { get; set; }
        public string CompanyName { get; set; } = null!;
        public string? Field { get; set; }  // e.g. "AI", "Cloud", "Cybersecurity"
        public string InterviewingStatus { get; set; } = "NotStarted"; // Present/OnSpot
        public string? RoomAllotted { get; set; }

        public int TotalInterviews { get; set; }
        public int StudentsShortlisted { get; set; }
        public int StudentsHired { get; set; }
        public int StudentsRejected { get; set; }
        public int StudentsQueued { get; set; }
    }

    public class ChangeCompanyRoomDto
    {
        public int CompanyId { get; set; }
        public int RoomId { get; set; }
    }
    
        public class CompanyContactLinkAddDto
        {
            [Required]
            public CompanyContactPlatform Platform { get; set; }

            [Required]
            [Url]
            public string Url { get; set; } = null!;
        }

        public class CompanyContactLinkUpdateDto
        {
            public CompanyContactPlatform? Platform { get; set; }

            [Url]
            public string? Url { get; set; }
        }
}
