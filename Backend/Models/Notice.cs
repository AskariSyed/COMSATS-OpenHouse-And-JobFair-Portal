using JobFairPortal.Models;
using Microsoft.AspNetCore.Http.HttpResults;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace JobFairPortal.Models
{
    public enum NoticeAudience
    {
        All,        // Visible to everyone
        Student,    // Visible only to Students
        Company     // Visible only to Companies
    }
    public class Notice
    {
        [Key]
        public int NoticeId { get; set; }

        [Required]
        public string Title { get; set; } = string.Empty;

        [Required]
        public string Content { get; set; } = string.Empty;

        [Required]
        public NoticeAudience Audience { get; set; } = NoticeAudience.All;

        // NEW: specific flag to hide notices instead of deleting them
        public bool IsHidden { get; set; } = false;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        public int JobFairId { get; set; }

        [ForeignKey("JobFairId")]
        public JobFair JobFair { get; set; } = null!;
    }
}
