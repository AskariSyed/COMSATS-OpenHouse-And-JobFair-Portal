using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.Models
{
    public enum SurveyType
    {
        CDC,
        Department
    }
    public class Survey
    {
        [Key]
        public int SurveyId { get; set; }
        public SurveyType Type { get; set; }
        public int CompanyId { get; set; }
        public string? Responses { get; set; }  // JSON string of multiple-choice + descriptive answers
        public DateTime SubmittedAt { get; set; } = DateTime.UtcNow;

        public Company Company { get; set; } = null!;
    }

}
