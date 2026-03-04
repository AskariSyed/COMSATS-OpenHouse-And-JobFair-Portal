using FirebaseAdmin.Messaging;
using JobFairPortal.Data;
using JobFairPortal.DTOs;
using JobFairPortal.Models;
using JobFairPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace JobFairPortal.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
     
    public class CompanyController : ControllerBase
    {
        private readonly JobFairRecruitmentDbContext _context;
        private readonly ILogger<CompanyController> _logger;
        private readonly MailKitMailService _mailService;
        private static readonly TimeZoneInfo JobFairTimeZone = ResolveJobFairTimeZone();
        private static readonly TimeSpan WorkingDayStartLocal = TimeSpan.FromHours(9);
        private static readonly TimeSpan WorkingDayEndLocal = TimeSpan.FromHours(16.5);

        public CompanyController(JobFairRecruitmentDbContext context, ILogger<CompanyController> logger, MailKitMailService mailService)
        {
            _context = context;
            _logger = logger;
            _mailService = mailService;
        }
        [HttpGet("finalyear-projects/with-students")]
        public async Task<IActionResult> GetFinalYearProjectsWithStudents()
        {
            var projects = await _context.Projects
                .Where(p => p.Type == ProjectType.FinalYear)
                .Include(p => p.StudentProjects)
                    .ThenInclude(sp => sp.Student)
                        .ThenInclude(s => s.User)
                .Include(p => p.StudentProjects)
                    .ThenInclude(sp => sp.Student)
                        .ThenInclude(s => s.Educations)
                .Include(p => p.StudentProjects)
                    .ThenInclude(sp => sp.Student)
                        .ThenInclude(s => s.Certifications)
                .Include(p => p.StudentProjects)
                    .ThenInclude(sp => sp.Student)
                        .ThenInclude(s => s.Achievements)
                .Include(p => p.StudentProjects)
                    .ThenInclude(sp => sp.Student)
                        .ThenInclude(s => s.ContactLinks)
                .Select(p => new
                {
                    ProjectId = p.ProjectId,
                    Title = p.Title,
                    Description = p.Description,
                    Skills = p.Skills,
                    DemoUrl = p.DemoUrl,
                    GitHubUrl = p.GitHubUrl,
                    StartDate = p.StartDate,
                    EndDate = p.EndDate,
                    Type = p.Type.ToString(),
                    ClientName = p.ClientName,
                    Supervisor = p.Supervisor,
                    TotalStudents = p.StudentProjects.Count(sp => sp.Status == ProjectInviteStatus.Accepted),

                    // --- All Students in Project ---
                    Students = p.StudentProjects
                        .Where(sp => sp.Status == ProjectInviteStatus.Accepted)
                        .Select(sp => new
                        {
                            // --- Basic Info ---
                            StudentId = sp.Student.StudentId,
                            Name = sp.Student.User.FullName,
                            Email = sp.Student.User.Email,
                            Phone = sp.Student.User.Phone,
                            RegistrationNo = sp.Student.RegistrationNo,
                            Department = sp.Student.Department,
                            CGPA = sp.Student.CGPA,
                            ProfilePicUrl = sp.Student.ProfilePicUrl,
                            Skills = sp.Student.Skills ?? new List<string>(),

                            // --- Project Role ---
                            Role = sp.role,
                            IsCreator = sp.IsCreator,
                            Status = sp.Status.ToString(),

                            // --- Education ---
                            Educations = sp.Student.Educations.Select(e => new
                            {
                                e.EducationId,
                                e.InstitutionName,
                                e.Degree,
                                e.FieldOfStudy,
                                e.StartDate,
                                e.EndDate,
                                e.IsCurrent,
                                e.CGPA,
                                e.Location
                            }).ToList(),

                            // --- Certifications ---
                            Certifications = sp.Student.Certifications.Select(c => new
                            {
                                c.CertificationId,
                                c.Title,
                                c.Issuer,
                                c.IssueDate,
                                c.CredentialUrl,
                                c.CredentialId
                            }).ToList(),

                            // --- Achievements ---
                            Achievements = sp.Student.Achievements.Select(a => new
                            {
                                a.AchievementId,
                                a.Title,
                                a.Description,
                                a.DateAchieved
                            }).ToList(),

                            // --- Contact Links ---
                            ContactLinks = sp.Student.ContactLinks.Select(cl => new
                            {
                                cl.LinkId,
                                Platform = cl.Platform.ToString(),
                                cl.Url
                            }).ToList()
                        }).ToList()
                })
                .ToListAsync();

            return Ok(new
            {
                TotalProjects = projects.Count,
                Projects = projects
            });
        }
                    
        [HttpGet("finalyear-projects/{projectId}/with-students")]
        public async Task<IActionResult> GetFinalYearProjectWithStudents(int projectId)
        {
            var project = await _context.Projects
                .Where(p => p.ProjectId == projectId && p.Type == ProjectType.FinalYear)
                .Include(p => p.StudentProjects)
                    .ThenInclude(sp => sp.Student)
                        .ThenInclude(s => s.User)
                .Include(p => p.StudentProjects)
                    .ThenInclude(sp => sp.Student)
                        .ThenInclude(s => s.Educations)
                .Include(p => p.StudentProjects)
                    .ThenInclude(sp => sp.Student)
                        .ThenInclude(s => s.Certifications)
                .Include(p => p.StudentProjects)
                    .ThenInclude(sp => sp.Student)
                        .ThenInclude(s => s.Achievements)
                .Include(p => p.StudentProjects)
                    .ThenInclude(sp => sp.Student)
                        .ThenInclude(s => s.Experiences)
                .Include(p => p.StudentProjects)
                    .ThenInclude(sp => sp.Student)
                        .ThenInclude(s => s.ContactLinks)
                .Select(p => new
                {
                    ProjectId = p.ProjectId,
                    Title = p.Title,
                    Description = p.Description,
                    Skills = p.Skills,
                    DemoUrl = p.DemoUrl,
                    GitHubUrl = p.GitHubUrl,
                    StartDate = p.StartDate,
                    EndDate = p.EndDate,
                    Type = p.Type.ToString(),
                    ClientName = p.ClientName,
                    Supervisor = p.Supervisor,
                    TotalStudents = p.StudentProjects.Count(sp => sp.Status == ProjectInviteStatus.Accepted),

                    // --- All Students in Project ---
                    Students = p.StudentProjects
                        .Where(sp => sp.Status == ProjectInviteStatus.Accepted)
                        .Select(sp => new
                        {
                            // --- Basic Info ---
                            StudentId = sp.Student.StudentId,
                            Name = sp.Student.User.FullName,
                            Email = sp.Student.User.Email,
                            Phone = sp.Student.User.Phone,
                            RegistrationNo = sp.Student.RegistrationNo,
                            Department = sp.Student.Department,
                            CGPA = sp.Student.CGPA,
                            ProfilePicUrl = sp.Student.ProfilePicUrl,
                            Skills = sp.Student.Skills ?? new List<string>(),

                            // --- Project Role ---
                            Role = sp.role,
                            IsCreator = sp.IsCreator,
                            Status = sp.Status.ToString(),

                            // --- Education ---
                            Educations = sp.Student.Educations.Select(e => new
                            {
                                e.EducationId,
                                e.InstitutionName,
                                e.Degree,
                                e.FieldOfStudy,
                                e.StartDate,
                                e.EndDate,
                                e.IsCurrent,
                                e.CGPA,
                                e.Location
                            }).ToList(),

                            // --- Certifications ---
                            Certifications = sp.Student.Certifications.Select(c => new
                            {
                                c.CertificationId,
                                c.Title,
                                c.Issuer,
                                c.IssueDate,
                                c.CredentialUrl,
                                c.CredentialId
                            }).ToList(),

                            // --- Achievements ---
                            Achievements = sp.Student.Achievements.Select(a => new
                            {
                                a.AchievementId,
                                a.Title,
                                a.Description,
                                a.DateAchieved
                            }).ToList(),

                            // --- Experiences ---
                            Experiences = sp.Student.Experiences.Select(ex => new
                            {
                                ex.ExperienceId,
                                ex.CompanyName,
                                ex.Role,
                                ex.Description,
                                ex.StartDate,
                                ex.EndDate,
                                ex.IsCurrent,
                                ex.Location
                            }).ToList(),

                            // --- Contact Links ---
                            ContactLinks = sp.Student.ContactLinks.Select(cl => new
                            {
                                cl.LinkId,
                                Platform = cl.Platform.ToString(),
                                cl.Url
                            }).ToList()
                        }).ToList()
                })
                .FirstOrDefaultAsync();

            if (project == null)
                return NotFound(new { Message = "Final Year Project not found." });

            return Ok(new { project });
        }

        [HttpGet("finalyear-projects")]
        public async Task<IActionResult> GetFinalYearProjects()
        {
            var projects = await _context.Projects
                .Where(p => p.Type == ProjectType.FinalYear)
                .Include(p => p.StudentProjects)
                    .ThenInclude(sp => sp.Student)
                        .ThenInclude(s => s.User)
                .Select(p => new
                {
                    ProjectId = p.ProjectId,
                    Title = p.Title,
                    Description = p.Description,
                    Skills = p.Skills,
                    DemoUrl = p.DemoUrl,
                    GitHubUrl = p.GitHubUrl,
                    StartDate = p.StartDate,
                    EndDate = p.EndDate,
                    Type = p.Type.ToString(),
                    ClientName = p.ClientName,
                    Supervisor = p.Supervisor,
                    TotalStudents = p.StudentProjects.Count(sp => sp.Status == ProjectInviteStatus.Accepted),

                    // Basic student list (without detailed info)
                    Students = p.StudentProjects
                        .Where(sp => sp.Status == ProjectInviteStatus.Accepted)
                        .Select(sp => new
                        {
                            StudentId = sp.Student.StudentId,
                            Name = sp.Student.User.FullName,
                            RegistrationNo = sp.Student.RegistrationNo,
                            CGPA = sp.Student.CGPA,
                            Role = sp.role,
                            IsCreator = sp.IsCreator
                        }).ToList()
                })
                .ToListAsync();

            return Ok(new
            {
                TotalProjects = projects.Count,
                Projects = projects
            });
        }
        [HttpGet("students")]
        public async Task<IActionResult> GetAllStudents()
        {
            var companyIdClaim = GetUserIdFromToken();
            if (companyIdClaim <= 0)
                return Unauthorized();

            var currentCompany = await _context.Companies
                .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);

            if (currentCompany == null)
                return NotFound("Company not found.");

            var activeJobFair = await _context.JobFairs
                .AsNoTracking()
                .FirstOrDefaultAsync(j => j.IsActive);

            if (activeJobFair == null)
                return BadRequest("No active job fair found.");

            var students = await _context.Students
                .Include(s => s.User)
                .Include(s => s.InterviewRequests)
                .Where(s => s.JobFairParticipations.Any(p => p.JobFairId == activeJobFair.JobFairId && p.HasRegistered))
                .Select(s => new
                {
                    StudentId = s.StudentId,
                    Name = s.User.FullName,
                    RegistrationNo = s.RegistrationNo,
                    Department = s.Department,
                    CGPA = (float)s.CGPA,
                    Skills = s.Skills,
                    ProfilePicUrl = s.ProfilePicUrl,
                    FypTitle = s.StudentProjects
                        .Where(sp => sp.Project.Type == ProjectType.FinalYear && sp.Status == ProjectInviteStatus.Accepted)
                        .Select(sp => sp.Project.Title)
                        .FirstOrDefault(),
                    CurrentInterviewStatus = _context.Interviews
                        .Where(i => i.CompanyId == currentCompany.CompanyId && i.StudentId == s.StudentId && i.JobFairId == activeJobFair.JobFairId)
                        .OrderByDescending(i => i.UpdatedAt)
                        .Select(i => i.Status.ToString())
                        .FirstOrDefault(),
                    
                    // --- Interview Request Status (if company is logged in) ---
                    InterviewRequest = new
                    {
                        HasRequest = s.InterviewRequests.Any(ir => ir.CompanyId == currentCompany.CompanyId && ir.JobFairId == activeJobFair.JobFairId),
                        Status = s.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId && ir.JobFairId == activeJobFair.JobFairId)
                            .Select(ir => ir.Status.ToString())
                            .FirstOrDefault(),
                        RequestId = s.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId && ir.JobFairId == activeJobFair.JobFairId)
                            .Select(ir => (int?)ir.RequestId)
                            .FirstOrDefault(),
                        RequestDate = s.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId && ir.JobFairId == activeJobFair.JobFairId)
                            .Select(ir => ir.CreatedAt)
                            .FirstOrDefault(),
                        ResponseDate = s.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId && ir.JobFairId == activeJobFair.JobFairId)
                            .Select(ir => ir.UpdatedAt)
                            .FirstOrDefault(),
                        RequestedBy = s.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId && ir.JobFairId == activeJobFair.JobFairId)
                            .Select(ir => ir.RequestedBy)
                            .FirstOrDefault()
                    }
                })
                .ToListAsync();

            return Ok(students);
        }
        [HttpGet("students/search-by-skill")]
        public async Task<IActionResult> SearchStudentsBySkill([FromQuery] string skill)
        {
            if (string.IsNullOrWhiteSpace(skill))
                return BadRequest("Skill parameter is required.");

            var companyIdClaim = GetUserIdFromToken();
            if (companyIdClaim <= 0)
                return Unauthorized();

            var currentCompany = await _context.Companies
                .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);

            if (currentCompany == null)
                return NotFound("Company not found.");

            var activeJobFair = await _context.JobFairs
                .AsNoTracking()
                .FirstOrDefaultAsync(j => j.IsActive);

            if (activeJobFair == null)
                return BadRequest("No active job fair found.");

            var students = await _context.Students
                .Include(s => s.User)
                .Include(s => s.InterviewRequests)
                .Where(s => s.Skills != null && s.Skills.Any(sk => sk.ToLower().Contains(skill.ToLower())))
                .Where(s => s.JobFairParticipations.Any(p => p.JobFairId == activeJobFair.JobFairId && p.HasRegistered))
                .Select(s => new
                {
                    StudentId = s.StudentId,
                    Name = s.User.FullName,
                    RegistrationNo = s.RegistrationNo,
                    Department = s.Department,
                    CGPA = (float)s.CGPA,
                    Skills = s.Skills,
                    ProfilePicUrl = s.ProfilePicUrl,
                    FypTitle = s.StudentProjects
                        .Where(sp => sp.Project.Type == ProjectType.FinalYear && sp.Status == ProjectInviteStatus.Accepted)
                        .Select(sp => sp.Project.Title)
                        .FirstOrDefault(),
                    CurrentInterviewStatus = _context.Interviews
                        .Where(i => i.CompanyId == currentCompany.CompanyId && i.StudentId == s.StudentId && i.JobFairId == activeJobFair.JobFairId)
                        .OrderByDescending(i => i.UpdatedAt)
                        .Select(i => i.Status.ToString())
                        .FirstOrDefault(),
                    
                    // --- Interview Request Status ---
                    InterviewRequest = new
                    {
                        HasRequest = s.InterviewRequests.Any(ir => ir.CompanyId == currentCompany.CompanyId && ir.JobFairId == activeJobFair.JobFairId),
                        Status = s.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId && ir.JobFairId == activeJobFair.JobFairId)
                            .Select(ir => ir.Status.ToString())
                            .FirstOrDefault(),
                        RequestId = s.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId && ir.JobFairId == activeJobFair.JobFairId)
                            .Select(ir => (int?)ir.RequestId)
                            .FirstOrDefault(),
                        RequestDate = s.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId && ir.JobFairId == activeJobFair.JobFairId)
                            .Select(ir => ir.CreatedAt)
                            .FirstOrDefault()
                    }
                })
                .ToListAsync();

            return Ok(students);
        }
        [HttpGet("students/search-by-registration")]
        public async Task<IActionResult> SearchStudentsByRegistration([FromQuery] string registrationNo)
        {
            if (string.IsNullOrWhiteSpace(registrationNo))
                return BadRequest("Registration number parameter is required.");

            var companyIdClaim = GetUserIdFromToken();
            if (companyIdClaim <= 0)
                return Unauthorized();

            var currentCompany = await _context.Companies
                .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);

            if (currentCompany == null)
                return NotFound("Company not found.");

            var activeJobFair = await _context.JobFairs
                .AsNoTracking()
                .FirstOrDefaultAsync(j => j.IsActive);

            if (activeJobFair == null)
                return BadRequest("No active job fair found.");

            var students = await _context.Students
                .Include(s => s.User)
                .Include(s => s.InterviewRequests)
                .Where(s => s.RegistrationNo.ToLower().Contains(registrationNo.ToLower()))
                .Where(s => s.JobFairParticipations.Any(p => p.JobFairId == activeJobFair.JobFairId && p.HasRegistered))
                .Select(s => new
                {
                    StudentId = s.StudentId,
                    Name = s.User.FullName,
                    RegistrationNo = s.RegistrationNo,
                    Department = s.Department,
                    CGPA = (float)s.CGPA,
                    Skills = s.Skills,
                    ProfilePicUrl = s.ProfilePicUrl,
                    FypTitle = s.StudentProjects
                        .Where(sp => sp.Project.Type == ProjectType.FinalYear && sp.Status == ProjectInviteStatus.Accepted)
                        .Select(sp => sp.Project.Title)
                        .FirstOrDefault(),
                    CurrentInterviewStatus = _context.Interviews
                        .Where(i => i.CompanyId == currentCompany.CompanyId && i.StudentId == s.StudentId && i.JobFairId == activeJobFair.JobFairId)
                        .OrderByDescending(i => i.UpdatedAt)
                        .Select(i => i.Status.ToString())
                        .FirstOrDefault(),
                    
                    // --- Interview Request Status ---
                    InterviewRequest = new
                    {
                        HasRequest = s.InterviewRequests.Any(ir => ir.CompanyId == currentCompany.CompanyId && ir.JobFairId == activeJobFair.JobFairId),
                        Status = s.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId && ir.JobFairId == activeJobFair.JobFairId)
                            .Select(ir => ir.Status.ToString())
                            .FirstOrDefault(),
                        RequestId = s.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId && ir.JobFairId == activeJobFair.JobFairId)
                            .Select(ir => (int?)ir.RequestId)
                            .FirstOrDefault(),
                        RequestDate = s.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId && ir.JobFairId == activeJobFair.JobFairId)
                            .Select(ir => ir.CreatedAt)
                            .FirstOrDefault()
                    }
                })
                .ToListAsync();

            return Ok(students);
        }
        [HttpGet("students/search-by-department")]
        public async Task<IActionResult> SearchStudentsByDepartment([FromQuery] string department)
        {
            if (string.IsNullOrWhiteSpace(department))
                return BadRequest("Department parameter is required.");

            var companyIdClaim = GetUserIdFromToken();
            if (companyIdClaim <= 0)
                return Unauthorized();

            var currentCompany = await _context.Companies
                .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);

            if (currentCompany == null)
                return NotFound("Company not found.");

            var activeJobFair = await _context.JobFairs
                .AsNoTracking()
                .FirstOrDefaultAsync(j => j.IsActive);

            if (activeJobFair == null)
                return BadRequest("No active job fair found.");

            var students = await _context.Students
                .Include(s => s.User)
                .Include(s => s.InterviewRequests)
                .Where(s => s.Department.ToLower().Contains(department.ToLower()))
                .Where(s => s.JobFairParticipations.Any(p => p.JobFairId == activeJobFair.JobFairId && p.HasRegistered))
                .Select(s => new
                {
                    StudentId = s.StudentId,
                    Name = s.User.FullName,
                    RegistrationNo = s.RegistrationNo,
                    Department = s.Department,
                    CGPA = (float)s.CGPA,
                    Skills = s.Skills,
                    ProfilePicUrl = s.ProfilePicUrl,
                    FypTitle = s.StudentProjects
                        .Where(sp => sp.Project.Type == ProjectType.FinalYear && sp.Status == ProjectInviteStatus.Accepted)
                        .Select(sp => sp.Project.Title)
                        .FirstOrDefault(),
                    CurrentInterviewStatus = _context.Interviews
                        .Where(i => i.CompanyId == currentCompany.CompanyId && i.StudentId == s.StudentId && i.JobFairId == activeJobFair.JobFairId)
                        .OrderByDescending(i => i.UpdatedAt)
                        .Select(i => i.Status.ToString())
                        .FirstOrDefault(),
                    
                    // --- Interview Request Status ---
                    InterviewRequest = new
                    {
                        HasRequest = s.InterviewRequests.Any(ir => ir.CompanyId == currentCompany.CompanyId && ir.JobFairId == activeJobFair.JobFairId),
                        Status = s.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId && ir.JobFairId == activeJobFair.JobFairId)
                            .Select(ir => ir.Status.ToString())
                            .FirstOrDefault(),
                        RequestId = s.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId && ir.JobFairId == activeJobFair.JobFairId)
                            .Select(ir => (int?)ir.RequestId)
                            .FirstOrDefault(),
                        RequestDate = s.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId && ir.JobFairId == activeJobFair.JobFairId)
                            .Select(ir => ir.CreatedAt)
                            .FirstOrDefault()
                    }
                })
                .ToListAsync();

            return Ok(students);
        }

        [Authorize(Roles = "Company")]
        [HttpGet("students/by-interview-status")]
        public async Task<IActionResult> GetStudentsByInterviewStatus([FromQuery] string status)
        {
            if (string.IsNullOrWhiteSpace(status))
                return BadRequest("Status parameter is required.");

            var companyIdClaim = GetUserIdFromToken();
            if (companyIdClaim <= 0)
                return Unauthorized();

            if (!Enum.TryParse<InterviewStatus>(status, true, out var targetStatus) ||
                (targetStatus != InterviewStatus.Hired && targetStatus != InterviewStatus.Shortlisted && targetStatus != InterviewStatus.Rejected))
            {
                return BadRequest("Status must be one of: Hired, Shortlisted, Rejected");
            }

            var currentCompany = await _context.Companies
                .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);

            if (currentCompany == null)
                return NotFound("Company not found.");

            var activeJobFair = await _context.JobFairs
                .AsNoTracking()
                .FirstOrDefaultAsync(j => j.IsActive);

            if (activeJobFair == null)
                return BadRequest("No active job fair found.");

            var studentIds = await _context.Interviews
                .Where(i => i.CompanyId == currentCompany.CompanyId && i.JobFairId == activeJobFair.JobFairId && i.Status == targetStatus)
                .Select(i => i.StudentId)
                .Distinct()
                .ToListAsync();

            var students = await _context.Students
                .Include(s => s.User)
                .Include(s => s.InterviewRequests)
                .Where(s => studentIds.Contains(s.StudentId))
                .Where(s => s.JobFairParticipations.Any(p => p.JobFairId == activeJobFair.JobFairId && p.HasRegistered))
                .Select(s => new
                {
                    StudentId = s.StudentId,
                    Name = s.User.FullName,
                    RegistrationNo = s.RegistrationNo,
                    Department = s.Department,
                    CGPA = (float)s.CGPA,
                    Skills = s.Skills,
                    ProfilePicUrl = s.ProfilePicUrl,
                    FypTitle = s.StudentProjects
                        .Where(sp => sp.Project.Type == ProjectType.FinalYear && sp.Status == ProjectInviteStatus.Accepted)
                        .Select(sp => sp.Project.Title)
                        .FirstOrDefault(),
                    InterviewOutcome = targetStatus.ToString(),
                    InterviewRequest = new
                    {
                        HasRequest = s.InterviewRequests.Any(ir => ir.CompanyId == currentCompany.CompanyId && ir.JobFairId == activeJobFair.JobFairId),
                        Status = s.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId && ir.JobFairId == activeJobFair.JobFairId)
                            .Select(ir => ir.Status.ToString())
                            .FirstOrDefault(),
                        RequestId = s.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId && ir.JobFairId == activeJobFair.JobFairId)
                            .Select(ir => (int?)ir.RequestId)
                            .FirstOrDefault(),
                        RequestDate = s.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId && ir.JobFairId == activeJobFair.JobFairId)
                            .Select(ir => ir.CreatedAt)
                            .FirstOrDefault()
                    }
                })
                .ToListAsync();

            return Ok(students);
        }
        [HttpGet("interview-requests/by-company")]
        public async Task<IActionResult> GetCompanyInterviewRequests([FromQuery] int companyId)
        {
            if (companyId <= 0)
                return BadRequest("Valid companyId parameter is required.");

            var requests = await _context.InterviewRequests
                .Where(r => r.CompanyId == companyId)
                .Select(r => new
                {
                    r.RequestId,
                    r.Status,
                    r.CompanyId
                    // Add more fields if needed
                })
                .ToListAsync();

            return Ok(requests);
        }
        //[Authorize(Roles = "Company")]
        [HttpGet("students/{studentId}/profile")]
        public async Task<IActionResult> GetStudentProfile(int studentId)
        {
            var companyIdClaim = GetUserIdFromToken();
            Company? currentCompany = null;
            if (companyIdClaim > 0)
            {
                currentCompany = await _context.Companies
                    .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);
            }

            var activeJobFair = await _context.JobFairs
                .AsNoTracking()
                .FirstOrDefaultAsync(j => j.IsActive);

            var targetJobFairId = currentCompany?.CurrentJobFairId ?? activeJobFair?.JobFairId;

            var student = await _context.Students
                .Include(s => s.User)
                .Include(s => s.Educations)
                .Include(s => s.Certifications)
                .Include(s => s.Achievements)
                .Include(s => s.Experiences)
                .Include(s => s.StudentProjects)
                    .ThenInclude(sp => sp.Project)
                .Include(s => s.ContactLinks)
                .Include(s => s.InterviewRequests)
                .FirstOrDefaultAsync(s => s.StudentId == studentId);

            if (student == null)
                return NotFound("Student not found.");

            var currentInterview = currentCompany != null
                ? await _context.Interviews
                    .Where(i => i.StudentId == studentId &&
                                i.CompanyId == currentCompany.CompanyId &&
                                (!targetJobFairId.HasValue || i.JobFairId == targetJobFairId.Value))
                    .OrderByDescending(i => i.CreatedAt)
                    .Select(i => new
                    {
                        i.InterviewId,
                        Status = i.Status.ToString(),
                        i.ScheduledTime,
                        i.StartedAt,
                        i.EndedAt,
                        i.DurationMinutes,
                        i.UpdatedAt
                    })
                    .FirstOrDefaultAsync()
                : null;

            // Build comprehensive student profile
            var response = new
            {
                // --- Main Student Info ---
                student.StudentId,
                student.RegistrationNo,
                student.Department,
                student.ProfilePicUrl,
                student.CvUrl,
                student.Skills,
                student.CGPA,
                student.CreatedAt,
                student.UpdatedAt,

                // --- User Info ---
                User = new
                {
                    student.User.FullName,
                    student.User.Email,
                    student.User.Phone,
                },

                // --- Interview Request Status from Current Company ---
                InterviewRequest = currentCompany != null
                    ? new
                    {
                        HasRequest = student.InterviewRequests.Any(ir =>
                            ir.CompanyId == currentCompany.CompanyId &&
                            (!targetJobFairId.HasValue || ir.JobFairId == targetJobFairId.Value)),
                        Status = student.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId &&
                                         (!targetJobFairId.HasValue || ir.JobFairId == targetJobFairId.Value))
                            .Select(ir => ir.Status.ToString())
                            .FirstOrDefault(),
                        RequestId = student.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId &&
                                         (!targetJobFairId.HasValue || ir.JobFairId == targetJobFairId.Value))
                            .Select(ir => (int?)ir.RequestId)
                            .FirstOrDefault(),
                        RejectionReason = student.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId &&
                                         (!targetJobFairId.HasValue || ir.JobFairId == targetJobFairId.Value))
                            .Select(ir => ir.ReasonForReject)
                            .FirstOrDefault(),
                        RequestDate = student.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId &&
                                         (!targetJobFairId.HasValue || ir.JobFairId == targetJobFairId.Value))
                            .Select(ir => ir.CreatedAt)
                            .FirstOrDefault(),
                        ResponseDate = student.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId &&
                                         (!targetJobFairId.HasValue || ir.JobFairId == targetJobFairId.Value))
                            .Select(ir => ir.UpdatedAt)
                            .FirstOrDefault(),
                        RequestedBy = student.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId &&
                                         (!targetJobFairId.HasValue || ir.JobFairId == targetJobFairId.Value))
                            .Select(ir => ir.RequestedBy)
                            .FirstOrDefault()
                    }
                    : null,

                CurrentInterview = currentInterview,

                // --- Educations ---
                Educations = student.Educations.Select(e => new
                {
                    e.EducationId,
                    e.InstitutionName,
                    e.Degree,
                    e.FieldOfStudy,
                    e.StartDate,
                    e.EndDate,
                    e.IsCurrent,
                    e.CGPA,
                    e.Location
                }).ToList(),

                // --- Certifications ---
                Certifications = student.Certifications.Select(c => new
                {
                    c.Title,
                    c.Issuer,
                    c.IssueDate,
                    c.CredentialUrl,
                    c.CredentialId
                }).ToList(),

                // --- Achievements ---
                Achievements = student.Achievements.Select(a => new
                {
                    a.Title,
                    a.Description,
                    a.DateAchieved
                }).ToList(),

                // --- Experiences ---
                Experiences = student.Experiences.Select(e => new
                {
                    e.CompanyName,
                    e.Role,
                    e.Description,
                    e.StartDate,
                    e.EndDate,
                    e.IsCurrent,
                    e.Location
                }).ToList(),

                // --- Contact Links ---
                ContactLinks = student.ContactLinks.Select(cl => new
                {
                    Platform = cl.Platform.ToString(),
                    cl.Url
                }).ToList(),

                // --- Projects ---
                Projects = student.StudentProjects
                    .Where(sp => sp.Project != null)
                    .Select(sp => new
                    {
                        sp.Project.ProjectId,
                        sp.Project.Title,
                        sp.Project.Description,
                        sp.Project.DemoUrl,
                        sp.Project.GitHubUrl,
                        sp.Project.Skills,
                        Type = sp.Project.Type.ToString(),
                        sp.Project.StartDate,
                        sp.Project.EndDate,
                        Role = sp.role,
                        Status = sp.Status.ToString()
                    }).ToList()
            };

            return Ok(new { student = response });
        }
        [Authorize(Roles = "Company")]
        [HttpGet("analytics")]
        public async Task<IActionResult> GetCompanyAnalytics()
        {
            // Load company including navigations we will access to avoid null reference
            var company = await _context.Companies
                .Include(c => c.Interviews)
                .Include(c => c.InterviewRequests)
                .Include(c => c.CurrentJobFair) // ensure CurrentJobFair is loaded
                .FirstOrDefaultAsync(c => c.UserId == GetUserIdFromToken());

            if (company == null)
                return NotFound("Company not found.");

            // Get FYP projects with student details
            var fypProjects = await _context.Projects
                .Where(p => p.Type == ProjectType.FinalYear)
                .Include(p => p.StudentProjects)
                    .ThenInclude(sp => sp.Student)
                        .ThenInclude(s => s.User)
                .Select(p => new
                {
                    p.ProjectId,
                    p.Title,
                    p.Description,
                    p.Skills,
                    p.DemoUrl,
                    StudentCount = p.StudentProjects.Count,
                    Students = p.StudentProjects.Select(sp => new
                    {
                        sp.Student.StudentId,
                        sp.Student.User.FullName,
                        sp.Student.RegistrationNo,
                        sp.Student.Department,
                        sp.Student.CGPA
                    }).ToList()
                })
                .ToListAsync();

            // Get shortlisted interviews for this company
            var shortlistedInterviews = await _context.Interviews
                .Where(i => i.CompanyId == company.CompanyId && i.Status == InterviewStatus.Shortlisted)
                .Include(i => i.Student)
                    .ThenInclude(s => s.User)
                .Select(i => new
                {
                    i.InterviewId,
                    StudentName = i.Student.User.FullName,
                    StudentId = i.Student.StudentId,
                    i.Student.RegistrationNo,
                    i.ScheduledTime,
                    i.Status
                })
                .ToListAsync();

            // Get scheduled interviews for this company
            var scheduledInterviews = await _context.Interviews
                .Where(i => i.CompanyId == company.CompanyId &&
                            i.ScheduledTime.HasValue &&
                            (i.Status == InterviewStatus.Queued || i.Status == InterviewStatus.InProgress))
                .Include(i => i.Student)
                    .ThenInclude(s => s.User)
                .Select(i => new
                {
                    i.InterviewId,
                    StudentName = i.Student.User.FullName,
                    StudentId = i.Student.StudentId,
                    i.Student.RegistrationNo,
                    i.ScheduledTime,
                    i.StartedAt,
                    i.EndedAt,
                    Status = i.Status.ToString(),
                    TimeUntilInterview = i.ScheduledTime.HasValue ? (i.ScheduledTime.Value - DateTime.UtcNow).TotalHours : 0
                })
                .ToListAsync();

            // Get total students called (invited for interviews)
            var totalStudentsCalled = await _context.Interviews
                .Where(i => i.CompanyId == company.CompanyId)
                .Select(i => i.StudentId)
                .Distinct()
                .CountAsync();

            // Calculate hiring rate
            var totalHired = await _context.Interviews
                .Where(i => i.CompanyId == company.CompanyId && i.Status == InterviewStatus.Hired)
                .CountAsync();

            var hiringRate = totalStudentsCalled > 0 ? ((double)totalHired / totalStudentsCalled) * 100 : 0;

            // Build response - use null-safe access to CurrentJobFair
            var analytics = new
            {
                CompanyId = company.CompanyId,
                CompanyName = company.Name,
                JobFairDate = company.CurrentJobFair?.date, // safe: CurrentJobFair may be null

                // FYP Projects
                FYPProjects = new
                {
                    TotalProjects = fypProjects.Count,
                    Projects = fypProjects,
                    TotalStudentsInProjects = fypProjects.Sum(p => p.StudentCount),
                    UniqueStudents = fypProjects.SelectMany(p => p.Students).Select(s => s.StudentId).Distinct().Count()
                },

                // Interviews
                Interviews = new
                {
                    ShortlistedCount = shortlistedInterviews.Count,
                    ShortlistedStudents = shortlistedInterviews,
                    ScheduledCount = scheduledInterviews.Count,
                    ScheduledInterviews = scheduledInterviews,
                    TotalStudentsCalled = totalStudentsCalled,
                    HiredCount = totalHired,
                    HiringRate = Math.Round(hiringRate, 2) + "%",
                    RejectedCount = await _context.Interviews
                        .Where(i => i.CompanyId == company.CompanyId && i.Status == InterviewStatus.Rejected)
                        .CountAsync()
                },

                // Summary Statistics
                Summary = new
                {
                    TotalFYPProjects = fypProjects.Count,
                    TotalShortlisted = shortlistedInterviews.Count,
                    TotalScheduledInterviews = scheduledInterviews.Count,
                    TotalStudentsCalled = totalStudentsCalled,
                    TotalHired = totalHired,
                    HiringRate = Math.Round(hiringRate, 2),
                    ConversionRate = totalStudentsCalled > 0 ? Math.Round(((double)shortlistedInterviews.Count / totalStudentsCalled) * 100, 2) : 0
                }
            };

            return Ok(analytics);
        }




        [HttpGet("notices")]
        [Authorize] 
        public async Task<IActionResult> GetNotices()
        {
            // 1. Get Active Job Fair
            var activeJobFair = await _context.JobFairs.FirstOrDefaultAsync(j => j.IsActive);
            if (activeJobFair == null)
                return Ok(new List<NoticeResponseDto>()); // Return empty if no event

            // 2. Determine User Role
            var isStudent = User.IsInRole("Student");
            var isCompany = User.IsInRole("Company");
            var isAdmin = User.IsInRole("Admin");

            // 3. Build Query
            var query = _context.Notices
                .Where(n => n.JobFairId == activeJobFair.JobFairId)
                .AsQueryable();

            // 4. Filter based on Audience
            if (isAdmin)
            {
                // Admins see everything
            }
            else if (isStudent)
            {
                // Students see "Student" AND "All"
                query = query.Where(n => n.Audience == NoticeAudience.Student || n.Audience == NoticeAudience.All);
            }
            else if (isCompany)
            {
                // Companies see "Company" AND "All"
                query = query.Where(n => n.Audience == NoticeAudience.Company || n.Audience == NoticeAudience.All);
            }
            else
            {
                // Fallback for unknown roles
                return Forbid();
            }

            // 5. Execute and Return
            var notices = await query
                .OrderByDescending(n => n.CreatedAt)
                .Select(n => new NoticeResponseDto
                {
                    NoticeId = n.NoticeId,
                    Title = n.Title,
                    Content = n.Content,
                    Audience = n.Audience.ToString(),
                    CreatedAt = n.CreatedAt
                })
                .ToListAsync();

            return Ok(notices);
        }


        [HttpGet("students/{studentId}/details")]
        public async Task<IActionResult> GetStudentDetail(int studentId)
        {
            _logger.LogInformation("GetStudentDetail called for studentId: {StudentId}", studentId);

            var companyIdClaim = GetUserIdFromToken();
            Company? currentCompany = null;
            if (companyIdClaim > 0)
            {
                currentCompany = await _context.Companies
                    .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);
            }

            var student = await _context.Students
                .Include(s => s.User)
                .Include(s => s.ContactLinks)
                .Include(s => s.StudentProjects)
                    .ThenInclude(sp => sp.Project)
                        .ThenInclude(p => p.StudentProjects)
                            .ThenInclude(sp => sp.Student)
                                .ThenInclude(st => st.User)
                .Include(s => s.Achievements)
                .Include(s => s.Certifications)
                .Include(s => s.Educations)
                .Include(s => s.Experiences)
                .Include(s => s.InterviewRequests)
                .FirstOrDefaultAsync(s => s.StudentId == studentId);

            if (student == null || student.User == null)
                return NotFound(new { Message = "Student not found." });

            var fyp = student.StudentProjects
                .FirstOrDefault(sp => sp.Project?.Type == ProjectType.FinalYear)?
                .Project;

            var detail = new
            {
                // --- Basic Info ---
                StudentId = student.StudentId,
                Name = student.User.FullName,
                RegistrationNo = student.RegistrationNo,
                Department = student.Department,
                CGPA = student.CGPA,
                ProfilePicUrl = student.ProfilePicUrl,
                Skills = student.Skills ?? new List<string>(),

                // --- Contact Details ---
                ContactDetails = new
                {
                    Email = student.User.Email,
                    Phone = student.User.Phone
                },

                // --- Social Links ---
                Links = student.ContactLinks != null
                    ? student.ContactLinks.ToDictionary(
                        cl => cl.Platform.ToString(),
                        cl => cl.Url)
                    : new Dictionary<string, string>(),

                // --- Interview Request Status from Current Company ---
                InterviewRequest = currentCompany != null
                    ? new
                    {
                        HasRequest = student.InterviewRequests.Any(ir => ir.CompanyId == currentCompany.CompanyId),
                        Status = student.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId)
                            .Select(ir => ir.Status.ToString())
                            .FirstOrDefault(),
                        RequestId = student.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId)
                            .Select(ir => (int?)ir.RequestId)
                            .FirstOrDefault(),
                        RejectionReason = student.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId)
                            .Select(ir => ir.ReasonForReject)
                            .FirstOrDefault(),
                        RequestDate = student.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId)
                            .Select(ir => ir.CreatedAt)
                            .FirstOrDefault(),
                        ResponseDate = student.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId)
                            .Select(ir => ir.UpdatedAt)
                            .FirstOrDefault(),
                        RequestedBy=student.InterviewRequests
                            .Where(ir => ir.CompanyId == currentCompany.CompanyId)
                            .Select(ir => ir.RequestedBy)
                            .FirstOrDefault()
                    }
                    : null,

                // --- FYP Details ---
                FinalYearProject = fyp != null ? new
                {
                    ProjectId = fyp.ProjectId,
                    Title = fyp.Title,
                    Description = fyp.Description,
                    DemoUrl = fyp.DemoUrl,
                    GitHubUrl = fyp.GitHubUrl,
                    Skills = fyp.Skills,
                    StartDate = fyp.StartDate,
                    EndDate = fyp.EndDate,
                    ClientName = fyp.ClientName,
                    Supervisor = fyp.Supervisor,
                    Partners = fyp.StudentProjects
                        .Where(sp => sp.StudentId != student.StudentId && sp.Status == ProjectInviteStatus.Accepted)
                        .Select(sp => new
                        {
                            sp.Student.StudentId,
                            sp.Student.RegistrationNo,
                            Name = sp.Student.User.FullName,
                            Role = sp.role
                        }).ToList()
                } : null,

                // --- All Projects ---
                AllProjects = student.StudentProjects
                    .Where(sp => sp.Project != null && sp.Status == ProjectInviteStatus.Accepted)
                    .Select(sp => new
                    {
                        sp.Project.ProjectId,
                        sp.Project.Title,
                        sp.Project.Description,
                        sp.Project.DemoUrl,
                        sp.Project.GitHubUrl,
                        sp.Project.Skills,
                        Type = sp.Project.Type.ToString(),
                        sp.Project.StartDate,
                        sp.Project.EndDate,
                        Role = sp.role,
                        IsCreator = sp.IsCreator
                    }).ToList(),

                // --- Education ---
                Educations = student.Educations.Select(e => new
                {
                    e.EducationId,
                    e.InstitutionName,
                    e.Degree,
                    e.FieldOfStudy,
                    e.StartDate,
                    e.EndDate,
                    e.IsCurrent,
                    e.CGPA,
                    e.Location
                }).ToList(),

                // --- Certifications ---
                Certifications = student.Certifications.Select(c => new
                {
                    c.CertificationId,
                    c.Title,
                    c.Issuer,
                    c.IssueDate,
                    c.CredentialUrl,
                    c.CredentialId
                }).ToList(),

                // --- Achievements ---
                Achievements = student.Achievements.Select(a => new
                {
                    a.AchievementId,
                    a.Title,
                    a.Description,
                    a.DateAchieved
                }).ToList(),

                // --- Experiences ---
                Experiences = student.Experiences.Select(ex => new
                {
                    ex.ExperienceId,
                    ex.CompanyName,
                    ex.Role,
                    ex.Location,
                    ex.Description,
                    ex.StartDate,
                    ex.EndDate,
                    ex.IsCurrent
                }).ToList(),

                // --- Timestamps ---
                CreatedAt = student.CreatedAt,
                UpdatedAt = student.UpdatedAt
            };

            return Ok(detail);
        }
        private int GetUserIdFromToken()
{
    var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
    if (int.TryParse(userIdClaim, out int userId))
        return userId;
    return 0;
}

