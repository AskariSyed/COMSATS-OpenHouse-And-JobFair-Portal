namespace JobFairPortal.DTOs
{
    public class AdminUpdateStudentProfileDto
    {
        public string? FullName { get; set; }
        public string? RegistrationNo { get; set; }
        public string? Department { get; set; }
        public decimal? CGPA { get; set; }
        public string? Phone { get; set; }
        public List<string>? Skills { get; set; }
    }
}
