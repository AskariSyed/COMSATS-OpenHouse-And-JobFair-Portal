using JobFairPortal.Models;
using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.DTOs
{
    public class ContactLinkAddDto
    {
        [Required]
        [MaxLength(50)]
        public ContactPlatform Platform { get; set; }

        [Required]
        [Url]
        public string Url { get; set; } = null!;
    }
    public class ContactLinkUpdateDto
    {
        [MaxLength(50)]
        public ContactPlatform? Platform { get; set; }

        [Url]
        public string? Url { get; set; }
    }
}
