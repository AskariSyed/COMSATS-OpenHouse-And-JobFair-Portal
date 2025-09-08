namespace JobFairPortal.DTOs
{
    public class CompanyDto
    {
        public int CompanyId { get; set; }
        public string Name { get; set; }
        public string? Email { get; set; }
        public bool IsPresent { get; set; }
        public string? RoomName { get; set; }
    }
    public class CompanyCreateDto
    {
        public string Name { get; set; } = null!;
        public string Industry { get; set; } = null!;
    }

    public class CompanyResponseDto
    {
        public int CompanyId { get; set; }
        public string Name { get; set; } = null!;
        public string? Industry { get; set; }
        public string? UserEmail { get; set; }
        public string? RoomName { get; set; }
    }
    public class CompanyOverviewDto
    {
        public int CompanyId { get; set; }
        public string CompanyName { get; set; } = null!;
        public string? Field { get; set; }  // e.g. "AI", "Cloud", "Cybersecurity"
        public string InterviewingStatus { get; set; } = "NotStarted"; // Present/OnSpot
        public string? RoomAllotted { get; set; }

        public int TotalInterviews { get; set; }
        public int StudentsShortlisted { get; set; }
        public int StudentsHired { get; set; }
        public int StudentsRejected { get; set; }
        public int StudentsQueued { get; set; }
    }

    public class ChangeCompanyRoomDto
    {
        public int CompanyId { get; set; }
        public int RoomId { get; set; }
    }

}
