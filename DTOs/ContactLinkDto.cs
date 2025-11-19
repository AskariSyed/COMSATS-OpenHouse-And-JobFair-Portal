using JobFairPortal.Models;
using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.DTOs
{
    public class ContactLinkAddDto
    {
   
        [MaxLength(50)]
        [Required]
        public string Platform { get; set; } = null!;

        [Required]
        [Url]
        public string Url { get; set; } = null!;
    }
    public class ContactLinkUpdateDto
{
    public string? Platform { get; set; }
    public string? Url { get; set; }
}

}
