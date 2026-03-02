using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.DTOs
{
    public class ChangePasswordDto
    {
        [Required]
        [MinLength(8, ErrorMessage = "Current password is required.")]
        public string CurrentPassword { get; set; } = null!;

        [Required]
        [MinLength(8, ErrorMessage = "New password must be at least 8 characters long.")]
        public string NewPassword { get; set; } = null!;

        [Required]
        [Compare("NewPassword", ErrorMessage = "Password confirmation does not match.")]
        public string ConfirmPassword { get; set; } = null!;
    }
}
