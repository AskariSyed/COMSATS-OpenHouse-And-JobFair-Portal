namespace JobFairPortal.DTOs
{
    public class ScheduleInterviewDto
    {
        public System.DateTime ScheduledTime { get; set; }
        public int? RequestId { get; set; } // optional: link to InterviewRequest if relevant
    }
}