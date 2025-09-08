using JobFairPortal.Models;

namespace JobFairPortal.DTOs
{
    public class RoomCreateDto
    {
        public string RoomName { get; set; } = null!;
        public int Capacity { get; set; }
    }
    public class RoomUpdateDto
    {

        public string RoomName { get; set; } = null!;
        public int Capacity { get; set; }
    }
    public class RoomResponseDto
    {
        public int RoomId { get; set; }
        public string RoomName { get; set; } = null!;
        public int Capacity { get; set; }
        public RoomStatus Status { get; set; }
        public string? CompanyName { get; set; }
    }

}
