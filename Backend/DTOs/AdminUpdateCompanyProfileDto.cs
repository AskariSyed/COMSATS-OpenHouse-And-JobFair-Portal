namespace JobFairPortal.DTOs
{
    public class AdminUpdateCompanyProfileDto
    {
        public string? Name { get; set; }
        public string? Industry { get; set; }
        public string? Description { get; set; }
        public string? Website { get; set; }
        public string? Address { get; set; }
        public string? CompanyEmail { get; set; }
        public string? CompanyPhone { get; set; }
        public string? FocalPersonName { get; set; }
        public string? FocalPersonEmail { get; set; }
        public string? FocalPersonPhone { get; set; }
        public int? RepsCount { get; set; }
        public int? InterviewDurationMinutes { get; set; }
    }
}
