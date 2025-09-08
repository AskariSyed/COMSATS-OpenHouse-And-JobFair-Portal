using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.Models
{
    public enum RequestStatus
    {
        Pending,
        Accepted,
        Rejected
    }

    public enum RequestedBy
    {
        Company,
        Student
    }

    public class InterviewRequest
    {
        [Key]
        public int RequestId { get; set; }
        [Required]
        public int CompanyId { get; set; }
        [Required]
        public int StudentId { get; set; }
        public RequestedBy RequestedBy { get; set; }
        public RequestStatus Status { get; set; } = RequestStatus.Pending;
        public string? ReasonForReject { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        public Company Company { get; set; } = null!;
        public Student Student { get; set; } = null!;
    }

}
