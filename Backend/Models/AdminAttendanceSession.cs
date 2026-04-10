using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace JobFairPortal.Models
{
    public class AdminAttendanceSession
    {
        [Key]
        public int AdminAttendanceSessionId { get; set; }

        // Opaque session token shown as QR to companies (short-lived)
        [Required]
        [MaxLength(200)]
        public string SessionToken { get; set; } = null!;

        [Required]
        public int  JobFairId { get; set; }

        public string? CreatedByAdmin { get; set; }

        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime ExpiresAt { get; set; }

        // Navigation
        [ForeignKey("JobFairId")]
        public JobFair JobFair { get; set; } = null!;
    }
}