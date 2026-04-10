namespace JobFairPortal.DTOs
{
    public class DashboardTopCandidateDto
    {
        public int StudentId { get; set; }
        public string CandidateName { get; set; } = string.Empty;
        public int Count { get; set; }
    }

    public class DashboardOverviewDto
    {
        public int TotalStudents { get; set; }
        public int TotalCompanies { get; set; }
        public int TotalRooms { get; set; }
        public int StudentsHired { get; set; }
        public int StudentsShortlisted { get; set; }
        public int TotalInterviews { get; set; }
        public int InterviewsScheduled { get; set; }
        public int InterviewsQueued { get; set; }
        public int InterviewsDidNotAppear { get; set; }
        public int InterviewsRejected { get; set; }
        public int CDCSurveysReceived { get; set; }
        public int DepartmentSurveysReceived { get; set; }
        public int TotalInterviewRequests { get; set; }
        public int TotalAcceptedRequests { get; set; }
        public double RequestAcceptanceRatio { get; set; }
        public int? TopRequestedCandidateId { get; set; }
        public string? TopRequestedCandidateName { get; set; }
        public int TopRequestedCandidateRequestCount { get; set; }
        public int? TopHiredCandidateId { get; set; }
        public string? TopHiredCandidateName { get; set; }
        public int TopHiredCandidateHireCount { get; set; }
        public List<DashboardTopCandidateDto> TopRequestedCandidates { get; set; } = new();
        public List<DashboardTopCandidateDto> TopHiredCandidates { get; set; } = new();
    }


}