// ========================================
// Interview Request Management Endpoints
// ========================================

/// <summary>
/// Company: Accept an interview request from a student
/// </summary>
[Authorize(Roles = "Company")]
[HttpPost("interview-requests/{requestId}/accept")]
        public async Task<IActionResult> AcceptInterviewRequest(int requestId, [FromBody] AcceptInterviewRequestDto dto)
        {
            var companyIdClaim = GetUserIdFromToken();
            if (companyIdClaim <= 0)
                return Unauthorized();

            var company = await _context.Companies
                .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);

            if (company == null)
                return NotFound("Company not found.");

            var request = await _context.InterviewRequests
                .Include(r => r.Student)
                    .ThenInclude(s => s.User)
                .Include(r => r.Company)
                .FirstOrDefaultAsync(r => r.RequestId == requestId && r.CompanyId == company.CompanyId);

            if (request == null)
                return NotFound("Interview request not found.");

            if (request.Status != RequestStatus.Pending)
                return BadRequest($"Cannot accept a request with status: {request.Status}");

            // Update request status
            request.Status = RequestStatus.Accepted;
            request.UpdatedAt = DateTime.UtcNow;

            // Create Interview record with JobFairId
            var interview = new Interview
            {
                CompanyId = company.CompanyId,
                StudentId = request.StudentId,
                RequestId = request.RequestId,
                Status = InterviewStatus.Queued,
                ScheduledTime = dto.ScheduledTime,
                JobFairId = request.JobFairId,  // ✅ FIX: Add the JobFairId from the request
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.Interviews.Add(interview);
            await _context.SaveChangesAsync();

            // Send FCM notification to student
            if (!string.IsNullOrWhiteSpace(request.Student.FcmToken))
            {
                try
                {
                    var message = new Message
                    {
                        Token = request.Student.FcmToken,
                        Notification = new FirebaseAdmin.Messaging.Notification
                        {
                            Title = "Interview Request Accepted",
                            Body = $"{company.Name} has accepted your interview request"
                        },
                        Data = new Dictionary<string, string>
                {
                    { "InterviewId", interview.InterviewId.ToString() },
                    { "CompanyId", company.CompanyId.ToString() },
                    { "CompanyName", company.Name },
                    { "ScheduledTime", dto.ScheduledTime?.ToString("o") ?? "To be scheduled" },
                    { "Type", "InterviewAccepted" }
                }
                    };

                    await FirebaseMessaging.DefaultInstance.SendAsync(message);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Failed to send FCM notification: {ex.Message}");
                }
            }

            return Ok(new
            {
                Message = "Interview request accepted successfully.",
                RequestId = request.RequestId,
                InterviewId = interview.InterviewId,
                StudentName = request.Student.User.FullName,
                ScheduledTime = interview.ScheduledTime,
                Status = request.Status.ToString()
            });
        }

        /// <summary>
        /// Company: Reject an interview request from a student
        /// </summary>
        [Authorize(Roles = "Company")]
