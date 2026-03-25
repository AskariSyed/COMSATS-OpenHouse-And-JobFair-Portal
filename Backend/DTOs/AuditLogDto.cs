namespace JobFairPortal.DTOs
{
    public class AuditLogDto
    {
        public int AuditLogId { get; set; }
        public string Action { get; set; } = null!;
        public string ActorName { get; set; } = null!;
        public DateTime CreatedAt { get; set; }
    }

}
