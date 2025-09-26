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
    //[Authorize(Roles = "Student")]
    public class StudentController : ControllerBase
    {
        private readonly JobFairRecruitmentDbContext _context;
        private readonly ILogger<StudentController> _logger;

        public StudentController(JobFairRecruitmentDbContext context, ILogger<StudentController> logger)
        {
            _context = context;
            _logger = logger;
        }
        [HttpPost("{studentId}/profile-pic")]
        public async Task<IActionResult> UploadProfilePic(int studentId, [FromForm] FileUploadDto dto)
        {
            var file = dto.File;
            var student = await _context.Students.Include(s => s.User).FirstOrDefaultAsync(s => s.StudentId == studentId);
            if (student == null)
                return NotFound("Student not found.");

            if (file == null || file.Length == 0)
                return BadRequest("No file uploaded.");

            var uploadsFolder = Path.Combine("uploads", "student", "profilepics");
            Directory.CreateDirectory(uploadsFolder);

            var fileName = $"{student.RegistrationNo}_{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
            var filePath = Path.Combine(uploadsFolder, fileName);

            // Save file
            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            // Update student profile pic url
            student.ProfilePicUrl = $"/uploads/student/profilepics/{fileName}";
            student.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Profile picture uploaded.", ProfilePicUrl = student.ProfilePicUrl });
        }

        // 2. Upload/Change CV
        [HttpPost("{studentId}/cv")]
        public async Task<IActionResult> UploadCV(int studentId, [FromForm] FileUploadDto dto)
        {
            var file = dto.File;
            var student = await _context.Students.Include(s => s.User).FirstOrDefaultAsync(s => s.StudentId == studentId);
            if (student == null)
                return NotFound("Student not found.");

            if (file == null || file.Length == 0)
                return BadRequest("No file uploaded.");

            var uploadsFolder = Path.Combine("uploads", "student", "cv");
            Directory.CreateDirectory(uploadsFolder);

            var fileName = $"{student.RegistrationNo}_{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
            var filePath = Path.Combine(uploadsFolder, fileName);

            // Save file
            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            // Update student CV url
            student.CVUrl = $"/uploads/student/cv/{fileName}";
            student.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { Message = "CV uploaded.", CVUrl = student.CVUrl });
        }

        // 3. Complete Profile
     
        [HttpPut("{studentId}/complete-profile")]
        public async Task<IActionResult> CompleteProfile(int studentId, [FromBody] CompleteProfileDto dto)
        {
            var student = await _context.Students.Include(s => s.User).FirstOrDefaultAsync(s => s.StudentId == studentId);
            if (student == null)
                return NotFound("Student not found.");

            if (!string.IsNullOrWhiteSpace(dto.CVUrl))
                student.CVUrl = dto.CVUrl;

            if (!string.IsNullOrWhiteSpace(dto.FypDemoUrl))
                student.FypDemoUrl = dto.FypDemoUrl;

            if (!string.IsNullOrWhiteSpace(dto.FypTitle))
                student.FypTitle = dto.FypTitle;

            if (!string.IsNullOrWhiteSpace(dto.FypDescription))
                student.FypDescription = dto.FypDescription;

            if (dto.CGPA.HasValue)
                student.CGPA = dto.CGPA.Value;

            if (dto.Skills != null && dto.Skills.Length > 0)
                student.Skills = dto.Skills;

            student.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Profile updated successfully." });
        }

        // DTO for multiple skills
       

        [HttpPost("{studentId}/skills/add")]
        public async Task<IActionResult> AddSkills(int studentId, [FromBody] SkillsDto dto)
        {
            if (dto.Skills == null || dto.Skills.Length == 0)
                return BadRequest("No skills provided.");

            var student = await _context.Students.FirstOrDefaultAsync(s => s.StudentId == studentId);
            if (student == null)
                return NotFound("Student not found.");

            var existingSkills = student.Skills?.ToList() ?? new List<string>();

            foreach (var skill in dto.Skills)
            {
                if (!string.IsNullOrWhiteSpace(skill) &&
                    !existingSkills.Contains(skill, StringComparer.OrdinalIgnoreCase))
                {
                    existingSkills.Add(skill.Trim());
                }
            }

            student.Skills = existingSkills.ToArray();
            student.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Skills added.", Skills = student.Skills });
        }

        [HttpPost("{studentId}/skills/remove")]
        public async Task<IActionResult> RemoveSkill(int studentId, [FromBody] string skill)
        {
            var student = await _context.Students.FirstOrDefaultAsync(s => s.StudentId == studentId);
            if (student == null)
                return NotFound("Student not found.");

            if (string.IsNullOrWhiteSpace(skill))
                return BadRequest("Skill cannot be empty.");

            var skills = student.Skills?.ToList() ?? new List<string>();
            var removed = skills.RemoveAll(s => string.Equals(s, skill, StringComparison.OrdinalIgnoreCase));
            if (removed == 0)
                return BadRequest("Skill not found.");

            student.Skills = skills.ToArray();
            student.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Skill removed.", Skills = student.Skills });
        }

        /// <summary>
        /// Replace all skills for a student (PUT).
        /// </summary>
        [HttpPut("{studentId}/skills")]
        public async Task<IActionResult> PutSkills(int studentId, [FromBody] SkillsDto dto)
        {
            if (dto.Skills == null || dto.Skills.Length == 0)
                return BadRequest("No skills provided.");

            var student = await _context.Students.FirstOrDefaultAsync(s => s.StudentId == studentId);
            if (student == null)
                return NotFound("Student not found.");

            student.Skills = dto.Skills;
            student.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Skills updated.", Skills = student.Skills });
        }

        // 6. Get Student Profile for Mobile App
        [HttpGet("{studentId}/profile")]
        public async Task<IActionResult> GetStudentProfile(int studentId)
        {
            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.StudentId == studentId);

            if (student == null)
                return NotFound("Student not found.");

            var profile = new
            {
                Name = student.User?.FullName,
                RegistrationNo = student.RegistrationNo,
                ProfilePicUrl = student.ProfilePicUrl,
                Skills = student.Skills ?? Array.Empty<string>(),
                CVUrl = student.CVUrl,
                FypDemoUrl = student.FypDemoUrl,
                FypDescription = student.FypDescription,
                Department = student.Department,
                CGPA = student.CGPA
            };

            return Ok(profile);
        }
        [HttpPut("{studentId}/links")]
        public async Task<IActionResult> UpdateStudentLinks(int studentId, [FromBody] StudentLinksDto dto)
        {
            var student = await _context.Students.FirstOrDefaultAsync(s => s.StudentId == studentId);
            if (student == null)
                return NotFound("Student not found.");

            if (!string.IsNullOrWhiteSpace(dto.FypDemoUrl))
                student.FypDemoUrl = dto.FypDemoUrl;

            if (!string.IsNullOrWhiteSpace(dto.LinkedIn))
                student.LinkedIn = dto.LinkedIn;

            if (!string.IsNullOrWhiteSpace(dto.GitHub))
                student.GitHub = dto.GitHub;

            student.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Student links updated successfully.",
                FypDemoUrl = student.FypDemoUrl,
                LinkedIn = student.LinkedIn,
                GitHub = student.GitHub
            });
        }

        /// <summary>
        /// Add or update the phone number for a student.
        /// </summary>
        [HttpPut("{studentId}/phone")]
        public async Task<IActionResult> UpdatePhone(int studentId, [FromBody] PhoneDto dto)
        {
            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.StudentId == studentId);
            if (student == null || student.User == null)
                return NotFound("Student not found.");

            if (string.IsNullOrWhiteSpace(dto.Phone))
                return BadRequest("Phone number is required.");

            student.User.Phone = dto.Phone;
            student.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Phone number updated successfully.", Phone = student.User.Phone });
        }
    }
}
