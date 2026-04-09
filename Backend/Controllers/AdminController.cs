using CsvHelper;
using CsvHelper.Configuration;
using JobFairPortal.Data;
using JobFairPortal.DTOs;
using JobFairPortal.Helpers;
using JobFairPortal.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using OfficeOpenXml; 
using System.Globalization; 
using System.Text;
using System.Text.Json;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using FirebaseAdmin.Messaging;
using Microsoft.Extensions.Configuration; 
using Notification = FirebaseAdmin.Messaging.Notification;
using Microsoft.Extensions.Caching.Memory;
using FirebaseAdmin;
using JobFairPortal.Services;
using System.Security.Claims;



namespace JobFairPortal.Controllers

{
    // -----------------------------
    // Controller
    // -----------------------------
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "Admin,CoAdmin")]
    public class AdminController : ControllerBase

    {
        private readonly JobFairRecruitmentDbContext _context;

        private readonly ILogger<AdminController> _logger;
        private readonly IMemoryCache _cache;
        private readonly MailKitMailService _mailService;



        public AdminController(JobFairRecruitmentDbContext context, ILogger<AdminController> logger, IMemoryCache cache, MailKitMailService mailService)
        {
            _context = context;
            _logger = logger;
            _cache = cache;
            _mailService = mailService;
        }

        private bool IsSuperAdmin()
        {
            var roleClaim = User.FindFirst(ClaimTypes.Role)?.Value;
            return string.Equals(roleClaim, UserRole.Admin.ToString(), StringComparison.OrdinalIgnoreCase);
        }

        private IActionResult SuperAdminOnly(string action)
        {
            return StatusCode(403, new
            {
                Code = "FORBIDDEN",
                Message = $"Only super admin can {action}."
            });
        }

        // Note: Admin/Co-admin creation now uses OTP-based flow via 
        // POST /api/admin/admins/request-otp and POST /api/admin/admins/create (see CreateAdminUser method below)

        // -----------------------------
        // Get All Companies (Global List, regardless of participation)
        // -----------------------------
            [HttpGet("companies/all")]
            public async Task<IActionResult> GetAllCompaniesGlobal(
                [FromQuery] int page = 1,
                [FromQuery] int pageSize = 20,
                [FromQuery] string? search = null)
            {
                _logger.LogInformation("GetAllCompaniesGlobal called.");

                if (page < 1) page = 1;
                if (pageSize < 1) pageSize = 20;

                var query = _context.Companies
                    .Include(c => c.User)
                    .Include(c => c.Room)
                    .Include(c => c.Jobs)
                    .Include(c => c.Interviews)
                    .AsQueryable();

                // Search filter
                if (!string.IsNullOrWhiteSpace(search))
                {
                    var searchLower = search.ToLower();
                    query = query.Where(c =>
                        (c.Name ?? string.Empty).ToLower().Contains(searchLower) ||
                        (c.Industry ?? string.Empty).ToLower().Contains(searchLower) ||
                        (c.CompanyEmail ?? string.Empty).ToLower().Contains(searchLower)
                    );
                }

                var totalCount = await query.CountAsync();
                var companies = await query
                    .OrderBy(c => c.Name)
                    .Skip((page - 1) * pageSize)
                    .Take(pageSize)
                    .Select(c => new {
                        CompanyId = c.CompanyId,
                        Name = c.Name,
                        Industry = c.Industry,
                        LogoUrl = c.LogoUrl,
                        ProfilePicUrl = c.LogoUrl,
                        Website = c.Website,
                        UserEmail = c.User != null ? c.User.Email : null,
                        UserPhone = c.User != null ? c.User.Phone : null,
                        CompanyEmail = c.CompanyEmail,
                        CompanyPhone = c.CompanyPhone,
                        FocalPersonName = c.FocalPersonName,
                        FocalPersonEmail = c.FocalPersonEmail,
                        FocalPersonPhone = c.FocalPersonPhone,
                        RoomName = c.Room != null ? c.Room.RoomName : null,
                        IsBlocked = c.IsBlocked,
                        RepsCount = c.RepsCount,
                        TotalJobs = c.Jobs.Count(),
                        TotalInterviews = c.Interviews.Count(),
                        CreatedAt = c.CreatedAt,
                        UpdatedAt = c.UpdatedAt
                    })
                    .ToListAsync();

                return Ok(new
                {
                    TotalCount = totalCount,
                    Page = page,
                    PageSize = pageSize,
                    TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
                    Companies = companies
                });
            }
        // -----------------------------
        // 24. Get All Students (Global List with Participation Status)
        // -----------------------------
        [HttpGet("students/all")]
        public async Task<IActionResult> GetAllStudentsGlobal(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20,
            [FromQuery] string? search = null,
            [FromQuery] string? department = null)
        {
            _logger.LogInformation("GetAllStudentsGlobal called.");

            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 20;

            var activeJobFairId = await GetActiveJobFairIdAsync();

            var query = _context.Students
                .Include(s => s.User)
                .AsQueryable();

            // Search filter
            if (!string.IsNullOrWhiteSpace(search))
            {
                var searchLower = search.ToLower();
                query = query.Where(s =>
                    (s.User != null && (s.User.FullName ?? string.Empty).ToLower().Contains(searchLower)) ||
                    s.RegistrationNo.ToLower().Contains(searchLower) ||
                    (s.User != null && (s.User.Email ?? string.Empty).ToLower().Contains(searchLower)));
            }

            // Department filter
            if (!string.IsNullOrWhiteSpace(department))
            {
                query = query.Where(s => s.Department == department);
            }

            var totalCount = await query.CountAsync();

            var students = await query
                .OrderBy(s => s.StudentId)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(s => new
                {
                    StudentId = s.StudentId,
                    Name = s.User != null ? s.User.FullName : null,
                    Email = s.User != null ? s.User.Email : null,
                    RegistrationNo = s.RegistrationNo,
                    Department = s.Department,
                    CGPA = s.CGPA,
                    CvUrl = s.CvUrl,
                    // Check if they have a participation record for the active job fair
                    Participation = activeJobFairId.HasValue
                        ? s.JobFairParticipations
                            .Where(p => p.JobFairId == activeJobFairId.Value)
                            .Select(p => new { p.ParticipationId, p.RegisteredAt })
                            .FirstOrDefault()
                        : null
                })
                .ToListAsync();

            // Map to final response structure
            var response = students.Select(s => new
            {
                s.StudentId,
                s.Name,
                s.Email,
                s.RegistrationNo,
                s.Department,
                s.CGPA,
                s.CvUrl,
                IsRegistered = s.Participation != null,
                ParticipationId = s.Participation?.ParticipationId,
                RegisteredAt = s.Participation?.RegisteredAt
            });

            return Ok(new
            {
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize,
                TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
                Students = response
            });
        }

        // -----------------------------
        // 2. Add Room
        // -----------------------------
        [HttpPost("rooms")]
        public async Task<IActionResult> AddRoom([FromBody] RoomCreateDto dto, [FromQuery] int? jobFairId = null)
        {
            jobFairId ??= await GetActiveJobFairIdAsync();
            if (jobFairId == null)
                return BadRequest("No active job fair found.");

            var room = new Room
            {
                RoomName = dto.RoomName,
                Capacity = dto.Capacity,
                Status = RoomStatus.Vacant,
                JobFairId = jobFairId.Value,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.Rooms.Add(room);
            await _context.SaveChangesAsync();
            _cache.Remove("dashboard_stats");

            return Ok(new RoomResponseDto
            {
                RoomId = room.RoomId,
                RoomName = room.RoomName,
                Capacity = room.Capacity,
                Status = room.Status
            });
        }
        [HttpPost("rooms/bulk-upload")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> BulkUploadRoomsFromFile(IFormFile file)
        {
            if (file == null || file.Length == 0)
                return BadRequest(new { Message = "No file was uploaded." });

            // FIX 1: Get Active Job Fair ID first
            var jobFairId = await GetActiveJobFairIdAsync();
            if (jobFairId == null)
                return BadRequest(new { Message = "No active job fair found. Cannot upload rooms." });

            var fileExtension = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (fileExtension != ".csv" && fileExtension != ".xlsx")
                return BadRequest(new { Message = "Invalid file format. Please upload a .csv or .xlsx file." });

            var roomsToCreate = new List<Room>();
            var roomsToUpdate = new List<Room>();
            var errors = new List<string>();

            ExcelPackage.License.SetNonCommercialPersonal("Hassan Askari");

            try
            {
                using (var stream = new MemoryStream())
                {
                    await file.CopyToAsync(stream);
                    stream.Position = 0;

                    if (fileExtension == ".xlsx")
                    {
                        // FIX 2: Pass jobFairId to the parser
                        await ParseXlsxStream(stream, roomsToCreate, roomsToUpdate, errors, jobFairId.Value);
                    }
                    else
                    {
                        // FIX 2: Pass jobFairId to the parser
                        await ParseCsvStream(stream, roomsToCreate, roomsToUpdate, errors, jobFairId.Value);
                    }
                }

                if (!roomsToCreate.Any() && !roomsToUpdate.Any())
                {
                    return BadRequest(new { Message = "No valid room data found to process.", Errors = errors });
                }

                if (roomsToCreate.Any())
                    await _context.Rooms.AddRangeAsync(roomsToCreate);

                if (roomsToUpdate.Any())
                    _context.Rooms.UpdateRange(roomsToUpdate);

                await _context.SaveChangesAsync();

                var message = $"Bulk upload finished. Added {roomsToCreate.Count}, Updated {roomsToUpdate.Count}.";
                return Ok(new { Message = message, Errors = errors });
            }
            catch (DbUpdateException dbEx)
            {
                _logger.LogError(dbEx, "Database error during bulk upload.");
                // This error message will now actually be relevant
                return StatusCode(500, new { Message = "Database error.", Details = dbEx.InnerException?.Message ?? dbEx.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error during bulk upload.");
                return StatusCode(500, new { Message = "An unexpected error occurred.", Details = ex.Message });
            }
        }
        [HttpGet("rooms/download")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        public async Task<IActionResult> DownloadRoomsTemplate()
        {

            ExcelPackage.License.SetNonCommercialPersonal("Hassan Askari");

            // Retrieve all rooms from the database
            var rooms = await _context.Rooms.ToListAsync();

            // Create the Excel file and populate it
            var stream = new MemoryStream();
            using (var package = new ExcelPackage(stream))
            {
                var worksheet = package.Workbook.Worksheets.Add("Rooms");

                // Define headers
                worksheet.Cells[1, 1].Value = "RoomName";
                worksheet.Cells[1, 2].Value = "Capacity";
                worksheet.Cells[1, 3].Value = "Status";

                // Add data from the database starting from row 2
                for (int i = 0; i < rooms.Count; i++)
                {
                    worksheet.Cells[i + 2, 1].Value = rooms[i].RoomName;
                    worksheet.Cells[i + 2, 2].Value = rooms[i].Capacity;
                    worksheet.Cells[i + 2, 3].Value = rooms[i].Status.ToString();
                }

                // Auto-fit columns for better readability
                worksheet.Cells[worksheet.Dimension.Address].AutoFitColumns();

                await package.SaveAsync();
            }

            stream.Position = 0;

            // Return the file for download
            var fileName = $"Rooms_{DateTime.Now:yyyyMMdd}.xlsx";
            return File(stream, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", fileName);
        }  // -----------------------------
           // 3. Get All Rooms
           // -----------------------------
           // 3. Get All Rooms
           // -----------------------------
        [HttpGet("rooms")]
        public async Task<IActionResult> GetRooms([FromQuery] int? jobFairId = null)
        {
            // Default to active job fair if not specified
            jobFairId ??= await GetActiveJobFairIdAsync();

            if (jobFairId == null)
                return BadRequest("No active job fair found.");

            var rooms = await _context.Rooms
                .Include(r => r.Company)
                .Where(r => r.JobFairId == jobFairId.Value) // âœ… Filter by JobFairId
                .Select(r => new RoomResponseDto
                {
                    RoomId = r.RoomId,
                    RoomName = r.RoomName,
                    Capacity = r.Capacity,
                    Status = r.Status,
                    CompanyName = r.Company != null ? r.Company.Name : null,
                    CompanyId = r.CompanyId,
                    CompanyRepsCount = r.Company != null ? r.Company.RepsCount : null
                })
                .ToListAsync();

            return Ok(rooms);
        }
        // -----------------------------
        // 4. Get All Companies
        // -----------------------------
            // -----------------------------
            // Block/Unblock Company for Current Job Fair
            // -----------------------------

            [HttpPut("companies/{companyId}/block")]
            public async Task<IActionResult> BlockCompany(int companyId)
            {
                var company = await _context.Companies.Include(c => c.JobFairParticipations).FirstOrDefaultAsync(c => c.CompanyId == companyId);
                if (company == null)
                    return NotFound(new { Message = "Company not found." });

                // Set IsBlocked true (blocks login)
                company.IsBlocked = true;
                company.UpdatedAt = DateTime.UtcNow;

                // Remove participation for active job fair
                var activeJobFair = await _context.JobFairs.FirstOrDefaultAsync(j => j.IsActive);
                if (activeJobFair != null)
                {
                    var participation = company.JobFairParticipations.FirstOrDefault(p => p.JobFairId == activeJobFair.JobFairId);
                    if (participation != null)
                    {
                        _context.CompanyJobFairParticipations.Remove(participation);
                    }
                }

                await _context.SaveChangesAsync();
                return Ok(new { Message = "Company blocked and participation cancelled for current job fair." });
            }

            [HttpPut("companies/{companyId}/unblock")]
            public async Task<IActionResult> UnblockCompany(int companyId)
            {
                var company = await _context.Companies.FirstOrDefaultAsync(c => c.CompanyId == companyId);
                if (company == null)
                    return NotFound(new { Message = "Company not found." });

                company.IsBlocked = false;
                company.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();
                return Ok(new { Message = "Company unblocked. They can now log in and register for future job fairs." });
            }

        [HttpGet("companies")]
        public async Task<IActionResult> GetCompanies([FromQuery] int? jobFairId = null, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            jobFairId ??= await GetActiveJobFairIdAsync();
            if (jobFairId == null)
                return BadRequest("No active job fair found.");

            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 20;

            // âœ… FIX: Query Participation to get status specific to this Job Fair
            var query = _context.CompanyJobFairParticipations
                .Include(p => p.Company)
                    .ThenInclude(c => c.User)
                .Include(p => p.Company)
                    .ThenInclude(c => c.Room)
                .Include(p => p.Company)
                    .ThenInclude(c => c.Interviews)
                .Include(p => p.Company)
                    .ThenInclude(c => c.Jobs)
                .Where(p => p.JobFairId == jobFairId.Value);

            var totalCount = await query.CountAsync();
            var participations = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var companies = participations.Select(p => new
            {
                CompanyId = p.CompanyId,
                Name = p.Company.Name,
                Industry = p.Company.Industry,
                LogoUrl = p.Company.LogoUrl,
                ProfilePicUrl = p.Company.LogoUrl,
                Website = p.Company.Website,
                UserEmail = p.Company.User != null ? p.Company.User.Email : null,
                UserPhone = p.Company.User != null ? p.Company.User.Phone : null,
                CompanyEmail = p.Company.CompanyEmail,
                CompanyPhone = p.Company.CompanyPhone,
                Email = p.Company.CompanyEmail,
                ContactEmail = p.Company.CompanyEmail,
                ContactNo = p.Company.CompanyPhone,
                FocalPersonName = p.Company.FocalPersonName,
                FocalPersonEmail = p.Company.FocalPersonEmail,
                FocalPersonPhone = p.Company.FocalPersonPhone,
                RoomName = p.Company.Room != null ? p.Company.Room.RoomName : null,
                ArrivalStatus = p.ArrivalStatus.ToString(), // âœ… Correct status for this fair
                IsPresent = p.IsPresent,                    // âœ… Correct presence for this fair
                RepsCount = p.Company.RepsCount,
                TotalJobs = p.Company.Jobs.Count(j => j.JobFairId == jobFairId.Value),
                TotalInterviews = p.Company.Interviews.Count(i => i.JobFairId == jobFairId.Value),
                HiredCount = p.Company.Interviews.Count(i => i.JobFairId == jobFairId.Value && i.Status == InterviewStatus.Hired),
                ShortlistedCount = p.Company.Interviews.Count(i => i.JobFairId == jobFairId.Value && i.Status == InterviewStatus.Shortlisted),
                RejectedCount = p.Company.Interviews.Count(i => i.JobFairId == jobFairId.Value && i.Status == InterviewStatus.Rejected),
                CreatedAt = p.RegisteredAt,
                UpdatedAt = p.UpdatedAt
            });

            return Ok(new
            {
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize,
                TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
                Companies = companies
            });
        }
        [HttpGet("companies/{companyId}/details")]
        public async Task<IActionResult> GetCompanyDetail(int companyId)
        {
            _logger.LogInformation("GetCompanyDetail called for companyId: {CompanyId}", companyId);

            var company = await _context.Companies
                .Include(c => c.User)
                .Include(c => c.Room)
                .Include(c => c.Interviews)
                    .ThenInclude(i => i.Student)
                        .ThenInclude(s => s.User)
                .Include(c => c.InterviewRequests)
                    .ThenInclude(ir => ir.Student)
                        .ThenInclude(s => s.User)
                .Include(c => c.Jobs)
                .Include(c => c.CompanyContactLinks)
                .Include(c => c.JobFairParticipations)
                    .ThenInclude(p => p.JobFair)
                .Include(c => c.JobFairParticipations)
                    .ThenInclude(p => p.Room)
                .FirstOrDefaultAsync(c => c.CompanyId == companyId);

            if (company == null)
                return NotFound(new { Message = "Company not found." });

            // Get participation for current/active job fair
            var activeJobFair = await _context.JobFairs.FirstOrDefaultAsync(j => j.IsActive);
            var participation = company.JobFairParticipations.FirstOrDefault(p => p.JobFairId == (company.CurrentJobFairId ?? activeJobFair?.JobFairId));

            var detail = new
            {
                // --- Basic Company Info ---
                CompanyId = company.CompanyId,
                Name = company.Name,
                Industry = company.Industry,
                Description = company.Description,
                Website = company.Website,
                LogoUrl = company.LogoUrl,
                Address = company.Address,

                // --- Contact Information ---
                ContactDetails = new
                {
                    Email = company.CompanyEmail,
                    Phone = company.CompanyPhone
                },

                // --- Focal Person Information ---
                FocalPerson = new
                {
                    Name = company.FocalPersonName,
                    Email = company.FocalPersonEmail,
                    Phone = company.FocalPersonPhone
                },

                // --- Room Assignment ---
                Room = company.Room != null ? new
                {
                    RoomId = company.Room.RoomId,
                    RoomName = company.Room.RoomName,
                    Capacity = company.Room.Capacity,
                    Status = company.Room.Status.ToString()
                } : null,

                // --- Company Status ---
                ArrivalStatus = participation?.ArrivalStatus.ToString() ?? "Pending",
                IsPresent = company.IsPresent,
                RepsCount = company.RepsCount,
                InterviewDurationMinutes = company.InterviewDurationMinutes,
                CurrentParticipation = participation != null ? new
                {
                    ParticipationId = participation.ParticipationId,
                    JobFairId = participation.JobFairId,
                    JobFairSemester = participation.JobFair?.Semester,
                    JobFairDate = participation.JobFair?.date,
                    IsActiveJobFair = participation.JobFair?.IsActive ?? false,
                    ArrivalStatus = participation.ArrivalStatus.ToString(),
                    IsPresent = participation.IsPresent,
                    RepsCount = participation.RepsCount,
                    InterviewDurationMinutes = participation.InterviewDurationMinutes,
                    Room = participation.Room != null ? new
                    {
                        participation.Room.RoomId,
                        participation.Room.RoomName,
                        participation.Room.Capacity,
                        Status = participation.Room.Status.ToString()
                    } : null,
                    RegisteredAt = participation.RegisteredAt,
                    UpdatedAt = participation.UpdatedAt
                } : null,

                ParticipationHistory = company.JobFairParticipations
                    .OrderByDescending(p => p.RegisteredAt)
                    .Select(p => new
                    {
                        ParticipationId = p.ParticipationId,
                        JobFairId = p.JobFairId,
                        JobFairSemester = p.JobFair != null ? p.JobFair.Semester : null,
                        JobFairDate = p.JobFair != null ? p.JobFair.date : (DateTime?)null,
                        IsActiveJobFair = p.JobFair != null && p.JobFair.IsActive,
                        ArrivalStatus = p.ArrivalStatus.ToString(),
                        IsPresent = p.IsPresent,
                        RepsCount = p.RepsCount,
                        InterviewDurationMinutes = p.InterviewDurationMinutes,
                        Room = p.Room != null ? new
                        {
                            p.Room.RoomId,
                            p.Room.RoomName,
                            p.Room.Capacity,
                            Status = p.Room.Status.ToString()
                        } : null,
                        RegisteredAt = p.RegisteredAt,
                        UpdatedAt = p.UpdatedAt
                    }).ToList(),

                // --- Social Media & Contact Links ---
                ContactLinks = company.CompanyContactLinks.Select(cl => new
                {
                    cl.LinkId,
                    Platform = cl.Platform.ToString(),
                    cl.Url
                }).ToList(),

                // --- Job Openings ---
                TotalJobs = company.Jobs.Count,
                Jobs = company.Jobs.Select(j => new
                {
                    j.JobId,
                    j.JobFairId,
                    j.JobTitle,
                    j.JobDescription,
                    j.RequiredSkills,
                    j.JobType,
                    j.NumberOfJobs,
                    AllSkillsRequired = string.Join(", ", j.RequiredSkills ?? new string[] { })
                }).ToList(),

                // --- Interview Statistics ---
                InterviewStats = new
                {
                    TotalInterviews = company.Interviews.Count,
                    Hired = company.Interviews.Count(i => i.Status == InterviewStatus.Hired),
                    Shortlisted = company.Interviews.Count(i => i.Status == InterviewStatus.Shortlisted),
                    Rejected = company.Interviews.Count(i => i.Status == InterviewStatus.Rejected),
                    Pending = company.Interviews.Count(i => i.Status == InterviewStatus.Queued)
                },

                // --- Scheduled Interviews ---
                ScheduledInterviews = company.Interviews
                    .Where(i => i.ScheduledTime.HasValue)
                    .OrderBy(i => i.ScheduledTime)
                    .Select(i => new
                    {
                        i.InterviewId,
                        i.JobFairId,
                        StudentName = i.Student.User.FullName,
                        StudentRegistration = i.Student.RegistrationNo,
                        StudentEmail = i.Student.User.Email,
                        StudentPhone = i.Student.User.Phone,
                        InterviewDate = i.ScheduledTime,
                        Status = i.Status.ToString(),

                    }).ToList(),

                // --- Hired Students ---
                HiredStudents = company.Interviews
                    .Where(i => i.Status == InterviewStatus.Hired)
                    .Select(i => new
                    {
                        i.InterviewId,
                        i.JobFairId,
                        StudentId = i.Student.StudentId,
                        StudentName = i.Student.User.FullName,
                        StudentRegistration = i.Student.RegistrationNo,
                        Department = i.Student.Department,
                        CGPA = i.Student.CGPA,
                        StudentEmail = i.Student.User.Email,
                        StudentPhone = i.Student.User.Phone,
                        HiredDate = i.UpdatedAt
                    }).ToList(),

                // --- Shortlisted Students ---
                ShortlistedStudents = company.Interviews
                    .Where(i => i.Status == InterviewStatus.Shortlisted)
                    .Select(i => new
                    {
                        i.InterviewId,
                        i.JobFairId,
                        StudentId = i.Student.StudentId,
                        StudentName = i.Student.User.FullName,
                        StudentRegistration = i.Student.RegistrationNo,
                        Department = i.Student.Department,
                        CGPA = i.Student.CGPA,
                        StudentEmail = i.Student.User.Email,
                        StudentPhone = i.Student.User.Phone,
                        ShortlistedDate = i.UpdatedAt
                    }).ToList(),

                // --- Rejected Students ---
                RejectedStudents = company.Interviews
                    .Where(i => i.Status == InterviewStatus.Rejected)
                    .Select(i => new
                    {
                        i.InterviewId,
                        i.JobFairId,
                        StudentId = i.Student.StudentId,
                        StudentName = i.Student.User.FullName,
                        StudentRegistration = i.Student.RegistrationNo,
                        Department = i.Student.Department,
                        CGPA = i.Student.CGPA,
                        RejectedDate = i.UpdatedAt
                    }).ToList(),

                // --- Interview Requests from Students ---
                InterviewRequests = company.InterviewRequests
                    .OrderByDescending(ir => ir.CreatedAt)
                    .Select(ir => new
                    {
                        ir.RequestId,
                        ir.JobFairId,
                        StudentId = ir.Student.StudentId,
                        StudentName = ir.Student.User.FullName,
                        StudentRegistration = ir.Student.RegistrationNo,
                        Department = ir.Student.Department,
                        CGPA = ir.Student.CGPA,
                        StudentEmail = ir.Student.User.Email,
                        Status = ir.Status.ToString(),
                        RejectionReason = ir.ReasonForReject,
                        RequestDate = ir.CreatedAt,
                        ResponseDate = ir.UpdatedAt
                    }).ToList(),

                // --- User Account Info ---
                AccountInfo = company.User != null ? new
                {
                    UserId = company.User.UserId,
                    Email = company.User.Email,
                    Phone = company.User.Phone,
                    IsActive = company.User.IsActive,
                    CreatedAt = company.User.CreatedAt
                } : null,

                // --- Timestamps ---
                CreatedAt = company.CreatedAt,
                UpdatedAt = company.UpdatedAt
            };

            return Ok(detail);
        }

        [HttpPut("companies/{companyId}/profile")]
        public async Task<IActionResult> UpdateCompanyProfile(int companyId, [FromBody] AdminUpdateCompanyProfileDto dto)
        {
            if (dto == null)
                return BadRequest(new { Message = "Request body is required." });

            var company = await _context.Companies.FirstOrDefaultAsync(c => c.CompanyId == companyId);
            if (company == null)
                return NotFound(new { Message = "Company not found." });

            if (!string.IsNullOrWhiteSpace(dto.Name)) company.Name = dto.Name.Trim();
            if (!string.IsNullOrWhiteSpace(dto.Industry)) company.Industry = dto.Industry.Trim();
            if (dto.Description != null) company.Description = dto.Description.Trim();
            if (dto.Website != null) company.Website = dto.Website.Trim();
            if (dto.Address != null) company.Address = dto.Address.Trim();
            if (dto.CompanyEmail != null) company.CompanyEmail = dto.CompanyEmail.Trim();
            if (dto.CompanyPhone != null) company.CompanyPhone = dto.CompanyPhone.Trim();
            if (!string.IsNullOrWhiteSpace(dto.FocalPersonName)) company.FocalPersonName = dto.FocalPersonName.Trim();
            if (!string.IsNullOrWhiteSpace(dto.FocalPersonEmail)) company.FocalPersonEmail = dto.FocalPersonEmail.Trim();
            if (!string.IsNullOrWhiteSpace(dto.FocalPersonPhone)) company.FocalPersonPhone = dto.FocalPersonPhone.Trim();
            if (dto.RepsCount.HasValue && dto.RepsCount.Value > 0) company.RepsCount = dto.RepsCount.Value;
            if (dto.InterviewDurationMinutes.HasValue && dto.InterviewDurationMinutes.Value > 0)
                company.InterviewDurationMinutes = dto.InterviewDurationMinutes.Value;

            company.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Company profile updated successfully.",
                CompanyId = company.CompanyId,
                UpdatedAt = company.UpdatedAt
            });
        }
        // ... (GetCompanyDetail remains mostly same, but could be enhanced similarly if needed) ...

        [HttpGet("companies/filter")]
        public async Task<IActionResult> FilterCompanies(
            [FromQuery] string? industry,
            [FromQuery] string? arrivalStatus,
            [FromQuery] bool? isPresent,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            _logger.LogInformation("FilterCompanies called with industry: {Industry}, arrivalStatus: {ArrivalStatus}, isPresent: {IsPresent}",
                industry, arrivalStatus, isPresent);

            var activeJobFairId = await GetActiveJobFairIdAsync();
            if (activeJobFairId == null) return BadRequest("No active job fair.");

            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 20;

            // âœ… FIX: Filter on Participation
            var query = _context.CompanyJobFairParticipations
                .Include(p => p.Company)
                    .ThenInclude(c => c.User)
                .Include(p => p.Company)
                    .ThenInclude(c => c.Room)
                .Include(p => p.Company)
                    .ThenInclude(c => c.Interviews)
                .Include(p => p.Company)
                    .ThenInclude(c => c.Jobs)
                .Where(p => p.JobFairId == activeJobFairId.Value)
                .AsQueryable();

            // Filter by industry (on Company)
            if (!string.IsNullOrWhiteSpace(industry))
                query = query.Where(p => !string.IsNullOrWhiteSpace(p.Company.Industry) && p.Company.Industry.ToLower().Contains(industry.ToLower()));

            // Filter by arrival status (on Participation)
            if (!string.IsNullOrWhiteSpace(arrivalStatus))
            {
                if (Enum.TryParse<ArrivalStatus>(arrivalStatus, true, out var status))
                    query = query.Where(p => p.ArrivalStatus == status);
            }

            // Filter by presence (on Participation)
            if (isPresent.HasValue)
                query = query.Where(p => p.IsPresent == isPresent.Value);

            var totalCount = await query.CountAsync();
            var participations = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var companies = participations.Select(p => new
            {
                CompanyId = p.CompanyId,
                Name = p.Company.Name,
                Industry = p.Company.Industry,
                LogoUrl = p.Company.LogoUrl,
                Website = p.Company.Website,
                UserEmail = p.Company.User != null ? p.Company.User.Email : null,
                RoomName = p.Company.Room != null ? p.Company.Room.RoomName : null,
                ArrivalStatus = p.ArrivalStatus.ToString(),
                IsPresent = p.IsPresent,
                TotalJobs = p.Company.Jobs.Count(j => j.JobFairId == activeJobFairId.Value),
                HiredCount = p.Company.Interviews.Count(i => i.JobFairId == activeJobFairId.Value && i.Status == InterviewStatus.Hired),
                ShortlistedCount = p.Company.Interviews.Count(i => i.JobFairId == activeJobFairId.Value && i.Status == InterviewStatus.Shortlisted)
            });

            return Ok(new
            {
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize,
                TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
                Companies = companies
            });
        }
        // -----------------------------
        // 5. Add On-Spot Company
        // -----------------------------
        [HttpPost("companies/onspot")]
        public async Task<IActionResult> AddOnSpotCompany([FromBody] CompanyCreateDto dto)
        {
            var activeJobFairId = await GetActiveJobFairIdAsync();
            if (activeJobFairId == null) return BadRequest("No active job fair.");

            if (string.IsNullOrWhiteSpace(dto.Email))
                return BadRequest("Email is required.");

            if (string.IsNullOrWhiteSpace(dto.FocalPersonName))
                return BadRequest("Focal person name is required.");

            if (string.IsNullOrWhiteSpace(dto.FocalPersonPhone))
                return BadRequest("Focal person phone is required.");

            var normalizedEmail = dto.Email.Trim().ToLowerInvariant();

            var existingCompanyWithSameEmail = await _context.Companies
                .Include(c => c.User)
                .FirstOrDefaultAsync(c => c.User.Email.ToLower() == normalizedEmail);

            if (existingCompanyWithSameEmail != null)
                return BadRequest("A company with this email already exists.");

            var existingUser = await _context.Users
                .FirstOrDefaultAsync(u => u.Email.ToLower() == normalizedEmail && u.Role == UserRole.Company);

            string? generatedTempPassword = null;

            if (existingUser == null)
            {
                generatedTempPassword = $"OnSpot@{Guid.NewGuid():N}";
                existingUser = new User
                {
                    Email = normalizedEmail,
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword(generatedTempPassword),
                    Role = UserRole.Company,
                    FullName = dto.FocalPersonName,
                    Phone = dto.FocalPersonPhone,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _context.Users.Add(existingUser);
                await _context.SaveChangesAsync();
            }

            var company = new Company
            {
                Name = dto.Name,
                Industry = dto.Industry,
                UserId = existingUser.UserId,
                FocalPersonName = dto.FocalPersonName,
                FocalPersonEmail = normalizedEmail,
                FocalPersonPhone = dto.FocalPersonPhone,
                CompanyEmail = normalizedEmail,
                CompanyPhone = dto.FocalPersonPhone,
                RepsCount = dto.RepsCount > 0 ? dto.RepsCount : 1,
                InterviewDurationMinutes = 30,
                IsPresent = true,
                JobFairId = activeJobFairId.Value, // Set initial fair
                CurrentJobFairId = activeJobFairId.Value,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.Companies.Add(company);
            await _context.SaveChangesAsync();

            // âœ… FIX: Create Participation Record
            var participation = new CompanyJobFairParticipation
            {
                CompanyId = company.CompanyId,
                JobFairId = activeJobFairId.Value,
                ArrivalStatus = ArrivalStatus.OnSpot,
                IsPresent = true,
                RepsCount = company.RepsCount,
                InterviewDurationMinutes = company.InterviewDurationMinutes,
                RegisteredAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };
            _context.CompanyJobFairParticipations.Add(participation);
            await _context.SaveChangesAsync();

            _ = Task.Run(async () =>
            {
                try
                {
                    var subject = "On-Spot Company Registration - Job Fair Portal";
                    var body = generatedTempPassword == null
                        ? $"""
Hello {dto.FocalPersonName},

Your company ({dto.Name}) has been registered on-spot for the active job fair.

Email: {normalizedEmail}

Your account already existed, so your previous password remains unchanged.

Regards,
Job Fair Team
"""
                        : $"""
Hello {dto.FocalPersonName},

Your company ({dto.Name}) has been registered on-spot for the active job fair.

Login email: {normalizedEmail}
Temporary password: {generatedTempPassword}

Please login and change your password immediately.

Regards,
Job Fair Team
""";

                    await _mailService.SendMailAsync(normalizedEmail, subject, body);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to send on-spot company registration email to {Email}", normalizedEmail);
                }
            });

            return Ok(new CompanyResponseDto
            {
                CompanyId = company.CompanyId,
                Name = company.Name,
                Industry = company.Industry
            });
        }

        // -----------------------------
        // 6. Get Interview Stats
        // -----------------------------
        [HttpGet("interviews/stats")]
        public async Task<IActionResult> GetInterviewStats()
        {
            var stats = await _context.Companies
                .Select(c => new InterviewStatsDto
                {
                    CompanyId = c.CompanyId,
                    CompanyName = c.Name,
                    TotalInterviews = c.Interviews.Count,
                    HiredCount = c.Interviews.Count(i => i.Status == InterviewStatus.Hired),
                    ShortlistedCount = c.Interviews.Count(i => i.Status == InterviewStatus.Shortlisted)
                })
                .ToListAsync();

            return Ok(stats);
        }

        // -----------------------------
        // 7. Get Survey Responses
        // -----------------------------
        [HttpGet("surveys")]
        public async Task<IActionResult> GetSurveys([FromQuery] int? jobFairId = null)
        {
            jobFairId ??= await GetActiveJobFairIdAsync();
            if (jobFairId == null)
                return Ok(new List<object>());

            // 1. Fetch data from DB first (Materialize)
            var surveysData = await _context.Surveys
                .Include(s => s.Company)
                .Where(s => s.JobFairId == jobFairId.Value)
                .OrderByDescending(s => s.SubmittedAt)
                .ToListAsync();

            // 2. Deserialize and Map in memory
            var surveys = surveysData.Select(s => new
            {
                SurveyId = s.SurveyId,
                CompanyId = s.CompanyId,
                Type = s.Type.ToString(),
                // Use the helper to get the specific SurveyResponseData fields
                Responses = DeserializeResponses(s.Responses),
                CompanyName = s.Company != null ? s.Company.Name : null,
                SubmittedAt = s.SubmittedAt
            }).ToList();

            return Ok(surveys);
        }
        #region Helper
        private static object? DeserializeResponses(string? responses)
        {
            if (string.IsNullOrEmpty(responses))
                return null;

            try
            {
                // Attempt to deserialize into the strongly-typed SurveyResponseData
                return JsonSerializer.Deserialize<JobFairPortal.Models.SurveyResponseData>(responses, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });
            }
            catch
            {
                try
                {
                    // Fallback: Try generic object if structure doesn't match
                    return JsonSerializer.Deserialize<object>(responses);
                }
                catch
                {
                    // Final Fallback: Return raw string
                    return responses;
                }
            }
        }
        #endregion// -----------------------------
        // 8. Audit Logs
        // -----------------------------
        [HttpGet("audit-logs")]
        public async Task<IActionResult> GetAuditLogs()
        {
            var logs = await _context.AuditLogs
                .Include(a => a.Actor)
                .OrderByDescending(a => a.CreatedAt)
                .Select(a => new AuditLogDto
                {
                    AuditLogId = a.LogId,
                    Action = a.Action,
                    ActorName = a.Actor != null ? (a.Actor.FullName ?? "System") : "System",
                    CreatedAt = a.CreatedAt
                })
                .ToListAsync();

            return Ok(logs);
        }

        // -----------------------------
        // 9. Update Room Status
        // -----------------------------
        [HttpPut("rooms/{roomId}/status")]
        public async Task<IActionResult> UpdateRoomStatus(int roomId, [FromQuery] RoomStatus status)
        {
            var room = await _context.Rooms.FindAsync(roomId);
            if (room == null)
                return NotFound("Room not found.");

            room.Status = status;
            room.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new RoomResponseDto
            {
                RoomId = room.RoomId,
                RoomName = room.RoomName,
                Capacity = room.Capacity,
                Status = room.Status,
                CompanyName = room.Company?.Name
            });
        }

        [HttpPut("rooms/{roomId}/capacity")]
        public async Task<IActionResult> UpdateRoomCapacity(int roomId, [FromQuery] int capacity, [FromQuery] bool force = false)
        {
            if (capacity < 1)
                return BadRequest("Capacity must be at least 1.");

            var room = await _context.Rooms
                .Include(r => r.Company)
                    .ThenInclude(c => c!.User)
                .FirstOrDefaultAsync(r => r.RoomId == roomId);

            if (room == null)
                return NotFound("Room not found.");

            if (room.CompanyId.HasValue)
            {
                var fallbackReps = room.Company?.RepsCount ?? 1;
                var requiredReps = await GetRequiredRepsForFairAsync(room.CompanyId.Value, room.JobFairId, fallbackReps);

                if (capacity < requiredReps && !force)
                {
                    return BadRequest(new
                    {
                        code = "CAPACITY_WARNING",
                        message = $"Capacity warning: New room capacity ({capacity}) is less than assigned company reps ({requiredReps})."
                    });
                }
            }

            room.Capacity = capacity;
            room.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new RoomResponseDto
            {
                RoomId = room.RoomId,
                RoomName = room.RoomName,
                Capacity = room.Capacity,
                Status = room.Status,
                CompanyName = room.Company?.Name,
                CompanyId = room.CompanyId,
                CompanyRepsCount = room.Company?.RepsCount
            });
        }

        // ...

        // -----------------------------
        // 10. Dashboard Overview
        // -----------------------------
        [HttpGet("dashboard/overview")]
        public async Task<IActionResult> GetDashboardOverview()
        {
            var activeJobFairId = await GetActiveJobFairIdAsync();
            if (activeJobFairId == null) return Ok(new DashboardOverviewDto());

            // 1. Define a unique cache key per active fair
            string cacheKey = $"dashboard_stats_{activeJobFairId.Value}";

            // 2. Check if data is already in cache
            if (!_cache.TryGetValue(cacheKey, out DashboardOverviewDto? dashboard) || dashboard == null)
            {
                // âš ï¸ CACHE MISS: Data not found, fetch from Database
                _logger.LogInformation("Fetching dashboard stats from DB...");

                var topRequestedCandidates = await _context.InterviewRequests
                    .Where(r => r.JobFairId == activeJobFairId.Value)
                    .GroupBy(r => r.StudentId)
                    .Select(g => new DashboardTopCandidateDto
                    {
                        StudentId = g.Key,
                        CandidateName = _context.Students
                            .Where(s => s.StudentId == g.Key)
                            .Select(s => s.User != null ? (s.User.FullName ?? "Unknown") : null)
                            .FirstOrDefault() ?? "Unknown",
                        Count = g.Count()
                    })
                    .OrderByDescending(x => x.Count)
                    .ThenBy(x => x.StudentId)
                    .Take(5)
                    .ToListAsync();

                if (!topRequestedCandidates.Any())
                {
                    topRequestedCandidates = await _context.Interviews
                        .Where(i => i.JobFairId == activeJobFairId.Value)
                        .GroupBy(i => i.StudentId)
                        .Select(g => new DashboardTopCandidateDto
                        {
                            StudentId = g.Key,
                            CandidateName = _context.Students
                                .Where(s => s.StudentId == g.Key)
                                .Select(s => s.User.FullName)
                                .FirstOrDefault() ?? "Unknown",
                            Count = g.Count()
                        })
                        .OrderByDescending(x => x.Count)
                        .ThenBy(x => x.StudentId)
                        .Take(5)
                        .ToListAsync();
                }

                var topRequestedCandidate = topRequestedCandidates.FirstOrDefault();

                var topHiredCandidates = await _context.Interviews
                    .Where(i => i.JobFairId == activeJobFairId.Value && i.Status == InterviewStatus.Hired)
                    .GroupBy(i => i.StudentId)
                    .Select(g => new DashboardTopCandidateDto
                    {
                        StudentId = g.Key,
                        CandidateName = _context.Students
                            .Where(s => s.StudentId == g.Key)
                            .Select(s => s.User.FullName)
                            .FirstOrDefault() ?? "Unknown",
                        Count = g.Count()
                    })
                    .OrderByDescending(x => x.Count)
                    .ThenBy(x => x.StudentId)
                    .Take(5)
                    .ToListAsync();

                var topHiredCandidate = topHiredCandidates.FirstOrDefault();

                // âœ… FIX: Filter all stats by Active Job Fair ID
                dashboard = new DashboardOverviewDto
                {
                    // FIX: Count from Participation table to get accurate attendee count
                    TotalStudents = await _context.StudentJobFairParticipations.CountAsync(s => s.JobFairId == activeJobFairId),
                    TotalCompanies = await _context.CompanyJobFairParticipations.CountAsync(p => p.JobFairId == activeJobFairId),
                    TotalRooms = await _context.Rooms.CountAsync(r => r.JobFairId == activeJobFairId),
                    StudentsHired = await _context.Interviews.CountAsync(i => i.JobFairId == activeJobFairId && i.Status == InterviewStatus.Hired),
                    StudentsShortlisted = await _context.Interviews.CountAsync(i => i.JobFairId == activeJobFairId && i.Status == InterviewStatus.Shortlisted),
                    CDCSurveysReceived = await _context.Surveys.CountAsync(s => s.JobFairId == activeJobFairId && s.Type == SurveyType.CDC),
                    DepartmentSurveysReceived = await _context.Surveys.CountAsync(s => s.JobFairId == activeJobFairId && s.Type == SurveyType.Department),
                    TopRequestedCandidateId = topRequestedCandidate?.StudentId,
                    TopRequestedCandidateName = topRequestedCandidate?.CandidateName,
                    TopRequestedCandidateRequestCount = topRequestedCandidate?.Count ?? 0,
                    TopHiredCandidateId = topHiredCandidate?.StudentId,
                    TopHiredCandidateName = topHiredCandidate?.CandidateName,
                    TopHiredCandidateHireCount = topHiredCandidate?.Count ?? 0,
                    TopRequestedCandidates = topRequestedCandidates,
                    TopHiredCandidates = topHiredCandidates
                };

                // 3. Save to Cache options (e.g., expire after 5 minutes)
                var cacheOptions = new MemoryCacheEntryOptions()
                    .SetAbsoluteExpiration(TimeSpan.FromMinutes(5))
                    .SetSlidingExpiration(TimeSpan.FromMinutes(2)); // Refresh if accessed frequently

                _cache.Set(cacheKey, dashboard, cacheOptions);
            }
            else
            {
                _logger.LogInformation("Returning dashboard stats from Cache.");
            }

            return Ok(dashboard);
        }
                // -----------------------------
        // 25. Unregister Student from Current Job Fair
        // -----------------------------
        [HttpDelete("students/{studentId}/unregister-from-fair")]
        public async Task<IActionResult> UnregisterStudentFromCurrentJobFair(int studentId)
        {
            // Get the active job fair
            var activeJobFairId = await GetActiveJobFairIdAsync();
            if (activeJobFairId == null)
                return NotFound(new { Message = "No active job fair found." });

            // Find the participation record
            var participation = await _context.StudentJobFairParticipations
                .FirstOrDefaultAsync(p => p.StudentId == studentId && p.JobFairId == activeJobFairId.Value);

            if (participation == null)
                return NotFound(new { Message = "Student is not registered for the current job fair." });

            _context.StudentJobFairParticipations.Remove(participation);
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Student unregistered from the current job fair successfully." });
        }
        // ========================================
        // Send FCM Notification to a Specific Company
        // ========================================
        [HttpPost("companies/{companyId}/notify")]
        public async Task<IActionResult> NotifyCompany(int companyId, [FromBody] FcmMessageDto dto)
        {
            try
            {
                // Validate input
                if (string.IsNullOrWhiteSpace(dto?.Title) || string.IsNullOrWhiteSpace(dto?.Body))
                {
                    _logger.LogWarning("NotifyCompany called with invalid payload - missing title or body");
                    return BadRequest(new
                    {
                        Code = "INVALID_PAYLOAD",
                        Message = "Title and Body are required.",
                        Success = false
                    });
                }

                // Fetch company
                var company = await _context.Companies
                    .FirstOrDefaultAsync(c => c.CompanyId == companyId);

                if (company == null)
                {
                    _logger.LogWarning("NotifyCompany failed - Company not found: {CompanyId}", companyId);
                    return NotFound(new
                    {
                        Code = "COMPANY_NOT_FOUND",
                        Message = $"Company with ID {companyId} not found.",
                        Success = false
                    });
                }

                if (string.IsNullOrWhiteSpace(company.FcmToken))
                {
                    _logger.LogWarning("NotifyCompany failed - No FCM token for company: {CompanyId}, Name: {Name}",
                        companyId, company.Name);
                    return BadRequest(new
                    {
                        Code = "NO_FCM_TOKEN",
                        Message = $"Company '{company.Name}' does not have a registered FCM token.",
                        CompanyId = companyId,
                        CompanyName = company.Name,
                        Success = false
                    });
                }

                // Construct the message
                var message = new Message
                {
                    Token = company.FcmToken,
                    Notification = new Notification
                    {
                        Title = dto.Title,
                        Body = dto.Body
                    },
                    Data = dto.Data ?? new Dictionary<string, string>()
                };

                try
                {
                    // Send message to FCM
                    string messageId = await FirebaseMessaging.DefaultInstance.SendAsync(message);

                    _logger.LogInformation("Notification sent successfully to company: {CompanyId}, Name: {Name}, MessageId: {MessageId}",
                        companyId, company.Name, messageId);

                    return Ok(new
                    {
                        Code = "SUCCESS",
                        Message = "Notification sent successfully.",
                        CompanyId = companyId,
                        CompanyName = company.Name,
                        MessageId = messageId,
                        SentAt = DateTime.UtcNow,
                        Success = true
                    });
                }
                catch (FirebaseException firebaseEx)
                {
                    _logger.LogError(firebaseEx,
                        "Firebase error sending notification to company: {CompanyId}, Name: {Name}",
                        companyId, company.Name);

                    return StatusCode(503, new
                    {
                        Code = "FIREBASE_ERROR",
                        Message = "Failed to send notification due to Firebase service error.",
                        Details = firebaseEx.Message,
                        CompanyId = companyId,
                        CompanyName = company.Name,
                        Success = false
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error while notifying company: {CompanyId}", companyId);
                return StatusCode(500, new
                {
                    Code = "INTERNAL_ERROR",
                    Message = "An unexpected error occurred while sending the notification.",
                    Details = ex.Message,
                    Success = false
                });
            }
        }

        // ========================================
        // Send FCM Notification to All Companies
        // ========================================
        [HttpPost("companies/notify-all")]
        public async Task<IActionResult> NotifyAllCompanies([FromBody] FcmMessageDto dto)
        {
            try
            {
                // 1. Validate Payload
                if (string.IsNullOrWhiteSpace(dto?.Title) || string.IsNullOrWhiteSpace(dto?.Body))
                {
                    _logger.LogWarning("NotifyAllCompanies - Invalid payload");
                    return BadRequest(new { Code = "INVALID_PAYLOAD", Message = "Title and Body are required.", Success = false });
                }

                // 2. Fetch Companies with Tokens
                var companiesWithTokens = await _context.Companies
                    .Where(c => !string.IsNullOrEmpty(c.FcmToken))
                    .ToListAsync();

                if (!companiesWithTokens.Any())
                {
                    return BadRequest(new { Code = "NO_FCM_TOKENS", Message = "No companies have registered FCM tokens.", Success = false });
                }

                // 3. Loop and Send (Manual Multicast)
                int successCount = 0;
                int failureCount = 0;
                var invalidTokensDetails = new List<object>();
                var errors = new List<string>();

                // We use a distinct list of tokens to avoid spamming
                var distinctCompanies = companiesWithTokens
                    .GroupBy(c => c.FcmToken)
                    .Select(g => g.First())
                    .ToList();

                foreach (var company in distinctCompanies)
                {
                    var message = new Message
                    {
                        Token = company.FcmToken,
                        Notification = new Notification
                        {
                            Title = dto.Title,
                            Body = dto.Body
                        },
                        Data = dto.Data ?? new Dictionary<string, string>()
                    };

                    try
                    {
                        await FirebaseMessaging.DefaultInstance.SendAsync(message);
                        successCount++;
                    }
                    catch (FirebaseException firebaseEx)
                    {
                        failureCount++;
                        var errorMsg = firebaseEx.Message.ToLower();

                        // Check for invalid tokens (404 or Not Found)
                        if (errorMsg.Contains("404") || errorMsg.Contains("not found") || errorMsg.Contains("registration token"))
                        {
                            // Mark token as null in DB
                            company.FcmToken = null;
                            company.UpdatedAt = DateTime.UtcNow;

                            invalidTokensDetails.Add(new
                            {
                                CompanyId = company.CompanyId,
                                Name = company.Name,
                                Reason = "Invalid Token - Removed"
                            });
                        }
                        else
                        {
                            errors.Add($"Company {company.CompanyId}: {firebaseEx.Message}");
                        }
                    }
                }

                // 4. Save changes if any tokens were removed
                if (invalidTokensDetails.Any())
                {
                    await _context.SaveChangesAsync();
                }

                return Ok(new
                {
                    Code = "SUCCESS",
                    Message = $"Notification sent to {successCount} companies.",
                    TotalAttempted = distinctCompanies.Count,
                    SuccessCount = successCount,
                    FailureCount = failureCount,
                    InvalidTokensRemoved = invalidTokensDetails.Count,
                    InvalidDetails = invalidTokensDetails,
                    OtherErrors = errors,
                    Success = successCount > 0
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error during bulk company notification");
                return StatusCode(500, new { Code = "INTERNAL_ERROR", Message = ex.Message, Success = false });
            }
        }
        // -----------------------------
        // 11. Interviews Summary
        // -----------------------------
        [HttpGet("interviews-summary")]
        public async Task<IActionResult> GetInterviewsSummary()
        {
            var completedStatuses = new[] { InterviewStatus.Shortlisted, InterviewStatus.Hired, InterviewStatus.Rejected };

            var totalCompleted = await _context.Interviews
                .CountAsync(i => completedStatuses.Contains(i.Status));

            var perCompany = await _context.Interviews
                .Where(i => completedStatuses.Contains(i.Status))
                .GroupBy(i => i.CompanyId)
                .Select(g => new CompanyInterviewSummaryDto
                {
                    CompanyId = g.Key,
                    CompanyName = _context.Companies.Where(c => c.CompanyId == g.Key).Select(c => c.Name).FirstOrDefault(),
                    InterviewsCompleted = g.Count()
                })
                .ToListAsync();

            return Ok(new InterviewSummaryDto
            {
                TotalInterviewsCompleted = totalCompleted,
                InterviewsPerCompany = perCompany
            });
        }

        // -----------------------------
        // 12. Filter Rooms
        // -----------------------------
        // -----------------------------
        // 12. Filter Rooms
        // -----------------------------
        [HttpGet("rooms/filter")]
        public async Task<IActionResult> FilterRooms(
            [FromQuery] RoomStatus? status,
            [FromQuery] int? minCapacity,
            [FromQuery] int? maxCapacity,
            [FromQuery] int? jobFairId = null)
        {
            jobFairId ??= await GetActiveJobFairIdAsync();
            if (jobFairId == null)
                return BadRequest("No active job fair found.");

            var query = _context.Rooms
                .Include(r => r.Company)
                .Where(r => r.JobFairId == jobFairId.Value) // âœ… Filter by JobFairId
                .AsQueryable();

            if (status.HasValue)
                query = query.Where(r => r.Status == status.Value);

            if (minCapacity.HasValue)
                query = query.Where(r => r.Capacity >= minCapacity.Value);

            if (maxCapacity.HasValue)
                query = query.Where(r => r.Capacity <= maxCapacity.Value);

            var rooms = await query
                .Select(r => new RoomResponseDto
                {
                    RoomId = r.RoomId,
                    RoomName = r.RoomName,
                    Capacity = r.Capacity,
                    Status = r.Status,
                    CompanyName = r.Company != null ? r.Company.Name : null,
                    CompanyId = r.CompanyId,
                    CompanyRepsCount = r.Company != null ? r.Company.RepsCount : null
                })
                .ToListAsync();

            return Ok(rooms);
        }

        // -----------------------------
        // 13. Assign Company to Room (Updated)
        // -----------------------------
        [HttpPut("rooms/assign-company")]
        public async Task<IActionResult> AssignCompanyToRoom([FromQuery] int companyId, [FromQuery] int roomId, [FromQuery] bool force = false)
        {
            var company = await _context.Companies
                .Include(c => c.User)
                .FirstOrDefaultAsync(c => c.CompanyId == companyId);
            if (company == null) return NotFound("Company not found.");

            var requestedRoom = await _context.Rooms.FindAsync(roomId);
            if (requestedRoom == null) return NotFound("Requested room not found.");

            if (requestedRoom.Status == RoomStatus.Alloted)
                return BadRequest("Requested room is already occupied.");

            if (requestedRoom.CompanyId.HasValue && requestedRoom.CompanyId != companyId)
                return BadRequest("Requested room is already assigned to another company.");

            var requiredReps = await GetRequiredRepsForFairAsync(companyId, requestedRoom.JobFairId, company.RepsCount);
            if (requestedRoom.Capacity < requiredReps)
            {
                if (!force)
                {
                    return BadRequest(new
                    {
                        code = "CAPACITY_WARNING",
                        message = $"Capacity warning: Room capacity ({requestedRoom.Capacity}) is less than company reps ({requiredReps})."
                    });
                }
            }

            // 1. Update Room
            requestedRoom.CompanyId = companyId;
            requestedRoom.Status = RoomStatus.Alloted;
            requestedRoom.UpdatedAt = DateTime.UtcNow;

            // 2. Update Participation Record
            var participation = await _context.CompanyJobFairParticipations
                .FirstOrDefaultAsync(p => p.CompanyId == companyId && p.JobFairId == requestedRoom.JobFairId);

            if (participation != null)
            {
                participation.RoomId = roomId;
                participation.UpdatedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
            QueueManualRoomAllotmentNotifications(company, requestedRoom, requiredReps, isConfirmed: true);

            return Ok(new RoomResponseDto
            {
                RoomId = requestedRoom.RoomId,
                RoomName = requestedRoom.RoomName,
                Capacity = requestedRoom.Capacity,
                Status = requestedRoom.Status,
                CompanyName = company.Name
            });
        }

        // -----------------------------
        // 15. Remove Company from Room (Updated)
        // -----------------------------
        [HttpPut("rooms/{roomId}/remove-company")]
        public async Task<IActionResult> RemoveCompanyFromRoom(int roomId)
        {
            var room = await _context.Rooms.Include(r => r.Company).FirstOrDefaultAsync(r => r.RoomId == roomId);
            if (room == null) return NotFound("Room not found.");

            var companyId = room.CompanyId;

            // 1. Update Room
            room.CompanyId = null;
            room.Status = RoomStatus.Vacant;
            room.UpdatedAt = DateTime.UtcNow;

            // 2. Update Participation Record
            if (companyId.HasValue)
            {
                var participation = await _context.CompanyJobFairParticipations
                    .FirstOrDefaultAsync(p => p.CompanyId == companyId.Value && p.JobFairId == room.JobFairId);

                if (participation != null)
                {
                    participation.RoomId = null;
                    participation.UpdatedAt = DateTime.UtcNow;
                }
            }

            await _context.SaveChangesAsync();

            return Ok(new RoomResponseDto
            {
                RoomId = room.RoomId,
                RoomName = room.RoomName,
                Capacity = room.Capacity,
                Status = room.Status,
                CompanyName = null
            });
        }

        [HttpDelete("rooms/{roomId}")]
        public async Task<IActionResult> DeleteRoom(int roomId)
        {
            var room = await _context.Rooms.FirstOrDefaultAsync(r => r.RoomId == roomId);
            if (room == null) return NotFound("Room not found.");

            if (room.CompanyId.HasValue || room.Status != RoomStatus.Vacant)
                return BadRequest("Only vacant rooms can be deleted. Remove/deallocate company first.");

            _context.Rooms.Remove(room);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Room deleted successfully." });
        }


        // -----------------------------
        // 16. Get All Students (Paginated)
        // -----------------------------
        [HttpGet("students")]
        public async Task<IActionResult> GetAllStudents([FromQuery] int page = 1, [FromQuery] int pageSize = 20, [FromQuery] string? search = null, [FromQuery] int? jobFairId = null)
        {
            _logger.LogInformation("GetAllStudents called by admin with page={Page}, pageSize={PageSize}.", page, pageSize);

            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 20;

            var activeJobFairId = await GetActiveJobFairIdAsync();
            var selectedJobFairId = jobFairId ?? activeJobFairId;
            if (selectedJobFairId == null)
            {
                return Ok(new
                {
                    TotalCount = 0,
                    Page = page,
                    PageSize = pageSize,
                    TotalPages = 0,
                    Students = new List<object>()
                });
            }

            // âœ… FIX: Query StudentJobFairParticipations to get students for THIS fair only
            var query = _context.StudentJobFairParticipations
                .Include(p => p.Student)
                    .ThenInclude(s => s.User)
                .Include(p => p.Student)
                    .ThenInclude(s => s.StudentProjects)
                        .ThenInclude(sp => sp.Project)
                .Include(p => p.Student)
                    .ThenInclude(s => s.Achievements)
                .Include(p => p.Student)
                    .ThenInclude(s => s.Certifications)
                .Include(p => p.Student)
                    .ThenInclude(s => s.Educations)
                .Where(p => p.JobFairId == selectedJobFairId.Value);

            if (!string.IsNullOrWhiteSpace(search))
            {
                var searchLower = search.ToLower();
                query = query.Where(p =>
                    (p.Student.User != null && (p.Student.User.FullName ?? string.Empty).ToLower().Contains(searchLower)) ||
                    p.Student.RegistrationNo.ToLower().Contains(searchLower) ||
                    (p.Student.User != null && (p.Student.User.Email ?? string.Empty).ToLower().Contains(searchLower)));
            }

            var totalCount = await query.CountAsync();
            var participations = await query
                .OrderBy(p => p.StudentId)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var students = participations.Select(p => new
            {
                StudentId = p.Student.StudentId,
                Name = p.Student.User.FullName,
                Email = p.Student.User.Email,
                Phone = p.Student.User.Phone,
                RegistrationNo = p.Student.RegistrationNo,
                Department = p.Student.Department,
                CGPA = p.Student.CGPA,
                ProfilePicUrl = p.Student.ProfilePicUrl,
                ProfilePic = p.Student.ProfilePicUrl,
                Skills = p.Student.Skills ?? new List<string>(),
                FypTitle = p.Student.StudentProjects
                    .Where(sp => sp.Project != null && sp.Project.Type == ProjectType.FinalYear)
                    .Select(sp => sp.Project.Title)
                    .FirstOrDefault(),
                TotalProjects = p.Student.StudentProjects.Count(sp => sp.Status == ProjectInviteStatus.Accepted),
                TotalAchievements = p.Student.Achievements.Count,
                TotalCertifications = p.Student.Certifications.Count,
                TotalEducations = p.Student.Educations.Count,
                CreatedAt = p.Student.CreatedAt,
                UpdatedAt = p.Student.UpdatedAt,
                RegisteredAt = p.RegisteredAt // Include when they registered for this fair
            }).ToList();

            return Ok(new
            {
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize,
                TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
                Students = students
            });
        }

        // Admin endpoint to update student email and password
        [HttpPut("students/{studentId}/edit-credentials")]
        public async Task<IActionResult> UpdateStudentCredentials(int studentId, [FromBody] AdminUpdateStudentDto dto)
        {
            if (dto == null)
                return BadRequest(new { Message = "Request body is required." });

            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.StudentId == studentId);

            if (student == null)
                return NotFound(new { Message = "Student not found." });

            // Update email if provided
            if (!string.IsNullOrWhiteSpace(dto.Email))
            {
                var emailExists = await _context.Users
                    .AnyAsync(u => u.Email == dto.Email && u.UserId != student.User.UserId);

                if (emailExists)
                    return BadRequest(new { Message = "Email already in use by another user." });

                student.User.Email = dto.Email.Trim();
            }

            // Update password if provided
            if (!string.IsNullOrWhiteSpace(dto.Password))
            {
                string hashedPassword = BCrypt.Net.BCrypt.HashPassword(dto.Password);
                student.User.PasswordHash = hashedPassword;
            }

            student.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Student credentials updated successfully.",
                StudentId = student.StudentId,
                Email = student.User.Email,
                UpdatedAt = student.UpdatedAt
            });
        }

        [HttpPut("students/{studentId}/profile")]
        public async Task<IActionResult> UpdateStudentProfile(int studentId, [FromBody] AdminUpdateStudentProfileDto dto)
        {
            if (dto == null)
                return BadRequest(new { Message = "Request body is required." });

            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.StudentId == studentId);

            if (student == null)
                return NotFound(new { Message = "Student not found." });

            if (!string.IsNullOrWhiteSpace(dto.FullName))
                student.User.FullName = dto.FullName.Trim();

            if (!string.IsNullOrWhiteSpace(dto.RegistrationNo))
                student.RegistrationNo = dto.RegistrationNo.Trim();

            if (!string.IsNullOrWhiteSpace(dto.Department))
                student.Department = dto.Department.Trim();

            if (!string.IsNullOrWhiteSpace(dto.Phone))
                student.User.Phone = dto.Phone.Trim();

            if (dto.CGPA.HasValue)
                student.CGPA = dto.CGPA.Value;

            if (dto.Skills != null)
            {
                student.Skills = dto.Skills
                    .Where(s => !string.IsNullOrWhiteSpace(s))
                    .Select(s => s.Trim())
                    .Distinct(StringComparer.OrdinalIgnoreCase)
                    .ToList();
            }

            student.User.UpdatedAt = DateTime.UtcNow;
            student.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Student profile updated successfully.",
                StudentId = student.StudentId,
                UpdatedAt = student.UpdatedAt
            });
        }
        
        // -----------------------------
        // 17. Filter Students by Department, Min CGPA, or Registration Number
        // -----------------------------
        [HttpGet("students/advanced-filter")]
        public async Task<IActionResult> AdvancedFilterStudents(
           [FromQuery] string? department,
           [FromQuery] decimal? minCgpa,
           [FromQuery] string? fypTitleContains)
        {
            _logger.LogInformation("AdvancedFilterStudents called with department: {Department}, minCgpa: {MinCgpa}, fypTitleContains: {FypTitle}",
                department, minCgpa, fypTitleContains);

            var activeJobFairId = await GetActiveJobFairIdAsync();
            if (activeJobFairId == null)
            {
                return Ok(new
                {
                    TotalCount = 0,
                    Students = new List<object>()
                });
            }

            // âœ… FIX: Query StudentJobFairParticipations
            var query = _context.StudentJobFairParticipations
                .Include(p => p.Student)
                    .ThenInclude(s => s.User)
                .Include(p => p.Student)
                    .ThenInclude(s => s.StudentProjects)
                        .ThenInclude(sp => sp.Project)
                .Include(p => p.Student)
                    .ThenInclude(s => s.ContactLinks)
                .Where(p => p.JobFairId == activeJobFairId.Value)
                .AsQueryable();

            // Apply filters on the Student navigation property
            if (!string.IsNullOrWhiteSpace(department))
                query = query.Where(p => p.Student.Department == department);

            if (minCgpa.HasValue)
                query = query.Where(p => p.Student.CGPA >= minCgpa.Value);

            if (!string.IsNullOrWhiteSpace(fypTitleContains))
            {
                query = query.Where(p =>
                    p.Student.StudentProjects.Any(sp =>
                        sp.Project.Type == ProjectType.FinalYear &&
                        sp.Project.Title.Contains(fypTitleContains)));
            }

            var participations = await query.ToListAsync();

            var students = participations.Select(p => new
            {
                StudentId = p.Student.StudentId,
                Name = p.Student.User.FullName,
                RegistrationNo = p.Student.RegistrationNo,
                Department = p.Student.Department,
                CGPA = p.Student.CGPA,
                FYPs = p.Student.StudentProjects
                    .Where(sp => sp.Project.Type == ProjectType.FinalYear)
                    .Select(sp => new
                    {
                        Title = sp.Project.Title,
                        Description = sp.Project.Description,
                        Status = sp.Status
                    }).ToList(),
                Skills = p.Student.Skills ?? new List<string>(),
                Links = p.Student.ContactLinks != null
                    ? p.Student.ContactLinks.ToDictionary(
                        cl => cl.Platform.ToString(),
                        cl => cl.Url)
                    : new Dictionary<string, string>()
            }).ToList();

            return Ok(new
            {
                TotalCount = students.Count,
                Students = students
            });
        }

        // -----------------------------
        // 18. Get Student Detail by Id
        // -----------------------------

        // Update the existing GetStudentDetail endpoint
        [HttpGet("students/{studentId}/details")]
        public async Task<IActionResult> GetStudentDetail(int studentId)
        {
            _logger.LogInformation("GetStudentDetail called for studentId: {StudentId}", studentId);

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
                .FirstOrDefaultAsync(s => s.StudentId == studentId);

            if (student == null || student.User == null)
                return NotFound(new { Message = "Student not found." });

            var fyp = student.StudentProjects
                .FirstOrDefault(sp => sp.Project?.Type == ProjectType.FinalYear && sp.Status == ProjectInviteStatus.Accepted)?
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
                CVUrl=student.CvUrl,
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
                        Type = sp.Project.Type.ToString(),
                        sp.Project.Description,
                        sp.Project.DemoUrl,
                        sp.Project.GitHubUrl,
                        sp.Project.Skills,
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
                    e.GradeType,
                    e.GradeValue,
                    e.MarksObtained,
                    e.TotalMarks,
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

                // --- Work Experience ---
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
        }// FIX: Add 'int jobFairId' parameter
        private async Task ParseXlsxStream(Stream stream, List<Room> roomsToCreate, List<Room> roomsToUpdate, List<string> errors, int jobFairId)
        {
            using (var package = new ExcelPackage(stream))
            {
                var worksheet = package.Workbook.Worksheets.FirstOrDefault();
                if (worksheet == null)
                {
                    errors.Add("The XLSX file is empty.");
                    return;
                }

                var existingRooms = await _context.Rooms.ToDictionaryAsync(r => r.RoomName, r => r);
                var namesInFile = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

                for (int row = 2; row <= worksheet.Dimension.End.Row; row++)
                {
                    try
                    {
                        var roomName = worksheet.Cells[row, 1].Value?.ToString()?.Trim();
                        var capacityStr = worksheet.Cells[row, 2].Value?.ToString()?.Trim();
                        var statusStr = worksheet.Cells[row, 3].Value?.ToString()?.Trim();

                        if (string.IsNullOrWhiteSpace(roomName)) continue;

                        if (namesInFile.Contains(roomName))
                        {
                            errors.Add($"Row {row}: Duplicate entry for '{roomName}' in file. Skipped.");
                            continue;
                        }
                        namesInFile.Add(roomName);

                        if (!int.TryParse(capacityStr, out int capacity))
                        {
                            errors.Add($"Row {row}: Invalid Capacity '{capacityStr}'.");
                            continue;
                        }

                        if (!Enum.TryParse<RoomStatus>(statusStr, true, out RoomStatus status))
                        {
                            errors.Add($"Row {row}: Invalid Status '{statusStr}'.");
                            continue;
                        }

                        if (existingRooms.TryGetValue(roomName, out var existingRoom))
                        {
                            // Existing room logic remains the same (JobFairId doesn't usually change on update)
                            if (existingRoom.Capacity != capacity || existingRoom.Status != status)
                            {
                                existingRoom.Capacity = capacity;
                                existingRoom.Status = status;
                                existingRoom.UpdatedAt = DateTime.UtcNow;
                                roomsToUpdate.Add(existingRoom);
                            }
                        }
                        else
                        {
                            roomsToCreate.Add(new Room
                            {
                                RoomName = roomName,
                                Capacity = capacity,
                                Status = status,
                                JobFairId = jobFairId, // FIX: Assign the ID here
                                CreatedAt = DateTime.UtcNow,
                                UpdatedAt = DateTime.UtcNow
                            });
                        }
                    }
                    catch (Exception ex)
                    {
                        errors.Add($"Row {row}: Error processing row. {ex.Message}");
                    }
                }
            }
        }// FIX: Add 'int jobFairId' parameter
        private async Task ParseCsvStream(Stream stream, List<Room> roomsToCreate, List<Room> roomsToUpdate, List<string> errors, int jobFairId)
        {
            using (var reader = new StreamReader(stream))
            using (var csv = new CsvReader(reader, CultureInfo.InvariantCulture))
            {
                var existingRooms = await _context.Rooms.ToDictionaryAsync(r => r.RoomName, r => r);
                var namesInFile = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

                // Note: You might need to adjust RoomMap if it doesn't match your CSV structure exactly
                // csv.Context.RegisterClassMap<RoomMap>(); 

                var records = csv.GetRecords<RoomBulkCreateDto>();
                int row = 2;

                foreach (var record in records)
                {
                    try
                    {
                        if (string.IsNullOrWhiteSpace(record.RoomName)) continue;

                        if (namesInFile.Contains(record.RoomName))
                        {
                            errors.Add($"Row {row}: Duplicate entry for '{record.RoomName}' in file. Skipped.");
                            row++;
                            continue;
                        }
                        namesInFile.Add(record.RoomName);

                        if (existingRooms.TryGetValue(record.RoomName, out var existingRoom))
                        {
                            if (existingRoom.Capacity != record.Capacity || existingRoom.Status != record.Status)
                            {
                                existingRoom.Capacity = record.Capacity;
                                existingRoom.Status = record.Status;
                                existingRoom.UpdatedAt = DateTime.UtcNow;
                                roomsToUpdate.Add(existingRoom);
                            }
                        }
                        else
                        {
                            roomsToCreate.Add(new Room
                            {
                                RoomName = record.RoomName,
                                Capacity = record.Capacity,
                                Status = record.Status,
                                JobFairId = jobFairId, // FIX: Assign the ID here
                                CreatedAt = DateTime.UtcNow,
                                UpdatedAt = DateTime.UtcNow
                            });
                        }
                    }
                    catch (Exception ex)
                    {
                        errors.Add($"Row {row}: Error. {ex.Message}");
                    }
                    row++;
                }
            }
        }
        // -----------------------------
        // Send FCM Notification to a Specific Student
        // -----------------------------

        [HttpPost("students/{studentId}/send-email")]
        public async Task<IActionResult> SendEmailToStudent(int studentId, [FromBody] AdminSendEmailDto dto)
        {
            if (dto == null || string.IsNullOrWhiteSpace(dto.Subject) || string.IsNullOrWhiteSpace(dto.Body))
            {
                return BadRequest(new { Message = "Subject and body are required." });
            }

            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.StudentId == studentId);

            if (student == null)
            {
                return NotFound(new { Message = "Student not found." });
            }

            if (student.User == null || string.IsNullOrWhiteSpace(student.User.Email))
            {
                return BadRequest(new { Message = "Student email is not available." });
            }

            try
            {
                await _mailService.SendMailAsync(student.User.Email.Trim(), dto.Subject.Trim(), dto.Body.Trim());

                return Ok(new
                {
                    Message = "Email sent successfully.",
                    StudentId = student.StudentId,
                    StudentName = student.User.FullName,
                    StudentEmail = student.User.Email
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send email to student {StudentId}", studentId);
                return StatusCode(500, new { Message = "Failed to send email. Please try again." });
            }
        }

        [HttpPost("students/{studentId}/notify")]
        public async Task<IActionResult> NotifyStudent(int studentId, [FromBody] FcmMessageDto dto)
        {
            try
            {
                // Validate input
                if (string.IsNullOrWhiteSpace(dto?.Title) || string.IsNullOrWhiteSpace(dto?.Body))
                {
                    _logger.LogWarning("NotifyStudent called with invalid payload - missing title or body");
                    return BadRequest(new
                    {
                        Code = "INVALID_PAYLOAD",
                        Message = "Title and Body are required.",
                        Success = false
                    });
                }

              
                // Fetch student
                var student = await _context.Students
                    .Include(s => s.User)
                    .FirstOrDefaultAsync(s => s.StudentId == studentId);

                if (student == null)
                {
                    _logger.LogWarning("NotifyStudent failed - Student not found: {StudentId}", studentId);
                    return NotFound(new
                    {
                        Code = "STUDENT_NOT_FOUND",
                        Message = $"Student with ID {studentId} not found.",
                        Success = false
                    });
                }

                if (string.IsNullOrWhiteSpace(student.FcmToken))
                {
                    _logger.LogWarning("NotifyStudent failed - No FCM token for student: {StudentId}, Name: {Name}",
                        studentId, student.User?.FullName);
                    return BadRequest(new
                    {
                        Code = "NO_FCM_TOKEN",
                        Message = $"Student '{student.User?.FullName}' does not have a registered FCM token.",
                        StudentId = studentId,
                        StudentName = student.User?.FullName,
                        Success = false
                    });
                }

                // Construct the message
                var message = new Message
                {
                    Token = student.FcmToken,
                    Notification = new Notification
                    {
                        Title = dto.Title,
                        Body = dto.Body
                    },
                    Data = dto.Data ?? new Dictionary<string, string>()
                };

                try
                {
                    // Send message to FCM
                    string messageId = await FirebaseMessaging.DefaultInstance.SendAsync(message);

                    _logger.LogInformation("Notification sent successfully to student: {StudentId}, Name: {Name}, MessageId: {MessageId}",
                        studentId, student.User?.FullName, messageId);

                    return Ok(new
                    {
                        Code = "SUCCESS",
                        Message = "Notification sent successfully.",
                        StudentId = studentId,
                        StudentName = student.User?.FullName,
                        StudentEmail = student.User?.Email,
                        MessageId = messageId,
                        SentAt = DateTime.UtcNow,
                        Success = true
                    });
                }
                catch (FirebaseException firebaseEx)
                {
                    _logger.LogError(firebaseEx,
                        "Firebase error sending notification to student: {StudentId}, Name: {Name}",
                        studentId, student.User?.FullName);

                    return StatusCode(503, new
                    {
                        Code = "FIREBASE_ERROR",
                        Message = "Failed to send notification due to Firebase service error.",
                        Details = firebaseEx.Message,
                        StudentId = studentId,
                        StudentName = student.User?.FullName,
                        Success = false
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error while notifying student: {StudentId}", studentId);
                return StatusCode(500, new
                {
                    Code = "INTERNAL_ERROR",
                    Message = "An unexpected error occurred while sending the notification.",
                    Details = ex.Message,
                    Success = false
                });
            }
        }

        // ========================================
        // Send FCM Notification to All Students
        // ========================================
        [HttpPost("students/notify-all")]
        public async Task<IActionResult> NotifyAllStudents([FromBody] FcmMessageDto dto)
        {
            try
            {
                // 1. Validate Payload
                if (string.IsNullOrWhiteSpace(dto?.Title) || string.IsNullOrWhiteSpace(dto?.Body))
                {
                    _logger.LogWarning("NotifyAllStudents - Invalid payload");
                    return BadRequest(new { Code = "INVALID_PAYLOAD", Message = "Title and Body are required.", Success = false });
                }

                // 2. Fetch Students with Tokens
                // We select the whole object so we can identify WHICH student failed later
                var studentsWithTokens = await _context.Students
                    .Include(s => s.User)
                    .Where(s => !string.IsNullOrEmpty(s.FcmToken))
                    .ToListAsync();

                if (!studentsWithTokens.Any())
                {
                    return BadRequest(new { Code = "NO_FCM_TOKENS", Message = "No students have registered FCM tokens.", Success = false });
                }

                // 3. Loop and Send (Manual Multicast)
                int successCount = 0;
                int failureCount = 0;
                var invalidTokensDetails = new List<object>();
                var errors = new List<string>();

                // We use a distinct list of tokens to avoid spamming, 
                // but we map back to students for error reporting if needed.
                var distinctStudents = studentsWithTokens
                    .GroupBy(s => s.FcmToken)
                    .Select(g => g.First()) // Take one student per unique token
                    .ToList();

                foreach (var student in distinctStudents)
                {
                    var message = new Message
                    {
                        Token = student.FcmToken,
                        Notification = new Notification
                        {
                            Title = dto.Title,
                            Body = dto.Body
                        },
                        Data = dto.Data ?? new Dictionary<string, string>()
                    };

                    try
                    {
                        // USE THE METHOD WE KNOW WORKS
                        await FirebaseMessaging.DefaultInstance.SendAsync(message);
                        successCount++;
                    }
                    catch (FirebaseException firebaseEx)
                    {
                        failureCount++;
                        var errorMsg = firebaseEx.Message.ToLower();

                        // Check for invalid tokens (404 or Not Found)
                        if (errorMsg.Contains("404") || errorMsg.Contains("not found") || errorMsg.Contains("registration token"))
                        {
                            // Mark token as null in DB
                            student.FcmToken = null;
                            student.UpdatedAt = DateTime.UtcNow;

                            invalidTokensDetails.Add(new
                            {
                                StudentId = student.StudentId,
                                Name = student.User?.FullName,
                                Reason = "Invalid Token - Removed"
                            });
                        }
                        else
                        {
                            errors.Add($"Student {student.StudentId}: {firebaseEx.Message}");
                        }
                    }
                }

                // 4. Save changes if any tokens were removed
                if (invalidTokensDetails.Any())
                {
                    await _context.SaveChangesAsync();
                }

                return Ok(new
                {
                    Code = "SUCCESS",
                    Message = $"Notification sent to {successCount} students.",
                    TotalAttempted = distinctStudents.Count,
                    SuccessCount = successCount,
                    FailureCount = failureCount,
                    InvalidTokensRemoved = invalidTokensDetails.Count,
                    InvalidDetails = invalidTokensDetails,
                    OtherErrors = errors, // Shows why others failed
                    Success = successCount > 0
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error during bulk notification");
                return StatusCode(500, new { Code = "INTERNAL_ERROR", Message = ex.Message, Success = false });
            }
        }
        [HttpGet("jobfairs/{jobFairId}/analytics")]
        public async Task<IActionResult> GetJobFairAnalytics(int jobFairId)
        {
            _logger.LogInformation("GetJobFairAnalytics called for jobFairId: {JobFairId}", jobFairId);

            string cacheKey = $"jobfair_analytics_{jobFairId}";
            if (_cache.TryGetValue(cacheKey, out object? cachedData) && cachedData != null)
            {
                return Ok(cachedData);
            }

            var jobFair = await _context.JobFairs.FindAsync(jobFairId);
            if (jobFair == null) return NotFound(new { Message = "Job Fair not found." });

            // 1. Fetch Participations (The source of truth for attendance)
            var companyParticipations = await _context.CompanyJobFairParticipations
                .Include(p => p.Company)
                    .ThenInclude(c => c.Jobs) // Load jobs to filter by fair
                .Include(p => p.Company)
                    .ThenInclude(c => c.User)
                .Include(p => p.Room)
                .Where(p => p.JobFairId == jobFairId)
                .ToListAsync();

            var studentParticipations = await _context.StudentJobFairParticipations
                .Include(p => p.Student)
                    .ThenInclude(s => s.User)
                .Where(p => p.JobFairId == jobFairId)
                .ToListAsync();

            // 2. Fetch Interviews & Requests for this fair
            var interviews = await _context.Interviews
                .Include(i => i.Company)
                .Include(i => i.Student)
                    .ThenInclude(s => s.User)
                .Where(i => i.JobFairId == jobFairId)
                .ToListAsync();

            var requests = await _context.InterviewRequests
                .Where(ir => ir.JobFairId == jobFairId)
                .ToListAsync();

            var rooms = await _context.Rooms
                .Where(r => r.JobFairId == jobFairId)
                .ToListAsync();

            // 3. Calculate Stats
            var studentsDetailed = studentParticipations
                .Select(sp => new
                {
                    StudentId = sp.StudentId,
                    Name = sp.Student.User?.FullName,
                    RegistrationNo = sp.Student.RegistrationNo,
                    Department = sp.Student.Department,
                    CGPA = sp.Student.CGPA,
                    ProfilePicUrl = sp.Student.ProfilePicUrl,
                    CvUrl = sp.Student.CvUrl,
                    Hired = interviews.Any(i => i.StudentId == sp.StudentId && i.Status == InterviewStatus.Hired),
                    Shortlisted = interviews.Any(i => i.StudentId == sp.StudentId && i.Status == InterviewStatus.Shortlisted),
                    InterviewCount = interviews.Count(i => i.StudentId == sp.StudentId)
                })
                .OrderByDescending(s => s.Hired)
                .ThenByDescending(s => s.Shortlisted)
                .ThenByDescending(s => s.CGPA)
                .ToList();

            var companyDetailed = companyParticipations
                .Select(p => new
                {
                    CompanyId = p.CompanyId,
                    CompanyName = p.Company.Name,
                    Industry = p.Company.Industry,
                    IsPresent = p.IsPresent,
                    TotalJobOpenings = p.Company.Jobs.Count(j => j.JobFairId == jobFairId),
                    TotalInterviews = interviews.Count(i => i.CompanyId == p.CompanyId),
                    HiredCount = interviews.Count(i => i.CompanyId == p.CompanyId && i.Status == InterviewStatus.Hired),
                    ShortlistedCount = interviews.Count(i => i.CompanyId == p.CompanyId && i.Status == InterviewStatus.Shortlisted),
                    RejectedCount = interviews.Count(i => i.CompanyId == p.CompanyId && i.Status == InterviewStatus.Rejected),
                    PendingCount = interviews.Count(i => i.CompanyId == p.CompanyId && i.Status == InterviewStatus.Queued)
                })
                .OrderByDescending(c => c.TotalInterviews)
                .ThenByDescending(c => c.HiredCount)
                .ToList();

            var jobsDetailed = companyParticipations
                .SelectMany(p => p.Company.Jobs
                    .Where(j => j.JobFairId == jobFairId)
                    .Select(j => new
                    {
                        JobId = j.JobId,
                        JobTitle = j.JobTitle,
                        JobType = j.JobType.ToString(),
                        Location = (string?)null,
                        CompanyId = p.CompanyId,
                        CompanyName = p.Company.Name,
                        SalaryRange = (string?)null,
                        IsActive = true,
                        NumberOfJobs = j.NumberOfJobs,
                        CreatedAt = j.CreatedAt
                    }))
                .OrderByDescending(j => j.CreatedAt)
                .ToList();

            var roomsDetailed = rooms
                .Select(r => new
                {
                    RoomId = r.RoomId,
                    RoomName = r.RoomName,
                    Capacity = r.Capacity,
                    Status = r.Status.ToString(),
                    CompanyId = r.CompanyId,
                    CompanyName = r.CompanyId.HasValue
                        ? companyParticipations
                            .Where(p => p.CompanyId == r.CompanyId.Value)
                            .Select(p => p.Company.Name)
                            .FirstOrDefault()
                        : null,
                    InterviewCount = r.CompanyId.HasValue
                        ? interviews.Count(i => i.CompanyId == r.CompanyId.Value)
                        : 0
                })
                .OrderBy(r => r.RoomName)
                .ToList();

            var companyRoomLookup = companyParticipations
                .GroupBy(p => p.CompanyId)
                .ToDictionary(g => g.Key, g => g.FirstOrDefault()?.Room?.RoomName);

            var interviewsDetailed = interviews
                .Select(i => new
                {
                    InterviewId = i.InterviewId,
                    CompanyId = i.CompanyId,
                    CompanyName = i.Company?.Name,
                    StudentId = i.StudentId,
                    StudentName = i.Student?.User?.FullName,
                    StudentRegistrationNo = i.Student?.RegistrationNo,
                    ScheduledTime = i.ScheduledTime,
                    StartedAt = i.StartedAt,
                    EndedAt = i.EndedAt,
                    RoomNo = companyRoomLookup.TryGetValue(i.CompanyId, out var roomName) ? roomName : null,
                    Result = i.Status.ToString(),
                    DurationMinutes = (i.StartedAt.HasValue && i.EndedAt.HasValue)
                        ? (int?)(i.EndedAt.Value - i.StartedAt.Value).TotalMinutes
                        : null
                })
                .OrderByDescending(i => i.ScheduledTime)
                .ToList();

            var analytics = new
            {
                JobFairId = jobFair.JobFairId,
                Semester = jobFair.Semester,
                Date = jobFair.date,
                IsActive = jobFair.IsActive,

                OverallStats = new
                {
                    TotalStudents = studentParticipations.Count,
                    TotalCompanies = companyParticipations.Count,
                    TotalRooms = rooms.Count,
                    // Count jobs specifically linked to this fair
                    TotalJobs = companyParticipations.Sum(p => p.Company.Jobs.Count(j => j.JobFairId == jobFairId)),
                    TotalInterviews = interviews.Count,
                    TotalInterviewRequests = requests.Count
                },

                InterviewStats = new
                {
                    Hired = interviews.Count(i => i.Status == InterviewStatus.Hired),
                    Shortlisted = interviews.Count(i => i.Status == InterviewStatus.Shortlisted),
                    Rejected = interviews.Count(i => i.Status == InterviewStatus.Rejected),
                    Pending = interviews.Count(i => i.Status == InterviewStatus.Queued),
                    HiringRate = interviews.Count > 0
                        ? Math.Round((double)interviews.Count(i => i.Status == InterviewStatus.Hired) / interviews.Count * 100, 2)
                        : 0
                },

                // Group students from participation list
                StudentsByDepartment = studentParticipations
                    .GroupBy(p => p.Student.Department)
                    .Select(g => new
                    {
                        Department = g.Key,
                        Count = g.Count(),
                        AverageCGPA = g.Any() ? Math.Round(g.Average(p => p.Student.CGPA), 2) : 0,
                        Hired = interviews.Count(i => studentParticipations.Any(sp => sp.StudentId == i.StudentId && sp.Student.Department == g.Key) &&
                                                    i.Status == InterviewStatus.Hired)
                    })
                    .ToList(),

                CompanyParticipation = companyParticipations
                    .Select(p => new
                    {
                        CompanyId = p.CompanyId,
                        CompanyName = p.Company.Name ?? "Unknown",
                        Industry = p.Company.Industry,
                        LogoUrl = p.Company.LogoUrl,
                        IsPresent = p.IsPresent,
                        ArrivalStatus = p.ArrivalStatus.ToString(),
                        TotalJobs = (p.Company.Jobs ?? new List<Job>()).Count(j => j.JobFairId == jobFairId),
                        TotalInterviews = interviews.Count(i => i.CompanyId == p.CompanyId),
                        HiredCount = interviews.Count(i => i.CompanyId == p.CompanyId && i.Status == InterviewStatus.Hired),
                        ShortlistedCount = interviews.Count(i => i.CompanyId == p.CompanyId && i.Status == InterviewStatus.Shortlisted),
                        InterviewRequestsReceived = requests.Count(ir => ir.CompanyId == p.CompanyId)
                    })
                    .OrderByDescending(c => c.HiredCount)
                    .ToList(),

                RoomUtilization = new
                {
                    TotalRooms = rooms.Count,
                    VacantRooms = rooms.Count(r => r.Status == RoomStatus.Vacant),
                    AllottedRooms = rooms.Count(r => r.Status == RoomStatus.Alloted),
                    TentativeRooms = rooms.Count(r => r.Status == RoomStatus.TentativelyAlloted),
                    AllocationRate = rooms.Count > 0
                        ? Math.Round((double)rooms.Count(r => r.Status == RoomStatus.Alloted) / rooms.Count * 100, 2)
                        : 0
                },

                DetailedLists = new
                {
                    Students = studentsDetailed,
                    Companies = companyDetailed,
                    JobOpenings = jobsDetailed,
                    Interviews = interviewsDetailed,
                    Rooms = roomsDetailed
                }
            };

            var cacheOptions = new MemoryCacheEntryOptions().SetAbsoluteExpiration(TimeSpan.FromMinutes(10));
            _cache.Set(cacheKey, analytics, cacheOptions);

            return Ok(analytics);
        }
        [HttpGet("jobfairs")]
        public async Task<IActionResult> GetAllJobFairs([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            _logger.LogInformation("GetAllJobFairs called with page={Page}, pageSize={PageSize}.", page, pageSize);

            if (page < 1) page = 1;

            if (pageSize < 1) pageSize = 20;

            var query = _context.JobFairs
                .Include(jf => jf.Students)
                .Include(jf => jf.Companies)
                .Include(jf => jf.Interviews)
                .Include(jf => jf.Rooms)
                .OrderByDescending(jf => jf.date);

            var totalCount = await query.CountAsync();
            var jobFairs = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(jf => new
                {
                    JobFairId = jf.JobFairId,
                    Semester = jf.Semester,
                    Date = jf.date,
                    IsActive = jf.IsActive,
                    TotalStudents = jf.Students != null ? jf.Students.Count : 0,
                    TotalCompanies = jf.Companies != null ? jf.Companies.Count : 0,
                    TotalRooms = jf.Rooms != null ? jf.Rooms.Count : 0,
                    TotalInterviews = jf.Interviews != null ? jf.Interviews.Count : 0,
                    StudentsHired = jf.Interviews != null ? jf.Interviews.Count(i => i.Status == InterviewStatus.Hired) : 0,
                    StudentsShortlisted = jf.Interviews != null ? jf.Interviews.Count(i => i.Status == InterviewStatus.Shortlisted) : 0,
                    CreatedAt = jf.date
                })
                .ToListAsync();

            return Ok(new
            {
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize,
                TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
                JobFairs = jobFairs
            });
        }
        [HttpGet("notices")]
        [Authorize(Roles = "Admin,CoAdmin")]
        public async Task<IActionResult> GetNotices()
        {
            var activeJobFair = await _context.JobFairs.FirstOrDefaultAsync(j => j.IsActive);
            if (activeJobFair == null)
                return Ok(new List<NoticeResponseDto>());

            var isStudent = User.IsInRole("Student");
            var isCompany = User.IsInRole("Company");
            var isAdmin = User.IsInRole("Admin") || User.IsInRole("CoAdmin");

            var query = _context.Notices
                .Where(n => n.JobFairId == activeJobFair.JobFairId)
                .AsQueryable();

            // --- FILTERING LOGIC ---
            if (isAdmin)
            {
                // Admin sees EVERYTHING (Hidden and Visible)
                // No IsHidden filter here
            }
            else
            {
                // Everyone else only sees NOT HIDDEN items
                query = query.Where(n => n.IsHidden == false);

                if (isStudent)
                    query = query.Where(n => n.Audience == NoticeAudience.Student || n.Audience == NoticeAudience.All);
                else if (isCompany)
                    query = query.Where(n => n.Audience == NoticeAudience.Company || n.Audience == NoticeAudience.All);
                else
                    return Forbid();
            }

            var notices = await query
                .OrderByDescending(n => n.CreatedAt)
                .Select(n => new NoticeResponseDto
                {
                    NoticeId = n.NoticeId,
                    Title = n.Title,
                    Content = n.Content,
                    Audience = n.Audience.ToString(),
                    IsHidden = n.IsHidden,
                    CreatedAt = n.CreatedAt
                })
                .ToListAsync();

            return Ok(notices);
        }
        // ========================================
        // DIAGNOSTIC: Check Firebase Configuration
        // ========================================

        [HttpGet("firebase/config-check")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> FirebaseConfigCheck()
        {
            try
            {
                _logger.LogInformation("Starting Firebase configuration check");

                // Check if Firebase is initialized
                if (FirebaseApp.DefaultInstance == null)
                {
                    return StatusCode(503, new
                    {
                        Code = "FIREBASE_NOT_INITIALIZED",
                        Message = "Firebase Admin SDK is not initialized.",
                        Status = "ERROR",
                        Timestamp = DateTime.UtcNow
                    });
                }

                // Test with a sample message to verify credentials
                var testMessage = new Message
                {
                    Topic = "test-topic-config-check",
                    Notification = new Notification
                    {
                        Title = "Firebase Config Check",
                        Body = "Testing Firebase configuration"
                    }
                };

                try
                {
                    string messageId = await FirebaseMessaging.DefaultInstance.SendAsync(testMessage);

                    return Ok(new
                    {
                        Code = "FIREBASE_CONFIGURED",
                        Message = "Firebase is properly configured and operational.",
                        Status = "SUCCESS",
                        FirebaseApp = FirebaseApp.DefaultInstance.Name,
                        TestMessageId = messageId,
                        Timestamp = DateTime.UtcNow,
                        Recommendations = new List<string>()
                    });
                }
                catch (FirebaseException firebaseEx)
                {
                    return StatusCode(503, new
                    {
                        Code = "FIREBASE_MISCONFIGURED",
                        Message = "Firebase is initialized but has configuration issues.",
                        Status = "ERROR",
                        FirebaseErrorCode = firebaseEx.ErrorCode,
                        FirebaseErrorMessage = firebaseEx.Message,
                        Recommendations = new List<string>
                        {
                            "Verify your Firebase service account JSON file is correct",
                            "Check that your Firebase project ID matches your credentials",
                            "Ensure Firebase Cloud Messaging API is enabled in your Google Cloud Console",
                            "Verify the service account has appropriate permissions"
                        },
                        Timestamp = DateTime.UtcNow
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Firebase configuration check failed");
                return StatusCode(500, new
                {
                    Code = "CHECK_ERROR",
                    Message = "An error occurred while checking Firebase configuration.",
                    Status = "ERROR",
                    Details = ex.Message,
                    Timestamp = DateTime.UtcNow
                });
            }
        }

        // ========================================
        // DIAGNOSTIC: Identify Invalid FCM Tokens
        // ========================================

        [HttpGet("fcm/invalid-tokens-report")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> GetInvalidTokensReport()
        {
            try
            {
                _logger.LogInformation("Starting invalid FCM tokens report generation");

                var studentsWithTokens = await _context.Students
                    .Include(s => s.User)
                    .Where(s => !string.IsNullOrEmpty(s.FcmToken))
                    .ToListAsync();

                if (!studentsWithTokens.Any())
                {
                    return Ok(new
                    {
                        Code = "NO_TOKENS",
                        Message = "No students have FCM tokens registered.",
                        TotalStudents = await _context.Students.CountAsync(),
                        StudentsWithTokens = 0,
                        InvalidTokens = new List<object>(),
                        Timestamp = DateTime.UtcNow
                    });
                }

                var invalidTokens = new List<object>();
                var validTokenCount = 0;

                foreach (var student in studentsWithTokens)
                {
                    try
                    {
                        // Attempt to send a dry-run message to each token
                        var testMessage = new Message
                        {
                            Token = student.FcmToken,
                            Notification = new Notification
                            {
                                Title = "Token Validation",
                                Body = "Validating your FCM token"
                            }
                        };

                        await FirebaseMessaging.DefaultInstance.SendAsync(testMessage);
                        validTokenCount++;
                    }
                    catch (FirebaseException firebaseEx)
                    {
                        var errorMessage = firebaseEx.Message ?? "Unknown error";

                        // 404 errors indicate invalid/expired tokens
                        if (errorMessage.Contains("404") || errorMessage.Contains("not found") ||
                            errorMessage.Contains("registration token"))
                        {
                            invalidTokens.Add(new
                            {
                                StudentId = student.StudentId,
                                Name = student.User?.FullName,
                                Reason = "Invalid Token - Removed"
                            });

                            _logger.LogWarning(
                                "Invalid FCM token found - Student: {StudentId}, {StudentName}, Error: {Error}",
                                student.StudentId, student.User?.FullName, errorMessage);
                        }
                    }
                    catch (Exception ex)
                    {
                        invalidTokens.Add(new
                        {
                            StudentId = student.StudentId,
                            Name = student.User?.FullName,
                            Reason = ex.Message
                        });
                    }
                }

                return Ok(new
                {
                    Code = "REPORT_GENERATED",
                    Message = $"Found {invalidTokens.Count} invalid tokens out of {studentsWithTokens.Count}",
                    TotalStudents = await _context.Students.CountAsync(),
                    StudentsWithTokens = studentsWithTokens.Count,
                    ValidTokens = validTokenCount,
                    InvalidTokens = invalidTokens.Count,
                    InvalidTokensPercentage = Math.Round((double)invalidTokens.Count / studentsWithTokens.Count * 100, 2),
                    DetailedInvalidTokens = invalidTokens,
                    Recommendations = new List<string>
                    {
                        "Run the cleanup endpoint to remove invalid tokens",
                        "Notify users to log in again to refresh their FCM tokens",
                        "Verify Firebase project credentials match your mobile app configuration",
                        "Check if Firebase project ID changed recently"
                    },
                    Timestamp = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating invalid tokens report");
                return StatusCode(500, new
                {
                    Code = "REPORT_ERROR",
                    Message = "An error occurred while generating the report.",
                    Details = ex.Message,
                    Timestamp = DateTime.UtcNow
                });
            }
        }

        // ========================================
        // ACTION: Clean All Invalid FCM Tokens
        // ========================================

        [HttpPost("fcm/cleanup-invalid-tokens")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> CleanupInvalidTokens()
        {
            try
            {
                _logger.LogInformation("Starting cleanup of invalid FCM tokens");

                var studentsWithTokens = await _context.Students
                    .Include(s => s.User)
                    .Where(s => !string.IsNullOrEmpty(s.FcmToken))
                    .ToListAsync();

                int removedCount = 0;
                var removedDetails = new List<object>();

                foreach (var student in studentsWithTokens)
                {
                    try
                    {
                        var testMessage = new Message
                        {
                            Token = student.FcmToken,
                            Notification = new Notification
                            {
                                Title = "Test",
                                Body = "Test"
                            }
                        };

                        await FirebaseMessaging.DefaultInstance.SendAsync(testMessage);
                    }
                    catch (FirebaseException firebaseEx)
                    {
                        var errorMessage = firebaseEx.Message ?? "Unknown error";

                        // Remove invalid tokens
                        if (errorMessage.Contains("404") || errorMessage.Contains("not found") ||
                            errorMessage.Contains("registration token"))
                        {
                            student.FcmToken = null;
                            student.UpdatedAt = DateTime.UtcNow;
                            removedCount++;

                            removedDetails.Add(new
                            {
                                StudentId = student.StudentId,
                                StudentName = student.User?.FullName,
                                Email = student.User?.Email,
                                RemovalTime = DateTime.UtcNow,
                                Reason = "Invalid/expired token"
                            });

                            _logger.LogInformation(
                                "Removed invalid FCM token for student: {StudentId}, {StudentName}",
                                student.StudentId, student.User?.FullName);
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning(ex, "Error validating token for student: {StudentId}", student.StudentId);
                    }
                }

                // Save changes if any tokens were removed
                if (removedCount > 0)
                {
                    await _context.SaveChangesAsync();
                    _logger.LogInformation("Cleanup complete: Removed {Count} invalid tokens", removedCount);
                }

                return Ok(new
                {
                    Code = "CLEANUP_COMPLETE",
                    Message = $"Successfully removed {removedCount} invalid FCM tokens",
                    TotalProcessed = studentsWithTokens.Count,
                    RemovedCount = removedCount,
                    RemovedDetails = removedDetails,
                    NextSteps = new List<string>
                    {
                        "Users with removed tokens will need to log in again",
                        "New FCM tokens will be generated during the next login",
                        "Monitor notification sending to verify tokens are working"
                    },
                    Timestamp = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during FCM token cleanup");
                return StatusCode(500, new
                {
                    Code = "CLEANUP_ERROR",
                    Message = "An error occurred during cleanup.",
                    Details = ex.Message,
                    Timestamp = DateTime.UtcNow
                });
            }
        }



        // Add this helper method to AdminController to fix CS0103
        private async Task<int?> GetActiveJobFairIdAsync()
        {
            // Example implementation: get the most recent active JobFair
            var activeJobFair = await _context.JobFairs
                .Where(jf => jf.IsActive)
                .OrderByDescending(jf => jf.date)
                .FirstOrDefaultAsync();

            return activeJobFair?.JobFairId;
        }

        // ======================================
        // ATTENDANCE MANAGEMENT ENDPOINTS
        // ======================================


        /// <summary>
        /// GET /api/admin/jobfairs/{jobFairId}/companies
        /// Get all companies registered for a specific job fair
        /// </summary>
        [HttpGet("jobfairs/{jobFairId}/companies")]
        public async Task<IActionResult> GetCompaniesForJobFair(int jobFairId)
        {
            try
            {
                var companies = await _context.CompanyJobFairParticipations
                    .Where(p => p.JobFairId == jobFairId)
                    .Include(p => p.Company)
                    .AsNoTracking()
                    .OrderBy(p => p.Company.Name)
                    .Select(p => new
                    {
                        id = p.Company.CompanyId,
                        companyName = p.Company.Name,
                        logoUrl = p.Company.LogoUrl,
                        profilePicUrl = p.Company.LogoUrl,
                        contactEmail = p.Company.FocalPersonEmail,
                        contactNumber = p.Company.FocalPersonPhone,
                        isPresent = p.IsPresent
                    })
                    .ToListAsync();

                return Ok(companies);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting companies for job fair");
                return StatusCode(500, new { error = "Internal server error" });
            }
        }

        /// <summary>
        /// GET /api/admin/attendance/stats/{jobFairId}
        /// Get attendance statistics for a job fair
        /// </summary>
        [HttpGet("attendance/stats/{jobFairId}")]
        public async Task<IActionResult> GetAttendanceStats(int jobFairId)
        {
            try
            {
                var participations = await _context.CompanyJobFairParticipations
                    .Where(p => p.JobFairId == jobFairId)
                    .AsNoTracking()
                    .ToListAsync();

                var totalCompanies = participations.Count;
                var presentCompanies = participations.Count(p => p.IsPresent);
                var absentCompanies = totalCompanies - presentCompanies;
                var presentPercentage = totalCompanies > 0 ? (presentCompanies * 100.0) / totalCompanies : 0;

                return Ok(new
                {
                    totalCompanies,
                    presentCompanies,
                    absentCompanies,
                    presentPercentage = Math.Round(presentPercentage, 2)
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting attendance stats");
                return StatusCode(500, new { error = "Internal server error" });
            }
        }
    [HttpDelete("notice/{id}")]
    [Authorize(Roles = "Admin,CoAdmin")]
        public async Task<IActionResult> DeleteNotice(int id)
        {
            var notice = await _context.Notices.FindAsync(id);
            if (notice == null)
                return NotFound("Notice not found.");

            // SOFT DELETE: Just hide it
            notice.IsHidden = true;
            notice.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new { Message = "Notice has been hidden (Soft Deleted)." });
        }
    
        [HttpPost("notices")]
        [Authorize(Roles = "Admin,CoAdmin")]
        public async Task<IActionResult> CreateNotice([FromBody] NoticeCreateDto dto)
        {
            var activeJobFair = await _context.JobFairs.FirstOrDefaultAsync(j => j.IsActive);
            if (activeJobFair == null)
                return BadRequest("No active Job Fair found. Cannot create notice.");

            var notice = new Notice
            {
                Title = dto.Title,
                Content = dto.Content,
                Audience = dto.Audience,
                JobFairId = activeJobFair.JobFairId,
                IsHidden = false, // Default is visible
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
                IsHidden = notice.IsHidden,
                CreatedAt = notice.CreatedAt
            });
        }

        [HttpPut("notices/{id}")]
        [Authorize(Roles = "Admin,CoAdmin")]
        public async Task<IActionResult> UpdateNotice(int id, [FromBody] NoticeUpdateDto dto)
        {
            var notice = await _context.Notices.FindAsync(id);
            if (notice == null)
                return NotFound("Notice not found.");

            // Update notice fields
            notice.Title = dto.Title;
            notice.Content = dto.Content;
            notice.Audience = dto.Audience;
            notice.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new NoticeResponseDto
            {
                NoticeId = notice.NoticeId,
                Title = notice.Title,
                Content = notice.Content,
                Audience = notice.Audience.ToString(),
                IsHidden = notice.IsHidden,
                CreatedAt = notice.CreatedAt
            });
        }
        
        [HttpPut("Notice/{id}/toggle-visibility")]
        [Authorize(Roles = "Admin,CoAdmin")]
        public async Task<IActionResult> ToggleVisibility(int id)
        {
            var notice = await _context.Notices.FindAsync(id);
            if (notice == null)
                return NotFound("Notice not found.");

            // Flip the status
            notice.IsHidden = !notice.IsHidden;
            notice.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = notice.IsHidden ? "Notice hidden." : "Notice is now visible.",
                IsHidden = notice.IsHidden
            });
        }
 
        // ======================================
        // END ATTENDANCE MANAGEMENT ENDPOINTS
        // ======================================


        // -----------------------------
        // 19. Manual Participation Registration
        // -----------------------------

        [HttpPost("companies/{companyId}/register-for-fair")]
        public async Task<IActionResult> RegisterCompanyForFair(int companyId, [FromQuery] int? jobFairId = null)
        {
            jobFairId ??= await GetActiveJobFairIdAsync();
            if (jobFairId == null) return BadRequest("No active job fair found.");

            var exists = await _context.CompanyJobFairParticipations
                .AnyAsync(p => p.CompanyId == companyId && p.JobFairId == jobFairId.Value);

            if (exists) return BadRequest("Company is already registered for this job fair.");

            var participation = new CompanyJobFairParticipation
            {
                CompanyId = companyId,
                JobFairId = jobFairId.Value,
                ArrivalStatus = ArrivalStatus.Pending,
                RegisteredAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.CompanyJobFairParticipations.Add(participation);
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Company registered for job fair successfully.", ParticipationId = participation.ParticipationId });
        }

        [HttpPost("students/{studentId}/register-for-fair")]
        public async Task<IActionResult> RegisterStudentForFair(int studentId, [FromQuery] int? jobFairId = null)
        {
            jobFairId ??= await GetActiveJobFairIdAsync();
            if (jobFairId == null) return BadRequest("No active job fair found.");

            var exists = await _context.StudentJobFairParticipations
                .AnyAsync(p => p.StudentId == studentId && p.JobFairId == jobFairId.Value);

            if (exists) return BadRequest("Student is already registered for this job fair.");

            var participation = new StudentJobFairParticipation
            {
                StudentId = studentId,
                JobFairId = jobFairId.Value,
                RegisteredAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.StudentJobFairParticipations.Add(participation);
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Student registered for job fair successfully.", ParticipationId = participation.ParticipationId });
        }
        [HttpPut("rooms/tentatively-assign")]
        public async Task<IActionResult> TentativelyAssignRoom([FromQuery] int companyId, [FromQuery] int roomId, [FromQuery] bool force = false)
        {
            var company = await _context.Companies
                .Include(c => c.User)
                .FirstOrDefaultAsync(c => c.CompanyId == companyId);
            if (company == null) return NotFound("Company not found.");

            var requestedRoom = await _context.Rooms.FindAsync(roomId);
            if (requestedRoom == null) return NotFound("Requested room not found.");

            if (requestedRoom.Status == RoomStatus.Alloted)
                return BadRequest("Requested room is already permanently occupied.");

            if (requestedRoom.CompanyId.HasValue && requestedRoom.CompanyId != companyId)
                return BadRequest("Requested room is already tentatively assigned to another company.");

            var requiredReps = await GetRequiredRepsForFairAsync(companyId, requestedRoom.JobFairId, company.RepsCount);
            if (requestedRoom.Capacity < requiredReps)
            {
                if (!force)
                {
                    return BadRequest(new
                    {
                        code = "CAPACITY_WARNING",
                        message = $"Capacity warning: Room capacity ({requestedRoom.Capacity}) is less than company reps ({requiredReps})."
                    });
                }
            }

            // 1. Update Room
            requestedRoom.CompanyId = companyId;
            requestedRoom.Status = RoomStatus.TentativelyAlloted;
            requestedRoom.UpdatedAt = DateTime.UtcNow;

            // 2. Update Participation Record
            var participation = await _context.CompanyJobFairParticipations
                .FirstOrDefaultAsync(p => p.CompanyId == companyId && p.JobFairId == requestedRoom.JobFairId);

            if (participation != null)
            {
                participation.RoomId = roomId;
                participation.UpdatedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
            QueueManualRoomAllotmentNotifications(company, requestedRoom, requiredReps, isConfirmed: false);

            return Ok(new RoomResponseDto
            {
                RoomId = requestedRoom.RoomId,
                RoomName = requestedRoom.RoomName,
                Capacity = requestedRoom.Capacity,
                Status = requestedRoom.Status,
                CompanyName = company.Name ?? "Unknown"
            });
        }

        // -----------------------------
        // 21. Confirm Room Allotment
        // -----------------------------
        [HttpPut("rooms/{roomId}/confirm-allotment")]
        public async Task<IActionResult> ConfirmRoomAllotment(int roomId, [FromQuery] bool force = false)
        {
            var room = await _context.Rooms
                .Include(r => r.Company)
                    .ThenInclude(c => c!.User)
                .FirstOrDefaultAsync(r => r.RoomId == roomId);
            if (room == null) return NotFound("Room not found.");

            if (room.Status == RoomStatus.Alloted)
                return BadRequest("Room is already permanently alloted.");

            if (room.Status == RoomStatus.Vacant)
                return BadRequest("Room is vacant. Please assign a company first.");

            var requiredReps = await GetRequiredRepsForFairAsync(room.CompanyId ?? 0, room.JobFairId, room.Company?.RepsCount ?? 1);
            if (room.Capacity < requiredReps)
            {
                if (!force)
                {
                    return BadRequest(new
                    {
                        code = "CAPACITY_WARNING",
                        message = $"Capacity warning: Room capacity ({room.Capacity}) is less than company reps ({requiredReps})."
                    });
                }
            }

            // Change status to Alloted
            room.Status = RoomStatus.Alloted;
            room.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            if (room.Company != null)
            {
                QueueManualRoomAllotmentNotifications(room.Company, room, requiredReps, isConfirmed: true);
            }

            return Ok(new RoomResponseDto
            {
                RoomId = room.RoomId,
                RoomName = room.RoomName,
                Capacity = room.Capacity,
                Status = room.Status,
                CompanyName = room.Company?.Name,
                CompanyId = room.CompanyId,
                CompanyRepsCount = room.Company != null ? room.Company.RepsCount : null
            });
        }
        // Replace the existing AddJobFair method with this safer DTO-based implementation.
        [HttpPost("jobfairs")]
        public async Task<IActionResult> AddJobFair([FromBody] JobFairCreateDto dto)
        {
            if (dto == null) return BadRequest("Request body is required.");
            if (string.IsNullOrWhiteSpace(dto.Semester))
                return BadRequest("Semester name is required.");

            // Optional: prevent duplicate semester/date combos
            var exists = await _context.JobFairs
                .AnyAsync(j => j.Semester == dto.Semester && j.date.Date == dto.date.Date);
            if (exists)
                return BadRequest("A job fair with the same semester and date already exists.");

            if (dto.IsActive)
            {
                var activeFairs = await _context.JobFairs.Where(j => j.IsActive).ToListAsync();
                foreach (var fair in activeFairs)
                {
                    fair.IsActive = false;
                    
                }
            }

            var jobFair = new JobFair
            {
                Semester = dto.Semester.Trim(),
                date = dto.date,
                IsActive = dto.IsActive,
                
            };

            _context.JobFairs.Add(jobFair);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Job Fair created successfully.",
                JobFairId = jobFair.JobFairId,
                Semester = jobFair.Semester,
                Date = jobFair.date,
                IsActive = jobFair.IsActive
            });
        }

        // Activate a specific job fair and deactivate all others
        [HttpPost("jobfairs/{jobFairId}/activate")]
        public async Task<IActionResult> ActivateJobFair(int jobFairId)
        {
            var jobFair = await _context.JobFairs.FindAsync(jobFairId);
            if (jobFair == null)
                return NotFound(new { Message = "Job Fair not found." });

            using var tx = await _context.Database.BeginTransactionAsync();
            try
            {
                var activeFairs = await _context.JobFairs.Where(j => j.IsActive && j.JobFairId != jobFairId).ToListAsync();
                foreach (var fair in activeFairs)
                {
                    fair.IsActive = false;
                }

                jobFair.IsActive = true;

                await _context.SaveChangesAsync();
                await tx.CommitAsync();

                return Ok(new
                {
                    Message = "Job Fair activated successfully.",
                    JobFairId = jobFair.JobFairId,
                    Semester = jobFair.Semester,
                    Date = jobFair.date,
                    IsActive = jobFair.IsActive
                });
            }
            catch (Exception ex)
            {
                await tx.RollbackAsync();
                _logger.LogError(ex, "Failed to activate job fair {JobFairId}", jobFairId);
                return StatusCode(500, new { Message = "Failed to activate job fair.", Error = ex.Message });
            }
        }
       

        [HttpPut("jobfairs/{jobFairId}")]
        public async Task<IActionResult> UpdateJobFair(int jobFairId, [FromBody] JobFairUpdateDto dto)
        {
            if (dto == null) 
                return BadRequest(new { Message = "Request body is required." });

            var jobFair = await _context.JobFairs.FindAsync(jobFairId);
            if (jobFair == null)
                return NotFound(new { Message = "Job Fair not found." });

            // Prevent editing job fairs that have started or occurred
            var nowUtcDate = DateTime.UtcNow.Date;
            if (jobFair.date.Date <= nowUtcDate)
                return BadRequest(new { Message = "Cannot edit a job fair that has started or already occurred." });

            // Update semester if provided
            if (!string.IsNullOrWhiteSpace(dto.Semester))
            {
                jobFair.Semester = dto.Semester.Trim();
            }

            // Update date if provided
            if (dto.date.HasValue)
            {
                // Ensure the new date is in the future
                if (dto.date.Value.Date <= nowUtcDate)
                    return BadRequest(new { Message = "New date must be in the future." });

                jobFair.date = dto.date.Value;
            }

            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Job Fair updated successfully.",
                JobFairId = jobFair.JobFairId,
                Semester = jobFair.Semester,
                Date = jobFair.date,
                IsActive = jobFair.IsActive
            });
        }

        [HttpDelete("jobfairs/{jobFairId}")]
        public async Task<IActionResult> DeleteFutureJobFair(int jobFairId)
        {
            // Only admins can call this controller (controller-level [Authorize(Roles = "Admin")] is present)
            var jobFair = await _context.JobFairs.FindAsync(jobFairId);
            if (jobFair == null)
                return NotFound(new { Message = "Job Fair not found." });

            // Prevent deletion of job fairs that have started or occurred
            var nowUtcDate = DateTime.UtcNow.Date;
            if (jobFair.date.Date <= nowUtcDate)
                return BadRequest(new { Message = "Cannot delete a job fair that has started or already occurred." });

            // Gather counts for admin visibility (optional)
            var companyParticipations = await _context.CompanyJobFairParticipations.CountAsync(p => p.JobFairId == jobFairId);
            var studentParticipations = await _context.StudentJobFairParticipations.CountAsync(p => p.JobFairId == jobFairId);
            var roomsCount = await _context.Rooms.CountAsync(r => r.JobFairId == jobFairId);
            var interviewsCount = await _context.Interviews.CountAsync(i => i.JobFairId == jobFairId);
            var requestsCount = await _context.InterviewRequests.CountAsync(ir => ir.JobFairId == jobFairId);
            var surveysCount = await _context.Surveys.CountAsync(s => s.JobFairId == jobFairId);

            using var tx = await _context.Database.BeginTransactionAsync();
            try
            {
                // Remove JobFair (EF will cascade based on your OnModelCreating configuration)
                _context.JobFairs.Remove(jobFair);
                await _context.SaveChangesAsync();

                await tx.CommitAsync();

                return Ok(new
                {
                    Message = "Job Fair deleted successfully.",
                    JobFairId = jobFairId,
                    Removed = new
                    {
                        CompanyParticipations = companyParticipations,
                        StudentParticipations = studentParticipations,
                        Rooms = roomsCount,
                        Interviews = interviewsCount,
                        InterviewRequests = requestsCount,
                        Surveys = surveysCount
                    }
                });
            }
            catch (Exception ex)
            {
                await tx.RollbackAsync();
                _logger.LogError(ex, "Failed to delete job fair {JobFairId}", jobFairId);
                return StatusCode(500, new { Message = "Failed to delete job fair.", Error = ex.Message });
            }
        }

        private async Task<int> GetRequiredRepsForFairAsync(int companyId, int jobFairId, int fallbackReps)
        {
            if (companyId <= 0)
            {
                return fallbackReps > 0 ? fallbackReps : 1;
            }

            var fairReps = await _context.CompanyJobFairParticipations
                .Where(p => p.CompanyId == companyId && p.JobFairId == jobFairId)
                .Select(p => (int?)p.RepsCount)
                .FirstOrDefaultAsync();

            if (fairReps.HasValue && fairReps.Value > 0)
            {
                return fairReps.Value;
            }

            return fallbackReps > 0 ? fallbackReps : 1;
        }

        private void QueueManualRoomAllotmentNotifications(Company company, Room room, int repsCount, bool isConfirmed)
        {
            _ = Task.Run(async () =>
            {
                try
                {
                    var title = isConfirmed ? "Room Allotment Confirmed" : "Room Tentatively Assigned";
                    var body = isConfirmed
                        ? $"Your room {room.RoomName} has been confirmed for {repsCount} representative(s)."
                        : $"Your room {room.RoomName} has been tentatively assigned for {repsCount} representative(s).";

                    var notificationTasks = new List<Task>(2);

                    if (!string.IsNullOrWhiteSpace(company.FcmToken))
                    {
                        var message = new Message
                        {
                            Token = company.FcmToken,
                            Notification = new Notification
                            {
                                Title = title,
                                Body = body
                            },
                            Data = new Dictionary<string, string>
                            {
                                ["type"] = "ROOM_ALLOTMENT",
                                ["roomId"] = room.RoomId.ToString(),
                                ["roomName"] = room.RoomName ?? string.Empty,
                                ["status"] = isConfirmed ? "CONFIRMED" : "TENTATIVE",
                                ["repsCount"] = repsCount.ToString()
                            }
                        };

                        notificationTasks.Add(FirebaseMessaging.DefaultInstance.SendAsync(message));
                    }

                    var recipientEmail = company.User?.Email;
                    if (!string.IsNullOrWhiteSpace(recipientEmail))
                    {
                        var emailSubject = isConfirmed
                            ? "Room Allotment Confirmed - Job Fair"
                            : "Room Tentatively Assigned - Job Fair";
                        var emailBody = $"""
Hello {company.Name},

Your room assignment has been updated.

Room: {room.RoomName}
Status: {(isConfirmed ? "Confirmed" : "Tentative")}
Representatives: {repsCount}

Regards,
Job Fair Team
""";

                        notificationTasks.Add(_mailService.SendMailAsync(recipientEmail, emailSubject, emailBody));
                    }

                    if (notificationTasks.Count > 0)
                    {
                        await Task.WhenAll(notificationTasks);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to send manual room allotment notifications for company {CompanyId}", company.CompanyId);
                }
            });
        }

        // âœ… NEW: Admin management endpoints
        // ========================================
        // Send OTP to Super Admin (authorize co-admin creation)
        // ========================================
        [HttpPost("admins/send-otp")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> SendCoAdminCreationOtp()
        {
            if (!IsSuperAdmin())
                return SuperAdminOnly("request an admin action OTP");

            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdClaim?.Value, out int userId))
                return Unauthorized(new { Code = "INVALID_TOKEN", Message = "Unable to identify user from token." });

            var admin = await _context.Users.FirstOrDefaultAsync(u => u.UserId == userId && (u.Role == UserRole.Admin || u.Role == UserRole.CoAdmin));
            if (admin == null)
                return NotFound(new { Code = "ADMIN_NOT_FOUND", Message = "Admin user not found." });

            // Generate 6-digit OTP
            var otp = GenerateAdminOtp();
            var cacheKey = $"coadmin-create-otp:{userId}";
            _cache.Set(cacheKey, otp, TimeSpan.FromMinutes(10));

            _logger.LogInformation("Co-admin creation OTP generated for admin {AdminId}", userId);

            try
            {
                var subject = "Admin Action Verification - Job Fair Portal";
                var body = Services.EmailTemplateService.GetAdminActionOtpTemplate(
                    admin.FullName ?? "Admin", otp, 10);
                await _mailService.SendMailAsync(admin.Email, subject, body);
                _logger.LogInformation("Co-admin creation OTP sent to {Email}", admin.Email);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send OTP email to admin {AdminId}", userId);
                return StatusCode(500, new { Code = "EMAIL_ERROR", Message = "Failed to send OTP email. Please try again." });
            }

            return Ok(new
            {
                Code = "SUCCESS",
                Message = "OTP sent to your registered email address.",
                ExpiryMinutes = 10
            });
        }

        // ========================================
        // Verify OTP (pre-flight from frontend)
        // ========================================
        [HttpPost("admins/verify-otp")]
        [Authorize(Roles = "Admin")]
        public IActionResult VerifyCoAdminCreationOtp([FromBody] AdminVerifyOtpDto dto)
        {
            if (!IsSuperAdmin())
                return SuperAdminOnly("verify an admin action OTP");

            if (string.IsNullOrWhiteSpace(dto.Otp))
                return BadRequest(new { Code = "VALIDATION_ERROR", Message = "OTP is required." });

            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdClaim?.Value, out int userId))
                return Unauthorized(new { Code = "INVALID_TOKEN", Message = "Unable to identify user from token." });

            var cacheKey = $"coadmin-create-otp:{userId}";
            if (!_cache.TryGetValue(cacheKey, out string? cachedOtp) || string.IsNullOrWhiteSpace(cachedOtp))
                return BadRequest(new { Code = "OTP_EXPIRED", Message = "OTP has expired or was not found. Please request a new one." });

            if (!cachedOtp.Equals(dto.Otp.Trim(), StringComparison.Ordinal))
                return BadRequest(new { Code = "INVALID_OTP", Message = "The OTP you entered is incorrect." });

            return Ok(new { Code = "SUCCESS", Message = "OTP verified successfully." });
        }

        // ========================================
        // Create Co-Admin (name + email only â€” password auto-generated)
        // ========================================
        [HttpPost("admins/create")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> CreateAdminUser([FromBody] AdminCreateDto dto)
        {
            if (!IsSuperAdmin())
                return SuperAdminOnly("create co-admin accounts");

            _logger.LogInformation("Super admin creating new co-admin user with email: {Email}", dto.Email);

            // Validate input fields
            if (string.IsNullOrWhiteSpace(dto.Email) || string.IsNullOrWhiteSpace(dto.Name))
                return BadRequest(new { Code = "VALIDATION_ERROR", Message = "Email and name are required." });

            if (string.IsNullOrWhiteSpace(dto.Otp))
                return BadRequest(new { Code = "VALIDATION_ERROR", Message = "OTP verification is required to create a co-admin." });

            // Re-verify OTP inside this endpoint (prevents CSRF/race conditions)
            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdClaim?.Value, out int callerAdminId))
                return Unauthorized(new { Code = "INVALID_TOKEN", Message = "Unable to identify user from token." });

            var otpCacheKey = $"coadmin-create-otp:{callerAdminId}";
            if (!_cache.TryGetValue(otpCacheKey, out string? cachedOtp) || string.IsNullOrWhiteSpace(cachedOtp))
                return BadRequest(new { Code = "OTP_EXPIRED", Message = "OTP has expired. Please request a new one." });

            if (!cachedOtp.Equals(dto.Otp.Trim(), StringComparison.Ordinal))
                return BadRequest(new { Code = "INVALID_OTP", Message = "Invalid OTP." });

            // Invalidate OTP immediately after use
            _cache.Remove(otpCacheKey);

            // Check for duplicate
            var existingAdmin = await _context.Users.FirstOrDefaultAsync(u =>
                u.Email == dto.Email.Trim() &&
                (u.Role == UserRole.Admin || u.Role == UserRole.CoAdmin));
            if (existingAdmin != null)
            {
                _logger.LogWarning("Admin creation failed. Admin with email {Email} already exists.", dto.Email);
                return BadRequest(new { Code = "DUPLICATE_ADMIN", Message = "An admin/co-admin with this email already exists." });
            }

            try
            {
                // Auto-generate a strong password
                var plainPassword = GenerateSecureAdminPassword();
                string hashedPassword = BCrypt.Net.BCrypt.HashPassword(plainPassword);

                var adminUser = new User
                {
                    FullName = dto.Name.Trim(),
                    Email = dto.Email.Trim(),
                    PasswordHash = hashedPassword,
                    Role = UserRole.CoAdmin,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _context.Users.Add(adminUser);
                await _context.SaveChangesAsync();

                _logger.LogInformation("âœ… Co-admin user created successfully: {Email}", dto.Email);

                // Send branded welcome email with auto-generated credentials
                try
                {
                    var subject = "Welcome - Your Co-Admin Account on Job Fair Portal";
                    var body = Services.EmailTemplateService.GetWelcomeAdminTemplate(
                        dto.Name.Trim(), dto.Email.Trim(), plainPassword);
                    await _mailService.SendMailAsync(dto.Email.Trim(), subject, body);
                    _logger.LogInformation("Welcome email sent to new co-admin: {Email}", dto.Email);
                }
                catch (Exception mailEx)
                {
                    _logger.LogWarning(mailEx, "Failed to send welcome email to co-admin: {Email}", dto.Email);
                }

                return Ok(new
                {
                    Code = "SUCCESS",
                    Message = "Co-admin created successfully. Login credentials have been emailed.",
                    AdminId = adminUser.UserId,
                    Email = adminUser.Email,
                    Name = adminUser.FullName
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating admin user");
                return StatusCode(500, new { Code = "ERROR", Message = "Error creating admin user: " + ex.Message });
            }
        }

        // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        // Private helpers
        // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        private static string GenerateAdminOtp()
        {
            using var rng = System.Security.Cryptography.RandomNumberGenerator.Create();
            var buffer = new byte[sizeof(int)];
            rng.GetBytes(buffer);
            var number = Math.Abs(BitConverter.ToInt32(buffer, 0));
            return (number % 900000 + 100000).ToString();
        }

        /// <summary>
        /// Generates a cryptographically random password that always satisfies
        /// the portal's complexity rules (upper, lower, digit, special, â‰¥9 chars).
        /// </summary>
        private static string GenerateSecureAdminPassword()
        {
            const string upper = "ABCDEFGHJKLMNPQRSTUVWXYZ";
            const string lower = "abcdefghjkmnpqrstuvwxyz";
            const string digits = "23456789";
            const string special = "@#$%!&*";
            const string all = upper + lower + digits + special;

            using var rng = System.Security.Cryptography.RandomNumberGenerator.Create();

            char Pick(string charset)
            {
                var buf = new byte[1];
                while (true)
                {
                    rng.GetBytes(buf);
                    var idx = buf[0] % charset.Length;
                    return charset[idx];
                }
            }

            // Guarantee at least one of each required class
            var chars = new List<char>
            {
                Pick(upper), Pick(upper),
                Pick(lower), Pick(lower),
                Pick(digits),
                Pick(special),
            };

            // Fill to 12 characters
            for (int i = chars.Count; i < 12; i++)
                chars.Add(Pick(all));

            // Fisher-Yates shuffle
            for (int i = chars.Count - 1; i > 0; i--)
            {
                var buf = new byte[1];
                rng.GetBytes(buf);
                int j = buf[0] % (i + 1);
                (chars[i], chars[j]) = (chars[j], chars[i]);
            }

            return new string(chars.ToArray());
        }

        // ========================================
        // Change Admin Password
        // ========================================
        [HttpPut("admins/change-password")]
        [Authorize(Roles = "Admin,CoAdmin")]
        public async Task<IActionResult> ChangeAdminPassword([FromBody] ChangeAdminPasswordDto dto)
        {
            _logger.LogInformation("Admin changing password");

            // Validate input
            if (string.IsNullOrWhiteSpace(dto.CurrentPassword) || string.IsNullOrWhiteSpace(dto.NewPassword))
            {
                return BadRequest(new { Code = "VALIDATION_ERROR", Message = "Current password and new password are required." });
            }

            if (!System.Text.RegularExpressions.Regex.IsMatch(dto.NewPassword, @"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{9,}$"))
            {
                return BadRequest(new { Code = "WEAK_PASSWORD", Message = "Password does not meet minimum requirement: at least one upper case, one lower case, 9 characters in total, one special character, and one digit." });
            }

            try
            {
                // Get current admin user from token claims
                var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
                if (!int.TryParse(userIdClaim?.Value, out int userId))
                {
                    return Unauthorized(new { Code = "INVALID_TOKEN", Message = "Unable to identify user from token." });
                }

                var admin = await _context.Users.FirstOrDefaultAsync(u => u.UserId == userId && (u.Role == UserRole.Admin || u.Role == UserRole.CoAdmin));
                if (admin == null)
                {
                    return NotFound(new { Code = "ADMIN_NOT_FOUND", Message = "Admin user not found." });
                }

                // Verify current password
                if (!BCrypt.Net.BCrypt.Verify(dto.CurrentPassword, admin.PasswordHash))
                {
                    _logger.LogWarning("Password change failed: incorrect current password for admin {AdminId}", userId);
                    return BadRequest(new { Code = "INVALID_PASSWORD", Message = "Current password is incorrect." });
                }

                // Hash new password
                string hashedNewPassword = BCrypt.Net.BCrypt.HashPassword(dto.NewPassword);
                admin.PasswordHash = hashedNewPassword;
                admin.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                _logger.LogInformation("âœ… Admin {AdminId} changed password successfully", userId);

                return Ok(new
                {
                    Code = "SUCCESS",
                    Message = "Password changed successfully."
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error changing admin password");
                return StatusCode(500, new { Code = "ERROR", Message = "Error changing password: " + ex.Message });
            }
        }

        // ========================================
        // Change Admin Email
        // ========================================
        [HttpPut("admins/change-email")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> ChangeAdminEmail([FromBody] ChangeAdminEmailDto dto)
        {
            _logger.LogInformation("Admin changing email");

            // Validate input
            if (string.IsNullOrWhiteSpace(dto.NewEmail) || string.IsNullOrWhiteSpace(dto.Password))
            {
                return BadRequest(new { Code = "VALIDATION_ERROR", Message = "New email and password are required." });
            }

            try
            {
                // Get current admin user from token claims
                var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
                if (!int.TryParse(userIdClaim?.Value, out int userId))
                {
                    return Unauthorized(new { Code = "INVALID_TOKEN", Message = "Unable to identify user from token." });
                }

                var admin = await _context.Users.FirstOrDefaultAsync(u => u.UserId == userId && (u.Role == UserRole.Admin || u.Role == UserRole.CoAdmin));
                if (admin == null)
                {
                    return NotFound(new { Code = "ADMIN_NOT_FOUND", Message = "Admin user not found." });
                }

                // Verify password
                if (!BCrypt.Net.BCrypt.Verify(dto.Password, admin.PasswordHash))
                {
                    _logger.LogWarning("Email change failed: incorrect password for admin {AdminId}", userId);
                    return BadRequest(new { Code = "INVALID_PASSWORD", Message = "Password is incorrect." });
                }

                // Check if new email already exists
                var existingUser = await _context.Users.FirstOrDefaultAsync(u => u.Email == dto.NewEmail && u.UserId != userId);
                if (existingUser != null)
                {
                    return BadRequest(new { Code = "DUPLICATE_EMAIL", Message = "This email is already in use." });
                }

                // Update email
                admin.Email = dto.NewEmail;
                admin.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                _logger.LogInformation("âœ… Admin {AdminId} changed email to {NewEmail}", userId, dto.NewEmail);

                return Ok(new
                {
                    Code = "SUCCESS",
                    Message = "Email changed successfully.",
                    NewEmail = admin.Email
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error changing admin email");
                return StatusCode(500, new { Code = "ERROR", Message = "Error changing email: " + ex.Message });
            }
        }

        // ========================================
        // Get All Admins
        // ========================================
        [HttpGet("admins")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> GetAllAdmins()
        {
            if (!IsSuperAdmin())
            {
                return SuperAdminOnly("view co-admin accounts");
            }

            _logger.LogInformation("Fetching all admin users");

            try
            {
                var admins = await _context.Users
                    .Where(u => u.Role == UserRole.CoAdmin)
                    .Select(u => new
                    {
                        u.UserId,
                        u.Email,
                        u.FullName,
                        u.IsActive,
                        u.CreatedAt
                    })
                    .OrderByDescending(u => u.CreatedAt)
                    .ToListAsync();

                return Ok(new
                {
                    Code = "SUCCESS",
                    Count = admins.Count,
                    Admins = admins
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching admins");
                return StatusCode(500, new { Code = "ERROR", Message = "Error fetching admins: " + ex.Message });
            }
        }

        [HttpPut("admins/{adminId:int}/block")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> BlockCoAdmin(int adminId)
        {
            if (!IsSuperAdmin())
            {
                return SuperAdminOnly("block co-admin accounts");
            }

            var coAdmin = await _context.Users.FirstOrDefaultAsync(u => u.UserId == adminId && u.Role == UserRole.CoAdmin);
            if (coAdmin == null)
            {
                return NotFound(new { Code = "ADMIN_NOT_FOUND", Message = "Co-admin profile not found." });
            }

            if (!coAdmin.IsActive)
            {
                return Ok(new { Code = "SUCCESS", Message = "Co-admin is already blocked." });
            }

            coAdmin.IsActive = false;
            coAdmin.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { Code = "SUCCESS", Message = "Co-admin blocked successfully." });
        }

        [HttpPut("admins/{adminId:int}/unblock")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> UnblockCoAdmin(int adminId)
        {
            if (!IsSuperAdmin())
            {
                return SuperAdminOnly("unblock co-admin accounts");
            }

            var coAdmin = await _context.Users.FirstOrDefaultAsync(u => u.UserId == adminId && u.Role == UserRole.CoAdmin);
            if (coAdmin == null)
            {
                return NotFound(new { Code = "ADMIN_NOT_FOUND", Message = "Co-admin profile not found." });
            }

            if (coAdmin.IsActive)
            {
                return Ok(new { Code = "SUCCESS", Message = "Co-admin is already active." });
            }

            coAdmin.IsActive = true;
            coAdmin.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { Code = "SUCCESS", Message = "Co-admin unblocked successfully." });
        }

        [HttpDelete("admins/{adminId:int}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> DeleteCoAdmin(int adminId)
        {
            if (!IsSuperAdmin())
            {
                return SuperAdminOnly("delete co-admin accounts");
            }

            var coAdmin = await _context.Users.FirstOrDefaultAsync(u => u.UserId == adminId && u.Role == UserRole.CoAdmin);
            if (coAdmin == null)
            {
                return NotFound(new { Code = "ADMIN_NOT_FOUND", Message = "Co-admin profile not found." });
            }

            try
            {
                _context.Users.Remove(coAdmin);
                await _context.SaveChangesAsync();
                return Ok(new { Code = "SUCCESS", Message = "Co-admin deleted successfully." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to delete co-admin profile {AdminId}", adminId);
                return StatusCode(409, new
                {
                    Code = "DELETE_FAILED",
                    Message = "Unable to delete co-admin profile due to linked records. Block the profile instead."
                });
            }
        }
    }
}

