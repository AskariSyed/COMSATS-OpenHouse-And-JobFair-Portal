using System;
using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.DTOs
{
    public class AchievementDto
    {
        public int AchievementId { get; set; }
        public string Title { get; set; } = null!;
        public string? Description { get; set; }
        public DateTime? DateAchieved { get; set; }
    }
    public class AchievementUpdateDto
    {
        [MaxLength(100)]
        public string? Title { get; set; }

        [MaxLength(500)]
        public string? Description { get; set; }

        public DateTime? DateAchieved { get; set; }
    }
    public class AchievementAddDto
    {
        [Required]
        [MaxLength(100)]
        public string Title { get; set; } = null!;

        [MaxLength(500)]
        public string? Description { get; set; }

        public DateTime? DateAchieved { get; set; }
    }
}
