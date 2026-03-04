namespace JobFairPortal.DTOs
{
    public class DashboardOverviewDto
    {
        public int TotalStudents { get; set; }
        public int TotalCompanies { get; set; }
        public int TotalRooms { get; set; }
        public int StudentsHired { get; set; }
        public int StudentsShortlisted { get; set; }
        public int CDCSurveysReceived { get; set; }
        public int DepartmentSurveysReceived { get; set; }
        public int? TopRequestedCandidateId { get; set; }
        public string? TopRequestedCandidateName { get; set; }
        public int TopRequestedCandidateRequestCount { get; set; }
        public int? TopHiredCandidateId { get; set; }
        public string? TopHiredCandidateName { get; set; }
        public int TopHiredCandidateHireCount { get; set; }
    }


}
