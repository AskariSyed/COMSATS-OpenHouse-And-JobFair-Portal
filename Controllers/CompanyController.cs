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
    }
}
