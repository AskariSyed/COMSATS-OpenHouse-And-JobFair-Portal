namespace JobFairPortal.DTOs
{
    public class LoginDto
    {
        public string EmailOrRegNo { get; set; } = null!;
        public string Password { get; set; } = null!;
        public string? FcmToken { get; set; }
    }
}
