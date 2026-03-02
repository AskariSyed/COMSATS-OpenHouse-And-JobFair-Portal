using JobFairPortal.Data;
using JobFairPortal.Models;
using Microsoft.EntityFrameworkCore;

namespace JobFairPortal.Services
{
    public class ParticipationService : IParticipationService
    {
        private readonly JobFairRecruitmentDbContext _context;
        private readonly ILogger<ParticipationService> _logger;

        public ParticipationService(JobFairRecruitmentDbContext context, ILogger<ParticipationService> logger)
        {
            _context = context;
            _logger = logger;
        }

        #region Company Participation

        public async Task<bool> IsCompanyRegisteredForJobFairAsync(int companyId, int jobFairId)
        {
            return await _context.CompanyJobFairParticipations
                .AnyAsync(p => p.CompanyId == companyId && p.JobFairId == jobFairId);
        }

        public async Task<CompanyJobFairParticipation?> RegisterCompanyForJobFairAsync(int companyId, int jobFairId)
        {
            try
            {
                var existing = await GetCompanyParticipationAsync(companyId, jobFairId);
                if (existing != null)
                {
                    _logger.LogWarning("Company {CompanyId} already registered for JobFair {JobFairId}", 
                        companyId, jobFairId);
                    return existing;
                }

                var participation = new CompanyJobFairParticipation
                {
                    CompanyId = companyId,
                    JobFairId = jobFairId,
                    RegisteredAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _context.CompanyJobFairParticipations.Add(participation);
                await _context.SaveChangesAsync();

                _logger.LogInformation("Company {CompanyId} registered for JobFair {JobFairId}", 
                    companyId, jobFairId);

                return participation; // ? Always return the created participation
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error registering company {CompanyId} for JobFair {JobFairId}", 
                    companyId, jobFairId);
                throw; // ? Let the caller handle the exception
            }
        }

        public async Task<CompanyJobFairParticipation?> GetCompanyParticipationAsync(int companyId, int jobFairId)
        {
            return await _context.CompanyJobFairParticipations
                .Include(p => p.Company)
                .Include(p => p.JobFair)
                .Include(p => p.Room)
                .FirstOrDefaultAsync(p => p.CompanyId == companyId && p.JobFairId == jobFairId);
        }

        public async Task<IEnumerable<CompanyJobFairParticipation>> GetCompanyAllParticipationsAsync(int companyId)
        {
            return await _context.CompanyJobFairParticipations
                .Where(p => p.CompanyId == companyId)
                .Include(p => p.JobFair)
                .Include(p => p.Room)
                .OrderByDescending(p => p.RegisteredAt)
                .ToListAsync();
        }

        #endregion

        #region Student Participation

        public async Task<bool> IsStudentRegisteredForJobFairAsync(int studentId, int jobFairId)
        {
            return await _context.StudentJobFairParticipations
                .AnyAsync(p => p.StudentId == studentId && p.JobFairId == jobFairId);
        }

        public async Task<StudentJobFairParticipation?> RegisterStudentForJobFairAsync(int studentId, int jobFairId)
        {
            try
            {
                // Check if already registered
                var existing = await GetStudentParticipationAsync(studentId, jobFairId);
                if (existing != null)
                {
                    _logger.LogWarning("Student {StudentId} is already registered for JobFair {JobFairId}", 
                        studentId, jobFairId);
                    return existing;
                }

                // Create new participation record
                var participation = new StudentJobFairParticipation
                {
                    StudentId = studentId,
                    JobFairId = jobFairId,
                    RegisteredAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _context.StudentJobFairParticipations.Add(participation);
                await _context.SaveChangesAsync();

                _logger.LogInformation("Student {StudentId} registered for JobFair {JobFairId}", 
                    studentId, jobFairId);

                return participation;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error registering student {StudentId} for JobFair {JobFairId}", 
                    studentId, jobFairId);
                throw;
            }
        }

        public async Task<StudentJobFairParticipation?> GetStudentParticipationAsync(int studentId, int jobFairId)
        {
            return await _context.StudentJobFairParticipations
                .Include(p => p.Student)
                .Include(p => p.JobFair)
                .FirstOrDefaultAsync(p => p.StudentId == studentId && p.JobFairId == jobFairId);
        }

        public async Task<IEnumerable<StudentJobFairParticipation>> GetStudentAllParticipationsAsync(int studentId)
        {
            return await _context.StudentJobFairParticipations
                .Where(p => p.StudentId == studentId)
                .Include(p => p.JobFair)
                .OrderByDescending(p => p.RegisteredAt)
                .ToListAsync();
        }

        #endregion
    }
}