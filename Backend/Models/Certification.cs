using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace JobFairPortal.Models
{
    public class Certification
    {
        [Key]
        public int CertificationId { get; set; }

        [Required]
        [ForeignKey("Student")]
        public int StudentId { get; set; }

        [Required]
        [MaxLength(100)]
        public string Title { get; set; } = null!; 

        [MaxLength(100)]
        public string? Issuer { get; set; }  

        public DateTime? IssueDate { get; set; }

        [Url]
        public string? CredentialUrl { get; set; }

        public string? CredentialId { get; set; }

        public Student? Student { get; set; }
    }
}
