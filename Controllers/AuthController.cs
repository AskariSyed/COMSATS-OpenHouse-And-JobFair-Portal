using JobFairPortal.Data;
using JobFairPortal.Models;
using JobFairPortal.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using BCrypt.Net;

namespace JobFairPortal.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly JobFairRecruitmentDbContext _context;
        private readonly IConfiguration _configuration;

        public AuthController(JobFairRecruitmentDbContext context, IConfiguration configuration)
        {
            _context = context;
            _configuration = configuration;
        }

        // -----------------------------
        // Admin Login
        // -----------------------------
        [HttpPost("admin/login")]
        public async Task<IActionResult> AdminLogin([FromBody] LoginDto loginDto)
        {
            return await Login(loginDto, UserRole.Admin);
        }

        // -----------------------------
        // Company Login
        // -----------------------------
        [HttpPost("company/login")]
        public async Task<IActionResult> CompanyLogin([FromBody] LoginDto loginDto)
        {
            return await Login(loginDto, UserRole.Company);
        }

        // -----------------------------
        // Student Login
        // -----------------------------
        [HttpPost("student/login")]
        public async Task<IActionResult> StudentLogin([FromBody] LoginDto loginDto)
        {
            return await Login(loginDto, UserRole.Student);
        }

        // -----------------------------
        // Shared Login Logic
        // -----------------------------
        private async Task<IActionResult> Login(LoginDto loginDto, UserRole role)
        {
            // Registration number pattern: FA/SP + 2 digits + hyphen + 3 letters + hyphen + 3 digits
            var regNoPattern = @"^(FA|SP)\d{2}-[A-Z]{3}-\d{3}$";
            var input = loginDto.EmailOrRegNo.Trim();

            User? user = null;

            if (role == UserRole.Student)
            {
                // Check if input matches registration number format (case-insensitive)
                if (System.Text.RegularExpressions.Regex.IsMatch(input, regNoPattern, System.Text.RegularExpressions.RegexOptions.IgnoreCase))
                {
                    // Find student by registration number (case-insensitive)
                    var student = await _context.Students
                        .Include(s => s.User)
                        .FirstOrDefaultAsync(s => s.RegistrationNo.ToUpper() == input.ToUpper());

                    user = student?.User;
                }
                else
                {
                    // Try to find by email (case-insensitive)
                    user = await _context.Users
                        .FirstOrDefaultAsync(u => u.Email.ToLower() == input.ToLower() && u.Role == role);
                }
            }
            else
            {
                // For admin/company, find by email (case-insensitive)
                user = await _context.Users
                    .FirstOrDefaultAsync(u => u.Email.ToLower() == input.ToLower() && u.Role == role);
            }

            if (user == null)
                return Unauthorized("Invalid credentials.");

            // Verify hashed password
            if (!BCrypt.Net.BCrypt.Verify(loginDto.Password, user.PasswordHash))
                return Unauthorized("Invalid credentials.");

            // Generate JWT token
            var token = GenerateJwtToken(user);

            return Ok(new
            {
                Token = token,
                UserId = user.UserId,
                Name = user.FullName,
                Role = user.Role.ToString()
            });
        }

        // -----------------------------
        // JWT Token Generation
        // -----------------------------
        private string GenerateJwtToken(User user)
        {
            var key = Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]);

            var claims = new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.Email),
                new Claim(ClaimTypes.NameIdentifier, user.UserId.ToString()),
                new Claim(ClaimTypes.Role, user.Role.ToString()),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(claims),
                Expires = DateTime.UtcNow.AddMinutes(Convert.ToDouble(_configuration["Jwt:ExpiryMinutes"])),
                Issuer = _configuration["Jwt:Issuer"],
                Audience = _configuration["Jwt:Audience"],
                SigningCredentials = new SigningCredentials(
                    new SymmetricSecurityKey(key),
                    SecurityAlgorithms.HmacSha256Signature)
            };

            var tokenHandler = new JwtSecurityTokenHandler();
            var token = tokenHandler.CreateToken(tokenDescriptor);

            return tokenHandler.WriteToken(token);
        }

        // -----------------------------
        // Student Registration
        // -----------------------------
        [HttpPost("student/register")]
        public async Task<IActionResult> RegisterStudent(
            [FromServices] MailKitMailService mailService,
            [FromBody] string registrationNo)
        {
            if (string.IsNullOrWhiteSpace(registrationNo))
                return BadRequest("Registration number is required.");

            // Registration number pattern: FA/SP + 2 digits + hyphen + 3 letters + hyphen + 3 digits
            var regNoPattern = @"^(FA|SP)\d{2}-[A-Z]{3}-\d{3}$";
            if (!System.Text.RegularExpressions.Regex.IsMatch(registrationNo, regNoPattern, System.Text.RegularExpressions.RegexOptions.IgnoreCase))
                return BadRequest("Invalid registration number format. Example: FA22-BCS-155 or SP22-ABC-123");

            var email = $"{registrationNo}@cuiwah.edu.pk";

            // Check if user already exists
            var existingUser = await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
            if (existingUser != null)
                return BadRequest("Student already registered.");

            // Extract program code (e.g., BCS, BSE, etc.)
            var parts = registrationNo.ToUpper().Split('-');
            if (parts.Length < 3)
                return BadRequest("Invalid registration number format.");

            var programCode = parts[1];

            // Only allow these courses
            string department = programCode switch
            {
                "BCS" or "BSE" or "BAI" => "Computer Science",
                "CVE" => "Civil Engineering",
                "BME" => "Mechanical Engineering",
                "BEE" or "BCE" => "Electrical Engineering",
                "BBA" or "BAF" => "Management Sciences",
                _ => null
            };

            if (department == null)
                return BadRequest("Registration is only allowed for: BCS, BSE, BAI, CVE, BME, BEE, BCE, BBA, BAF.");

            // Generate random password
            var password = Guid.NewGuid().ToString("N")[..8];
            var passwordHash = BCrypt.Net.BCrypt.HashPassword(password);

            // Create User
            var user = new User
            {
                Email = email,
                PasswordHash = passwordHash,
                Role = UserRole.Student,
                IsActive = true
            };
            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            // Create Student
            var student = new Student
            {
                UserId = user.UserId,
                RegistrationNo = registrationNo,
                Department = department,
                CGPA = 0
            };
            _context.Students.Add(student);
            await _context.SaveChangesAsync();

            // Send email
            var subject = "Your Job Fair Portal Account";
            var body = $"Dear Student,\n\nYour account has been created.\nEmail: {email}\nPassword: {password}\n\nPlease change your password after first login.";
            await mailService.SendMailAsync(email, subject, body);

            return Ok(new { Message = "Student registered and password sent to email.", Email = email });
        }
    }

    // -----------------------------
    // Login DTO
    // -----------------------------
    public class LoginDto
    {
        public string EmailOrRegNo { get; set; } = null!;
        public string Password { get; set; } = null!;
    }
}
