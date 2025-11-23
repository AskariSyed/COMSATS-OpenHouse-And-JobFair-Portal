using JobFairPortal.Models;
using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.DTOs
{
    public class NoticeCreateDto
    {
        [Required]
        public string Title { get; set; } = string.Empty;
        [Required]
        public string Content { get; set; } = string.Empty;
        [Required]
        public NoticeAudience Audience { get; set; }
    }

    public class NoticeResponseDto
    {
        public int NoticeId { get; set; }
        public string Title { get; set; }
        public string Content { get; set; }
        public string Audience { get; set; }
        public bool IsHidden { get; set; } // NEW field
        public DateTime CreatedAt { get; set; }
    }
}
