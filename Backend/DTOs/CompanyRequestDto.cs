namespace JobFairPortal.DTOs
{
    public class CompanyRequestDto
    {
        public Models.CompanyRequestType Type { get; set; }
        public string Description { get; set; } = null!;
        public int? Quantity { get; set; }
        public string? AdditionalInfo { get; set; }
        // optional: client may include JobFairId but server will validate against active fair
        public int? JobFairId { get; set; }
    }
}