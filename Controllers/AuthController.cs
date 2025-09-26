using BCrypt.Net;
using JobFairPortal.Data;
using JobFairPortal.DTOs;
using JobFairPortal.Models;
using JobFairPortal.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.IdentityModel.Tokens;
using OfficeOpenXml;
using System.IdentityModel.Tokens.Jwt;
using System.Net.Mail;
using System.Security.Claims;
using System.Text;

namespace JobFairPortal.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly JobFairRecruitmentDbContext _context;
        private readonly IConfiguration _configuration;
        private readonly MailKitMailService _mailService;
        private readonly IMemoryCache _cache;


        public AuthController(JobFairRecruitmentDbContext context, IConfiguration configuration, MailKitMailService mailService,IMemoryCache cache)
        {
            _context = context;
            _configuration = configuration;
            _mailService = mailService;
            _cache = cache;

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
        // Student Login (with Profile Check)
        // -----------------------------
        [HttpPost("student/login")]
        public async Task<IActionResult> StudentLogin([FromBody] LoginDto loginDto)
        {
            var regNoPattern = @"^(FA|SP)\d{2}-[A-Z]{3}-\d{3}$";
            var input = loginDto.EmailOrRegNo.Trim();

            User? user = null;
            Student? student = null;

            // Check if input is Registration No or Email
            if (System.Text.RegularExpressions.Regex.IsMatch(input, regNoPattern, System.Text.RegularExpressions.RegexOptions.IgnoreCase))
            {
                student = await _context.Students
                    .Include(s => s.User)
                    .FirstOrDefaultAsync(s => s.RegistrationNo.ToUpper() == input.ToUpper());
                user = student?.User;
            }
            else
            {
                user = await _context.Users
                    .Include(u => u.Student)
                    .FirstOrDefaultAsync(u => u.Email.ToLower() == input.ToLower() && u.Role == UserRole.Student);
                student = user?.Student;
            }

            if (user == null || student == null)
                return Unauthorized("Invalid credentials.");

            if (!BCrypt.Net.BCrypt.Verify(loginDto.Password, user.PasswordHash))
                return Unauthorized("Invalid credentials.");

            // Save/Update FCM Token if provided
            if (!string.IsNullOrWhiteSpace(loginDto.FcmToken))
            {
                student.FcmToken = loginDto.FcmToken;
                student.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();
            }

            // Generate JWT token
            var token = GenerateJwtToken(user);

            // ✅ Check if profile is incomplete (first-time login)
            bool isProfileComplete = !string.IsNullOrWhiteSpace(student.CVUrl) &&
                                     !string.IsNullOrWhiteSpace(student.Department) &&
                                     (student.Skills != null && student.Skills.Length > 0); 

            if (!isProfileComplete)
            {
                // Respond with minimal info
                return Ok(new
                {
                    Token = token,
                    Role = user.Role.ToString(),
                    ProfileComplete = false,
                    UserId=user.UserId,

                    Student = new
                    {
                        student.StudentId,
                        Name = user.FullName,
                        student.RegistrationNo,
                        user.Email,
                        
                    }
                });
            }

            // Build full student profile DTO
            var studentProfile = new StudentLoginResponseDto
            {
                StudentId = student.StudentId,
                Name = user.FullName,
                RegistrationNo = student.RegistrationNo,
                ProfilePicUrl = student.ProfilePicUrl,
                CVUrl = student.CVUrl,
                FypTitle = student.FypTitle,
                FypDemoUrl = student.FypDemoUrl,
                FypDescription = student.FypDescription,
                Department = student.Department,
                CGPA = student.CGPA,
                Skills = student.Skills,
                Email = user.Email,
                Phone = user.Phone,
                LinkedIn = student.LinkedIn,
                GitHub = student.GitHub,
                FcmToken = student.FcmToken
            };

            return Ok(new
            {
                Token = token,
                Role = user.Role.ToString(),
                ProfileComplete = true,
                UserId=user.UserId,
                Student = studentProfile
            });
        }

        private async Task<IActionResult> Login(LoginDto loginDto, UserRole role)
        {
            var regNoPattern = @"^(FA|SP)\d{2}-[A-Z]{3}-\d{3}$";
            var input = loginDto.EmailOrRegNo.Trim();

            User? user = null;
            Student? student = null;

            if (role == UserRole.Student)
            {
                if (System.Text.RegularExpressions.Regex.IsMatch(input, regNoPattern, System.Text.RegularExpressions.RegexOptions.IgnoreCase))
                {
                    student = await _context.Students
                        .Include(s => s.User)
                        .FirstOrDefaultAsync(s => s.RegistrationNo.ToUpper() == input.ToUpper());

                    user = student?.User;
                }
                else
                {
                    user = await _context.Users
                        .Include(u => u.Student)
                        .FirstOrDefaultAsync(u => u.Email.ToLower() == input.ToLower() && u.Role == role);

                    student = user?.Student;
                }
            }
            else
            {
                user = await _context.Users
                    .FirstOrDefaultAsync(u => u.Email.ToLower() == input.ToLower() && u.Role == role);
            }

            if (user == null)
                return Unauthorized("Invalid credentials.");

            if (!BCrypt.Net.BCrypt.Verify(loginDto.Password, user.PasswordHash))
                return Unauthorized("Invalid credentials.");

            // ✅ Save/Update FCM Token if Student login
            if (role == UserRole.Student && student != null && !string.IsNullOrWhiteSpace(loginDto.FcmToken))
            {
                student.FcmToken = loginDto.FcmToken;
                student.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();
            }

            // Generate JWT token
            var token = GenerateJwtToken(user);
          
            return Ok(new
            {
                Token = token,
                UserId = user.UserId,
                Name = user.FullName,
                Role = user.Role.ToString(),
                FcmToken = student?.FcmToken // ✅ return it back too
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

        // -----------------------------
        // Company Signup
        // -----------------------------
        [HttpPost("company-signup")]
        public async Task<IActionResult> CompanySignup([FromForm] CompanySignupDto dto)
        {
            // Validate email and phone
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            // Check if user email or rep email already exists
            if (await _context.Users.AnyAsync(u => u.Email == dto.UserEmail) ||
                await _context.Companies.AnyAsync(c => c.RepEmail == dto.RepEmail))
                return BadRequest("User email or representative email already exists.");

            // Save logo if provided
            string? logoUrl = null;
            if (dto.Logo != null && dto.Logo.Length > 0)
            {
                var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", "companies", "logo");
                Directory.CreateDirectory(uploadsFolder);

                var fileName = $"{Guid.NewGuid()}{Path.GetExtension(dto.Logo.FileName)}";
                var filePath = Path.Combine(uploadsFolder, fileName);

                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await dto.Logo.CopyToAsync(stream);
                }

                // Save relative path for serving via static files
                logoUrl = $"/uploads/companies/logo/{fileName}";
            }

            // Create user
            var user = new User
            {
                Email = dto.UserEmail,
                FullName = dto.UserFullName,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.UserPassword),
                Role = UserRole.Company,
                IsActive = false // Activate after OTP
            };
            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            // Create company
            var company = new Company
            {
                UserId = user.UserId,
                Name = dto.Name,
                Description = dto.Description,
                RepsCount = dto.RepsCount,
                RepEmail = dto.RepEmail,
                RepPhone = dto.RepPhone,
                Address = dto.Address,
                InterviewDurationMinutes = dto.InterviewDurationMinutes,
                Industry = dto.Industry,
                LogoUrl = logoUrl,
                ArrivalStatus = ArrivalStatus.PreRegistered,
                IsPresent = false,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };
            _context.Companies.Add(company);
            await _context.SaveChangesAsync();

            // Add job offerings
            foreach (var jobDto in dto.JobOfferings)
            {
                var job = new Job
                {
                    CompanyId = company.CompanyId,
                    JobTitle = jobDto.JobTitle,
                    JobDescription = jobDto.JobDescription,
                    RequiredSkills = jobDto.RequiredSkills
                };
                _context.Jobs.Add(job);
            }
            await _context.SaveChangesAsync();

            // Generate OTP and send to RepEmail
            var otp = new Random().Next(100000, 999999).ToString();
            var cacheKey = $"company-otp:{dto.RepEmail.ToLower()}";
            _cache.Set(cacheKey, otp, TimeSpan.FromMinutes(10));

            await _mailService.SendMailAsync(dto.RepEmail, "Company Signup OTP", $"Your OTP is: {otp}");

            return Ok(new
            {
                Message = "Signup successful. OTP sent to representative email.",
                CompanyId = company.CompanyId,
                LogoUrl = logoUrl
            });
        }

        // -----------------------------
        // Company OTP Verification
        // -----------------------------
        [HttpPost("company-verify-otp")]
        public async Task<IActionResult> VerifyCompanyOtp([FromBody] CompanyOtpVerifyDto dto)
        {
            if (string.IsNullOrWhiteSpace(dto.RepEmail) || string.IsNullOrWhiteSpace(dto.Otp))
                return BadRequest("Email and OTP are required.");

            var cacheKey = $"company-otp:{dto.RepEmail.ToLower()}";
            if (!_cache.TryGetValue(cacheKey, out string cachedOtp))
                return BadRequest("OTP expired or not found.");

            if (cachedOtp != dto.Otp)
                return BadRequest("Invalid OTP.");

            // Activate the user account
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == dto.UserEmail.ToLower() && u.Role == UserRole.Company);
            if (user == null)
                return NotFound("User not found.");

            user.IsActive = true;
            user.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            // Remove OTP from cache after successful verification
            _cache.Remove(cacheKey);

            return Ok(new { Message = "OTP verified. Company account activated." });
        }

        // -----------------------------
        // Resend Company Signup OTP
        // -----------------------------
        [HttpPost("company-resend-otp")]
        public async Task<IActionResult> ResendCompanyOtp([FromBody] CompanyResendOtpDto dto)
        {
            if (string.IsNullOrWhiteSpace(dto.RepEmail))
                return BadRequest("Representative email is required.");

            // Check if the company user exists and is not yet active
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Email.ToLower() == dto.UserEmail.ToLower() && u.Role == UserRole.Company);

            if (user == null)
                return NotFound("User not found.");
            if (user.IsActive)
                return BadRequest("Account is already activated.");

            // Generate new OTP
            var otp = new Random().Next(100000, 999999).ToString();
            var cacheKey = $"company-otp:{dto.RepEmail.ToLower()}";
            _cache.Set(cacheKey, otp, TimeSpan.FromMinutes(10));

            // Send OTP to representative email
            await _mailService.SendMailAsync(dto.RepEmail, "Company Signup OTP (Resend)", $"Your new OTP is: {otp}");

            return Ok(new { Message = "OTP resent to representative email." });
        }
    }
}

