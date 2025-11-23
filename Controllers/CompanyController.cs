using JobFairPortal.Data;
using JobFairPortal.DTOs;
using JobFairPortal.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace JobFairPortal.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    
    public class CompanyController : ControllerBase
    {
        private readonly JobFairRecruitmentDbContext _context;

        public CompanyController(JobFairRecruitmentDbContext context)
        {
            _context = context;
        }
        [HttpGet("finalyear-projects")]
        public async Task<IActionResult> GetFinalYearProjects()
        {
            var projects = await _context.Projects
                .Where(p => p.Type == ProjectType.FinalYear)
                .Select(p => new ProjectListDto
                {
                    ProjectId = p.ProjectId,
                    Title = p.Title,
                    Description = p.Description,
                    Skills= p.Skills,
                    DemoUrl = p.DemoUrl,
                  
                })
                .ToListAsync();

            return Ok(projects);
        }
        [HttpGet("students")]
public async Task<IActionResult> GetAllStudents()
{
    var students = await _context.Students
        .Include(s => s.User)
        .Select(s => new StudentListDto
        {
            StudentId = s.StudentId,
            Name = s.User.FullName,
            RegistrationNo = s.RegistrationNo,
            Department = s.Department,
            CGPA = (float)s.CGPA,
            Skills = s.Skills,
            ProfilePicUrl = s.ProfilePicUrl
        })
        .ToListAsync();

    return Ok(students);
}
[HttpGet("students/search-by-skill")]
public async Task<IActionResult> SearchStudentsBySkill([FromQuery] string skill)
{
    if (string.IsNullOrWhiteSpace(skill))
        return BadRequest("Skill parameter is required.");

    var students = await _context.Students
        .Include(s => s.User)
        .Where(s => s.Skills != null && s.Skills.Any(sk => sk.ToLower().Contains(skill.ToLower())))
        .Select(s => new StudentListDto
        {
            StudentId = s.StudentId,
            Name = s.User.FullName,
            RegistrationNo = s.RegistrationNo,
            Department = s.Department,
            CGPA = (float)s.CGPA,
            Skills = s.Skills,
            ProfilePicUrl = s.ProfilePicUrl
        })
        .ToListAsync();

    return Ok(students);
}
[HttpGet("students/search-by-registration")]
public async Task<IActionResult> SearchStudentsByRegistration([FromQuery] string registrationNo)
{
    if (string.IsNullOrWhiteSpace(registrationNo))
        return BadRequest("Registration number parameter is required.");

    var students = await _context.Students
        .Include(s => s.User)
        .Where(s => s.RegistrationNo.ToLower().Contains(registrationNo.ToLower()))
        .Select(s => new StudentListDto
        {
            StudentId = s.StudentId,
            Name = s.User.FullName,
            RegistrationNo = s.RegistrationNo,
            Department = s.Department,
            CGPA = (float)s.CGPA,
            Skills = s.Skills,
            ProfilePicUrl = s.ProfilePicUrl
        })
        .ToListAsync();

    return Ok(students);
}
[HttpGet("students/search-by-department")]
public async Task<IActionResult> SearchStudentsByDepartment([FromQuery] string department)
{
    if (string.IsNullOrWhiteSpace(department))
        return BadRequest("Department parameter is required.");

    var students = await _context.Students
        .Include(s => s.User)
        .Where(s => s.Department.ToLower().Contains(department.ToLower()))
        .Select(s => new StudentListDto
        {
            StudentId = s.StudentId,
            Name = s.User.FullName,
            RegistrationNo = s.RegistrationNo,
            Department = s.Department,
            CGPA = (float)s.CGPA,
            Skills = s.Skills,
            ProfilePicUrl = s.ProfilePicUrl
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
    var student = await _context.Students
        .Include(s => s.User)
        .Include(s => s.Educations)
        .Include(s => s.Certifications)
        .Include(s => s.Achievements)
        .Include(s => s.Experiences)
        .Include(s => s.StudentProjects)
            .ThenInclude(sp => sp.Project)
        .Include(s => s.ContactLinks)
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
            student.User.UserId,
            student.User.FullName,
            student.User.Email,
            student.User.Phone,
            student.User.IsActive,
            student.User.CreatedAt
        },

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
        Experiences = student.Experiences.Select(e => new
        {
            e.ExperienceId,
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
            cl.LinkId,
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
        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> CreateNotice([FromBody] NoticeCreateDto dto)
        {
            // Find active job fair
            var activeJobFair = await _context.JobFairs.FirstOrDefaultAsync(j => j.IsActive);
            if (activeJobFair == null)
                return BadRequest("No active Job Fair found. Cannot create notice.");

            var notice = new Notice
            {
                Title = dto.Title,
                Content = dto.Content,
                Audience = dto.Audience,
                JobFairId = activeJobFair.JobFairId,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.Notices.Add(notice);
            await _context.SaveChangesAsync();

            return Ok(new NoticeResponseDto
            {
                NoticeId = notice.NoticeId,
                Title = notice.Title,
                Content = notice.Content,
                Audience = notice.Audience.ToString(),
                CreatedAt = notice.CreatedAt
            });
        }

        // -----------------------------
        // 2. Get Notices (Dynamic based on Role)
        // -----------------------------
        [HttpGet]
        [Authorize] // Requires login (Admin, Student, or Company)
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

        // Helper method to get User ID from token
        private int GetUserIdFromToken()
{
    var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
    if (int.TryParse(userIdClaim, out int userId))
        return userId;
    return 0;
}
    }
}