[HttpPost("interview-requests/{requestId}/reject")]
public async Task<IActionResult> RejectInterviewRequest(int requestId, [FromBody] RejectInterviewRequestDto dto)
{
    var companyIdClaim = GetUserIdFromToken();
    if (companyIdClaim <= 0)
        return Unauthorized();

    var company = await _context.Companies
        .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);

    if (company == null)
        return NotFound("Company not found.");

    var request = await _context.InterviewRequests
        .Include(r => r.Student)
            .ThenInclude(s => s.User)
        .Include(r => r.Company)
        .FirstOrDefaultAsync(r => r.RequestId == requestId && r.CompanyId == company.CompanyId);

    if (request == null)
        return NotFound("Interview request not found.");

    if (request.Status != RequestStatus.Pending)
        return BadRequest($"Cannot reject a request with status: {request.Status}");

    // Update request status
    request.Status = RequestStatus.Rejected;
    request.ReasonForReject = dto.Reason;
    request.UpdatedAt = DateTime.UtcNow;

    await _context.SaveChangesAsync();

    // Send FCM notification to student
    if (!string.IsNullOrWhiteSpace(request.Student.FcmToken))
    {
        try
        {
            var message = new Message
            {
                Token = request.Student.FcmToken,
                Notification = new FirebaseAdmin.Messaging.Notification
                {
                    Title = "Interview Request Rejected",
                    Body = $"{company.Name} has rejected your interview request"
                },
                Data = new Dictionary<string, string>
                {
                    { "RequestId", request.RequestId.ToString() },
                    { "CompanyId", company.CompanyId.ToString() },
                    { "CompanyName", company.Name },
                    { "Reason", dto.Reason ?? "No reason provided" },
                    { "Type", "InterviewRejected" }
                }
            };

            await FirebaseMessaging.DefaultInstance.SendAsync(message);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Failed to send FCM notification: {ex.Message}");
        }
    }

    return Ok(new
    {
        Message = "Interview request rejected successfully.",
        RequestId = request.RequestId,
        StudentName = request.Student.User.FullName,
        RejectionReason = dto.Reason,
        Status = request.Status.ToString()
    });
}

