namespace JobFairPortal.DTOs
{
    public class StudentLoginResponseDto
    {
        public int StudentId { get; set; }
        public string RegistrationNo { get; set; } = null!;
        public string? ProfilePicUrl { get; set; }
        public string? CvUrl { get; set; }
        public string Department { get; set; } = null!;
        public decimal CGPA { get; set; }
        public List<string>? Skills { get; set; }
        public Dictionary<string, string> Links { get; set; } = new();
        public string? FcmToken { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public List<ExperienceDto> Experiences { get; set; } = new();
        public List<AchievementDto> Achievements { get; set; } = new();
        public List<CertificationDto> Certifications { get; set; } = new();
        public List<EducationDto> Educations { get; set; } = new();
        public UserDto User { get; set; } = null!;
    }
}
