using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.Models
{
    public enum ContactPlatform
    {
        LinkedIn,
        GitHub,
        Portfolio,
        Twitter,
        Facebook,
        Instagram,
        Other
    }
    public class ContactLink
    {
        [Key]
        public int LinkId { get; set; }

        [Required]
        public int StudentId { get; set; }

        [Required]
        public ContactPlatform Platform { get; set; } 

        [Required]
        [Url]
        public string Url { get; set; } = null!;

        public Student Student { get; set; } = null!;
    }
}
