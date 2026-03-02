using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.DTOs
{
    public class ForgotPasswordDto
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = null!;
    }
    public class VerifyResetTokenDto
    {
        [Required]
        public string Token { get; set; } = null!;

        [Required]
        public int UserId { get; set; }
    }
    public class ResetPasswordDto
    {
        [Required]
        public string Token { get; set; } = null!;

        [Required]
        public int UserId { get; set; }

        [Required]
        [MinLength(8, ErrorMessage = "Password must be at least 8 characters long.")]
        public string NewPassword { get; set; } = null!;

        [Required]
        public string ConfirmPassword { get; set; } = null!;
    }
    public class ForgotPasswordOtpDto
    {
        [Required]
        public string EmailOrRegNo { get; set; } = null!;
    }
    public class VerifyPasswordResetOtpDto
    {
        [Required]
        public int UserId { get; set; }

        [Required]
        public string Otp { get; set; } = null!;

        [Required]
        [MinLength(8, ErrorMessage = "Password must be at least 8 characters long.")]
        public string NewPassword { get; set; } = null!;

        [Required]
        public string ConfirmPassword { get; set; } = null!;
    }
  
}