/// <summary>
/// Company: Get all pending interview requests sent by students (to this company)
/// </summary>
[Authorize(Roles = "Company")]
[HttpGet("interview-requests/pending")]
public async Task<IActionResult> GetPendingInterviewRequests([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
{
    var companyIdClaim = GetUserIdFromToken();
    if (companyIdClaim <= 0)
        return Unauthorized();

    var company = await _context.Companies
        .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);

    if (company == null)
        return NotFound("Company not found.");

    if (page < 1) page = 1;
    if (pageSize < 1) pageSize = 20;

    var query = _context.InterviewRequests
        .Include(r => r.Student)
            .ThenInclude(s => s.User)
        .Where(r => r.CompanyId == company.CompanyId && r.Status == RequestStatus.Pending);

    var totalCount = await query.CountAsync();
    var requests = await query
        .Skip((page - 1) * pageSize)
        .Take(pageSize)
        .OrderByDescending(r => r.CreatedAt)
        .Select(r => new
        {
            r.RequestId,
            StudentId = r.Student.StudentId,
            StudentName = r.Student.User.FullName,
            StudentEmail = r.Student.User.Email,
            StudentPhone = r.Student.User.Phone,
            StudentRegistration = r.Student.RegistrationNo,
            StudentDepartment = r.Student.Department,
            StudentCGPA = r.Student.CGPA,
            RequestedBy= r.RequestedBy,
            StudentProfilePic = r.Student.ProfilePicUrl,
            StudentSkills = r.Student.Skills,
            Status = r.Status.ToString(),
            RequestDate = r.CreatedAt
        })
        .ToListAsync();

    return Ok(new
    {
        CompanyId = company.CompanyId,
        CompanyName = company.Name,
        TotalCount = totalCount,
        Page = page,
        PageSize = pageSize,
        TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
        PendingRequests = requests
    });
}


[Authorize(Roles = "Company")]
[HttpGet("interview-requests/all")]
public async Task<IActionResult> GetAllInterviewRequests(
    [FromQuery] string? status = null,
    [FromQuery] int page = 1,
    [FromQuery] int pageSize = 20)
{
    var companyIdClaim = GetUserIdFromToken();
    if (companyIdClaim <= 0)
        return Unauthorized();

    var company = await _context.Companies
        .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);

    if (company == null)
        return NotFound("Company not found.");

    if (page < 1) page = 1;
    if (pageSize < 1) pageSize = 20;

    var query = _context.InterviewRequests
        .Include(r => r.Student)
            .ThenInclude(s => s.User)
        .Where(r => r.CompanyId == company.CompanyId);

    // Filter by status if provided
    if (!string.IsNullOrWhiteSpace(status))
    {
        if (Enum.TryParse<RequestStatus>(status, true, out var statusEnum))
        {
            query = query.Where(r => r.Status == statusEnum);
        }
        else
        {
            return BadRequest("Invalid status value. Valid values: Pending, Accepted, Rejected");
        }
    }

    var totalCount = await query.CountAsync();
    var requests = await query
        .Skip((page - 1) * pageSize)
        .Take(pageSize)
        .OrderByDescending(r => r.CreatedAt)
        .Select(r => new
        {
            r.RequestId,
            StudentId = r.Student.StudentId,
            StudentName = r.Student.User.FullName,
            StudentEmail = r.Student.User.Email,
            StudentPhone = r.Student.User.Phone,
            StudentRegistration = r.Student.RegistrationNo,
            StudentDepartment = r.Student.Department,
            StudentCGPA = r.Student.CGPA,
            StudentCvUrl = r.Student.CvUrl,
            StudentProfilePic = r.Student.ProfilePicUrl,
            StudentSkills = r.Student.Skills,
            Status = r.Status.ToString(),
            RejectionReason = r.ReasonForReject,
            RequestDate = r.CreatedAt,
            ResponseDate = r.UpdatedAt,
            Interview = _context.Interviews
                .Where(i => i.RequestId == r.RequestId)
                .OrderByDescending(i => i.UpdatedAt)
                .Select(i => new
                {
                    i.InterviewId,
                    InterviewStatus = i.Status.ToString(),
                    i.ScheduledTime,
                    i.StartedAt,
                    i.EndedAt
                })
                .FirstOrDefault()
        })
        .ToListAsync();

    var summary = new
    {
        TotalRequests = totalCount,
        PendingCount = await _context.InterviewRequests
            .Where(r => r.CompanyId == company.CompanyId && r.Status == RequestStatus.Pending)
            .CountAsync(),
        AcceptedCount = await _context.InterviewRequests
            .Where(r => r.CompanyId == company.CompanyId && r.Status == RequestStatus.Accepted)
            .CountAsync(),
        RejectedCount = await _context.InterviewRequests
            .Where(r => r.CompanyId == company.CompanyId && r.Status == RequestStatus.Rejected)
            .CountAsync()
    };

    return Ok(new
    {
        CompanyId = company.CompanyId,
        CompanyName = company.Name,
        Summary = summary,
        TotalCount = totalCount,
        Page = page,
        PageSize = pageSize,
        TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
        Requests = requests
    });
}

        
        [Authorize(Roles = "Company")]
        [HttpPost("interview-requests/send")]
        public async Task<IActionResult> SendInterviewRequest([FromBody] SendCompanyInterviewRequestDto dto)
        {
            var companyIdClaim = GetUserIdFromToken();
            if (companyIdClaim <= 0)
                return Unauthorized();

            // 1. Get the Active Job Fair (CRITICAL FIX)
            var activeJobFair = await _context.JobFairs.FirstOrDefaultAsync(j => j.IsActive);
            if (activeJobFair == null)
                return BadRequest("No active Job Fair found. Cannot send interview requests.");

            var company = await _context.Companies
                .Include(c => c.User)
                .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);

            if (company == null)
                return NotFound("Company not found.");

            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.StudentId == dto.StudentId);

            if (student == null)
                return NotFound("Student not found.");

            // Check if request already exists
            var existingRequest = await _context.InterviewRequests
                .FirstOrDefaultAsync(r => r.CompanyId == company.CompanyId &&
                                           r.StudentId == student.StudentId &&
                                           r.Status == RequestStatus.Pending);

            if (existingRequest != null)
                return BadRequest("A pending interview request already exists for this student.");

            // Create interview request
            var interviewRequest = new InterviewRequest
            {
                JobFairId = activeJobFair.JobFairId, // <--- ADDED THIS LINE
                CompanyId = company.CompanyId,
                StudentId = student.StudentId,
                Status = RequestStatus.Pending,

                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.InterviewRequests.Add(interviewRequest);
            await _context.SaveChangesAsync();

            // Send FCM notification to student
            if (!string.IsNullOrWhiteSpace(student.FcmToken))
            {
                try
                {
                    var message = new Message
                    {
                        Token = student.FcmToken,
                        Notification = new FirebaseAdmin.Messaging.Notification
                        {
                            Title = "Interview Request",
                            Body = $"{company.Name} has sent you an interview request"
                        },
                        Data = new Dictionary<string, string>
                {
                    { "RequestId", interviewRequest.RequestId.ToString() },
                    { "CompanyId", company.CompanyId.ToString() },
                    { "CompanyName", company.Name },
                    { "Type", "InterviewRequest" }
                }
                    };

                    await FirebaseMessaging.DefaultInstance.SendAsync(message);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Failed to send FCM notification: {ex.Message}");
                }
            }

            return Ok(new
            {
                Message = "Interview request sent successfully.",
                RequestId = interviewRequest.RequestId,
                StudentName = student.User.FullName,
                StudentEmail = student.User.Email,
                Status = interviewRequest.Status.ToString()
            });
        }/// <summary>
         
[Authorize(Roles = "Company")]
[HttpGet("interview-requests/statistics")]
public async Task<IActionResult> GetInterviewRequestStatistics()
{
    var companyIdClaim = GetUserIdFromToken();
    if (companyIdClaim <= 0)
        return Unauthorized();

    var company = await _context.Companies
        .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);

    if (company == null)
        return NotFound("Company not found.");

    var statistics = new
    {
        CompanyId = company.CompanyId,
        CompanyName = company.Name,
        
        // Request Statistics
        TotalRequests = await _context.InterviewRequests
            .Where(r => r.CompanyId == company.CompanyId)
            .CountAsync(),
        
        PendingRequests = await _context.InterviewRequests
            .Where(r => r.CompanyId == company.CompanyId && r.Status == RequestStatus.Pending)
            .CountAsync(),
        
        AcceptedRequests = await _context.InterviewRequests
            .Where(r => r.CompanyId == company.CompanyId && r.Status == RequestStatus.Accepted)
            .CountAsync(),
        
        RejectedRequests = await _context.InterviewRequests
            .Where(r => r.CompanyId == company.CompanyId && r.Status == RequestStatus.Rejected)
            .CountAsync(),
        
        // Interview Statistics
        ScheduledInterviews = await _context.Interviews
            .Where(i => i.CompanyId == company.CompanyId && i.ScheduledTime.HasValue)
            .CountAsync(),
        
        CompletedInterviews = await _context.Interviews
            .Where(i => i.CompanyId == company.CompanyId && 
                       (i.Status == InterviewStatus.Hired || 
                        i.Status == InterviewStatus.Shortlisted || 
                        i.Status == InterviewStatus.Rejected))
            .CountAsync(),
        
        HiredCandidates = await _context.Interviews
            .Where(i => i.CompanyId == company.CompanyId && i.Status == InterviewStatus.Hired)
            .CountAsync(),
        
        ShortlistedCandidates = await _context.Interviews
            .Where(i => i.CompanyId == company.CompanyId && i.Status == InterviewStatus.Shortlisted)
            .CountAsync(),
        
        RejectedCandidates = await _context.Interviews
            .Where(i => i.CompanyId == company.CompanyId && i.Status == InterviewStatus.Rejected)
            .CountAsync()
    };

    return Ok(statistics);
}


[HttpGet("finalyear-projects/{projectId}/full-details")]
public async Task<IActionResult> GetFinalYearProjectFullDetails(int projectId)
{
    var project = await _context.Projects
        .Where(p => p.ProjectId == projectId && p.Type == ProjectType.FinalYear)
        .Include(p => p.StudentProjects)
            .ThenInclude(sp => sp.Student)
                .ThenInclude(s => s.User)
        .Include(p => p.StudentProjects)
            .ThenInclude(sp => sp.Student)
                .ThenInclude(s => s.Educations)
        .Include(p => p.StudentProjects)
            .ThenInclude(sp => sp.Student)
                .ThenInclude(s => s.Certifications)
        .Include(p => p.StudentProjects)
            .ThenInclude(sp => sp.Student)
                .ThenInclude(s => s.Achievements)
        .Include(p => p.StudentProjects)
            .ThenInclude(sp => sp.Student)
                .ThenInclude(s => s.Experiences)
        .Include(p => p.StudentProjects)
            .ThenInclude(sp => sp.Student)
                .ThenInclude(s => s.ContactLinks)
        .Include(p => p.StudentProjects)
            .ThenInclude(sp => sp.Student)
                .ThenInclude(s => s.Achievements)
        .FirstOrDefaultAsync();

    if (project == null)
        return NotFound(new { Message = "Final Year Project not found." });

            // Build comprehensive project response
            var projectDetail = new
            {
                // --- Project Information ---
                ProjectId = project.ProjectId,
                Title = project.Title,
                Description = project.Description,
                Type = project.Type.ToString(),
                Skills = string.IsNullOrEmpty(project.Skills) ? new List<string>(): project.Skills.Split(',').Select(s => s.Trim()).ToList(),
                DemoUrl = project.DemoUrl,
        GitHubUrl = project.GitHubUrl,
        ClientName = project.ClientName,
        Supervisor = project.Supervisor,
        StartDate = project.StartDate,
        EndDate = project.EndDate,
        CreatedAt = project.CreatedAt,
        

        // --- Project Statistics ---
        TotalStudents = project.StudentProjects.Count(sp => sp.Status == ProjectInviteStatus.Accepted),
        TotalInvites = project.StudentProjects.Count,
        AcceptedMembers = project.StudentProjects.Count(sp => sp.Status == ProjectInviteStatus.Accepted),
        PendingInvites = project.StudentProjects.Count(sp => sp.Status == ProjectInviteStatus.Pending),
        RejectedInvites = project.StudentProjects.Count(sp => sp.Status == ProjectInviteStatus.Rejected),

        // --- All Students in Project (Complete Details) ---
        Students = project.StudentProjects
            .Where(sp => sp.Status == ProjectInviteStatus.Accepted)
            .Select(sp => new
            {
                // --- Basic Student Info ---
                StudentId = sp.Student.StudentId,
                FullName = sp.Student.User.FullName,
                Email = sp.Student.User.Email,
                Phone = sp.Student.User.Phone,
                RegistrationNo = sp.Student.RegistrationNo,
                Department = sp.Student.Department,
                CGPA = sp.Student.CGPA,
                ProfilePicUrl = sp.Student.ProfilePicUrl,
                Skills = sp.Student.Skills ?? new List<string>(),

                // --- Project Role Information ---
                ProjectRole = new
                {
                    Role = sp.role,
                    IsCreator = sp.IsCreator,
                    Status = sp.Status.ToString()
                   
                },

                // --- Education Background ---
                Education = new
                {
                    TotalEducations = sp.Student.Educations.Count,
                    Educations = sp.Student.Educations.Select(e => new
                    {
                        e.EducationId,
                        e.InstitutionName,
                        e.Degree,
                        e.FieldOfStudy,
                        e.StartDate,
                        e.EndDate,
                        e.IsCurrent,
                        e.CGPA,
                        e.Location
                    }).ToList()
                },

                // --- Certifications ---
                Certifications = new
                {
                    TotalCertifications = sp.Student.Certifications.Count,
                    Certifications = sp.Student.Certifications.Select(c => new
                    {
                        c.CertificationId,
                        c.Title,
                        c.Issuer,
                        c.IssueDate,
                        c.CredentialUrl,
                        c.CredentialId
                    }).ToList()
                },

                // --- Achievements ---
                Achievements = new
                {
                    TotalAchievements = sp.Student.Achievements.Count,
                    Achievements = sp.Student.Achievements.Select(a => new
                    {
                        a.AchievementId,
                        a.Title,
                        a.Description,
                        a.DateAchieved
                    }).ToList()
                },

                // --- Work Experience ---
                WorkExperience = new
                {
                    TotalExperiences = sp.Student.Experiences.Count,
                    Experiences = sp.Student.Experiences.Select(ex => new
                    {
                        ex.ExperienceId,
                        ex.CompanyName,
                        ex.Role,
                        ex.Description,
                        ex.StartDate,
                        ex.EndDate,
                        ex.IsCurrent,
                        ex.Location
                    }).ToList()
                },

                // --- Contact Links / Social Media ---
                ContactLinks = new
                {
                    TotalLinks = sp.Student.ContactLinks.Count,
                    Links = sp.Student.ContactLinks.Select(cl => new
                    {
                        cl.LinkId,
                        Platform = cl.Platform.ToString(),
                        cl.Url
                    }).ToList()
                },

                // --- User Account Info ---
                AccountInfo = new
                {
                    UserId = sp.Student.User.UserId,
                    IsActive = sp.Student.User.IsActive,
                    CreatedAt = sp.Student.User.CreatedAt,
                    UpdatedAt = sp.Student.User.UpdatedAt
                }
            })
            .OrderByDescending(s => s.ProjectRole.IsCreator) // Show creator first
            .ToList(),

        // --- Pending/Rejected Invites ---
        PendingStudents = project.StudentProjects
            .Where(sp => sp.Status == ProjectInviteStatus.Pending)
            .Select(sp => new
            {
                StudentId = sp.Student.StudentId,
                Name = sp.Student.User.FullName,
                Email = sp.Student.User.Email,
                RegistrationNo = sp.Student.RegistrationNo,
                Department = sp.Student.Department,
                CGPA = sp.Student.CGPA,
                ProfilePicUrl = sp.Student.ProfilePicUrl,
                Status = sp.Status.ToString()
         
            }).ToList(),

        RejectedStudents = project.StudentProjects
            .Where(sp => sp.Status == ProjectInviteStatus.Rejected)
            .Select(sp => new
            {
                StudentId = sp.Student.StudentId,
                Name = sp.Student.User.FullName,
                Email = sp.Student.User.Email,
                RegistrationNo = sp.Student.RegistrationNo,
                Department = sp.Student.Department,
                CGPA = sp.Student.CGPA,
                Status = sp.Status.ToString()
              
            }).ToList(),

        // --- Summary Statistics ---
        Summary = new
        {
            AverageStudentCGPA = Math.Round(project.StudentProjects
                .Where(sp => sp.Status == ProjectInviteStatus.Accepted)
                .Average(sp => sp.Student.CGPA), 2),
            UniqueDepartments = project.StudentProjects
                .Where(sp => sp.Status == ProjectInviteStatus.Accepted)
                .Select(sp => sp.Student.Department)
                .Distinct()
                .ToList(),
            DepartmentBreakdown = project.StudentProjects
                .Where(sp => sp.Status == ProjectInviteStatus.Accepted)
                .GroupBy(sp => sp.Student.Department)
                .Select(g => new
                {
                    Department = g.Key,
                    Count = g.Count(),
                    AverageCGPA = Math.Round(g.Average(sp => sp.Student.CGPA), 2)
                }).ToList(),
            TotalSkillsUsed = (string.IsNullOrEmpty(project.Skills) ? new List<string>() : project.Skills.Split(',').Select(s => s.Trim()).ToList()).Count,
            CreatorInfo = project.StudentProjects
                .Where(sp => sp.IsCreator && sp.Status == ProjectInviteStatus.Accepted)
                .Select(sp => new
                {
                    sp.Student.StudentId,
                    Name = sp.Student.User.FullName,
                    Email = sp.Student.User.Email,
                    RegistrationNo = sp.Student.RegistrationNo
                }).FirstOrDefault()
        }
    };

    return Ok(new { project = projectDetail });
}

