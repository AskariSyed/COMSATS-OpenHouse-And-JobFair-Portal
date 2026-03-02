namespace JobFairPortal.DTOs
{
    public class FcmTokenValidationDto
    {
        public int StudentId { get; set; }
        public string Token { get; set; } = null!;
        public DateTime LastValidated { get; set; }
        public bool IsValid { get; set; }
        public string? ValidationError { get; set; }
    }

    public class FcmTokenRefreshDto
    {
        public int StudentId { get; set; }
        public string OldToken { get; set; } = null!;
        public string NewToken { get; set; } = null!;
    }
}