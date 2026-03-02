namespace JobFairPortal.DTOs
{
    public class JobFairCreateDto
    {
        public string Semester { get; set; } = null!;
        public DateTime date { get; set; }
        public bool IsActive { get; set; } = false;
    }
}