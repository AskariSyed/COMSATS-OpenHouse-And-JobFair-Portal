using JobFairPortal.Models;
namespace JobFairPortal.DTOs
{

    public class SurveyDto
    {
        public int SurveyId { get; set; }
        public SurveyType Type { get; set; }
        public int CompanyId { get; set; }
        public string CompanyName { get; set; } = null!;
    }
    // DTO
    public class SurveyResponseDto
    {
        public int SurveyId { get; set; }
        public string Type { get; set; } = null!;
        public object? Responses { get; set; }   // parsed JSON object (dictionary/array)
        public string? CompanyName { get; set; }
        public DateTime SubmittedAt { get; set; }
    }



}
