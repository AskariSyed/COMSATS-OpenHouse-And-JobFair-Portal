using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace JobFairPortal.Models
{
    public enum CompanyRequestType
    {
        Supplies,       // e.g., pen, paper, tape
        Cleaning,       // janitorial / cleaning
        Info,           // information, maps, schedules
        Equipment,      // chairs, tables, extension cords
        Other
    }

    public enum CompanyRequestStatus
    {
        Pending,
        InProgress,
        Fulfilled,
        Rejected,
        Cancelled
    }

    public class CompanyRequest
    {
        [Key]
        public int CompanyRequestId { get; set; }

        [Required]
        public int CompanyId { get; set; }

        // Which job fair this request is for (helps admins filter by event)
        public int JobFairId { get; set; }

        [Required]
        public CompanyRequestType Type { get; set; }

        // Free-form description (what they need)
        [Required]
        [MaxLength(1000)]
        public string Description { get; set; } = null!;

        // Optional quantity (for supplies)
        public int? Quantity { get; set; }

        // Optional additional details (e.g., preferred time, location at fair)
        public string? AdditionalInfo { get; set; }

        public CompanyRequestStatus Status { get; set; } = CompanyRequestStatus.Pending;

        // Admin notes / fulfilment details
        public string? AdminNote { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? FulfilledAt { get; set; }

        // Navigation
        public Company Company { get; set; } = null!;
        public JobFair JobFair { get; set; } = null!;
    }
}