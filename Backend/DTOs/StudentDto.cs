using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.DTOs
{
    public class CompleteProfileDto
    {
        public string? Name { get; set; }
        public string? CVUrl { get; set; }
        public string? FypDemoUrl { get; set; }
        public string? FypTitle { get; set; }
        public string? FypDescription { get; set; }
        public decimal? CGPA { get; set; }
        public List<string>? Skills { get; set; }

    }
    public class SkillsDto
    {
        public List<string>? Skills { get; set; }

    }
    public class StudentListDto
    {
        public int StudentId { get; set; }
        public string? Name { get; set; }
        public string RegistrationNo { get; set; } = null!;
        public string Department { get; set; } = null!;
        public float CGPA { get; set; }
        public List<string> Skills { get; set; } = new();
        public string? ProfilePicUrl { get; set; }
    }
    
        public class NameDto
        {
            [Required]
            [MaxLength(150)]
            public string FullName { get; set; } = null!;
        }
    public class StudentRegistrationDto
    {
        [Required(ErrorMessage = "Registration number is required.")]
        [StringLength(15, MinimumLength = 10, ErrorMessage = "Invalid registration number format.")]
        [RegularExpression(@"^(FA|SP)\d{2}-[A-Z]{3}-\d{3}$",
            ErrorMessage = "Invalid registration number format. Example: FA22-BCS-155")]
        public string RegistrationNo { get; set; } = null!;
    }
}


