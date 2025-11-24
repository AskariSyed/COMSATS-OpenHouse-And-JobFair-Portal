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

    public class AcceptInterviewRequestDto
    {
        [Required]
        public DateTime? ScheduledTime { get; set; }
    }
    public class SendCompanyInterviewRequestDto
    {
        [Required]
        public int StudentId { get; set; }
    }
}
