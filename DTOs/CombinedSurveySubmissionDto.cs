using JobFairPortal.Models;

namespace JobFairPortal.DTOs
{
    public class CombinedSurveySubmissionDto
    {
        public int? CompanyId { get; set; }
        public int? JobFairId { get; set; }

        // If present, will be saved as SurveyType.CDC
        public SurveyResponseData? CdcResponse { get; set; }

        // If present, will be saved as SurveyType.Department
        public SurveyResponseData? DepartmentResponse { get; set; }
    }

}
