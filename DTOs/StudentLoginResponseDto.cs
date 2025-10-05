namespace JobFairPortal.DTOs
{
    public class StudentLoginResponseDto
    {
        public int StudentId { get; set; }
        public string RegistrationNo { get; set; } = null!;
        public string? ProfilePicUrl { get; set; }
        public string? CVUrl { get; set; }
        public string? FypTitle { get; set; }
        public string? FypDemoUrl { get; set; }
        public string? FypDescription { get; set; }
        public string Department { get; set; } = null!;
        public decimal CGPA { get; set; }
        public string[]? Skills { get; set; }
        public Dictionary<string, string>? Links { get; set; }
        public string? FcmToken { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }

        // Nested user object:
        public UserDto User { get; set; } = null!;
    }
}