/// <summary>
/// Get FYP summary with team overview (lighter version)
/// </summary>
[HttpGet("finalyear-projects/{projectId}/summary")]
public async Task<IActionResult> GetFinalYearProjectSummary(int projectId)
{
    var project = await _context.Projects
        .Where(p => p.ProjectId == projectId && p.Type == ProjectType.FinalYear)
        .Include(p => p.StudentProjects)
            .ThenInclude(sp => sp.Student)
                .ThenInclude(s => s.User)
        .FirstOrDefaultAsync();

    if (project == null)
        return NotFound(new { Message = "Final Year Project not found." });

    var summary = new
    {
        ProjectId = project.ProjectId,
        Title = project.Title,
        Description = project.Description,
        Skills = string.IsNullOrEmpty(project.Skills) ? new List<string>() : project.Skills.Split(',').Select(s => s.Trim()).ToList(),
        DemoUrl = project.DemoUrl,
        GitHubUrl = project.GitHubUrl,
        Supervisor = project.Supervisor,
        ClientName = project.ClientName,
        
        TeamOverview = new
        {
            TotalMembers = project.StudentProjects.Count(sp => sp.Status == ProjectInviteStatus.Accepted),
            Creator = project.StudentProjects
                .Where(sp => sp.IsCreator && sp.Status == ProjectInviteStatus.Accepted)
                .Select(sp => new
                {
                    sp.Student.StudentId,
                    Name = sp.Student.User.FullName,
                    RegistrationNo = sp.Student.RegistrationNo,
                    Department = sp.Student.Department,
                    CGPA = sp.Student.CGPA
                }).FirstOrDefault(),
            
            TeamMembers = project.StudentProjects
                .Where(sp => !sp.IsCreator && sp.Status == ProjectInviteStatus.Accepted)
                .Select(sp => new
                {
                    sp.Student.StudentId,
                    Name = sp.Student.User.FullName,
                    RegistrationNo = sp.Student.RegistrationNo,
                    Department = sp.Student.Department,
                    CGPA = sp.Student.CGPA,
                    Role = sp.role
                }).ToList()
        },

        Statistics = new
        {
            AcceptedCount = project.StudentProjects.Count(sp => sp.Status == ProjectInviteStatus.Accepted),
            PendingCount = project.StudentProjects.Count(sp => sp.Status == ProjectInviteStatus.Pending),
            RejectedCount = project.StudentProjects.Count(sp => sp.Status == ProjectInviteStatus.Rejected),
            AverageCGPA = Math.Round(project.StudentProjects
                .Where(sp => sp.Status == ProjectInviteStatus.Accepted)
                .Average(sp => sp.Student.CGPA), 2)
        }
    };

    return Ok(new { project = summary });
}

