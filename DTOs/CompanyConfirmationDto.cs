using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.DTOs
{
    /// <summary>
    /// DTO for company confirming their participation
    /// JobFairId is NOT required - system will use the active job fair
    /// </summary>
    public class CompanyConfirmationDto
    {
        [Required]
        [Range(1, 100, ErrorMessage = "Representative count must be between 1 and 100")]
        public int RepresentativeCount { get; set; }

        public string? SpecialRequirements { get; set; }
    }
}