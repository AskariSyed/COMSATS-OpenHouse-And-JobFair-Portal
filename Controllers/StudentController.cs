using JobFairPortal.Data;
using JobFairPortal.DTOs;
using JobFairPortal.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace JobFairPortal.Controllers
{

    [ApiController]
    [Route("api/[controller]")]
    
    [Authorize(Roles = "Student")]
    public class StudentController : ControllerBase
    {
        private readonly JobFairRecruitmentDbContext _context;
        private readonly ILogger<StudentController> _logger;

        public StudentController(JobFairRecruitmentDbContext context, ILogger<StudentController> logger)
        {
            _context = context;
            _logger = logger;
        }
        //[HttpGet("whoami")]
        //[Authorize]
        //public IActionResult WhoAmI()
        //{
        //    var claims = User.Claims.Select(c => new { c.Type, c.Value });
        //    return Ok(claims);
        //}


        [HttpPost("profile-pic")]
        public async Task<IActionResult> UploadProfilePic( [FromForm] FileUploadDto dto)

        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim))
                return Unauthorized("User ID not found in token.");

            if (!int.TryParse(userIdClaim, out int userId))
                return BadRequest("Invalid user ID format in token.");


            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");
            var file = dto.File;

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
        [HttpPost("cv")]
        public async Task<IActionResult> UploadCV([FromForm] FileUploadDto dto)
        {
            var file = dto.File;
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim))
                return Unauthorized("User ID not found in token.");

            if (!int.TryParse(userIdClaim, out int userId))
                return BadRequest("Invalid user ID format in token.");


            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.UserId == userId);

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
     
        [HttpPut("complete-profile")]
        public async Task<IActionResult> CompleteProfile( [FromBody] CompleteProfileDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim))
                return Unauthorized("User ID not found in token.");

            if (!int.TryParse(userIdClaim, out int userId))
                return BadRequest("Invalid user ID format in token.");


            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");
            if (!string.IsNullOrWhiteSpace(dto.Name))
                student.User.FullName = dto.Name;

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

            if (dto.Skills != null && dto.Skills.Count > 0)
                student.Skills = dto.Skills;

            student.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Profile updated successfully." });
        }

        // DTO for multiple skills
       

        [HttpPost("skills/add")]
        public async Task<IActionResult> AddSkills( [FromBody] SkillsDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim))
                return Unauthorized("User ID not found in token.");

            if (!int.TryParse(userIdClaim, out int userId))
                return BadRequest("Invalid user ID format in token.");


            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");
            if (dto.Skills == null || dto.Skills.Count == 0)
                return BadRequest("No skills provided.");


            var existingSkills = student.Skills?.ToList() ?? new List<string>();

            foreach (var skill in dto.Skills)
            {
                if (!string.IsNullOrWhiteSpace(skill) &&
                    !existingSkills.Contains(skill, StringComparer.OrdinalIgnoreCase))
                {
                    existingSkills.Add(skill.Trim());
                }
            }

            student.Skills = existingSkills;

            student.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Skills added.", Skills = student.Skills });
        }

        [HttpPost("skills/remove")]
        public async Task<IActionResult> RemoveSkill(int studentId, [FromBody] string skill)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim))
                return Unauthorized("User ID not found in token.");

            if (!int.TryParse(userIdClaim, out int userId))
                return BadRequest("Invalid user ID format in token.");


            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");
           
            if (string.IsNullOrWhiteSpace(skill))
                return BadRequest("Skill cannot be empty.");

            var skills = student.Skills?.ToList() ?? new List<string>();
            var removed = skills.RemoveAll(s => string.Equals(s, skill, StringComparison.OrdinalIgnoreCase));
            if (removed == 0)
                return BadRequest("Skill not found.");

            student.Skills = skills;
            student.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Skill removed.", Skills = student.Skills });
        }

        /// <summary>
        /// Replace all skills for a student (PUT).
        /// </summary>
        [HttpPut("skills")]
        public async Task<IActionResult> PutSkills(int studentId, [FromBody] SkillsDto dto)
        {
            if (dto.Skills == null || dto.Skills.Count == 0)
                return BadRequest("No skills provided.");

            var student = await _context.Students.FirstOrDefaultAsync(s => s.StudentId == studentId);
            if (student == null)
                return NotFound("Student not found.");

            student.Skills = dto.Skills;
            student.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Skills updated.", Skills = student.Skills });
        }




        [Authorize]
        [HttpGet("debug-claims")]
        public IActionResult DebugClaims()
        {
            Console.WriteLine("🧩 DEBUGGING CLAIMS -------------------");
            foreach (var claim in User.Claims)
            {
                Console.WriteLine($"👉 Type: {claim.Type} | Value: {claim.Value}");
            }
            Console.WriteLine("--------------------------------------");

            return Ok(User.Claims.Select(c => new { c.Type, c.Value }));
        }

        // 6. Get Student Profile for Mobile App


        [HttpGet("profile")]
        public async Task<IActionResult> GetStudentProfile()
        {
            
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim))
                return Unauthorized("User ID not found in token.");

            if (!int.TryParse(userIdClaim, out int userId))
                return BadRequest("Invalid user ID format in token.");

           
            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            var profile = new
            {
                Name = student.User?.FullName,
                RegistrationNo = student.RegistrationNo,
                ProfilePicUrl = student.ProfilePicUrl,
                Skills = student.Skills ?? new List<string>(),
                CVUrl = student.CVUrl,
                FypDemoUrl = student.FypDemoUrl,
                FypDescription = student.FypDescription,
                Department = student.Department,
                CGPA = student.CGPA,
                Links = student.Links ?? new Dictionary<string, string>()
            };

            return Ok(profile);
        }


        [HttpPut("links")]
        public async Task<IActionResult> UpdateStudentLinks(int studentId, [FromBody] StudentLinksDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim))
                return Unauthorized("User ID not found in token.");

            if (!int.TryParse(userIdClaim, out int userId))
                return BadRequest("Invalid user ID format in token.");


            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");
           

            if (!string.IsNullOrWhiteSpace(dto.FypDemoUrl))
                student.FypDemoUrl = dto.FypDemoUrl;

            if (dto.Links != null)
                student.Links = dto.Links;

            student.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Student links updated successfully.",
                FypDemoUrl = student.FypDemoUrl,
                Links = student.Links
            });
        }

        /// <summary>
        /// Add or update the phone number for a student.
        /// </summary>
        [HttpPut("phone")]
        public async Task<IActionResult> UpdatePhone(int studentId, [FromBody] PhoneDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim))
                return Unauthorized("User ID not found in token.");

            if (!int.TryParse(userIdClaim, out int userId))
                return BadRequest("Invalid user ID format in token.");


            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");
            if (string.IsNullOrWhiteSpace(dto.Phone))
                return BadRequest("Phone number is required.");

            student.User.Phone = dto.Phone;
            student.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Phone number updated successfully.", Phone = student.User.Phone });
        }



        [HttpPut("update")]
        [RequestSizeLimit(20_000_000)] // Optional: allow up to ~20MB
        public async Task<IActionResult> UpdateStudentProfile([FromForm] UpdateStudentDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim))
                return Unauthorized("User ID not found in token.");

            if (!int.TryParse(userIdClaim, out int userId))
                return BadRequest("Invalid user ID format in token.");

            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            // ✅ 1. Upload profile picture if provided
            if (dto.ProfilePic != null && dto.ProfilePic.Length > 0)
            {
                var uploadsFolder = Path.Combine("uploads", "student", "profilepics");
                Directory.CreateDirectory(uploadsFolder);

                var fileName = $"{student.RegistrationNo}_{Guid.NewGuid()}{Path.GetExtension(dto.ProfilePic.FileName)}";
                var filePath = Path.Combine(uploadsFolder, fileName);

                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await dto.ProfilePic.CopyToAsync(stream);
                }

                student.ProfilePicUrl = $"/uploads/student/profilepics/{fileName}";
            }

            // ✅ 2. Update text fields (if provided)
            if (!string.IsNullOrWhiteSpace(dto.Name))
                student.User.FullName = dto.Name;

            if (!string.IsNullOrWhiteSpace(dto.CVUrl))
                student.CVUrl = dto.CVUrl;

            if (!string.IsNullOrWhiteSpace(dto.FypTitle))
                student.FypTitle = dto.FypTitle;

            if (!string.IsNullOrWhiteSpace(dto.FypDemoUrl))
                student.FypDemoUrl = dto.FypDemoUrl;

            if (!string.IsNullOrWhiteSpace(dto.FypDescription))
                student.FypDescription = dto.FypDescription;

            if (!string.IsNullOrWhiteSpace(dto.Department))
                student.Department = dto.Department;

            if (dto.CGPA.HasValue)
                student.CGPA = (decimal)dto.CGPA.Value;

            if (dto.Skills != null && dto.Skills.Any())
                student.Skills = dto.Skills;

            if (dto.Links != null && dto.Links.Any())
            {
                student.Links ??= new Dictionary<string, string>();
               student.Links = dto.Links;
            }

            student.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Profile updated successfully.",
                student.ProfilePicUrl,
                student.CVUrl,
                student.Skills,
                student.FypTitle,
                student.FypDemoUrl,
                student.Links
            });
        }
        [HttpGet("fyp")]
        public async Task<IActionResult> GetFyp()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim)) return Unauthorized("User ID not found in token.");
            if (!int.TryParse(userIdClaim, out int userId)) return BadRequest("Invalid user ID.");

            var student = await _context.Students.FirstOrDefaultAsync(s => s.UserId == userId);
            if (student == null) return NotFound("Student not found.");

            return Ok(new
            {
                student.FypTitle,
                student.FypDemoUrl,
                student.FypDescription
            });
        }

        [HttpPut("fyp")]
        public async Task<IActionResult> UpdateFyp([FromBody] UpdateFypDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim)) return Unauthorized("User ID not found in token.");
            if (!int.TryParse(userIdClaim, out int userId)) return BadRequest("Invalid user ID.");

            var student = await _context.Students.FirstOrDefaultAsync(s => s.UserId == userId);
            if (student == null) return NotFound("Student not found.");

            if (!string.IsNullOrWhiteSpace(dto.FypTitle)) student.FypTitle = dto.FypTitle;
            if (!string.IsNullOrWhiteSpace(dto.FypDemoUrl)) student.FypDemoUrl = dto.FypDemoUrl;
            if (!string.IsNullOrWhiteSpace(dto.FypDescription)) student.FypDescription = dto.FypDescription;

            student.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "FYP details updated successfully",
                student.FypTitle,
                student.FypDemoUrl,
                student.FypDescription
            });
        }

    }
}
