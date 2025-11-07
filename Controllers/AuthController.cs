using BCrypt.Net;
using JobFairPortal.Data;
using JobFairPortal.DTOs;
using JobFairPortal.Models;
using JobFairPortal.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.IdentityModel.Tokens;

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
                    .Include(s => s.ContactLinks)
                    .Include(s => s.StudentProjects)
                        .ThenInclude(sp => sp.Project)
                    .FirstOrDefaultAsync(s => s.RegistrationNo.ToUpper() == input.ToUpper());
                user = student?.User;
            }
            else
            {
                user = await _context.Users
                    .Include(u => u.Student)
                        .ThenInclude(s => s.ContactLinks)
                    .Include(u => u.Student)
                        .ThenInclude(s => s.StudentProjects)
                            .ThenInclude(sp => sp.Project)
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

            // Check if profile is incomplete (first-time login)
            bool isProfileComplete = !string.IsNullOrWhiteSpace(student.Department)
                && (student.Skills != null && student.Skills.Count > 0)
                && (student.Certifications != null && student.Certifications.Count > 0)
                && (student.Achievements != null && student.Achievements.Count > 0)
                && !string.IsNullOrWhiteSpace(student.ProfilePicUrl);

            if (!isProfileComplete)
            {
                return Ok(new
                {
                    Token = token,
                    Role = user.Role.ToString(),
                    ProfileComplete = false,
                    UserId = user.UserId,
                    Student = new
                    {
                        student.StudentId,
                        student.RegistrationNo,
                        user.Email,
                        Links = student.ContactLinks != null
                            ? student.ContactLinks.ToDictionary(
                                cl => cl.Platform.ToString(),
                                cl => cl.Url)
                            : new Dictionary<string, string>(),
                        User = new
                        {
                            user.UserId,
                            user.Email,
                            user.Phone,
                            user.Role,
                            FullName = user.FullName,
                            user.IsActive,
                            user.CreatedAt,
                            user.UpdatedAt
                        }
                    }
                });
            }

            // Get FYP details from StudentProjects
            var fyp = student.StudentProjects
                .FirstOrDefault(sp => sp.Project != null && sp.Project.Type == ProjectType.FinalYear)?.Project;

            var studentProfile = new StudentLoginResponseDto
            {
                StudentId = student.StudentId,
                RegistrationNo = student.RegistrationNo,
                ProfilePicUrl = student.ProfilePicUrl,
                Department = student.Department,
                CGPA = student.CGPA,
                Skills = student.Skills,
                Links = student.ContactLinks != null
                    ? student.ContactLinks.ToDictionary(
                        cl => cl.Platform.ToString(),
                        cl => cl.Url)
                    : new Dictionary<string, string>(),
                FcmToken = student.FcmToken,
                CreatedAt = student.CreatedAt,
                UpdatedAt = student.UpdatedAt,
                Experiences = student.Experiences.Select(e => new ExperienceDto

                {
                    ExperienceId = e.ExperienceId,
                    CompanyName = e.CompanyName,
                    Role = e.Role,
                    Description = e.Description,
                    StartDate = e.StartDate,
                    EndDate = e.EndDate,
                    IsCurrent = e.IsCurrent,
                    Location = e.Location
                }).ToList(),
                Educations=student.Educations.Select(ed=>new EducationDto
                {
                    EducationId=ed.EducationId,
                    InstitutionName=ed.InstitutionName,
                    Degree=ed.Degree,
                    FieldOfStudy=ed.FieldOfStudy,
                    StartDate=ed.StartDate,
                    EndDate=ed.EndDate,
                    IsCurrent=ed.IsCurrent,
                    CGPA=ed.CGPA,
                    Location=ed.Location
                }).ToList(),
                Achievements = student.Achievements.Select(a => new AchievementDto
                {
                    AchievementId = a.AchievementId,
                    Title = a.Title,
                    Description = a.Description,
                    DateAchieved = a.DateAchieved
                }).ToList(),
                Certifications = student.Certifications.Select(c => new CertificationDto
                {
                    CertificationId = c.CertificationId,
                    Title = c.Title,
                    Issuer = c.Issuer,
                    IssueDate = c.IssueDate,
                    CredentialUrl = c.CredentialUrl,
                    CredentialId = c.CredentialId
                }).ToList(),
                User = new UserDto
                {
                    UserId = user.UserId,
                    Email = user.Email,
                    FullName = user.FullName,
                    Phone = user.Phone,
                    Role = user.Role.ToString(),
                    IsActive = user.IsActive,
                    CreatedAt = user.CreatedAt,
                    UpdatedAt = user.UpdatedAt
                }
            };

            return Ok(new
            {
                Token = token,
                Role = user.Role.ToString(),
                ProfileComplete = true,
                UserId = user.UserId,
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
        // Use NameIdentifier for userId (primary identity)
        new Claim(ClaimTypes.NameIdentifier, user.UserId.ToString()),
        new Claim(ClaimTypes.Role, user.Role.ToString()),

        // Optional: store email separately (won’t map to nameidentifier)
        new Claim(JwtRegisteredClaimNames.Email, user.Email),

        // Unique token ID
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

            // 🔹 Validate registration number format
            var regNoPattern = @"^(FA|SP)\d{2}-[A-Z]{3}-\d{3}$";
            if (!System.Text.RegularExpressions.Regex.IsMatch(
                registrationNo, regNoPattern,
                System.Text.RegularExpressions.RegexOptions.IgnoreCase))
            {
                return BadRequest("Invalid registration number format. Example: FA22-BCS-155 or SP22-ABC-123");
            }

            var email = $"{registrationNo}@cuiwah.edu.pk";

            // 🔹 Check if user already exists
            var existingUser = await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
            if (existingUser != null)
                return BadRequest("Student already registered.");

            // 🔹 Extract program & map department
            var parts = registrationNo.ToUpper().Split('-');
            if (parts.Length < 3)
                return BadRequest("Invalid registration number format.");

            var programCode = parts[1];
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

            // 🔹 Find Active Job Fair
            var activeJobFair = await _context.JobFairs.FirstOrDefaultAsync(j => j.IsActive);

            if (activeJobFair == null)
            {
                // No active Job Fair — return unique code
                return StatusCode(460, new
                {
                    Code = "NO_ACTIVE_JOBFAIR",
                    Message = "No active Job Fair available. Please contact the admin."
                });
            }

            // 🔹 Generate password
            var password = Guid.NewGuid().ToString("N")[..8];
            var passwordHash = BCrypt.Net.BCrypt.HashPassword(password);

            // 🔹 Create User
            var user = new User
            {
                Email = email,
                PasswordHash = passwordHash,
                Role = UserRole.Student,
                IsActive = true
            };
            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            // 🔹 Create Student (linked to Job Fair)
            var student = new Student
            {
                UserId = user.UserId,
                RegistrationNo = registrationNo,
                Department = department,
                CGPA = 0,
                JobFairId = activeJobFair.JobFairId 
            };
            _context.Students.Add(student);
            await _context.SaveChangesAsync();

            // 🔹 Send Email
            var subject = "Your Job Fair Portal Account";
            var body = $"""
    Dear Student,

    Your account for the Job Fair Portal has been created successfully.

    Email: {email}
    Password: {password}

    Please log in and change your password after your first login.

    Linked Job Fair: {activeJobFair.Semester} ({activeJobFair.date:yyyy-MM-dd})

    Regards,
    Job Fair Management Team
    """;

            await mailService.SendMailAsync(email, subject, body);

            return Ok(new
            {
                Message = "Student registered successfully and password sent via email.",
                Email = email,
                JobFairId = activeJobFair.JobFairId,
                JobFairSemester = activeJobFair.Semester
            });
        }

        // -----------------------------
        // Company Signup
        // -----------------------------
        [HttpPost("company-signup")]
        public async Task<IActionResult> CompanySignup([FromForm] CompanySignupDto dto)
        {
            // Validate input
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            // Check if user email or focal person email already exists
            if (await _context.Users.AnyAsync(u => u.Email == dto.UserEmail) ||
                await _context.Companies.AnyAsync(c => c.FocalPersonEmail == dto.FocalPersonEmail))
            {
                return BadRequest("User email or focal person email already exists.");
            }

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
                FocalPersonName = dto.FocalPersonName,
                FocalPersonEmail = dto.FocalPersonEmail,
                FocalPersonPhone = dto.FocalPersonPhone,
                CompanyEmail = dto.CompanyEmail,
                CompanyPhone = dto.CompanyPhone,
                Address = dto.Address,
                Website = dto.Website,
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
                    RequiredSkills = jobDto.RequiredSkills?.Split(',', StringSplitOptions.TrimEntries),
                    JobType = jobDto.Type
                };
                _context.Jobs.Add(job);
            }

            // Add company contact links
            foreach (var linkDto in dto.ContactLinks)
            {
                var contactLink = new CompanyContactLink
                {
                    CompanyId = company.CompanyId,
                    Platform = linkDto.Platform,
                    Url = linkDto.Url
                };
                _context.CompanyContactLinks.Add(contactLink);
            }

            await _context.SaveChangesAsync();

            // Generate OTP and send to FocalPersonEmail
            var otp = new Random().Next(100000, 999999).ToString();
            var cacheKey = $"company-otp:{dto.FocalPersonEmail.ToLower()}";
            _cache.Set(cacheKey, otp, TimeSpan.FromMinutes(10));

            await _mailService.SendMailAsync(dto.FocalPersonEmail, "Company Signup OTP", $"Your OTP is: {otp}");

            return Ok(new
            {
                Message = "Signup successful. OTP sent to focal person email.",
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

