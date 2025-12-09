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



namespace JobFairPortal.Controllers

{
    // -----------------------------
    // Controller
    // -----------------------------
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "Admin")]
    public class AdminController : ControllerBase
    {
        private readonly JobFairRecruitmentDbContext _context;

        private readonly ILogger<AdminController> _logger;
        private readonly IMemoryCache _cache;



        public AdminController(JobFairRecruitmentDbContext context, ILogger<AdminController> logger, IMemoryCache cache)
        {
            _context = context;
            _logger = logger;
            _cache = cache;
        }
        // -----------------------------
        // 1. Create Admin
        // -----------------------------
        [HttpPost("create-onetime")]
        public async Task<IActionResult> CreateAdmin([FromBody] AdminCreateDto dto)
        {
            _logger.LogInformation("CreateAdmin called with email: {Email}", dto.Email);

            var existingAdmin = await _context.Users.FirstOrDefaultAsync(u => u.Email == dto.Email && u.Role == UserRole.Admin);
            if (existingAdmin != null)
            {
                _logger.LogWarning("Admin creation failed. Admin with email {Email} already exists.", dto.Email);
                return BadRequest("Admin with this email already exists.");
            }

            string hashedPassword = BCrypt.Net.BCrypt.HashPassword(dto.Password);

            var adminUser = new User
            {
                FullName = dto.Name,
                Email = dto.Email,
                PasswordHash = hashedPassword,
                Role = UserRole.Admin
            };

            _context.Users.Add(adminUser);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Admin profile created successfully for email: {Email}", dto.Email);

            return Ok(new
            {
                Message = "Admin profile created successfully.",
                AdminId = adminUser.UserId,
                Email = adminUser.Email
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
        [HttpGet("rooms")]
        public async Task<IActionResult> GetRooms()
        {
            var rooms = await _context.Rooms
                .Include(r => r.Company)
                .Select(r => new RoomResponseDto
                {
                    RoomId = r.RoomId,
                    RoomName = r.RoomName,
                    Capacity = r.Capacity,
                    Status = r.Status,
                    CompanyName = r.Company != null ? r.Company.Name : null
                })
                .ToListAsync();

            return Ok(rooms);
        }

        // -----------------------------
        // 4. Get All Companies
        // -----------------------------
        [HttpGet("companies")]
        public async Task<IActionResult> GetCompanies([FromQuery] int? jobFairId = null, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            jobFairId ??= await GetActiveJobFairIdAsync();
            if (jobFairId == null)
                return BadRequest("No active job fair found.");

            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 20;

            var query = _context.Companies
                .Include(c => c.User)
                .Include(c => c.Room)
                .Include(c => c.Interviews)
                .Include(c => c.Jobs)
                .Where(c => c.JobFairId == jobFairId.Value);

            var totalCount = await query.CountAsync();
            var companies = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(c => new
                {
                    CompanyId = c.CompanyId,
                    Name = c.Name,
                    Industry = c.Industry,
                    LogoUrl = c.LogoUrl,
                    Website = c.Website,
                    UserEmail = c.User != null ? c.User.Email : null,
                    RoomName = c.Room != null ? c.Room.RoomName : null,
                    ArrivalStatus = c.ArrivalStatus.ToString(),
                    IsPresent = c.IsPresent,
                    TotalJobs = c.Jobs.Count,
                    TotalInterviews = c.Interviews.Count,
                    HiredCount = c.Interviews.Count(i => i.Status == InterviewStatus.Hired),
                    ShortlistedCount = c.Interviews.Count(i => i.Status == InterviewStatus.Shortlisted),
                    RejectedCount = c.Interviews.Count(i => i.Status == InterviewStatus.Rejected),
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
                .FirstOrDefaultAsync(c => c.CompanyId == companyId);

            if (company == null)
                return NotFound(new { Message = "Company not found." });

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
                ArrivalStatus = company.ArrivalStatus.ToString(),
                IsPresent = company.IsPresent,
                RepsCount = company.RepsCount,
                InterviewDurationMinutes = company.InterviewDurationMinutes,

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

            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 20;

            var query = _context.Companies
                .Include(c => c.User)
                .Include(c => c.Room)
                .Include(c => c.Interviews)
                .Include(c => c.Jobs)
                .AsQueryable();

            // Filter by industry
            if (!string.IsNullOrWhiteSpace(industry))
                query = query.Where(c => c.Industry.ToLower().Contains(industry.ToLower()));

            // Filter by arrival status
            if (!string.IsNullOrWhiteSpace(arrivalStatus))
            {
                if (Enum.TryParse<ArrivalStatus>(arrivalStatus, true, out var status))
                    query = query.Where(c => c.ArrivalStatus == status);
            }

            // Filter by presence
            if (isPresent.HasValue)
                query = query.Where(c => c.IsPresent == isPresent.Value);

            var totalCount = await query.CountAsync();
            var companies = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(c => new
                {
                    CompanyId = c.CompanyId,
                    Name = c.Name,
                    Industry = c.Industry,
                    LogoUrl = c.LogoUrl,
                    Website = c.Website,
                    UserEmail = c.User != null ? c.User.Email : null,
                    RoomName = c.Room != null ? c.Room.RoomName : null,
                    ArrivalStatus = c.ArrivalStatus.ToString(),
                    IsPresent = c.IsPresent,
                    TotalJobs = c.Jobs.Count,
                    HiredCount = c.Interviews.Count(i => i.Status == InterviewStatus.Hired),
                    ShortlistedCount = c.Interviews.Count(i => i.Status == InterviewStatus.Shortlisted)
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
        // 5. Add On-Spot Company
        // -----------------------------
        [HttpPost("companies/onspot")]
        public async Task<IActionResult> AddOnSpotCompany([FromBody] CompanyCreateDto dto)
        {
            var company = new Company
            {
                Name = dto.Name,
                Industry = dto.Industry,
                ArrivalStatus = ArrivalStatus.OnSpot,
                IsPresent = true,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.Companies.Add(company);
            await _context.SaveChangesAsync();

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
        public async Task<IActionResult> GetSurveys()
        {
            // 1. Fetch data from DB first (Materialize)
            var surveysData = await _context.Surveys
                .Include(s => s.Company)
                .OrderByDescending(s => s.SubmittedAt)
                .ToListAsync();

            // 2. Deserialize and Map in memory
            var surveys = surveysData.Select(s => new
            {
                SurveyId = s.SurveyId,
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
                    ActorName = a.Actor.FullName,
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

        // -----------------------------
        // 10. Dashboard Overview
        // -----------------------------
        [HttpGet("dashboard/overview")]
        public async Task<IActionResult> GetDashboardOverview()
        {
            // 1. Define a unique cache key
            string cacheKey = "dashboard_stats";

            // 2. Check if data is already in cache
            if (!_cache.TryGetValue(cacheKey, out DashboardOverviewDto dashboard))
            {
                // ⚠️ CACHE MISS: Data not found, fetch from Database
                _logger.LogInformation("Fetching dashboard stats from DB...");

                dashboard = new DashboardOverviewDto
                {
                    TotalStudents = await _context.Students.CountAsync(),
                    TotalCompanies = await _context.Companies.CountAsync(),
                    TotalRooms = await _context.Rooms.CountAsync(),
                    StudentsHired = await _context.Interviews.CountAsync(i => i.Status == InterviewStatus.Hired),
                    StudentsShortlisted = await _context.Interviews.CountAsync(i => i.Status == InterviewStatus.Shortlisted),
                    CDCSurveysReceived = await _context.Surveys.CountAsync(s => s.Type == SurveyType.CDC),
                    DepartmentSurveysReceived = await _context.Surveys.CountAsync(s => s.Type == SurveyType.Department)
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
        [HttpGet("rooms/filter")]
        public async Task<IActionResult> FilterRooms([FromQuery] RoomStatus? status, [FromQuery] int? minCapacity, [FromQuery] int? maxCapacity)
        {
            var query = _context.Rooms.Include(r => r.Company).AsQueryable();

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
                    CompanyName = r.Company != null ? r.Company.Name : null
                })
                .ToListAsync();

            return Ok(rooms);
        }

        // -----------------------------
        // 13. Assign Company to Room
        // -----------------------------
        [HttpPut("rooms/assign-company")]
        public async Task<IActionResult> AssignCompanyToRoom([FromQuery] int companyId, [FromQuery] int roomId)
        {
            var company = await _context.Companies.FindAsync(companyId);
            if (company == null)
                return NotFound("Company not found.");

            var requestedRoom = await _context.Rooms.FindAsync(roomId);
            if (requestedRoom == null)
                return NotFound("Requested room not found.");

            if (requestedRoom.Status == RoomStatus.Alloted)
                return BadRequest("Requested room is already occupied.");

            requestedRoom.CompanyId = companyId;
            requestedRoom.Status = RoomStatus.Alloted;
            requestedRoom.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

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
        // 14. Update Room Details
        // -----------------------------
        [HttpPut("rooms/{roomId}")]
        public async Task<IActionResult> UpdateRoomDetails(int roomId, [FromBody] RoomUpdateDto dto)
        {
            var room = await _context.Rooms.FindAsync(roomId);
            if (room == null)
                return NotFound("Room not found.");

            room.RoomName = dto.RoomName;
            room.Capacity = dto.Capacity;
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

        // -----------------------------
        // 15. Remove Company from Room
        // -----------------------------
        [HttpPut("rooms/{roomId}/remove-company")]
        public async Task<IActionResult> RemoveCompanyFromRoom(int roomId)
        {
            var room = await _context.Rooms.Include(r => r.Company).FirstOrDefaultAsync(r => r.RoomId == roomId);
            if (room == null)
                return NotFound("Room not found.");

            room.CompanyId = null;
            room.Status = RoomStatus.Vacant;
            room.UpdatedAt = DateTime.UtcNow;

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


        // -----------------------------
        // 16. Get All Students (Paginated)
        // -----------------------------
        [HttpGet("students")]
        public async Task<IActionResult> GetAllStudents([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            _logger.LogInformation("GetAllStudents called by admin with page={Page}, pageSize={PageSize}.", page, pageSize);

            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 20;

            var query = _context.Students
                .Include(s => s.User)
                .Include(s => s.StudentProjects)
                    .ThenInclude(sp => sp.Project)
                .Include(s => s.Achievements)
                .Include(s => s.Certifications)
                .Include(s => s.Educations)
                .OrderBy(s => s.StudentId);

            var totalCount = await query.CountAsync();
            var students = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(s => new
                {
                    StudentId = s.StudentId,
                    Name = s.User.FullName,
                    Email = s.User.Email,
                    Phone = s.User.Phone,
                    RegistrationNo = s.RegistrationNo,
                    Department = s.Department,
                    CGPA = s.CGPA,
                    ProfilePicUrl = s.ProfilePicUrl,
                    Skills = s.Skills ?? new List<string>(),
                    FypTitle = s.StudentProjects
                        .Where(sp => sp.Project != null && sp.Project.Type == ProjectType.FinalYear)
                        .Select(sp => sp.Project.Title)
                        .FirstOrDefault(),
                    TotalProjects = s.StudentProjects.Count(sp => sp.Status == ProjectInviteStatus.Accepted),
                    TotalAchievements = s.Achievements.Count,
                    TotalCertifications = s.Certifications.Count,
                    TotalEducations = s.Educations.Count,
                    CreatedAt = s.CreatedAt,
                    UpdatedAt = s.UpdatedAt
                })
                .ToListAsync();

            return Ok(new
            {
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize,
                TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
                Students = students
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

            var query = _context.Students
                .Include(s => s.User)
                .Include(s => s.StudentProjects)
                    .ThenInclude(sp => sp.Project)
                .AsQueryable();

            // Apply department filter
            if (!string.IsNullOrWhiteSpace(department))
                query = query.Where(s => s.Department == department);

            // Apply CGPA filter
            if (minCgpa.HasValue)
                query = query.Where(s => s.CGPA >= minCgpa.Value);

            // Apply FYP title filter
            if (!string.IsNullOrWhiteSpace(fypTitleContains))
            {
                query = query.Where(s =>
                    s.StudentProjects.Any(sp =>
                        sp.Project.Type == ProjectType.FinalYear &&
                        sp.Project.Title.Contains(fypTitleContains)));
            }

            var students = await query
                .Select(s => new
                {
                    StudentId = s.StudentId,
                    Name = s.User.FullName,
                    RegistrationNo = s.RegistrationNo,
                    Department = s.Department,
                    CGPA = s.CGPA,
                    FYPs = s.StudentProjects
                        .Where(sp => sp.Project.Type == ProjectType.FinalYear)
                        .Select(sp => new
                        {
                            Title = sp.Project.Title,
                            Description = sp.Project.Description,
                            Status = sp.Status
                        }).ToList(),
                    Skills = s.Skills ?? new List<string>(),
                    Links = s.ContactLinks != null
    ? s.ContactLinks.ToDictionary(
        cl => cl.Platform.ToString(),
        cl => cl.Url)
    : new Dictionary<string, string>()
                })
                .ToListAsync();

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
                                StudentName = student.User?.FullName,
                                Email = student.User?.Email,
                                RegistrationNo = student.RegistrationNo,
                                Token = $"{student.FcmToken[..20]}... (truncated)",
                                ErrorType = "INVALID_TOKEN",
                                ErrorReason = "Token is expired or from a different Firebase project",
                                Severity = "HIGH"
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
                            StudentName = student.User?.FullName,
                            Email = student.User?.Email,
                            RegistrationNo = student.RegistrationNo,
                            Token = $"{student.FcmToken[..20]}... (truncated)",
                            ErrorType = "VALIDATION_ERROR",
                            ErrorReason = ex.Message,
                            Severity = "MEDIUM"
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
    }
}