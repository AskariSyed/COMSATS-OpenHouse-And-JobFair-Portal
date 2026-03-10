namespace JobFairPortal.DTOs
{
    public class StudentLoginResponseDto
    {
        public int StudentId { get; set; }
        public string RegistrationNo { get; set; }
        public string? ProfilePicUrl { get; set; }
        public string? CvUrl { get; set; }
        public string Department { get; set; }
        public decimal CGPA { get; set; }
        public List<string>? Skills { get; set; }
        public Dictionary<string, string> Links { get; set; }
        public string? FcmToken { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public List<ExperienceDto> Experiences { get; set; }
        public List<AchievementDto> Achievements { get; set; }
        public List<CertificationDto> Certifications { get; set; }
        public List<EducationDto> Educations { get; set; }
        public UserDto User { get; set; }
    }
}
