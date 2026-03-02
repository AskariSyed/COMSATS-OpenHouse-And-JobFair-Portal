
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace JobFairPortal.Models
{
    public class Education
    {
        [Key]
        public int EducationId { get; set; }

        [Required]
        [ForeignKey("Student")]
        public int StudentId { get; set; }

        [Required]
        [MaxLength(150)]
        public string InstitutionName { get; set; } = null!;

        [Required]
        [MaxLength(100)]
        public string Degree { get; set; } = null!; 

        [MaxLength(100)]
        public string? FieldOfStudy { get; set; }  

        public DateTime? StartDate { get; set; }

        public DateTime? EndDate { get; set; }

        public bool IsCurrent { get; set; } = false;

        [Range(0, 4.0)]
        public double? CGPA { get; set; }

        [MaxLength(200)]
        public string? Location { get; set; }

        public Student Student { get; set; } = null!;
    }
}
