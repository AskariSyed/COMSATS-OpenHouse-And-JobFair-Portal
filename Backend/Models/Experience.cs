using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace JobFairPortal.Models
{
    public class Experience
    {
        [Key]
        public int ExperienceId { get; set; }

        [Required]
        [ForeignKey("Student")]
        public int StudentId { get; set; }

        [Required]
        [MaxLength(100)]
        public string CompanyName { get; set; } = null!;

        [Required]
        [MaxLength(100)]
        public string Role { get; set; } = null!;

        [MaxLength(500)]
        public string? Description { get; set; }

        [DataType(DataType.Date)]
        public DateTime StartDate { get; set; }

        [DataType(DataType.Date)]
        public DateTime? EndDate { get; set; }

        public bool IsCurrent { get; set; } = false;

        [MaxLength(100)]
        public string? Location { get; set; }

        public Student? Student { get; set; }
    }
}
