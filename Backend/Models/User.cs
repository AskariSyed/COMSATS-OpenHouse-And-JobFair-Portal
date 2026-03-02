using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.Models
{
    public enum UserRole
    {
        Admin,
        Student,
        Company
    }

    public class User
    {
        [Key]
        public int UserId { get; set; }
        [Required]
        public string Email { get; set; } = null!;
        [Required]
        public string PasswordHash { get; set; } = null!;
        public UserRole Role { get; set; }
        public string? FullName { get; set; }
        public string? Phone { get; set; }
        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        public Student? Student { get; set; }
        public Company? Company { get; set; }
    }

}
