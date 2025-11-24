namespace JobFairPortal.Models
{
    public class PasswordResetOtpToken
    {
        public string Otp { get; set; } = null!;
        public int UserId { get; set; }
        public string Email { get; set; } = null!;
        public DateTime CreatedAt { get; set; }
        public bool IsUsed { get; set; }
    }
}
