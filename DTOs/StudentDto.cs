namespace JobFairPortal.DTOs
{
    public class CompleteProfileDto
    {
        public string? Name { get; set; }
        public string? CVUrl { get; set; }
        public string? FypDemoUrl { get; set; }
        public string? FypTitle { get; set; }
        public string? FypDescription { get; set; }
        public decimal? CGPA { get; set; }
        public string[]? Skills { get; set; }
    }
    public class SkillsDto
    {
        public string[] Skills { get; set; }
    }
}
