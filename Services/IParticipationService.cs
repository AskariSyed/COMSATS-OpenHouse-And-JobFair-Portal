using JobFairPortal.Models;

namespace JobFairPortal.Services
{
    public interface IParticipationService
    {
        // Company participation methods
        Task<bool> IsCompanyRegisteredForJobFairAsync(int companyId, int jobFairId);
        Task<CompanyJobFairParticipation?> RegisterCompanyForJobFairAsync(int companyId, int jobFairId);
        Task<CompanyJobFairParticipation?> GetCompanyParticipationAsync(int companyId, int jobFairId);
        Task<IEnumerable<CompanyJobFairParticipation>> GetCompanyAllParticipationsAsync(int companyId);

        // Student participation methods
        Task<bool> IsStudentRegisteredForJobFairAsync(int studentId, int jobFairId);
        Task<StudentJobFairParticipation?> RegisterStudentForJobFairAsync(int studentId, int jobFairId);
        Task<StudentJobFairParticipation?> GetStudentParticipationAsync(int studentId, int jobFairId);
        Task<IEnumerable<StudentJobFairParticipation>> GetStudentAllParticipationsAsync(int studentId);
    }
}