/// <summary>
/// Export FYP details as PDF/JSON (for companies to download team info)
/// </summary>
[HttpGet("finalyear-projects/{projectId}/export")]
public async Task<IActionResult> ExportFinalYearProjectDetails(int projectId, [FromQuery] string format = "json")
{
    var project = await _context.Projects
        .Where(p => p.ProjectId == projectId && p.Type == ProjectType.FinalYear)
        .Include(p => p.StudentProjects)
            .ThenInclude(sp => sp.Student)
                .ThenInclude(s => s.User)
        .Include(p => p.StudentProjects)
            .ThenInclude(sp => sp.Student)
                .ThenInclude(s => s.Educations)
        .Include(p => p.StudentProjects)
            .ThenInclude(sp => sp.Student)
                .ThenInclude(s => s.ContactLinks)
        .FirstOrDefaultAsync();

    if (project == null)
        return NotFound(new { Message = "Final Year Project not found." });

    if (format.ToLower() == "json")
    {
        var projectData = new
        {
            ProjectId = project.ProjectId,
            Title = project.Title,
            Description = project.Description,
            Skills = project.Skills,
            DemoUrl = project.DemoUrl,
            GitHubUrl = project.GitHubUrl,
            Supervisor = project.Supervisor,
            ClientName = project.ClientName,
            StartDate = project.StartDate,
            EndDate = project.EndDate,
            Students = project.StudentProjects
                .Where(sp => sp.Status == ProjectInviteStatus.Accepted)
                .Select(sp => new
                {
                    Name = sp.Student.User.FullName,
                    Email = sp.Student.User.Email,
                    Phone = sp.Student.User.Phone,
                    RegistrationNo = sp.Student.RegistrationNo,
                    Department = sp.Student.Department,
                    CGPA = sp.Student.CGPA,
                    Role = sp.role,
                    IsCreator = sp.IsCreator,
                    ContactLinks = sp.Student.ContactLinks.Select(cl => new
                    {
                        Platform = cl.Platform.ToString(),
                        cl.Url
                    }).ToList()
                }).ToList()
        };

        var json = System.Text.Json.JsonSerializer.Serialize(projectData, new System.Text.Json.JsonSerializerOptions { WriteIndented = true });
        var bytes = System.Text.Encoding.UTF8.GetBytes(json);
        return File(bytes, "application/json", $"FYP_{project.ProjectId}_{project.Title.Replace(" ", "_")}.json");
    }

    return BadRequest("Unsupported format. Use 'json'.");
}
        
        [Authorize(Roles = "Company")]
        [HttpGet("jobs")]
        public async Task<IActionResult> GetCompanyJobs([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            var companyIdClaim = GetUserIdFromToken();
            if (companyIdClaim <= 0)
                return Unauthorized();

            var company = await _context.Companies
                .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);

            if (company == null)
                return NotFound("Company not found.");

            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 20;

            var query = _context.Jobs
                .Where(j => j.CompanyId == company.CompanyId);

            var totalCount = await query.CountAsync();
            var jobs = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(j => new
                {
                    j.JobId,
                    j.JobTitle,
                    j.JobDescription,
                    j.RequiredSkills,
                    j.JobType,
                    j.NumberOfJobs,
                    j.CreatedAt,
                    j.UpdatedAt
                })
                .ToListAsync();

            return Ok(new
            {
                CompanyId = company.CompanyId,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize,
                TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
                Jobs = jobs
            });
        }


        [Authorize(Roles = "Company")]
        [HttpPost("jobs")]
        public async Task<IActionResult> CreateJob([FromBody] CreateJobDto dto)
        {
            var companyIdClaim = GetUserIdFromToken();
            if (companyIdClaim <= 0)
                return Unauthorized();

            var company = await _context.Companies
                .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);

            if (company == null)
                return NotFound("Company not found.");

            // ✅ FIX: Get active job fair
            var activeJobFair = await _context.JobFairs.FirstOrDefaultAsync(j => j.IsActive);
            if (activeJobFair == null)
                return BadRequest("No active Job Fair found. Cannot post jobs.");

            var job = new Job
            {
                CompanyId = company.CompanyId,
                JobFairId = activeJobFair.JobFairId, // ✅ FIX: Assign JobFairId
                JobTitle = dto.JobTitle,
                JobDescription = dto.JobDescription,
                RequiredSkills = dto.RequiredSkills?.ToArray() ?? Array.Empty<string>(),
                JobType = dto.JobType,
                NumberOfJobs = dto.NumberOfJobs,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.Jobs.Add(job);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Job posted successfully.",
                JobId = job.JobId,
                JobTitle = job.JobTitle,
                Status = "Published"
            });
        }
        [Authorize(Roles = "Company")]
        [HttpPut("jobs/{jobId}")]
        public async Task<IActionResult> UpdateJob(int jobId, [FromBody] UpdateJobDto dto)
        {
            var companyIdClaim = GetUserIdFromToken();
            if (companyIdClaim <= 0)
                return Unauthorized();

            var company = await _context.Companies
                .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);

            if (company == null)
                return NotFound("Company not found.");

            var job = await _context.Jobs
                .FirstOrDefaultAsync(j => j.JobId == jobId && j.CompanyId == company.CompanyId);

            if (job == null)
                return NotFound("Job not found.");

            // Update fields
            if (!string.IsNullOrWhiteSpace(dto.JobTitle))
                job.JobTitle = dto.JobTitle;

            if (!string.IsNullOrWhiteSpace(dto.JobDescription))
                job.JobDescription = dto.JobDescription;

            if (dto.RequiredSkills != null && dto.RequiredSkills.Count > 0)
                job.RequiredSkills = dto.RequiredSkills.ToArray();

            if (dto.JobType.HasValue)
                job.JobType = dto.JobType.Value;

            if (dto.NumberOfJobs.HasValue && dto.NumberOfJobs.Value > 0)
                job.NumberOfJobs = dto.NumberOfJobs.Value;

            job.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Job updated successfully.",
                JobId = job.JobId,
                JobTitle = job.JobTitle
            });
        }

        /// <summary>
        /// Company: Delete a job posting
        /// </summary>
        [Authorize(Roles = "Company")]
        [HttpDelete("jobs/{jobId}")]
        public async Task<IActionResult> DeleteJob(int jobId)
        {
            var companyIdClaim = GetUserIdFromToken();
            if (companyIdClaim <= 0)
                return Unauthorized();

            var company = await _context.Companies
                .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);

            if (company == null)
                return NotFound("Company not found.");

            var job = await _context.Jobs
                .FirstOrDefaultAsync(j => j.JobId == jobId && j.CompanyId == company.CompanyId);

            if (job == null)
                return NotFound("Job not found.");

            _context.Jobs.Remove(job);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Job deleted successfully.",
                JobId = jobId
            });
        }

       
        [Authorize(Roles = "Company")]
        [HttpGet("profile")]
        public async Task<IActionResult> GetCompanyProfile()
        {
            var companyIdClaim = GetUserIdFromToken();
            if (companyIdClaim <= 0)
                return Unauthorized();

            var company = await _context.Companies
                .Include(c => c.User)
                .Include(c => c.Room)
                .Include(c => c.Jobs)
                .Include(c => c.CompanyContactLinks)
                .Include(c => c.Interviews)
                .Include(c => c.InterviewRequests)
                .Include(c => c.JobFairParticipations)
                .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);

            if (company == null)
                return NotFound("Company not found.");

            // Get participation for current/active job fair
            var activeJobFair = await _context.JobFairs.FirstOrDefaultAsync(j => j.IsActive);
            var participation = company.JobFairParticipations.FirstOrDefault(p => p.JobFairId == (company.CurrentJobFairId ?? activeJobFair?.JobFairId));

            var profile = new
            {
                // --- Basic Info ---
                CompanyId = company.CompanyId,
                Name = company.Name,
                Description = company.Description,
                Industry = company.Industry,
                LogoUrl = company.LogoUrl,
                Website = company.Website,
                Address = company.Address,

                // --- Contact Information ---
                ContactInfo = new
                {
                    Email = company.CompanyEmail,
                    Phone = company.CompanyPhone
                },

                // --- Focal Person ---
                FocalPerson = new
                {
                    Name = company.FocalPersonName,
                    Email = company.FocalPersonEmail,
                    Phone = company.FocalPersonPhone
                },

                // --- User Account ---
                UserAccount = new
                {
                    Email = company.User.Email,
                    Phone = company.User.Phone,
                    IsActive = company.User.IsActive,
                    CreatedAt = company.User.CreatedAt
                },

                // --- Social Links ---
                SocialLinks = company.CompanyContactLinks.Select(cl => new
                {
                    LinkId = cl.LinkId,
                    Platform = cl.Platform.ToString(),
                    Url = cl.Url
                }).ToList(),

                // --- Room Assignment ---
                RoomAssignment = company.Room != null ? new
                {
                    RoomId = company.Room.RoomId,
                    RoomName = company.Room.RoomName,
                    Capacity = company.Room.Capacity
                } : null,

                // --- Job Information ---
                Jobs = new
                {
                    TotalJobs = company.Jobs.Count,
                    Jobs = company.Jobs.Select(j => new
                    {
                        j.JobId,
                        j.JobTitle,
                        j.JobDescription,
                        j.RequiredSkills,
                        j.JobType,
                        j.NumberOfJobs
                    }).ToList()
                },

                // --- Interview Statistics ---
                InterviewStats = new
                {
                    TotalRequests = company.InterviewRequests.Count,
                    PendingRequests = company.InterviewRequests.Count(ir => ir.Status == RequestStatus.Pending),
                    AcceptedRequests = company.InterviewRequests.Count(ir => ir.Status == RequestStatus.Accepted),
                    RejectedRequests = company.InterviewRequests.Count(ir => ir.Status == RequestStatus.Rejected),
                    TotalInterviews = company.Interviews.Count,
                    HiredCandidates = company.Interviews.Count(i => i.Status == InterviewStatus.Hired),
                    ShortlistedCandidates = company.Interviews.Count(i => i.Status == InterviewStatus.Shortlisted)
                },

                // --- Company Settings ---
                CompanySettings = new
                {
                    RepsCount = company.RepsCount,
                    InterviewDurationMinutes = company.InterviewDurationMinutes,
                    ArrivalStatus = participation?.ArrivalStatus.ToString() ?? "Pending",
                    IsPresent = company.IsPresent
                },

                // --- Timestamps ---
                CreatedAt = company.CreatedAt,
                UpdatedAt = company.UpdatedAt
            };

            return Ok(profile);
        }

        
        [Authorize(Roles = "Company")]
        [HttpPut("profile")]
        public async Task<IActionResult> EditCompanyProfile([FromForm] EditCompanyProfileDto dto)
        {
            var companyIdClaim = GetUserIdFromToken();
            if (companyIdClaim <= 0)
                return Unauthorized();

            var company = await _context.Companies
                .Include(c => c.User)
                .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);

            if (company == null)
                return NotFound("Company not found.");

            // --- Update Logo if provided ---
            if (dto.Logo != null && dto.Logo.Length > 0)
            {
                // Delete old logo if exists
                if (!string.IsNullOrWhiteSpace(company.LogoUrl))
                {
                    var oldFileName = company.LogoUrl.Split('/').Last();
                    var oldPath = Path.Combine("wwwroot", "uploads", "companies", "logo", oldFileName);
                    if (System.IO.File.Exists(oldPath))
                    {
                        try
                        {
                            System.IO.File.Delete(oldPath);
                        }
                        catch (Exception ex)
                        {
                            _logger.LogWarning($"Failed to delete old logo: {ex.Message}");
                        }
                    }
                }

                // Upload new logo
                var uploadsFolder = Path.Combine("wwwroot", "uploads", "companies", "logo");
                Directory.CreateDirectory(uploadsFolder);

                var fileName = $"{company.CompanyId}_{Guid.NewGuid()}{Path.GetExtension(dto.Logo.FileName)}";
                var filePath = Path.Combine(uploadsFolder, fileName);

                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await dto.Logo.CopyToAsync(stream);
                }

                company.LogoUrl = $"/uploads/companies/logo/{fileName}";
            }

            // --- Update Website ---
            if (!string.IsNullOrWhiteSpace(dto.Website))
                company.Website = dto.Website;

            // --- Update Email ---
            if (!string.IsNullOrWhiteSpace(dto.CompanyEmail))
                company.CompanyEmail = dto.CompanyEmail;

            // --- Update Phone ---
            if (!string.IsNullOrWhiteSpace(dto.CompanyPhone))
                company.CompanyPhone = dto.CompanyPhone;

            // --- Update Address ---
            if (!string.IsNullOrWhiteSpace(dto.Address))
                company.Address = dto.Address;

            // --- Update Description ---
            if (!string.IsNullOrWhiteSpace(dto.Description))
                company.Description = dto.Description;

            // --- Update User Phone ---
            if (!string.IsNullOrWhiteSpace(dto.UserPhone))
                company.User.Phone = dto.UserPhone;

            // --- Update Interview Duration (Expected Interview Time) ---
            if (dto.InterviewDurationMinutes.HasValue)
            {
                company.InterviewDurationMinutes = dto.InterviewDurationMinutes.Value;

                var activeJobFair = await _context.JobFairs
                    .AsNoTracking()
                    .FirstOrDefaultAsync(j => j.IsActive);

                var targetJobFairId = company.CurrentJobFairId ?? activeJobFair?.JobFairId;
                if (targetJobFairId.HasValue)
                {
                    var participation = await _context.CompanyJobFairParticipations
                        .FirstOrDefaultAsync(p => p.CompanyId == company.CompanyId && p.JobFairId == targetJobFairId.Value);

                    if (participation != null)
                    {
                        participation.InterviewDurationMinutes = dto.InterviewDurationMinutes.Value;
                        participation.UpdatedAt = DateTime.UtcNow;
                    }
                }
            }

            company.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Profile updated successfully.",
                CompanyId = company.CompanyId,
                LogoUrl = company.LogoUrl,
                Website = company.Website,
                InterviewDurationMinutes = company.InterviewDurationMinutes
            });
        }

        
        [Authorize(Roles = "Company")]
        [HttpPost("contact-links")]
        public async Task<IActionResult> AddContactLink([FromBody] AddContactLinkDto dto)
        {
            var companyIdClaim = GetUserIdFromToken();
            if (companyIdClaim <= 0)
                return Unauthorized();

            var company = await _context.Companies
                .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);

            if (company == null)
                return NotFound("Company not found.");

            // Check if link for this platform already exists
            var existingLink = await _context.CompanyContactLinks
                .FirstOrDefaultAsync(cl => cl.CompanyId == company.CompanyId && cl.Platform == dto.Platform);

            if (existingLink != null)
                return BadRequest($"A {dto.Platform} link already exists. Use PUT to update it.");

            var contactLink = new CompanyContactLink
            {
                CompanyId = company.CompanyId,
                Platform = dto.Platform,
                Url = dto.Url
            };

            _context.CompanyContactLinks.Add(contactLink);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Contact link added successfully.",
                LinkId = contactLink.LinkId,
                Platform = contactLink.Platform.ToString(),
                Url = contactLink.Url
            });
        }

        
        [Authorize(Roles = "Company")]
        [HttpPut("contact-links/{linkId}")]
        public async Task<IActionResult> UpdateContactLink(int linkId, [FromBody] UpdateContactLinkDto dto)
        {
            var companyIdClaim = GetUserIdFromToken();
            if (companyIdClaim <= 0)
                return Unauthorized();

            var company = await _context.Companies
                .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);

            if (company == null)
                return NotFound("Company not found.");

            var contactLink = await _context.CompanyContactLinks
                .FirstOrDefaultAsync(cl => cl.LinkId == linkId && cl.CompanyId == company.CompanyId);

            if (contactLink == null)
                return NotFound("Contact link not found.");

            if (!string.IsNullOrWhiteSpace(dto.Url))
                contactLink.Url = dto.Url;

            if (dto.Platform.HasValue)
                contactLink.Platform = dto.Platform.Value;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Contact link updated successfully.",
                LinkId = contactLink.LinkId,
                Platform = contactLink.Platform.ToString(),
                Url = contactLink.Url
            });
        }

        
        [Authorize(Roles = "Company")]
        [HttpDelete("contact-links/{linkId}")]
        public async Task<IActionResult> DeleteContactLink(int linkId)
        {
            var companyIdClaim = GetUserIdFromToken();
            if (companyIdClaim <= 0)
                return Unauthorized();

            var company = await _context.Companies
                .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);

            if (company == null)
                return NotFound("Company not found.");

            var contactLink = await _context.CompanyContactLinks
                .FirstOrDefaultAsync(cl => cl.LinkId == linkId && cl.CompanyId == company.CompanyId);

            if (contactLink == null)
                return NotFound("Contact link not found.");

            _context.CompanyContactLinks.Remove(contactLink);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Contact link deleted successfully.",
                LinkId = linkId
            });
        }
        [Authorize(Roles = "Company")]
        [HttpPost("confirm-attendance")]
        public async Task<IActionResult> ConfirmAttendance()
        {
            try
            {
                var companyIdClaim = GetUserIdFromToken();
                if (companyIdClaim <= 0)
                    return Unauthorized();

                var company = await _context.Companies
                    .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);

                if (company == null)
                    return NotFound(new { Message = "Company not found." });

                var activeJobFair = await _context.JobFairs
                    .AsNoTracking()
                    .FirstOrDefaultAsync(j => j.IsActive);

                if (activeJobFair == null)
                    return BadRequest(new { Code = "VALIDATION_ERROR", Message = "No active job fair found." });

                var today = DateTime.UtcNow.Date;
                var jobFairDate = activeJobFair.date.Date;
                var daysUntilJobFair = (jobFairDate - today).Days;

                if (daysUntilJobFair != 1)
                {
                    return BadRequest(new
                    {
                        Code = "VALIDATION_ERROR",
                        Message = "Attendance confirmation is only allowed one day before the job fair date."
                    });
                }

                // Get the service from DI
                var confirmationService = HttpContext.RequestServices.GetRequiredService<ICompanyConfirmationService>();
                var result = await confirmationService.ConfirmCompanyAttendanceAsync(company.CompanyId);

                return Ok(result);
            }
            catch (InvalidOperationException ex)
            {
                _logger.LogWarning(ex, "Validation error in confirm attendance");
                return BadRequest(new { Code = "VALIDATION_ERROR", Message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error confirming attendance");
                return StatusCode(500, new { Code = "ERROR", Message = "An error occurred while confirming your attendance." });
            }
        }
        [Authorize(Roles = "Company")]
        [HttpGet("confirmation-status")]
        public async Task<IActionResult> GetConfirmationStatus()
        {
            try
            {
                var companyIdClaim = GetUserIdFromToken();
                if (companyIdClaim <= 0)
                    return Unauthorized();

                var company = await _context.Companies
                    .Include(c => c.User)
                    .Include(c => c.Room)
                    .Include(c => c.JobFairParticipations)
                    .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);

                if (company == null)
                    return NotFound(new { Message = "Company not found." });

                // Get active job fair
                var activeJobFair = await _context.JobFairs
                    .AsNoTracking()
                    .FirstOrDefaultAsync(j => j.IsActive);

                if (activeJobFair == null)
                    return BadRequest(new { Message = "No active job fair found." });

                // Get participation for current/active job fair
                var participation = company.JobFairParticipations.FirstOrDefault(p => p.JobFairId == (company.CurrentJobFairId ?? activeJobFair?.JobFairId));
                var today = DateTime.UtcNow.Date;
                var jobFairDate = activeJobFair.date.Date;
                var daysUntilJobFair = (jobFairDate - today).Days;
                var isConfirmed = participation?.ArrivalStatus == ArrivalStatus.PreRegistered;

                var status = new
                {
                    CompanyId = company.CompanyId,
                    CompanyName = company.Name,
                    JobFairId = activeJobFair.JobFairId,
                    JobFairSemester = activeJobFair.Semester,
                    JobFairDate = activeJobFair.date,
                    IsPresent = participation?.IsPresent ?? false,
                    IsConfirmed = isConfirmed,
                    DaysUntilJobFair = daysUntilJobFair,
                    IsConfirmationWindowOpen = daysUntilJobFair == 1,
                    CanConfirmAttendance = daysUntilJobFair == 1 && !isConfirmed,
                    ArrivalStatus = participation?.ArrivalStatus.ToString() ?? "Pending",
                    RepresentativeCount = company.RepsCount,
                    RoomAssigned = company.Room != null,
                    RoomDetails = company.Room != null ? new
                    {
                        RoomId = company.Room.RoomId,
                        RoomName = company.Room.RoomName,
                        Capacity = company.Room.Capacity,
                        Status = company.Room.Status.ToString()
                    } : null,
                    ConfirmedAt = company.UpdatedAt
                };

                return Ok(status);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting confirmation status");
                return StatusCode(500, new { Message = "An error occurred while retrieving status." });
            }
        }
        [Authorize(Roles = "Company")]
        [HttpPost("interviews/schedule")]
        public async Task<IActionResult> OptimizeJobFairSchedule([FromQuery] DateTime? date = null)
        {
            var companyUserId = GetUserIdFromToken();
            if (companyUserId <= 0) return Unauthorized();

            var company = await _context.Companies.FirstOrDefaultAsync(c => c.UserId == companyUserId);
            if (company == null) return NotFound("Company not found.");

            var activeJobFair = await _context.JobFairs.AsNoTracking().FirstOrDefaultAsync(j => j.IsActive);
            if (activeJobFair == null) return BadRequest("No active job fair. Scheduling available only during an active fair.");

            var participation = await _context.CompanyJobFairParticipations
                .FirstOrDefaultAsync(p => p.CompanyId == company.CompanyId && p.JobFairId == activeJobFair.JobFairId);

            if (participation == null) return BadRequest("Company is not registered for the active job fair.");
            if (!participation.IsPresent) return BadRequest("Company is not marked present for the active job fair.");

            var scheduleDate = (date ?? activeJobFair.date).Date;

            // Boundaries (kept simple — adjust timezone handling as needed)
            var buffer = TimeSpan.FromSeconds(90);
            var nowUtc = DateTime.UtcNow;
            var (dayStart, hardStop, dayEndExclusive) = GetWorkingWindowUtc(scheduleDate);
            var startTime = nowUtc > dayStart ? nowUtc : dayStart;

            var interviewDurationMinutes = participation.InterviewDurationMinutes > 0 ? participation.InterviewDurationMinutes : company.InterviewDurationMinutes;
            if (interviewDurationMinutes <= 0) return BadRequest("Interview duration is not configured for this company.");

            var companyDuration = TimeSpan.FromMinutes(interviewDurationMinutes);

            var acceptedRequests = await _context.InterviewRequests
                .AsNoTracking()
                .Where(r => r.CompanyId == company.CompanyId && r.JobFairId == activeJobFair.JobFairId && r.Status == RequestStatus.Accepted)
                .ToListAsync();

            var existingCompanyInterviewStudentIds = (await _context.Interviews
                .AsNoTracking()
                .Where(i => i.CompanyId == company.CompanyId
                            && i.JobFairId == activeJobFair.JobFairId
                            && i.ScheduledTime.HasValue
                            && i.ScheduledTime.Value >= dayStart
                            && i.ScheduledTime.Value < dayEndExclusive)
                .Select(i => i.StudentId)
                .ToListAsync())
                .ToHashSet();

            var requestsToSchedule = acceptedRequests
                .Where(r => !existingCompanyInterviewStudentIds.Contains(r.StudentId))
                .ToList();

            if (!requestsToSchedule.Any())
                return Ok(new { Message = "No accepted requests to schedule." });

            var studentIds = requestsToSchedule.Select(r => r.StudentId).Distinct().ToList();

            var globalInterviews = await _context.Interviews
                .AsNoTracking()
                .Where(i => studentIds.Contains(i.StudentId)
                            && i.ScheduledTime.HasValue
                            && i.ScheduledTime.Value >= dayStart
                            && i.ScheduledTime.Value < dayEndExclusive)
                .ToListAsync();

            var existingCompanyInterviews = await _context.Interviews
                .AsNoTracking()
                .Where(i => i.CompanyId == company.CompanyId
                            && i.JobFairId == activeJobFair.JobFairId
                            && i.ScheduledTime.HasValue
                            && i.ScheduledTime.Value >= dayStart
                            && i.ScheduledTime.Value < dayEndExclusive)
                .ToListAsync();

            var involvedCompanyIds = globalInterviews.Select(i => i.CompanyId)
                .Union(existingCompanyInterviews.Select(i => i.CompanyId))
                .Where(id => id != 0)
                .Distinct()
                .ToList();

            var durationsDict = new Dictionary<int, int>();
            if (involvedCompanyIds.Any())
            {
                var participations = await _context.CompanyJobFairParticipations
                    .Where(p => involvedCompanyIds.Contains(p.CompanyId) && p.JobFairId == activeJobFair.JobFairId)
                    .ToListAsync();

                foreach (var p in participations)
                    durationsDict[p.CompanyId] = p.InterviewDurationMinutes;

                var missingCompanyIds = involvedCompanyIds.Except(durationsDict.Keys).ToList();
                if (missingCompanyIds.Any())
                {
                    var comps = await _context.Companies.Where(c => missingCompanyIds.Contains(c.CompanyId)).ToListAsync();
                    foreach (var c in comps)
                        durationsDict[c.CompanyId] = c.InterviewDurationMinutes;
                }
            }

            DateTime ComputeInterviewEnd(Interview i)
            {
                var start = DateTime.SpecifyKind(i.ScheduledTime!.Value, DateTimeKind.Utc);
                var dur = TimeSpan.FromMinutes(durationsDict.ContainsKey(i.CompanyId) && durationsDict[i.CompanyId] > 0
                    ? durationsDict[i.CompanyId]
                    : company.InterviewDurationMinutes);
                return start + dur;
            }

            var companyBusy = new List<(DateTime start, DateTime end)>();
            foreach (var i in existingCompanyInterviews)
            {
                var s = DateTime.SpecifyKind(i.ScheduledTime!.Value, DateTimeKind.Utc);
                var e = ComputeInterviewEnd(i);
                companyBusy.Add((s, e));
            }

            var studentBusy = new Dictionary<int, List<(DateTime start, DateTime end)>>();
            foreach (var sid in studentIds) studentBusy[sid] = new List<(DateTime start, DateTime end)>();

            foreach (var i in globalInterviews)
            {
                var s = DateTime.SpecifyKind(i.ScheduledTime!.Value, DateTimeKind.Utc);
                var e = ComputeInterviewEnd(i);
                if (!studentBusy.ContainsKey(i.StudentId)) studentBusy[i.StudentId] = new List<(DateTime, DateTime)>();
                studentBusy[i.StudentId].Add((s, e));
            }

            var globalCounts = globalInterviews.GroupBy(i => i.StudentId).ToDictionary(g => g.Key, g => g.Count());

            requestsToSchedule.Sort((a, b) =>
            {
                var ca = globalCounts.ContainsKey(a.StudentId) ? globalCounts[a.StudentId] : 0;
                var cb = globalCounts.ContainsKey(b.StudentId) ? globalCounts[b.StudentId] : 0;
                return cb.CompareTo(ca);
            });

            var optimizedInterviews = new List<Interview>();
            var localCompanyBusy = new List<(DateTime start, DateTime end)>(companyBusy);
            var localStudentBusy = studentBusy.ToDictionary(kvp => kvp.Key, kvp => kvp.Value.ToList());

            foreach (var req in requestsToSchedule)
            {
                var duration = companyDuration;
                var searchPointer = startTime;

                while (searchPointer + duration <= hardStop)
                {
                    var potentialEnd = searchPointer + duration;
                    var candidateStartWithBuffer = searchPointer - buffer;
                    var candidateEndWithBuffer = potentialEnd + buffer;

                    var companyConflicts = localCompanyBusy.Any(b => Overlaps(b.start, b.end, candidateStartWithBuffer, candidateEndWithBuffer));
                    var studentConflicts = localStudentBusy.TryGetValue(req.StudentId, out var sbList) &&
                                           sbList.Any(b => Overlaps(b.start, b.end, candidateStartWithBuffer, candidateEndWithBuffer));

                    if (!companyConflicts && !studentConflicts)
                    {
                        var interview = new Interview
                        {
                            CompanyId = company.CompanyId,
                            StudentId = req.StudentId,
                            RequestId = req.RequestId,
                            JobFairId = activeJobFair.JobFairId,
                            ScheduledTime = searchPointer,
                            Status = InterviewStatus.Queued,
                            CreatedAt = DateTime.UtcNow,
                            UpdatedAt = DateTime.UtcNow
                        };

                        optimizedInterviews.Add(interview);

                        localCompanyBusy.Add((searchPointer, potentialEnd));
                        if (!localStudentBusy.ContainsKey(req.StudentId)) localStudentBusy[req.StudentId] = new List<(DateTime, DateTime)>();
                        localStudentBusy[req.StudentId].Add((searchPointer, potentialEnd));
                        break;
                    }

                    var overlappingEnds = new List<DateTime>();
                    overlappingEnds.AddRange(localCompanyBusy.Where(b => Overlaps(b.start, b.end, candidateStartWithBuffer, candidateEndWithBuffer)).Select(b => b.end));
                    if (localStudentBusy.TryGetValue(req.StudentId, out var listForStudent))
                        overlappingEnds.AddRange(listForStudent.Where(b => Overlaps(b.start, b.end, candidateStartWithBuffer, candidateEndWithBuffer)).Select(b => b.end));

                    if (overlappingEnds.Any())
                    {
                        var maxEnd = overlappingEnds.Max();
                        searchPointer = maxEnd.Add(buffer);
                        searchPointer = DateTime.SpecifyKind(new DateTime(searchPointer.Year, searchPointer.Month, searchPointer.Day, searchPointer.Hour, searchPointer.Minute, 0), DateTimeKind.Utc);
                        continue;
                    }

                    searchPointer = searchPointer.AddMinutes(1);
                }
            }

            if (!optimizedInterviews.Any())
                return Ok(new { Message = "No available slots found to schedule interviews." });

            using (var tx = await _context.Database.BeginTransactionAsync())
            {
                try
                {
                    var scheduledDates = optimizedInterviews.Select(i => i.ScheduledTime!.Value.Date).Distinct().ToList();
                    var candidateStudentIds = optimizedInterviews.Select(i => i.StudentId).Distinct().ToList();
                    var dbConflicts = await _context.Interviews
                        .AsNoTracking()
                        .Where(i => i.JobFairId == activeJobFair.JobFairId
                                    && i.ScheduledTime.HasValue
                                    && i.ScheduledTime.Value >= dayStart
                                    && i.ScheduledTime.Value < dayEndExclusive
                                    && (i.CompanyId == company.CompanyId || candidateStudentIds.Contains(i.StudentId)))
                        .ToListAsync();

                    List<(DateTime start, DateTime end)> dbCompanyBusy = dbConflicts.Where(i => i.CompanyId == company.CompanyId)
                        .Select(i =>
                        {
                            var s = DateTime.SpecifyKind(i.ScheduledTime!.Value, DateTimeKind.Utc);
                            var e = s.AddMinutes(durationsDict.ContainsKey(i.CompanyId) && durationsDict[i.CompanyId] > 0 ? durationsDict[i.CompanyId] : company.InterviewDurationMinutes);
                            return (start: s, end: e);
                        })
                        .ToList();

                    var dbStudentBusy = new Dictionary<int, List<(DateTime start, DateTime end)>>();
                    foreach (var i in dbConflicts)
                    {
                        var dStart = DateTime.SpecifyKind(i.ScheduledTime!.Value, DateTimeKind.Utc);
                        var dEnd = dStart.AddMinutes(durationsDict.ContainsKey(i.CompanyId) && durationsDict[i.CompanyId] > 0 ? durationsDict[i.CompanyId] : company.InterviewDurationMinutes);
                        if (!dbStudentBusy.ContainsKey(i.StudentId)) dbStudentBusy[i.StudentId] = new List<(DateTime, DateTime)>();
                        dbStudentBusy[i.StudentId].Add((dStart, dEnd));
                    }

                    foreach (var opt in optimizedInterviews)
                    {
                        var s = opt.ScheduledTime!.Value;
                        var e = s + companyDuration;
                        if (dbCompanyBusy.Any(b => Overlaps(b.start, b.end, s - buffer, e + buffer)))
                            throw new InvalidOperationException("Scheduling conflict detected for company during save. Try again.");

                        if (dbStudentBusy.TryGetValue(opt.StudentId, out var studentBusyList) && studentBusyList.Any(b => Overlaps(b.start, b.end, s - buffer, e + buffer)))
                            throw new InvalidOperationException("Scheduling conflict detected for a student during save. Try again.");
                    }

                    _context.Interviews.AddRange(optimizedInterviews);
                    await _context.SaveChangesAsync();

                    await tx.CommitAsync();

                    // --- FCM Notifications: fetch tokens and send
                    var scheduledStudentIds = optimizedInterviews.Select(i => i.StudentId).Distinct().ToList();
                    var students = await _context.Students
                        .AsNoTracking()
                        .Where(s => scheduledStudentIds.Contains(s.StudentId))
                        .Select(s => new { s.StudentId, s.FcmToken })
                        .ToListAsync();

                    var studentTokenMap = students.ToDictionary(s => s.StudentId, s => s.FcmToken);

                    _ = Task.Run(async () =>
                    {
                        foreach (var iv in optimizedInterviews)
                        {
                            if (!studentTokenMap.TryGetValue(iv.StudentId, out var token) || string.IsNullOrWhiteSpace(token))
                                continue;

                            var scheduledIso = iv.ScheduledTime?.ToString("o") ?? "";
                            var message = new Message
                            {
                                Token = token,
                                Notification = new FirebaseAdmin.Messaging.Notification
                                {
                                    Title = "Interview Scheduled",
                                    Body = $"{company.Name} scheduled your interview at {scheduledIso}"
                                },
                                Data = new Dictionary<string, string>
                                {
                                    { "InterviewId", iv.InterviewId.ToString() },
                                    { "CompanyId", company.CompanyId.ToString() },
                                    { "CompanyName", company.Name },
                                    { "ScheduledTime", scheduledIso },
                                    { "Type", "InterviewScheduled" }
                                }
                            };

                            try
                            {
                                await FirebaseMessaging.DefaultInstance.SendAsync(message);
                            }
                            catch (Exception ex)
                            {
                                _logger.LogWarning(ex, "FCM send failed for student {StudentId}", iv.StudentId);
                            }
                        }
                    });

                    var result = optimizedInterviews.Select(i => new
                    {
                        i.InterviewId,
                        i.StudentId,
                        i.CompanyId,
                        ScheduledTime = i.ScheduledTime
                    }).ToList();

                    return Ok(new { Message = "Interviews scheduled successfully.", Count = result.Count, Scheduled = result });
                }
                catch (Exception ex)
                {
                    await tx.RollbackAsync();
                    return StatusCode(409, new { Message = "Failed to schedule due to conflicts or an error.", Error = ex.Message });
                }
            }
        }

        [HttpGet("students/{studentId}/availability")]
        public async Task<IActionResult> GetStudentAvailability(int studentId, [FromQuery] DateTime? date = null, [FromQuery] int stepMinutes = 5)
        {
            var companyUserId = GetUserIdFromToken();
            if (companyUserId <= 0) return Unauthorized();

            var company = await _context.Companies.FirstOrDefaultAsync(c => c.UserId == companyUserId);
            if (company == null) return NotFound("Company not found.");

            var activeJobFair = await _context.JobFairs.AsNoTracking().FirstOrDefaultAsync(j => j.IsActive);
            if (activeJobFair == null) return BadRequest("No active job fair.");

            var participation = await _context.CompanyJobFairParticipations
                .FirstOrDefaultAsync(p => p.CompanyId == company.CompanyId && p.JobFairId == activeJobFair.JobFairId);

            if (participation == null) return BadRequest("Company is not registered for the active job fair.");
            if (!participation.IsPresent) return BadRequest("Company must be marked present to schedule interviews.");

            var targetDate = (date ?? activeJobFair.date).Date;

            // interview duration used for candidate slot length
            var durationMinutes = participation.InterviewDurationMinutes > 0 ? participation.InterviewDurationMinutes : company.InterviewDurationMinutes;
            if (durationMinutes <= 0) return BadRequest("Interview duration not configured for this company.");

            var duration = TimeSpan.FromMinutes(durationMinutes);
            var buffer = TimeSpan.FromSeconds(90);

            // Working window
            var (dayStart, hardStop, dayEndExclusive) = GetWorkingWindowUtc(targetDate);

            // Build busy lists for company & student for that date
            var companyInterviews = await _context.Interviews
                .Where(i => i.CompanyId == company.CompanyId
                    && i.JobFairId == activeJobFair.JobFairId
                    && i.ScheduledTime.HasValue
                    && i.ScheduledTime.Value >= dayStart
                    && i.ScheduledTime.Value < dayEndExclusive)
                .ToListAsync();

            var studentInterviews = await _context.Interviews
                .Where(i => i.StudentId == studentId
                    && i.JobFairId == activeJobFair.JobFairId
                    && i.ScheduledTime.HasValue
                    && i.ScheduledTime.Value >= dayStart
                    && i.ScheduledTime.Value < dayEndExclusive)
                .ToListAsync();

            var companyBusy = companyInterviews.Select(i =>
            {
                var s = DateTime.SpecifyKind(i.ScheduledTime!.Value, DateTimeKind.Utc);
                var e = s.AddMinutes(durationMinutes);
                return (start: s, end: e);
            }).ToList();

            var studentBusy = studentInterviews.Select(i =>
            {
                var s = DateTime.SpecifyKind(i.ScheduledTime!.Value, DateTimeKind.Utc);
                var e = s.AddMinutes(durationMinutes); // assume same duration for conflict checking
                return (start: s, end: e);
            }).ToList();

            // If student doesn't exist or not registered for fair, return 404 or validation
            var student = await _context.Students.FirstOrDefaultAsync(s => s.StudentId == studentId);
            if (student == null) return NotFound("Student not found.");

            var studentParticipationExists = await _context.StudentJobFairParticipations
                .AnyAsync(sp => sp.StudentId == studentId && sp.JobFairId == activeJobFair.JobFairId);

            if (!studentParticipationExists)
                return BadRequest("Student is not registered for the active job fair.");

            // iterate slots
            var availableSlots = new List<DateTime>();
            var pointer = DateTime.UtcNow > dayStart ? DateTime.UtcNow : dayStart;
            // normalize pointer to minute boundary
            pointer = DateTime.SpecifyKind(new DateTime(pointer.Year, pointer.Month, pointer.Day, pointer.Hour, pointer.Minute, 0), DateTimeKind.Utc);

            for (var t = pointer; t + duration <= hardStop; t = t.AddMinutes(stepMinutes))
            {
                var candStart = t;
                var candEnd = t + duration;
                var candStartWithBuffer = candStart - buffer;
                var candEndWithBuffer = candEnd + buffer;

                var companyConflict = companyBusy.Any(b => Overlaps(b.start, b.end, candStartWithBuffer, candEndWithBuffer));
                var studentConflict = studentBusy.Any(b => Overlaps(b.start, b.end, candStartWithBuffer, candEndWithBuffer));

                if (!companyConflict && !studentConflict)
                    availableSlots.Add(candStart);
                // optional: limit to reasonable number of slots
                if (availableSlots.Count >= 50) break;
            }

            var result = availableSlots
                .Select(dt => dt.ToString("o"))
                .ToList();

            return Ok(new
            {
                StudentId = studentId,
                CompanyId = company.CompanyId,
                Date = targetDate,
                SlotDurationMinutes = durationMinutes,
                Slots = result
            });
        }

        [Authorize(Roles = "Company")]
        [HttpPost("students/{studentId}/schedule")]
        public async Task<IActionResult> ScheduleInterview(int studentId, [FromBody] ScheduleInterviewDto dto)
        {
            if (dto == null) return BadRequest("Request body required.");
            var scheduledTime = DateTime.SpecifyKind(dto.ScheduledTime, DateTimeKind.Utc);

            var companyUserId = GetUserIdFromToken();
            if (companyUserId <= 0) return Unauthorized();

            var company = await _context.Companies.FirstOrDefaultAsync(c => c.UserId == companyUserId);
            if (company == null) return NotFound("Company not found.");

            var activeJobFair = await _context.JobFairs.AsNoTracking().FirstOrDefaultAsync(j => j.IsActive);
            if (activeJobFair == null) return BadRequest("No active job fair.");

            var participation = await _context.CompanyJobFairParticipations
                .FirstOrDefaultAsync(p => p.CompanyId == company.CompanyId && p.JobFairId == activeJobFair.JobFairId);

            if (participation == null) return BadRequest("Company not registered for the active job fair.");
            if (!participation.IsPresent) return BadRequest("Company must be marked present to schedule.");

            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.StudentId == studentId);
            if (student == null) return NotFound("Student not found.");

            var studentParticipation = await _context.StudentJobFairParticipations
                .AnyAsync(sp => sp.StudentId == studentId && sp.JobFairId == activeJobFair.JobFairId);

            if (!studentParticipation) return BadRequest("Student not registered for the active job fair.");

            // duration and buffers
            var durationMinutes = participation.InterviewDurationMinutes > 0 ? participation.InterviewDurationMinutes : company.InterviewDurationMinutes;
            if (durationMinutes <= 0) return BadRequest("Interview duration not configured.");
            var duration = TimeSpan.FromMinutes(durationMinutes);
            var buffer = TimeSpan.FromSeconds(90);

            // Basic window check (same working window as availability)
            var windowDate = GetDateInJobFairTimeZone(scheduledTime);
            var (dayStart, hardStop, dayEndExclusive) = GetWorkingWindowUtc(windowDate);
            if (scheduledTime < DateTime.UtcNow) return BadRequest("Scheduled time must be in the future.");
            if (scheduledTime < dayStart || scheduledTime + duration > hardStop) return BadRequest("Scheduled time outside allowed window.");

            // Build busy lists for this date
            var companyConflicts = await _context.Interviews
                .Where(i => i.CompanyId == company.CompanyId
                    && i.JobFairId == activeJobFair.JobFairId
                    && i.ScheduledTime.HasValue
                    && i.ScheduledTime.Value >= dayStart
                    && i.ScheduledTime.Value < dayEndExclusive)
                .Select(i => new { Start = i.ScheduledTime!.Value, End = i.ScheduledTime!.Value.AddMinutes(durationMinutes) })
                .ToListAsync();

            var studentConflicts = await _context.Interviews
                .Where(i => i.StudentId == studentId
                    && i.JobFairId == activeJobFair.JobFairId
                    && i.ScheduledTime.HasValue
                    && i.ScheduledTime.Value >= dayStart
                    && i.ScheduledTime.Value < dayEndExclusive)
                .Select(i => new { Start = i.ScheduledTime!.Value, End = i.ScheduledTime!.Value.AddMinutes(durationMinutes) })
                .ToListAsync();

            var candStartWithBuffer = scheduledTime - buffer;
            var candEndWithBuffer = scheduledTime + duration + buffer;

            bool companyBusy = companyConflicts.Any(b => Overlaps(DateTime.SpecifyKind(b.Start, DateTimeKind.Utc), DateTime.SpecifyKind(b.End, DateTimeKind.Utc), candStartWithBuffer, candEndWithBuffer));
            bool studentBusy = studentConflicts.Any(b => Overlaps(DateTime.SpecifyKind(b.Start, DateTimeKind.Utc), DateTime.SpecifyKind(b.End, DateTimeKind.Utc), candStartWithBuffer, candEndWithBuffer));

            if (companyBusy) return Conflict(new { Message = "Company has a conflicting interview at that time." });
            if (studentBusy) return Conflict(new { Message = "Student has a conflicting interview at that time." });

            // Create interview (optionally link to request if provided)
            var interview = new Interview
            {
                CompanyId = company.CompanyId,
                StudentId = studentId,
                RequestId = dto.RequestId ?? 0,
                JobFairId = activeJobFair.JobFairId,
                ScheduledTime = scheduledTime,
                Status = InterviewStatus.Queued,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.Interviews.Add(interview);
            await _context.SaveChangesAsync();

            var companyJobs = await _context.Jobs
                .AsNoTracking()
                .Where(j => j.CompanyId == company.CompanyId)
                .Select(j => new { j.JobTitle, j.JobType, j.NumberOfJobs })
                .ToListAsync();

            try
            {
                var scheduledIso = scheduledTime.ToString("o");

                if (!string.IsNullOrWhiteSpace(student.FcmToken))
                {
                    var msg = new Message
                    {
                        Token = student.FcmToken,
                        Notification = new FirebaseAdmin.Messaging.Notification
                        {
                            Title = "Interview Scheduled",
                            Body = $"{company.Name} scheduled an interview for you at {scheduledIso}"
                        },
                        Data = new Dictionary<string, string>
                        {
                            { "InterviewId", interview.InterviewId.ToString() },
                            { "CompanyId", company.CompanyId.ToString() },
                            { "ScheduledTime", scheduledIso },
                            { "Type", "InterviewScheduled" }
                        }
                    };
                    await FirebaseMessaging.DefaultInstance.SendAsync(msg);
                }

                if (!string.IsNullOrWhiteSpace(student.User?.Email))
                {
                    var jobsHtml = companyJobs.Any()
                        ? string.Join("", companyJobs.Select(j => $"<li><strong>{j.JobTitle}</strong> ({j.JobType}) - Openings: {j.NumberOfJobs}</li>"))
                        : "<li>No active job postings listed.</li>";

                    var emailBody = $@"
<p>Dear {student.User.FullName},</p>
<p>Your interview has been scheduled.</p>
<p><strong>Company:</strong> {company.Name}<br/>
<strong>Time (UTC):</strong> {scheduledIso}</p>

<h3>Company Profile</h3>
<p><strong>Industry:</strong> {company.Industry ?? "N/A"}<br/>
<strong>Website:</strong> {(string.IsNullOrWhiteSpace(company.Website) ? "N/A" : company.Website)}<br/>
<strong>Description:</strong> {company.Description ?? "N/A"}</p>

<h3>Job Postings</h3>
<ul>{jobsHtml}</ul>

<p>Best of luck,<br/>Job Fair Team</p>";

                    await _mailService.SendMailAsync(student.User.Email, "Interview Scheduled", emailBody);
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to send interview scheduled notifications for InterviewId={InterviewId}", interview.InterviewId);
            }

            return Ok(new
            {
                Message = "Interview scheduled.",
                InterviewId = interview.InterviewId,
                CompanyId = company.CompanyId,
                StudentId = studentId,
                ScheduledTime = scheduledTime
            });
        }

        [Authorize(Roles = "Company")]
        [HttpPost("interviews/{interviewId}/start")]
        public async Task<IActionResult> StartInterview(int interviewId)
        {
            var companyUserId = GetUserIdFromToken();
            if (companyUserId <= 0) return Unauthorized();

            var company = await _context.Companies.FirstOrDefaultAsync(c => c.UserId == companyUserId);
            if (company == null) return NotFound("Company not found.");

            var interview = await _context.Interviews
                .FirstOrDefaultAsync(i => i.InterviewId == interviewId && i.CompanyId == company.CompanyId);

            if (interview == null) return NotFound("Interview not found.");

            if (interview.Status == InterviewStatus.Hired || interview.Status == InterviewStatus.Shortlisted || interview.Status == InterviewStatus.Rejected)
                return BadRequest("Interview is already completed.");

            interview.Status = InterviewStatus.InProgress;
            interview.StartedAt ??= DateTime.UtcNow;
            interview.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Interview started.",
                interview.InterviewId,
                interview.StartedAt,
                Status = interview.Status.ToString()
            });
        }

        [Authorize(Roles = "Company")]
        [HttpPost("interviews/{interviewId}/complete")]
        public async Task<IActionResult> CompleteInterview(int interviewId, [FromBody] InterviewCompleteDto dto)
        {
            if (dto == null || string.IsNullOrWhiteSpace(dto.ResultStatus))
                return BadRequest("ResultStatus is required.");

            var companyUserId = GetUserIdFromToken();
            if (companyUserId <= 0) return Unauthorized();

            var company = await _context.Companies.FirstOrDefaultAsync(c => c.UserId == companyUserId);
            if (company == null) return NotFound("Company not found.");

            var interview = await _context.Interviews
                .FirstOrDefaultAsync(i => i.InterviewId == interviewId && i.CompanyId == company.CompanyId);

            if (interview == null) return NotFound("Interview not found.");

            if (interview.Status == InterviewStatus.Hired || interview.Status == InterviewStatus.Shortlisted || interview.Status == InterviewStatus.Rejected)
                return BadRequest("Interview already completed.");

            if (!Enum.TryParse<InterviewStatus>(dto.ResultStatus, true, out var parsedStatus) ||
                (parsedStatus != InterviewStatus.Hired && parsedStatus != InterviewStatus.Shortlisted && parsedStatus != InterviewStatus.Rejected))
            {
                return BadRequest("ResultStatus must be one of: Hired, Shortlisted, Rejected.");
            }

            interview.Status = parsedStatus;
            interview.StartedAt ??= DateTime.UtcNow;
            interview.EndedAt = DateTime.UtcNow;
            interview.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            try
            {
                var student = await _context.Students
                    .Include(s => s.User)
                    .FirstOrDefaultAsync(s => s.StudentId == interview.StudentId);

                if (student != null)
                {
                    if (!string.IsNullOrWhiteSpace(student.FcmToken))
                    {
                        var push = new Message
                        {
                            Token = student.FcmToken,
                            Notification = new FirebaseAdmin.Messaging.Notification
                            {
                                Title = "Interview Result Updated",
                                Body = $"{company.Name} marked your interview result as {parsedStatus}."
                            },
                            Data = new Dictionary<string, string>
                            {
                                { "InterviewId", interview.InterviewId.ToString() },
                                { "CompanyId", company.CompanyId.ToString() },
                                { "ResultStatus", parsedStatus.ToString() },
                                { "Type", "InterviewCompleted" }
                            }
                        };
                        await FirebaseMessaging.DefaultInstance.SendAsync(push);
                    }

                    if (!string.IsNullOrWhiteSpace(student.User?.Email))
                    {
                        var body = $@"
<p>Dear {student.User.FullName},</p>
<p>Your interview with <strong>{company.Name}</strong> has been completed.</p>
<p><strong>Result:</strong> {parsedStatus}</p>
<p>Regards,<br/>Job Fair Team</p>";

                        await _mailService.SendMailAsync(student.User.Email, "Interview Result", body);
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to send completion notifications for InterviewId={InterviewId}", interview.InterviewId);
            }

            return Ok(new
            {
                Message = "Interview completed and result recorded.",
                interview.InterviewId,
                interview.StartedAt,
                interview.EndedAt,
                Status = interview.Status.ToString()
            });
        }
        private static (DateTime dayStartUtc, DateTime hardStopUtc, DateTime dayEndExclusiveUtc) GetWorkingWindowUtc(DateTime localDate)
        {
            var date = DateTime.SpecifyKind(localDate.Date, DateTimeKind.Unspecified);
            var dayStartLocal = date.Add(WorkingDayStartLocal);
            var hardStopLocal = date.Add(WorkingDayEndLocal);
            var dayEndExclusiveLocal = date.AddDays(1);

            return (
                TimeZoneInfo.ConvertTimeToUtc(dayStartLocal, JobFairTimeZone),
                TimeZoneInfo.ConvertTimeToUtc(hardStopLocal, JobFairTimeZone),
                TimeZoneInfo.ConvertTimeToUtc(dayEndExclusiveLocal, JobFairTimeZone)
            );
        }

        private static DateTime GetDateInJobFairTimeZone(DateTime utcDateTime)
        {
            var utc = DateTime.SpecifyKind(utcDateTime, DateTimeKind.Utc);
            return TimeZoneInfo.ConvertTimeFromUtc(utc, JobFairTimeZone).Date;
        }

        private static TimeZoneInfo ResolveJobFairTimeZone()
        {
            try
            {
                return TimeZoneInfo.FindSystemTimeZoneById("Pakistan Standard Time");
            }
            catch
            {
                try
                {
                    return TimeZoneInfo.FindSystemTimeZoneById("Asia/Karachi");
                }
                catch
                {
                    return TimeZoneInfo.Utc;
                }
            }
        }

        // Helper: check interval overlap (exclusive end)
        private static bool Overlaps(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd)
        {
            return aStart < bEnd && bStart < aEnd;
        }
        

        [Authorize(Roles = "Company")]
        [HttpPost("requests")]
        public async Task<IActionResult> CreateCompanyRequest([FromBody] CompanyRequestDto dto)
        {
            if (dto == null) return BadRequest("Request body is required.");

            var userId = GetUserIdFromToken();
            if (userId <= 0) return Unauthorized();

            var company = await _context.Companies.FirstOrDefaultAsync(c => c.UserId == userId);
            if (company == null) return NotFound("Company not found.");

            // Use active job fair if JobFairId omitted or validate provided JobFairId
            var activeJobFair = await _context.JobFairs.AsNoTracking().FirstOrDefaultAsync(j => j.IsActive);
            if (activeJobFair == null) return BadRequest("No active job fair to attach this request to.");

            if (dto.JobFairId.HasValue && dto.JobFairId.Value != activeJobFair.JobFairId)
                return BadRequest("Requests can only be submitted for the currently active job fair.");

            var req = new Models.CompanyRequest
            {
                CompanyId = company.CompanyId,
                JobFairId = activeJobFair.JobFairId,
                Type = dto.Type,
                Description = dto.Description,
                Quantity = dto.Quantity,
                AdditionalInfo = dto.AdditionalInfo,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                Status = Models.CompanyRequestStatus.Pending
            };

            _context.Add(req);
            await _context.SaveChangesAsync();

            // Reload company data for SignalR broadcast
            req = await _context.CompanyRequests.Include(r => r.Company).FirstOrDefaultAsync(r => r.CompanyRequestId == req.CompanyRequestId);

            // Notify admins in real-time
            try
            {
                var hub = HttpContext.RequestServices.GetService(typeof(Microsoft.AspNetCore.SignalR.IHubContext<JobFairPortal.Hubs.CompanyRequestsHub>)) as Microsoft.AspNetCore.SignalR.IHubContext<JobFairPortal.Hubs.CompanyRequestsHub>;
                if (hub != null)
                {
                    var payload = new
                    {
                        req.CompanyRequestId,
                        req.CompanyId,
                        CompanyName = req.Company?.Name ?? "Unknown",
                        req.JobFairId,
                        Type = req.Type.ToString(),
                        req.Description,
                        req.Quantity,
                        req.AdditionalInfo,
                        Status = req.Status.ToString(),
                        req.AdminNote,
                        req.CreatedAt,
                        req.UpdatedAt,
                        req.FulfilledAt
                    };
                    await hub.Clients.All.SendAsync("CompanyRequestCreated", payload);
                }
            }
            catch
            {
                // ignore
            }

            return Ok(new { Message = "Request submitted.", RequestId = req.CompanyRequestId });
        }

        [Authorize(Roles = "Company")]
        [HttpGet("requests")]
        public async Task<IActionResult> GetMyRequests()
        {
            var userId = GetUserIdFromToken();
            if (userId <= 0) return Unauthorized();

            var company = await _context.Companies.FirstOrDefaultAsync(c => c.UserId == userId);
            if (company == null) return NotFound("Company not found.");

            var requests = await _context.CompanyRequests
                .Where(r => r.CompanyId == company.CompanyId)
                .OrderByDescending(r => r.CreatedAt)
                .Select(r => new
                {
                    r.CompanyRequestId,
                    r.Type,
                    r.Description,
                    r.Quantity,
                    r.AdditionalInfo,
                    r.Status,
                    r.AdminNote,
                    r.CreatedAt,
                    r.UpdatedAt,
                    r.FulfilledAt,
                    r.JobFairId
                })
                .ToListAsync();

            return Ok(requests);
        }

        [Authorize(Roles = "Company")]
        [HttpPut("requests/{id}/cancel")]
        public async Task<IActionResult> CancelRequest(int id)
        {
            var userId = GetUserIdFromToken();
            if (userId <= 0) return Unauthorized();

            var company = await _context.Companies.FirstOrDefaultAsync(c => c.UserId == userId);
            if (company == null) return NotFound("Company not found.");

            var req = await _context.CompanyRequests.FirstOrDefaultAsync(r => r.CompanyRequestId == id && r.CompanyId == company.CompanyId);
            if (req == null) return NotFound("Request not found or access denied.");

            // Only allow cancellation if not already fulfilled or rejected
            if (req.Status == CompanyRequestStatus.Fulfilled || req.Status == CompanyRequestStatus.Rejected)
                return BadRequest("Cannot cancel a request that is already fulfilled or rejected.");

            req.Status = CompanyRequestStatus.Cancelled;
            req.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            // Notify admins via SignalR
            try
            {
                var hub = HttpContext.RequestServices.GetService(typeof(Microsoft.AspNetCore.SignalR.IHubContext<JobFairPortal.Hubs.CompanyRequestsHub>)) as Microsoft.AspNetCore.SignalR.IHubContext<JobFairPortal.Hubs.CompanyRequestsHub>;
                if (hub != null)
                {
                    var payload = new
                    {
                        req.CompanyRequestId,
                        req.CompanyId,
                        CompanyName = company?.Name ?? "Unknown",
                        req.JobFairId,
                        Type = req.Type.ToString(),
                        req.Description,
                        req.Quantity,
                        req.AdditionalInfo,
                        Status = req.Status.ToString(),
                        req.AdminNote,
                        req.CreatedAt,
                        req.UpdatedAt,
                        req.FulfilledAt
                    };
                    await hub.Clients.All.SendAsync("CompanyRequestUpdated", payload);
                }
            }
            catch { }

            return Ok(new { Message = "Request cancelled successfully." });
        }

        [Authorize(Roles = "Company")]
        [HttpPost("register-fcm-token")]
        public async Task<IActionResult> RegisterFcmToken([FromBody] FcmTokenValidationDto dto)
        {
            var userId = GetUserIdFromToken();
            if (userId <= 0) return Unauthorized();

            if (string.IsNullOrWhiteSpace(dto.Token))
                return BadRequest("FCM token is required.");

            var company = await _context.Companies.FirstOrDefaultAsync(c => c.UserId == userId);
            if (company == null)
                return NotFound("Company not found.");

            company.FcmToken = dto.Token;
            _context.Companies.Update(company);
            await _context.SaveChangesAsync();

            return Ok(new { Message = "FCM token registered successfully." });
        }
    }
}
