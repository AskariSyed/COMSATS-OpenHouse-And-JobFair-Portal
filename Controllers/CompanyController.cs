using JobFairPortal.Data;
using JobFairPortal.DTOs;
using JobFairPortal.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FirebaseAdmin.Messaging;
using System.Security.Claims;

namespace JobFairPortal.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    
    public class CompanyController : ControllerBase
    {
        private readonly JobFairRecruitmentDbContext _context;
        private readonly ILogger<AdminController> _logger;

        public CompanyController(JobFairRecruitmentDbContext context)
        {
            _context = context;
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
            
            // Get current company if authenticated, otherwise return all students
            Company? currentCompany = null;
            if (companyIdClaim > 0)
            {
                currentCompany = await _context.Companies
                    .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);
            }

            var students = await _context.Students
                .Include(s => s.User)
                .Include(s => s.InterviewRequests)
                .Select(s => new
                {
                    StudentId = s.StudentId,
                    Name = s.User.FullName,
                    RegistrationNo = s.RegistrationNo,
                    Department = s.Department,
                    CGPA = (float)s.CGPA,
                    Skills = s.Skills,
                    ProfilePicUrl = s.ProfilePicUrl,
                    
                    // --- Interview Request Status (if company is logged in) ---
                    InterviewRequest = currentCompany != null 
                        ? new
                        {
                            HasRequest = s.InterviewRequests.Any(ir => ir.CompanyId == currentCompany.CompanyId),
                            Status = s.InterviewRequests
                                .Where(ir => ir.CompanyId == currentCompany.CompanyId)
                                .Select(ir => ir.Status.ToString())
                                .FirstOrDefault(),
                            RequestId = s.InterviewRequests
                                .Where(ir => ir.CompanyId == currentCompany.CompanyId)
                                .Select(ir => (int?)ir.RequestId)
                                .FirstOrDefault(),
                            RequestDate = s.InterviewRequests
                                .Where(ir => ir.CompanyId == currentCompany.CompanyId)
                                .Select(ir => ir.CreatedAt)
                                .FirstOrDefault(),
                            ResponseDate = s.InterviewRequests
                                .Where(ir => ir.CompanyId == currentCompany.CompanyId)
                                .Select(ir => ir.UpdatedAt)
                                .FirstOrDefault(),
                            RequestedBy=s.InterviewRequests
                                .Where(ir => ir.CompanyId == currentCompany.CompanyId)
                                .Select(ir => ir.RequestedBy)
                                .FirstOrDefault()
                        }
                        : null
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
            Company? currentCompany = null;
            if (companyIdClaim > 0)
            {
                currentCompany = await _context.Companies
                    .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);
            }

            var students = await _context.Students
                .Include(s => s.User)
                .Include(s => s.InterviewRequests)
                .Where(s => s.Skills != null && s.Skills.Any(sk => sk.ToLower().Contains(skill.ToLower())))
                .Select(s => new
                {
                    StudentId = s.StudentId,
                    Name = s.User.FullName,
                    RegistrationNo = s.RegistrationNo,
                    Department = s.Department,
                    CGPA = (float)s.CGPA,
                    Skills = s.Skills,
                    ProfilePicUrl = s.ProfilePicUrl,
                    
                    // --- Interview Request Status ---
                    InterviewRequest = currentCompany != null
                        ? new
                        {
                            HasRequest = s.InterviewRequests.Any(ir => ir.CompanyId == currentCompany.CompanyId),
                            Status = s.InterviewRequests
                                .Where(ir => ir.CompanyId == currentCompany.CompanyId)
                                .Select(ir => ir.Status.ToString())
                                .FirstOrDefault(),
                            RequestId = s.InterviewRequests
                                .Where(ir => ir.CompanyId == currentCompany.CompanyId)
                                .Select(ir => (int?)ir.RequestId)
                                .FirstOrDefault(),
                            RequestDate = s.InterviewRequests
                                .Where(ir => ir.CompanyId == currentCompany.CompanyId)
                                .Select(ir => ir.CreatedAt)
                                .FirstOrDefault()
                        }
                        : null
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
            Company? currentCompany = null;
            if (companyIdClaim > 0)
            {
                currentCompany = await _context.Companies
                    .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);
            }

            var students = await _context.Students
                .Include(s => s.User)
                .Include(s => s.InterviewRequests)
                .Where(s => s.RegistrationNo.ToLower().Contains(registrationNo.ToLower()))
                .Select(s => new
                {
                    StudentId = s.StudentId,
                    Name = s.User.FullName,
                    RegistrationNo = s.RegistrationNo,
                    Department = s.Department,
                    CGPA = (float)s.CGPA,
                    Skills = s.Skills,
                    ProfilePicUrl = s.ProfilePicUrl,
                    
                    // --- Interview Request Status ---
                    InterviewRequest = currentCompany != null
                        ? new
                        {
                            HasRequest = s.InterviewRequests.Any(ir => ir.CompanyId == currentCompany.CompanyId),
                            Status = s.InterviewRequests
                                .Where(ir => ir.CompanyId == currentCompany.CompanyId)
                                .Select(ir => ir.Status.ToString())
                                .FirstOrDefault(),
                            RequestId = s.InterviewRequests
                                .Where(ir => ir.CompanyId == currentCompany.CompanyId)
                                .Select(ir => (int?)ir.RequestId)
                                .FirstOrDefault(),
                            RequestDate = s.InterviewRequests
                                .Where(ir => ir.CompanyId == currentCompany.CompanyId)
                                .Select(ir => ir.CreatedAt)
                                .FirstOrDefault()
                        }
                        : null
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
            Company? currentCompany = null;
            if (companyIdClaim > 0)
            {
                currentCompany = await _context.Companies
                    .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);
            }

            var students = await _context.Students
                .Include(s => s.User)
                .Include(s => s.InterviewRequests)
                .Where(s => s.Department.ToLower().Contains(department.ToLower()))
                .Select(s => new
                {
                    StudentId = s.StudentId,
                    Name = s.User.FullName,
                    RegistrationNo = s.RegistrationNo,
                    Department = s.Department,
                    CGPA = (float)s.CGPA,
                    Skills = s.Skills,
                    ProfilePicUrl = s.ProfilePicUrl,
                    
                    // --- Interview Request Status ---
                    InterviewRequest = currentCompany != null
                        ? new
                        {
                            HasRequest = s.InterviewRequests.Any(ir => ir.CompanyId == currentCompany.CompanyId),
                            Status = s.InterviewRequests
                                .Where(ir => ir.CompanyId == currentCompany.CompanyId)
                                .Select(ir => ir.Status.ToString())
                                .FirstOrDefault(),
                            RequestId = s.InterviewRequests
                                .Where(ir => ir.CompanyId == currentCompany.CompanyId)
                                .Select(ir => (int?)ir.RequestId)
                                .FirstOrDefault(),
                            RequestDate = s.InterviewRequests
                                .Where(ir => ir.CompanyId == currentCompany.CompanyId)
                                .Select(ir => ir.CreatedAt)
                                .FirstOrDefault()
                        }
                        : null
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

            // Build comprehensive student profile
            var response = new
            {
                // --- Main Student Info ---
                student.StudentId,
                student.RegistrationNo,
                student.Department,
                student.ProfilePicUrl,
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
            // Get company from token/user context
            var company = await _context.Companies
                .Include(c => c.Interviews)
                .Include(c => c.InterviewRequests)
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
                .Where(i => i.CompanyId == company.CompanyId && i.ScheduledTime.HasValue && i.ScheduledTime <= DateTime.UtcNow.AddDays(30))
                .Include(i => i.Student)
                    .ThenInclude(s => s.User)
                .Select(i => new
                {
                    i.InterviewId,
                    StudentName = i.Student.User.FullName,
                    StudentId = i.Student.StudentId,
                    i.Student.RegistrationNo,
                    i.ScheduledTime,
                    i.Status,
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

            // Build response
            var analytics = new
            {
                CompanyId = company.CompanyId,
                CompanyName = company.Name,
        
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

    // Create Interview record
    var interview = new Interview
    {
        CompanyId = company.CompanyId,
        StudentId = request.StudentId,
        RequestId = request.RequestId,
        Status = InterviewStatus.Queued,
        ScheduledTime = dto.ScheduledTime,
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
            StudentProfilePic = r.Student.ProfilePicUrl,
            StudentSkills = r.Student.Skills,
            Status = r.Status.ToString(),
            RejectionReason = r.ReasonForReject,
            RequestDate = r.CreatedAt,
            ResponseDate = r.UpdatedAt
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

            var job = new Job
            {
                CompanyId = company.CompanyId,
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
                .FirstOrDefaultAsync(c => c.UserId == companyIdClaim);

            if (company == null)
                return NotFound("Company not found.");

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
                    ArrivalStatus = company.ArrivalStatus.ToString(),
                    IsPresent = company.IsPresent
                },

                // --- Timestamps ---
                CreatedAt = company.CreatedAt,
                UpdatedAt = company.UpdatedAt
            };

            return Ok(profile);
        }

        /// <summary>
        /// Company: Edit profile (logo, website, contact links)
        /// </summary>
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

            company.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Profile updated successfully.",
                CompanyId = company.CompanyId,
                LogoUrl = company.LogoUrl,
                Website = company.Website
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
    }
}
