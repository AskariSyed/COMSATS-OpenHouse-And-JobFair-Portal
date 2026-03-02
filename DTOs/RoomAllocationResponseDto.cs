namespace JobFairPortal.DTOs
{
    /// <summary>
    /// Response DTO for room allocation result
    /// </summary>
    public class RoomAllocationResponseDto
    {
        public int CompanyId { get; set; }
        public string CompanyName { get; set; } = null!;
        public int JobFairId { get; set; }
        public bool IsConfirmed { get; set; }
        public int RepresentativeCount { get; set; }
        
        // Room Allocation Info
        public bool RoomAllocated { get; set; }
        public int? RoomId { get; set; }
        public string? RoomName { get; set; }
        public int? RoomCapacity { get; set; }
        public string AllocationStatus { get; set; } = null!; // "Tentatively Alloted", "Pending Physical Arrival"
        
        // Messages
        public string Message { get; set; } = null!;
        public DateTime ConfirmedAt { get; set; }
    }
}