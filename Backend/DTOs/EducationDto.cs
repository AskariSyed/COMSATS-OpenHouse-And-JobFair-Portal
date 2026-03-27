using System;
using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.DTOs
{
    public class EducationAddDto
    {
        [Required]
        [MaxLength(150)]
        public string InstitutionName { get; set; } = null!;

        [Required]
        [MaxLength(100)]
        public string Degree { get; set; } = null!;

        [MaxLength(100)]
        public string? FieldOfStudy { get; set; }

        // 🔹 FIX 1: Add [Required] and remove '?' to make it non-nullable
        [Required]
        public DateTime StartDate { get; set; }

        public DateTime? EndDate { get; set; } // EndDate can stay nullable (e.g., currently studying)

        public bool IsCurrent { get; set; } = false;

        [MaxLength(20)]
        public string? GradeType { get; set; }

        public double? GradeValue { get; set; }

        public double? MarksObtained { get; set; }

        public double? TotalMarks { get; set; }

        [Range(0, 4.0)]
        public double? CGPA { get; set; }

        [MaxLength(200)]
        public string? Location { get; set; }
    }

    public class EducationDto
    {
        public int EducationId { get; set; }
        public string InstitutionName { get; set; } = null!;
        public string Degree { get; set; } = null!;
        public string? FieldOfStudy { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public bool IsCurrent { get; set; }
        public string? GradeType { get; set; }
        public double? GradeValue { get; set; }
        public double? MarksObtained { get; set; }
        public double? TotalMarks { get; set; }
        public double? CGPA { get; set; }
        public string? Location { get; set; }
    }

    public class EducationUpdateDto
    {
        [MaxLength(150)]
        public string? InstitutionName { get; set; }

        [MaxLength(100)]
        public string? Degree { get; set; }

        [MaxLength(100)]
        public string? FieldOfStudy { get; set; }

        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }

        public bool? IsCurrent { get; set; }

        [MaxLength(20)]
        public string? GradeType { get; set; }

        public double? GradeValue { get; set; }

        public double? MarksObtained { get; set; }

        public double? TotalMarks { get; set; }

        [Range(0, 4.0)]
        public double? CGPA { get; set; }

        [MaxLength(200)]
        public string? Location { get; set; }
    }
}
