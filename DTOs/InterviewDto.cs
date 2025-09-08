namespace JobFairPortal.DTOs
{
    public class InterviewStatsDto
    {
        public int CompanyId { get; set; }
        public string CompanyName { get; set; }
        public int TotalInterviews { get; set; }
        public int HiredCount { get; set; }
        public int ShortlistedCount { get; set; }
    }

    public class InterviewSummaryDto
    {
        public int TotalInterviewsCompleted { get; set; }
        public List<CompanyInterviewSummaryDto> InterviewsPerCompany { get; set; } = new();
    }

    public class CompanyInterviewSummaryDto
    {
        public int CompanyId { get; set; }
        public string? CompanyName { get; set; }
        public int InterviewsCompleted { get; set; }
    }


}
