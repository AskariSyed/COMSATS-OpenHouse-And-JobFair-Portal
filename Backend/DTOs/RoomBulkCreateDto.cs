using JobFairPortal.Models;

namespace JobFairPortal.DTOs
{
    public class RoomBulkCreateDto
    {
        public string RoomName { get; set; } = null!;
        public int Capacity { get; set; }
        public RoomStatus Status { get; set; }
    }

}
