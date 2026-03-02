using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.DTOs
{
    public class UpdateCGPADto
    {
        [Required]
        [Range(0.0, 4.0, ErrorMessage = "CGPA must be between 0.0 and 4.0")]
        public decimal CGPA { get; set; }
    }
}
