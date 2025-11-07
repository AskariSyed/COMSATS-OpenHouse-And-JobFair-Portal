using System;
using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.DTOs
{
    public class CertificationAddDto
    {
        [Required]
        [MaxLength(100)]
        public string Title { get; set; } = null!;

        [MaxLength(100)]
        public string? Issuer { get; set; }

        public DateTime? IssueDate { get; set; }

        [Url]
        public string? CredentialUrl { get; set; }

        public string? CredentialId { get; set; }
    }

    public class CertificationUpdateDto
    {
        [MaxLength(100)]
        public string? Title { get; set; }

        [MaxLength(100)]
        public string? Issuer { get; set; }

        public DateTime? IssueDate { get; set; }

        [Url]
        public string? CredentialUrl { get; set; }

        public string? CredentialId { get; set; }
    }
    public class CertificationDto
    {
        public int CertificationId { get; set; }
        public string Title { get; set; } = null!;
        public string? Issuer { get; set; }
        public DateTime? IssueDate { get; set; }
        public string? CredentialUrl { get; set; }
        public string? CredentialId { get; set; }
    }
}
