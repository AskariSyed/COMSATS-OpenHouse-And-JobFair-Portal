using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace JobFairPortal.Models
{
    public enum RoomStatus
    {
        Vacant,
        TentativelyAlloted,
        Alloted
    }
    public class Room
    {
        [Key]
        public int RoomId { get; set; }
        [Required]
        public string RoomName { get; set; } = null!;
        [Required]
        public int Capacity { get; set; }
        public RoomStatus Status { get; set; } = RoomStatus.Vacant;
        public int? CompanyId { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        [ForeignKey("CompanyId")]
        public Company? Company { get; set; }
    }

}
