using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.DTOs
{
    public class SendInterviewRequestDto
    {
        [Required]
        public int CompanyId { get; set; }
    }
        public class RejectInterviewRequestDto
        {
            [MaxLength(500)]
            public string? Reason { get; set; }
        }
    
}
