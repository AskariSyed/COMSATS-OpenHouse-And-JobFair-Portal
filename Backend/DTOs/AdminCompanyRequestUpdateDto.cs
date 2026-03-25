namespace JobFairPortal.DTOs
{
    public class AdminCompanyRequestUpdateDto
    {
        public string Status { get; set; } = null!; // String value like "Pending", "InProgress", etc.
        public string? AdminNote { get; set; }
    }
}