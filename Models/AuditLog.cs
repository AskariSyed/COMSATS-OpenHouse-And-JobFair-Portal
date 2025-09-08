using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.Models
{
    public class AuditLog
    {
        [Key]
        public int LogId { get; set; }
        public int? UserId { get; set; }  // user_id
        public string Action { get; set; } = null!;
        public string EntityType { get; set; } = null!;
        public int? EntityId { get; set; }
        public string? Details { get; set; } // JSON string

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public User? Actor { get; set; }

    }

}
