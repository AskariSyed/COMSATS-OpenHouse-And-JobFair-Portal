using System;

namespace JobFairPortal.DTOs
{
    public class AchievementDto
    {
        public int AchievementId { get; set; }
        public string Title { get; set; } = null!;
        public string? Description { get; set; }
        public DateTime? DateAchieved { get; set; }
    }
}
