namespace JobFairPortal.DTOs
{
    public class AuditLogDto
    {
        public int AuditLogId { get; set; }
        public string Action { get; set; }
        public string ActorName { get; set; }
        public DateTime CreatedAt { get; set; }
    }

}
