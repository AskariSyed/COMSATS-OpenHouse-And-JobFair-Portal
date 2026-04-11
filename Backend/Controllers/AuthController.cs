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
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;

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
        private readonly ILogger<AuthController> _logger;
        private readonly AuthValidationService _validationService;
        private readonly AuthTokenService _tokenService;
        private readonly IParticipationService _participationService;

        // Constants
        private const int PASSWORD_MIN_LENGTH = 8;
        private const int OTP_LENGTH = 6;
        private const int TOKEN_EXPIRY_MINUTES = 15;
        private const int OTP_EXPIRY_MINUTES = 10;
        private const string REGISTRATION_NO_PATTERN = @"^(FA|SP)\d{2}-[A-Z]{3}-\d{3}$";
        private const string EMAIL_REGEX_PATTERN = @"^[^@\s]+@[^@\s]+\.[^@\s]+$";

        public AuthController(
            JobFairRecruitmentDbContext context,
            IConfiguration configuration,
            MailKitMailService mailService,
            IMemoryCache cache,
            ILogger<AuthController> logger,
            AuthValidationService validationService,
            AuthTokenService tokenService,
            IParticipationService participationService)
        {
            _context = context ?? throw new ArgumentNullException(nameof(context));
            _configuration = configuration ?? throw new ArgumentNullException(nameof(configuration));
            _mailService = mailService ?? throw new ArgumentNullException(nameof(mailService));
            _cache = cache ?? throw new ArgumentNullException(nameof(cache));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
            _validationService = validationService ?? throw new ArgumentNullException(nameof(validationService));
            _tokenService = tokenService ?? throw new ArgumentNullException(nameof(tokenService));
            _participationService = participationService ?? throw new ArgumentNullException(nameof(participationService));
        }

        // ========================================
        // LOGIN ENDPOINTS
        // ======================================== 

        [HttpPost("admin/login")]
        public async Task<IActionResult> AdminLogin([FromBody] LoginDto loginDto)
        {
            _logger.LogInformation("Admin login attempt for email: {Email}", loginDto.EmailOrRegNo);
            return await Login(loginDto, UserRole.Admin, allowCoAdminForAdminPortal: true);
        }

        [HttpPost("company/login")]
        public async Task<IActionResult> CompanyLogin([FromBody] LoginDto loginDto)
        {
            _logger.LogInformation("Company login attempt for email: {Email}", loginDto.EmailOrRegNo);
            return await Login(loginDto, UserRole.Company);
        }

        [HttpPost("student/login")]
        public async Task<IActionResult> StudentLogin([FromBody] LoginDto loginDto)
        {
            _logger.LogInformation("Student login attempt for identifier: {Identifier}", loginDto.EmailOrRegNo);

            if (!_validationService.ValidateLoginDto(loginDto, out var validationError))
                return BadRequest(validationError);

            var input = loginDto.EmailOrRegNo.Trim();
            User? user = null;
            Student? student = null;

            // Check if input is Registration No or Email
            if (Regex.IsMatch(input, REGISTRATION_NO_PATTERN, RegexOptions.IgnoreCase))
            {
                student = await _context.Students
                    .Include(s => s.User)
                    .Include(s => s.ContactLinks)
                    .Include(s => s.StudentProjects)
                        .ThenInclude(sp => sp.Project)
                    .Include(s => s.Experiences)
                    .Include(s => s.Educations)
                    .Include(s => s.Achievements)
                    .Include(s => s.Certifications)
                    .FirstOrDefaultAsync(s => s.RegistrationNo.ToUpper() == input.ToUpper());
                user = student?.User;
            }
            else
            {
                user = await _context.Users
                    .Include(u => u.Student)
                        .ThenInclude(s => s!.ContactLinks)
                    .Include(u => u.Student)
                        .ThenInclude(s => s!.StudentProjects)
                            .ThenInclude(sp => sp.Project)
                    .Include(u => u.Student)
                        .ThenInclude(s => s!.Experiences)
                    .Include(u => u.Student)
                        .ThenInclude(s => s!.Educations)
                    .Include(u => u.Student)
                        .ThenInclude(s => s!.Achievements)
                    .Include(u => u.Student)
                        .ThenInclude(s => s!.Certifications)
                    .FirstOrDefaultAsync(u => u.Email.ToLower() == input.ToLower() && u.Role == UserRole.Student);
                student = user?.Student;
            }

            if (user == null || student == null)
            {
                _logger.LogWarning("Student login failed - user not found for identifier: {Identifier}", input);
                return Unauthorized("Invalid credentials.");
            }

            if (!BCrypt.Net.BCrypt.Verify(loginDto.Password, user.PasswordHash))
            {
                _logger.LogWarning("Student login failed - invalid password for user: {UserId}", user.UserId);
                return Unauthorized("Invalid credentials.");
            }

            if (!user.IsActive)
            {
                _logger.LogWarning("Student login attempted on inactive account: {UserId}", user.UserId);
                return Unauthorized("Account not verified. Please complete the OTP verification process.");
            }

            // Update FCM Token if provided
            if (!string.IsNullOrWhiteSpace(loginDto.FcmToken))
            {
                student.FcmToken = loginDto.FcmToken;
                student.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();
                _logger.LogInformation("FCM token updated for student: {StudentId}", student.StudentId);
            }

            var token = _tokenService.GenerateJwtToken(user);
            var isProfileComplete = _validationService.IsStudentProfileComplete(student);

            if (!isProfileComplete)
            {
                _logger.LogInformation("Student login successful but profile incomplete for: {StudentId}", student.StudentId);
                return Ok(BuildIncompleteProfileResponse(user, student, token));
            }

            _logger.LogInformation("Student login successful for: {StudentId}", student.StudentId);
            return Ok(BuildCompleteProfileResponse(user, student, token));
        }

        private async Task<IActionResult> Login(LoginDto loginDto, UserRole role, bool allowCoAdminForAdminPortal = false)
        {
            if (!_validationService.ValidateLoginDto(loginDto, out var validationError))
                return BadRequest(validationError);

            var input = loginDto.EmailOrRegNo.Trim();

            User? user;
            if (allowCoAdminForAdminPortal && role == UserRole.Admin)
            {
                user = await _context.Users
                    .FirstOrDefaultAsync(u =>
                        u.Email.ToLower() == input.ToLower() &&
                        (u.Role == UserRole.Admin || u.Role == UserRole.CoAdmin));
            }
            else
            {
                user = await _context.Users
                    .FirstOrDefaultAsync(u => u.Email.ToLower() == input.ToLower() && u.Role == role);
            }

            if (user == null)
            {
                _logger.LogWarning("Login failed for role {Role} - user not found: {Email}", role, input);
                return Unauthorized("Invalid credentials.");
            }

            if (!BCrypt.Net.BCrypt.Verify(loginDto.Password, user.PasswordHash))
            {
                _logger.LogWarning("Login failed for role {Role} - invalid password: {UserId}", role, user.UserId);
                return Unauthorized("Invalid credentials.");
            }

            if (!user.IsActive)
            {
                _logger.LogWarning("Login attempted on inactive account - role {Role}, user: {UserId}", role, user.UserId);
                if (user.Role == UserRole.Admin || user.Role == UserRole.CoAdmin)
                {
                    return Unauthorized("Your admin account is blocked. Please contact super admin.");
                }
                return Unauthorized("Account not verified. Please complete the OTP verification process.");
            }


            if (role == UserRole.Company)
            {
                var company = await _context.Companies.FirstOrDefaultAsync(c => c.UserId == user.UserId);
                if (company != null)
                {
                    if (company.IsBlocked)
                    {
                        _logger.LogWarning("Blocked company login attempt: {CompanyId}", company.CompanyId);
                        return Unauthorized("Your account is on hold/blocked. Contact administration for further information.");
                    }
                    if (!string.IsNullOrWhiteSpace(loginDto.FcmToken))
                    {
                        company.FcmToken = loginDto.FcmToken;
                        company.UpdatedAt = DateTime.UtcNow;
                        await _context.SaveChangesAsync();
                        _logger.LogInformation("FCM token updated for company: {CompanyId}", company.CompanyId);
                    }
                }
            }

            var token = _tokenService.GenerateJwtToken(user);

            _logger.LogInformation("Login successful for role {Role}, user: {UserId}", role, user.UserId);

            return Ok(new
            {
                Token = token,
                UserId = user.UserId,
                Name = user.FullName,
                Role = user.Role.ToString(),
                IsActive = user.IsActive
            });
        }

        // ========================================
        // STUDENT REGISTRATION
        // ========================================

        [HttpPost("student/register")]
        public async Task<IActionResult> RegisterStudent([FromBody] StudentRegistrationDto dto)
        {
            if (!_validationService.ValidateStudentRegistration(dto, out var validationError))
                return BadRequest(validationError);

            var registrationNo = dto.RegistrationNo.Trim().ToUpper();

            // Check if user already exists
            var email = $"{registrationNo}@cuiwah.edu.pk";
            if (await _context.Users.AnyAsync(u => u.Email == email))
            {
                _logger.LogWarning("Student registration failed - user already exists: {Email}", email);
                return BadRequest("Student already registered.");
            }

            // Extract and validate department
            var department = _validationService.ExtractDepartmentFromRegNo(registrationNo);
            if (string.IsNullOrWhiteSpace(department))
            {
                _logger.LogWarning("Student registration failed - invalid program code in: {RegistrationNo}", registrationNo);
                return BadRequest("Registration is only allowed for: BCS, BSE, BAI, CVE, BME, BEE, BCE, BBA, BAF.");
            }

            // Find active job fair
            var activeJobFair = await _context.JobFairs.FirstOrDefaultAsync(j => j.IsActive);
            if (activeJobFair == null)
            {
                _logger.LogError("Student registration failed - no active job fair");
                return StatusCode(460, new
                {
                    Code = "NO_ACTIVE_JOBFAIR",
                    Message = "No active Job Fair available. Please contact the admin."
                });
            }

            // Generate temporary password
            var tempPassword = GenerateTemporaryPassword();
            var passwordHash = BCrypt.Net.BCrypt.HashPassword(tempPassword);

            try
            {
                // Create User
                var user = new User
                {
                    Email = email,
                    PasswordHash = passwordHash,
                    Role = UserRole.Student,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                _context.Users.Add(user);
                await _context.SaveChangesAsync();

                // Create Student
                var student = new Student
                {
                    UserId = user.UserId,
                    RegistrationNo = registrationNo,
                    Department = department,
                    CGPA = 0,
                    JobFairId = activeJobFair.JobFairId,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                _context.Students.Add(student);
                await _context.SaveChangesAsync();

                // Auto-register student for the active job fair
                await _participationService.RegisterStudentForJobFairAsync(student.StudentId, activeJobFair.JobFairId);

                // Send credentials via email
                await SendStudentRegistrationEmail(email, tempPassword, activeJobFair);

                _logger.LogInformation("Student registered successfully: {Email}", email);

                return Ok(new
                {
                    Message = "Student registered successfully. Credentials sent via email.",
                    Email = email,
                    JobFairId = activeJobFair.JobFairId,
                    JobFairSemester = activeJobFair.Semester
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during student registration for: {Email}", email);
                return StatusCode(500, new { Message = "An error occurred during registration. Please try again." });
            }
        }

        // ========================================
        // COMPANY SIGNUP & OTP
        // ========================================

        [HttpPost("company-signup")]
        public async Task<IActionResult> CompanySignup([FromForm] CompanySignupDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            if (!_validationService.ValidateCompanySignup(dto, out var validationError))
                return BadRequest(validationError);

            // Check for duplicate emails
            if (await _context.Users.AnyAsync(u => u.Email == dto.UserEmail) ||
                await _context.Companies.AnyAsync(c => c.FocalPersonEmail == dto.FocalPersonEmail))
            {
                _logger.LogWarning("Company signup failed - email already exists");
                return BadRequest("User email or focal person email already exists.");
            }

            var activeJobFair = await _context.JobFairs.FirstOrDefaultAsync(j => j.IsActive);
            if (activeJobFair == null)
            {
                _logger.LogError("Company signup failed - no active job fair");
                return BadRequest("No active Job Fair found. Please activate a Job Fair first.");
            }

            try
            {
                // Save logo
                var logoUrl = await SaveCompanyLogo(dto.Logo);

                // Create User
                var user = new User
                {
                    Email = dto.UserEmail,
                    FullName = dto.UserFullName,
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.UserPassword),
                    Role = UserRole.Company,
                    IsActive = false,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                _context.Users.Add(user);
                await _context.SaveChangesAsync();

                // Create Company
                var company = new Company
                {
                    UserId = user.UserId,
                    JobFairId = activeJobFair.JobFairId,
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
                    IsPresent = false,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                _context.Companies.Add(company);
                await _context.SaveChangesAsync();

                // ✅ NEW: Create Company Job Fair Participation Record
                var participation = new CompanyJobFairParticipation
                {
                    CompanyId = company.CompanyId,
                    JobFairId = activeJobFair.JobFairId,
                    ArrivalStatus = ArrivalStatus.Pending,
                    RepsCount = dto.RepsCount,
                    InterviewDurationMinutes = dto.InterviewDurationMinutes,
                    RegisteredAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                _context.CompanyJobFairParticipations.Add(participation);

                // Add Job Offerings
                if (dto.JobOfferings != null && dto.JobOfferings.Count > 0)
                {
                    foreach (var jobDto in dto.JobOfferings)
                    {
                        var job = new Job
                        {
                            CompanyId = company.CompanyId,
                            JobFairId = activeJobFair.JobFairId, // ✅ FIX: Assign JobFairId
                            JobTitle = jobDto.JobTitle,
                            JobDescription = jobDto.JobDescription,
                            RequiredSkills = jobDto.RequiredSkills?.Split(',', StringSplitOptions.TrimEntries),
                            JobType = jobDto.Type,
                            NumberOfJobs = jobDto.JobCount,
                            CreatedAt = DateTime.UtcNow,
                            UpdatedAt = DateTime.UtcNow
                        };
                        _context.Jobs.Add(job);
                    }
                }

                // Add Contact Links
                if (dto.ContactLinks != null && dto.ContactLinks.Count > 0)
                {
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
                }

                await _context.SaveChangesAsync();

                // Generate and send OTP
                var otp = GenerateOtp();
                var cacheKey = $"company-otp:{dto.FocalPersonEmail.ToLower()}";
                _cache.Set(cacheKey, otp, TimeSpan.FromMinutes(OTP_EXPIRY_MINUTES));

                await SendCompanyOtpEmail(dto.FocalPersonEmail, otp);

                _logger.LogInformation("Company signed up successfully: {CompanyId}", company.CompanyId);

                return Ok(new
                {
                    Message = "Signup successful. OTP sent to focal person email.",
                    CompanyId = company.CompanyId,
                    JobFairId = activeJobFair.JobFairId,
                    LogoUrl = logoUrl
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during company signup");
                return StatusCode(500, new { Message = "An error occurred during signup. Please try again." });
            }
        }

        [HttpPost("company-verify-otp")]
        public async Task<IActionResult> VerifyCompanyOtp([FromBody] CompanyOtpVerifyDto dto)
        {
            if (!_validationService.ValidateCompanyOtpVerify(dto, out var validationError))
                return BadRequest(validationError);

            var cacheKey = $"company-otp:{dto.RepEmail.ToLower()}";
            if (!_cache.TryGetValue(cacheKey, out string? cachedOtp) || string.IsNullOrWhiteSpace(cachedOtp))
            {
                _logger.LogWarning("OTP verification failed - OTP not found for: {Email}", dto.RepEmail);
                return BadRequest("OTP expired or not found.");
            }

            if (!cachedOtp.Equals(dto.Otp, StringComparison.Ordinal))
            {
                _logger.LogWarning("OTP verification failed - invalid OTP for: {Email}", dto.RepEmail);
                return BadRequest("Invalid OTP.");
            }

            var user = await _context.Users.FirstOrDefaultAsync(u =>
                u.Email.ToLower() == dto.UserEmail.ToLower() && u.Role == UserRole.Company);

            if (user == null)
            {
                _logger.LogWarning("OTP verification failed - user not found: {Email}", dto.UserEmail);
                return NotFound("User not found.");
            }

            user.IsActive = true;
            user.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            _cache.Remove(cacheKey);

            _logger.LogInformation("Company account activated: {UserId}", user.UserId);

            return Ok(new { Message = "OTP verified. Company account activated." });
        }

        [HttpPost("company-resend-otp")]
        public async Task<IActionResult> ResendCompanyOtp([FromBody] CompanyResendOtpDto dto)
        {
            if (!_validationService.ValidateCompanyResendOtp(dto, out var validationError))
                return BadRequest(validationError);

            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Email.ToLower() == dto.UserEmail.ToLower() && u.Role == UserRole.Company);

            if (user == null)
            {
                _logger.LogWarning("Resend OTP failed - user not found: {Email}", dto.UserEmail);
                return NotFound("User not found.");
            }

            if (user.IsActive)
            {
                _logger.LogWarning("Resend OTP failed - account already activated: {UserId}", user.UserId);
                return BadRequest("Account is already activated.");
            }

            try
            {
                var otp = GenerateOtp();
                var cacheKey = $"company-otp:{dto.RepEmail.ToLower()}";
                _cache.Set(cacheKey, otp, TimeSpan.FromMinutes(OTP_EXPIRY_MINUTES));

                await SendCompanyOtpEmail(dto.RepEmail, otp);

                _logger.LogInformation("OTP resent for company: {UserId}", user.UserId);

                return Ok(new { Message = "OTP resent to representative email." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error resending OTP for user: {UserId}", user.UserId);
                return StatusCode(500, new { Message = "Failed to resend OTP. Please try again." });
            }
        }

        // ========================================
        // PASSWORD RESET
        // ========================================

        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordDto dto)
        {
            if (!_validationService.ValidateForgotPassword(dto, out var validationError))
                return BadRequest(validationError);

            var user = await _context.Users.FirstOrDefaultAsync(u =>
                u.Email.ToLower() == dto.Email.ToLower());

            if (user == null)
            {
                _logger.LogInformation("Forgot password request for non-existent email: {Email}", dto.Email);
                return BadRequest(new
                {
                    Code = "ACCOUNT_NOT_FOUND",
                    Message = "No account found with this email address. Please verify your email and try again."
                });
            }

            // Allow password reset for all accounts including Admin

            try
            {
                var resetToken = GenerateResetToken();
                var tokenHash = BCrypt.Net.BCrypt.HashPassword(resetToken);
                var expiryTime = DateTime.UtcNow.AddMinutes(TOKEN_EXPIRY_MINUTES);

                var cacheKey = $"password-reset:{user.UserId}";
                _cache.Set(cacheKey, new PasswordResetToken
                {
                    Token = tokenHash,
                    ExpiryTime = expiryTime,
                    Email = user.Email,
                    IsUsed = false
                }, TimeSpan.FromMinutes(TOKEN_EXPIRY_MINUTES));

                var resetLink = $"{_configuration["App:FrontendUrl"]}/reset-password?token={Uri.EscapeDataString(resetToken)}&userId={user.UserId}";

                await SendPasswordResetEmail(user.Email, user.FullName, resetLink);

                _logger.LogInformation("Password reset link sent for user: {UserId}", user.UserId);

                return Ok(new
                {
                    Message = "Password reset link has been sent to your email.",
                    ExpiryMinutes = TOKEN_EXPIRY_MINUTES
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending password reset email for user: {UserId}", user.UserId);
                return StatusCode(500, new { Message = "Failed to send reset email. Please try again." });
            }
        }

        [HttpPost("verify-reset-token")]
        public async Task<IActionResult> VerifyResetToken([FromBody] VerifyResetTokenDto dto)
        {
            if (!_validationService.ValidateVerifyResetToken(dto, out var validationError))
                return BadRequest(validationError);

            var user = await _context.Users.FirstOrDefaultAsync(u => u.UserId == dto.UserId);
            if (user == null)
            {
                _logger.LogWarning("Token verification failed - user not found: {UserId}", dto.UserId);
                return NotFound("User not found.");
            }

            var cacheKey = $"password-reset:{user.UserId}";
            if (!_cache.TryGetValue(cacheKey, out PasswordResetToken? cachedToken) || cachedToken == null)
            {
                _logger.LogWarning("Token verification failed - token not found for user: {UserId}", dto.UserId);
                return BadRequest("Reset token expired or not found. Please request a new one.");
            }

            if (cachedToken.IsUsed)
            {
                _logger.LogWarning("Token verification failed - token already used for user: {UserId}", dto.UserId);
                return BadRequest("This reset token has already been used.");
            }

            if (DateTime.UtcNow > cachedToken.ExpiryTime)
            {
                _cache.Remove(cacheKey);
                _logger.LogWarning("Token verification failed - token expired for user: {UserId}", dto.UserId);
                return BadRequest("Reset token has expired. Please request a new one.");
            }

            if (!BCrypt.Net.BCrypt.Verify(dto.Token, cachedToken.Token))
            {
                _logger.LogWarning("Token verification failed - invalid token for user: {UserId}", dto.UserId);
                return BadRequest("Invalid reset token.");
            }

            return Ok(new
            {
                Message = "Token verified successfully.",
                UserId = user.UserId,
                Email = user.Email
            });
        }

        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordDto dto)
        {
            if (!_validationService.ValidateResetPassword(dto, out var validationError))
                return BadRequest(validationError);

            var user = await _context.Users.FirstOrDefaultAsync(u => u.UserId == dto.UserId);
            if (user == null)
            {
                _logger.LogWarning("Password reset failed - user not found: {UserId}", dto.UserId);
                return NotFound("User not found.");
            }

            var cacheKey = $"password-reset:{user.UserId}";
            if (!_cache.TryGetValue(cacheKey, out PasswordResetToken? cachedToken) || cachedToken == null)
            {
                _logger.LogWarning("Password reset failed - token not found for user: {UserId}", dto.UserId);
                return BadRequest("Reset token expired or not found. Please request a new one.");
            }

            if (cachedToken.IsUsed)
            {
                _logger.LogWarning("Password reset failed - token already used for user: {UserId}", dto.UserId);
                return BadRequest("This reset token has already been used.");
            }

            if (DateTime.UtcNow > cachedToken.ExpiryTime)
            {
                _cache.Remove(cacheKey);
                _logger.LogWarning("Password reset failed - token expired for user: {UserId}", dto.UserId);
                return BadRequest("Reset token has expired. Please request a new one.");
            }

            if (!BCrypt.Net.BCrypt.Verify(dto.Token, cachedToken.Token))
            {
                _logger.LogWarning("Password reset failed - invalid token for user: {UserId}", dto.UserId);
                return BadRequest("Invalid reset token.");
            }

            try
            {
                user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.NewPassword);
                user.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                cachedToken.IsUsed = true;
                _cache.Remove(cacheKey);

                await SendPasswordChangedEmail(user.Email, user.FullName);

                _logger.LogInformation("Password reset successfully for user: {UserId}", user.UserId);

                return Ok(new { Message = "Password reset successfully. You can now login with your new password." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during password reset for user: {UserId}", dto.UserId);
                return StatusCode(500, new { Message = "An error occurred during password reset. Please try again." });
            }
        }

        [HttpPost("forgot-password/send-otp")]
        public async Task<IActionResult> SendPasswordResetOtp([FromBody] ForgotPasswordOtpDto dto)
        {
            if (!_validationService.ValidateForgotPasswordOtp(dto, out var validationError))
                return BadRequest(validationError);

            var input = dto.EmailOrRegNo.Trim();
            User? user = null;

            // Check if input is Registration No or Email
            if (Regex.IsMatch(input, REGISTRATION_NO_PATTERN, RegexOptions.IgnoreCase))
            {
                var student = await _context.Students
                    .Include(s => s.User)
                    .FirstOrDefaultAsync(s => s.RegistrationNo.ToUpper() == input.ToUpper());
                user = student?.User;

                if (user == null)
                {
                    _logger.LogWarning("Password reset OTP request - student account not found for registration number: {RegistrationNo}", input);
                    return BadRequest(new
                    {
                        Code = "STUDENT_NOT_FOUND",
                        Message = "No student account found with this registration number. Please verify your registration number and try again."
                    });
                }
            }
            else
            {
                user = await _context.Users.FirstOrDefaultAsync(u =>
                    u.Email.ToLower() == input.ToLower());

                if (user == null)
                {
                    _logger.LogWarning("Password reset OTP request - user account not found for email: {Email}", input);
                    return BadRequest(new
                    {
                        Code = "ACCOUNT_NOT_FOUND",
                        Message = "No account found with this email address. Please verify your email and try again."
                    });
                }

                // Allow all accounts including Admin
            }

            try
            {
                var otp = GenerateOtp();
                var cacheKey = $"password-reset-otp:{user.UserId}";

                _cache.Set(cacheKey, new PasswordResetOtpToken
                {
                    Otp = otp,
                    UserId = user.UserId,
                    Email = user.Email,
                    CreatedAt = DateTime.UtcNow,
                    IsUsed = false
                }, TimeSpan.FromMinutes(OTP_EXPIRY_MINUTES));

                await SendPasswordResetOtpEmail(user.Email, user.FullName, otp);

                _logger.LogInformation("Password reset OTP sent successfully for user: {UserId}, Email: {Email}", user.UserId, user.Email);

                return Ok(new
                {
                    Message = "OTP has been sent to your registered email address.",
                    ExpiryMinutes = OTP_EXPIRY_MINUTES,
                    UserId = user.UserId,
                    Email = user.Email
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending password reset OTP for user: {UserId}", user.UserId);
                return StatusCode(500, new { Message = "Failed to send OTP. Please try again later." });
            }
        }

        [HttpPost("forgot-password/verify-otp")]
        public async Task<IActionResult> VerifyPasswordResetOtp([FromBody] VerifyPasswordResetOtpDto dto)
        {
            if (!_validationService.ValidateVerifyPasswordResetOtp(dto, out var validationError))
                return BadRequest(validationError);

            var user = await _context.Users.FirstOrDefaultAsync(u => u.UserId == dto.UserId);
            if (user == null)
            {
                _logger.LogWarning("OTP verification failed - user not found: {UserId}", dto.UserId);
                return NotFound("User not found.");
            }

            var cacheKey = $"password-reset-otp:{user.UserId}";
            if (!_cache.TryGetValue(cacheKey, out PasswordResetOtpToken? otpToken) || otpToken == null)
            {
                _logger.LogWarning("OTP verification failed - OTP not found for user: {UserId}", dto.UserId);
                return BadRequest("OTP expired or not found. Please request a new one.");
            }

            if (otpToken.IsUsed)
            {
                _logger.LogWarning("OTP verification failed - OTP already used for user: {UserId}", dto.UserId);
                return BadRequest("This OTP has already been used.");
            }

            if (!otpToken.Otp.Equals(dto.Otp, StringComparison.Ordinal))
            {
                _logger.LogWarning("OTP verification failed - invalid OTP for user: {UserId}", dto.UserId);
                return BadRequest("Invalid OTP.");
            }

            if (DateTime.UtcNow.Subtract(otpToken.CreatedAt).TotalMinutes > OTP_EXPIRY_MINUTES)
            {
                _cache.Remove(cacheKey);
                _logger.LogWarning("OTP verification failed - OTP expired for user: {UserId}", dto.UserId);
                return BadRequest("OTP has expired. Please request a new one.");
            }

            try
            {
                user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.NewPassword);
                user.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                otpToken.IsUsed = true;
                _cache.Remove(cacheKey);

                await SendPasswordChangedEmail(user.Email, user.FullName);

                _logger.LogInformation("Password reset via OTP successful for user: {UserId}", user.UserId);

                return Ok(new { Message = "Password reset successfully. You can now login with your new password." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during OTP password reset for user: {UserId}", dto.UserId);
                return StatusCode(500, new { Message = "An error occurred during password reset. Please try again." });
            }
        }

        // ========================================
        // CHANGE PASSWORD (AUTHENTICATED USER)
        // ========================================

        [HttpPost("change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordDto dto)
        {
            if (!_validationService.ValidateChangePassword(dto, out var validationError))
                return BadRequest(validationError);

            // Get the authenticated user's ID from the JWT token
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out int userId))
            {
                _logger.LogWarning("Change password failed - unable to extract user ID from token");
                return Unauthorized("Invalid authentication token.");
            }

            var user = await _context.Users.FirstOrDefaultAsync(u => u.UserId == userId);
            if (user == null)
            {
                _logger.LogWarning("Change password failed - user not found: {UserId}", userId);
                return NotFound("User not found.");
            }

            // Verify current password
            if (!BCrypt.Net.BCrypt.Verify(dto.CurrentPassword, user.PasswordHash))
            {
                _logger.LogWarning("Change password failed - invalid current password for user: {UserId}", userId);
                return BadRequest("Current password is incorrect.");
            }

            try
            {
                // Update password
                user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.NewPassword);
                user.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                // Send confirmation email
                await SendPasswordChangedEmail(user.Email, user.FullName);

                _logger.LogInformation("Password changed successfully for user: {UserId}", userId);

                return Ok(new
                {
                    Message = "Password changed successfully.",
                    UserId = user.UserId,
                    Email = user.Email
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during password change for user: {UserId}", userId);
                return StatusCode(500, new { Message = "An error occurred while changing your password. Please try again." });
            }
        }
        
        // ========================================
        // PRIVATE HELPER METHODS
        // ========================================

        private object BuildIncompleteProfileResponse(User user, Student student, string token)
        {
            return new
            {
                Token = token,
                Role = user.Role.ToString(),
                ProfileComplete = false,
                UserId = user.UserId,
                StudentId = student.StudentId,
                Student = new
                {
                    student.RegistrationNo,
                    student.Department,
                    student.CGPA,
                    ProfilePicUrl = student.ProfilePicUrl,
                    Skills = student.Skills ?? new List<string>(),
                    User = new
                    {
                        user.UserId,
                        user.Email,
                        user.FullName,
                        user.Phone
                    }
                }
            };
        }

        private object BuildCompleteProfileResponse(User user, Student student, string token)
        {
            var fyp = student.StudentProjects
                .FirstOrDefault(sp => sp.Project?.Type == ProjectType.FinalYear)?.Project;

            return new
            {
                Token = token,
                Role = user.Role.ToString(),
                ProfileComplete = true,
                UserId = user.UserId,
                StudentId = student.StudentId,
                Student = new StudentLoginResponseDto
                {
                    StudentId = student.StudentId,
                    RegistrationNo = student.RegistrationNo,
                    Department = student.Department,
                    CGPA = student.CGPA,
                    ProfilePicUrl = student.ProfilePicUrl,
                    CvUrl = student.CvUrl,
                    Skills = student.Skills,
                    FcmToken = student.FcmToken,
                    CreatedAt = student.CreatedAt,
                    UpdatedAt = student.UpdatedAt,
                    Experiences = student.Experiences?.Select(e => new ExperienceDto
                    {
                        ExperienceId = e.ExperienceId,
                        CompanyName = e.CompanyName,
                        Role = e.Role,
                        StartDate = e.StartDate,
                        EndDate = e.EndDate,
                        IsCurrent = e.IsCurrent,
                        Location = e.Location,
                        Description = e.Description
                    }).ToList() ?? new List<ExperienceDto>(),
                    Educations = student.Educations?.Select(e => new EducationDto
                    {
                        EducationId = e.EducationId,
                        InstitutionName = e.InstitutionName,
                        Degree = e.Degree,
                        FieldOfStudy = e.FieldOfStudy,
                        StartDate = e.StartDate,
                        EndDate = e.EndDate,
                        IsCurrent = e.IsCurrent,
                        GradeType = e.GradeType,
                        GradeValue = e.GradeValue,
                        MarksObtained = e.MarksObtained,
                        TotalMarks = e.TotalMarks,
                        CGPA = e.CGPA,
                        Location = e.Location
                    }).ToList() ?? new List<EducationDto>(),
                    Achievements = student.Achievements?.Select(a => new AchievementDto
                    {
                        AchievementId = a.AchievementId,
                        Title = a.Title,
                        Description = a.Description,
                        DateAchieved = a.DateAchieved
                    }).ToList() ?? new List<AchievementDto>(),
                    Certifications = student.Certifications?.Select(c => new CertificationDto
                    {
                        CertificationId = c.CertificationId,
                        Title = c.Title,
                        Issuer = c.Issuer,
                        IssueDate = c.IssueDate,
                        CredentialUrl = c.CredentialUrl,
                        CredentialId = c.CredentialId
                    }).ToList() ?? new List<CertificationDto>(),
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
                }
            };
        }

        private async Task<string?> SaveCompanyLogo(IFormFile? logoFile)
        {
            if (logoFile == null || logoFile.Length == 0)
                return null;

            try
            {
                var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", "companies", "logo");
                Directory.CreateDirectory(uploadsFolder);

                var fileName = $"{Guid.NewGuid()}{Path.GetExtension(logoFile.FileName)}";
                var filePath = Path.Combine(uploadsFolder, fileName);

                using var stream = new FileStream(filePath, FileMode.Create);
                await logoFile.CopyToAsync(stream);

                return $"/uploads/companies/logo/{fileName}";
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error saving company logo");
                return null;
            }
        }

        private async Task SendStudentRegistrationEmail(string email, string tempPassword, JobFair jobFair)
        {
            var subject = "Welcome to Job Fair Portal — Your Login Credentials";
            var body = EmailTemplateService.GetStudentWelcomeTemplate(
                email,
                tempPassword,
                jobFair.Semester ?? "Upcoming Semester",
                jobFair.date.ToString("MMMM dd, yyyy"));
            await _mailService.SendMailAsync(email, subject, body);
        }

        private async Task SendCompanyOtpEmail(string email, string otp)
        {
            var subject = "Company Registration Verification — Job Fair Portal";
            var body = EmailTemplateService.GetCompanyOtpTemplate(otp, OTP_EXPIRY_MINUTES);
            await _mailService.SendMailAsync(email, subject, body);
        }

        private async Task SendPasswordResetEmail(string email, string? fullName, string resetLink)
        {
            var subject = "Password Reset Request — Job Fair Portal";
            var body = EmailTemplateService.GetPasswordResetLinkTemplate(
                fullName ?? "User", resetLink, TOKEN_EXPIRY_MINUTES);
            await _mailService.SendMailAsync(email, subject, body);
        }

        private async Task SendPasswordResetOtpEmail(string email, string? fullName, string otp)
        {
            var subject = "Password Reset OTP — Job Fair Portal";
            var body = EmailTemplateService.GetPasswordResetOtpTemplate(
                fullName ?? "User", otp, OTP_EXPIRY_MINUTES);
            await _mailService.SendMailAsync(email, subject, body);
        }

        private async Task SendPasswordChangedEmail(string email, string? fullName)
        {
            var subject = "Password Changed Successfully — Job Fair Portal";
            var body = EmailTemplateService.GetPasswordChangedTemplate(fullName ?? "User");
            await _mailService.SendMailAsync(email, subject, body);
        }

        private string GenerateResetToken()
        {
            var randomBytes = new byte[32];
            using var rng = RandomNumberGenerator.Create();
            rng.GetBytes(randomBytes);
            return Convert.ToBase64String(randomBytes);
        }

        private string GenerateOtp()
        {
            using var rng = RandomNumberGenerator.Create();
            var buffer = new byte[sizeof(int)];
            rng.GetBytes(buffer);
            var randomNumber = Math.Abs(BitConverter.ToInt32(buffer, 0));
            return (randomNumber % 900000 + 100000).ToString();
        }

        private string GenerateTemporaryPassword()
        {
            const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%";
            var random = new Random();
            var password = new StringBuilder();

            for (int i = 0; i < PASSWORD_MIN_LENGTH; i++)
            {
                password.Append(chars[random.Next(chars.Length)]);
            }

            return password.ToString();
        }
    }
}