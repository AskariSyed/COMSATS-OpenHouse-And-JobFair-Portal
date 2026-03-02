using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.Models
{
    public enum CompanyContactPlatform
    {
        LinkedIn,
        Website,
        Twitter,
        Facebook,
        Instagram,
        Other
    }

    public class CompanyContactLink
    {
        [Key]
        public int LinkId { get; set; }

        [Required]
        public int CompanyId { get; set; }

        [Required]
        public CompanyContactPlatform Platform { get; set; }

        [Required]
        [Url]
        public string Url { get; set; } = null!;

        public Company Company { get; set; } = null!;
    }
}
