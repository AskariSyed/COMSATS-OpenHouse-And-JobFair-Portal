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
            // Fetch student
            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.StudentId == studentId);

            if (student == null)
                return NotFound("Student not found.");

            if (string.IsNullOrWhiteSpace(student.FcmToken))
                return BadRequest("Student does not have a registered FCM token.");

            // Construct the message
            var message = new Message
            {
                Token = student.FcmToken,

                // 🔹 This field ensures popup notifications on devices
                Notification = new Notification
                {
                    Title = dto.Title ?? "Notification",
                    Body = dto.Body ?? ""
                },

                // Optional data for app logic
                Data = dto.Data ?? new Dictionary<string, string>()
            };

            try
            {
                // Send message to FCM
                string response = await FirebaseMessaging.DefaultInstance.SendAsync(message);
                return Ok(new { Message = "Notification sent successfully.", Id = response });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { Message = "Failed to send notification.", Error = ex.Message });
            }
        }

        // -----------------------------
        // Send FCM Notification to All Students
        // -----------------------------
        [HttpPost("students/notify-all")]
        public async Task<IActionResult> NotifyAllStudents([FromBody] FcmMessageDto dto)
        {
            var tokens = await _context.Students
                .Where(s => !string.IsNullOrEmpty(s.FcmToken))
                .Select(s => s.FcmToken)
                .ToListAsync();

            if (!tokens.Any())
                return BadRequest("No students have registered FCM tokens.");

            var message = new MulticastMessage
            {
                Tokens = tokens,
                Notification = new Notification
                {
                    Title = dto.Title,
                    Body = dto.Body
                },
                Data = dto.Data ?? new Dictionary<string, string>() // optional
            };

            try
            {
                var response = await FirebaseMessaging.DefaultInstance.SendMulticastAsync(message);

                return Ok(new
                {
                    SuccessCount = response.SuccessCount,
                    FailureCount = response.FailureCount,
                    Responses = response.Responses.Select((r, i) => new
                    {
                        Token = tokens[i],
                        Success = r.IsSuccess,
                        Error = r.Exception?.Message
                    })
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { Message = "Failed to send notifications.", Error = ex.Message });
            }
        }
        // -----------------------------
        // Add Job Fair (Admin Only)
        // -----------------------------

        // Update existing AddJobFair endpoint to return proper response
        [HttpPost("jobfairs")]
        public async Task<IActionResult> AddJobFair([FromBody] JobFair dto)
        {
            if (string.IsNullOrWhiteSpace(dto.Semester))
                return BadRequest("Semester name is required.");

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
                Semester = dto.Semester,
                date = dto.date,
                IsActive = dto.IsActive
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

        private async Task<int?> GetActiveJobFairIdAsync()
        {
            var active = await _context.JobFairs.FirstOrDefaultAsync(jf => jf.IsActive);
            return active?.JobFairId;
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
                    TotalStudents = jf.Students.Count,
                    TotalCompanies = jf.Companies.Count,
                    TotalRooms = jf.Rooms.Count,
                    TotalInterviews = jf.Interviews.Count,
                    StudentsHired = jf.Interviews.Count(i => i.Status == InterviewStatus.Hired),
                    StudentsShortlisted = jf.Interviews.Count(i => i.Status == InterviewStatus.Shortlisted),
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
        [HttpGet("jobfairs/{jobFairId}/analytics")]
        public async Task<IActionResult> GetJobFairAnalytics(int jobFairId)
        {
            _logger.LogInformation("GetJobFairAnalytics called for jobFairId: {JobFairId}", jobFairId);

            // 1. ⚡ CHECK CACHE FIRST
            string cacheKey = $"jobfair_analytics_{jobFairId}";
            if (_cache.TryGetValue(cacheKey, out object cachedData))
            {
                _logger.LogInformation("Returning Analytics from Cache 🚀");
                return Ok(cachedData);
            }

            // 2. 🐢 FETCH FROM DB (Only if not in cache)
            // Added AsSplitQuery() to fix the slow database call
            var jobFair = await _context.JobFairs
                .AsSplitQuery()
                .Include(jf => jf.Students)
                    .ThenInclude(s => s.User)
                .Include(jf => jf.Companies)
                    .ThenInclude(c => c.User)
                .Include(jf => jf.Interviews)
                    .ThenInclude(i => i.Student)
                .Include(jf => jf.Rooms)
                .Include(jf => jf.Jobs)
                .Include(jf => jf.InterviewRequests)
                .FirstOrDefaultAsync(jf => jf.JobFairId == jobFairId);

            if (jobFair == null)
                return NotFound(new { Message = "Job Fair not found." });

            // 3. CALCULATION LOGIC (Same as before)
            var analytics = new
            {
                JobFairId = jobFair.JobFairId,
                Semester = jobFair.Semester,
                Date = jobFair.date,
                IsActive = jobFair.IsActive,

                OverallStats = new
                {
                    TotalStudents = jobFair.Students?.Count ?? 0,
                    TotalCompanies = jobFair.Companies?.Count ?? 0,
                    TotalRooms = jobFair.Rooms?.Count ?? 0,
                    TotalJobs = jobFair.Jobs?.Count ?? 0,
                    TotalInterviews = jobFair.Interviews?.Count ?? 0,
                    TotalInterviewRequests = jobFair.InterviewRequests?.Count ?? 0
                },

                InterviewStats = new
                {
                    Hired = jobFair.Interviews?.Count(i => i.Status == InterviewStatus.Hired) ?? 0,
                    Shortlisted = jobFair.Interviews?.Count(i => i.Status == InterviewStatus.Shortlisted) ?? 0,
                    Rejected = jobFair.Interviews?.Count(i => i.Status == InterviewStatus.Rejected) ?? 0,
                    Pending = jobFair.Interviews?.Count(i => i.Status == InterviewStatus.Queued) ?? 0,
                    HiringRate = (jobFair.Interviews?.Count ?? 0) > 0
                        ? Math.Round((double)jobFair.Interviews.Count(i => i.Status == InterviewStatus.Hired) / jobFair.Interviews.Count * 100, 2)
                        : 0
                },

                StudentsByDepartment = jobFair.Students?
                    .Where(s => s.Department != null)
                    .GroupBy(s => s.Department)
                    .Select(g => new
                    {
                        Department = g.Key,
                        Count = g.Count(),
                        AverageCGPA = g.Any() ? Math.Round(g.Average(s => s.CGPA), 2) : 0,
                        Hired = jobFair.Interviews.Count(i => i.Student != null && i.Student.Department == g.Key && i.Status == InterviewStatus.Hired)
                    })
                    .ToList() ?? new(),

                CompanyParticipation = jobFair.Companies?
                    .Select(c => new
                    {
                        CompanyId = c.CompanyId,
                        CompanyName = c.Name ?? "Unknown",
                        Industry = c.Industry,
                        LogoUrl = c.LogoUrl,
                        IsPresent = c.IsPresent,
                        ArrivalStatus = c.ArrivalStatus.ToString(),
                        TotalJobs = jobFair.Jobs.Count(j => j.CompanyId == c.CompanyId),
                        TotalInterviews = jobFair.Interviews.Count(i => i.CompanyId == c.CompanyId),
                        HiredCount = jobFair.Interviews.Count(i => i.CompanyId == c.CompanyId && i.Status == InterviewStatus.Hired),
                        ShortlistedCount = jobFair.Interviews.Count(i => i.CompanyId == c.CompanyId && i.Status == InterviewStatus.Shortlisted),
                        RejectedCount = jobFair.Interviews.Count(i => i.CompanyId == c.CompanyId && i.Status == InterviewStatus.Rejected),
                        InterviewRequestsReceived = jobFair.InterviewRequests.Count(ir => ir.CompanyId == c.CompanyId)
                    })
                    .OrderByDescending(c => c.HiredCount)
                    .ToList() ?? new(),

                StudentParticipation = new
                {
                    TotalRegistered = jobFair.Students?.Count ?? 0,
                    StudentsApplied = jobFair.InterviewRequests?.Select(ir => ir.StudentId).Distinct().Count() ?? 0,
                    StudentsHired = jobFair.Interviews?.Count(i => i.Status == InterviewStatus.Hired) ?? 0,
                    ApplicationRate = (jobFair.Students?.Count ?? 0) > 0
                        ? Math.Round((double)jobFair.InterviewRequests.Select(ir => ir.StudentId).Distinct().Count() / jobFair.Students.Count * 100, 2)
                        : 0,
                    HiringRate = (jobFair.InterviewRequests?.Select(ir => ir.StudentId).Distinct().Count() ?? 0) > 0
                        ? Math.Round((double)jobFair.Interviews.Count(i => i.Status == InterviewStatus.Hired) / jobFair.InterviewRequests.Select(ir => ir.StudentId).Distinct().Count() * 100, 2)
                        : 0
                },

                TopStudents = jobFair.Students?
                    .OrderByDescending(s => s.CGPA)
                    .Take(10)
                    .Select(s => new
                    {
                        StudentId = s.StudentId,
                        Name = s.User?.FullName ?? "Unknown",
                        RegistrationNo = s.RegistrationNo,
                        Department = s.Department,
                        CGPA = s.CGPA,
                        InterviewsAttended = jobFair.Interviews.Count(i => i.StudentId == s.StudentId),
                        Hired = jobFair.Interviews.Any(i => i.StudentId == s.StudentId && i.Status == InterviewStatus.Hired)
                    })
                    .ToList() ?? new(),

                RoomUtilization = new
                {
                    TotalRooms = jobFair.Rooms?.Count ?? 0,
                    VacantRooms = jobFair.Rooms?.Count(r => r.Status == RoomStatus.Vacant) ?? 0,
                    AllottedRooms = jobFair.Rooms?.Count(r => r.Status == RoomStatus.Alloted) ?? 0,
                    TentativeRooms = jobFair.Rooms?.Count(r => r.Status == RoomStatus.TentativelyAlloted) ?? 0,
                    AllocationRate = (jobFair.Rooms?.Count ?? 0) > 0
                        ? Math.Round((double)jobFair.Rooms.Count(r => r.Status == RoomStatus.Alloted) / jobFair.Rooms.Count * 100, 2)
                        : 0
                }
            };

            // 4. 💾 SAVE TO CACHE (Expire in 10 minutes)
            var cacheOptions = new MemoryCacheEntryOptions()
                .SetAbsoluteExpiration(TimeSpan.FromMinutes(10));

            _cache.Set(cacheKey, analytics, cacheOptions);

            return Ok(analytics);
        }
        [HttpGet("jobfairs/{jobFairId}/companies")]
        public async Task<IActionResult> GetJobFairCompanies(int jobFairId, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            _logger.LogInformation("GetJobFairCompanies called for jobFairId: {JobFairId}", jobFairId);

            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 20;

            var jobFair = await _context.JobFairs.FirstOrDefaultAsync(jf => jf.JobFairId == jobFairId);
            if (jobFair == null)
                return NotFound(new { Message = "Job Fair not found." });

            var query = _context.Companies
                .Include(c => c.Room)
                .Include(c => c.User)
                .Include(c => c.Interviews)
                .Include(c => c.Jobs)
                .Include(c => c.InterviewRequests)
                .Where(c => c.JobFairId == jobFairId);

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
                    Email = c.CompanyEmail,
                    Phone = c.CompanyPhone,
                    FocalPerson = c.FocalPersonName,
                    Address = c.Address,
                    IsPresent = c.IsPresent,
                    ArrivalStatus = c.ArrivalStatus.ToString(),
                    RoomAssigned = c.Room != null ? new
                    {
                        RoomId = c.Room.RoomId,
                        RoomName = c.Room.RoomName,
                        Capacity = c.Room.Capacity
                    } : null,
                    RepsCount = c.RepsCount,
                    InterviewDurationMinutes = c.InterviewDurationMinutes,
                    TotalJobs = c.Jobs.Count,
                    TotalInterviews = c.Interviews.Count,
                    HiredCount = c.Interviews.Count(i => i.Status == InterviewStatus.Hired),
                    ShortlistedCount = c.Interviews.Count(i => i.Status == InterviewStatus.Shortlisted),
                    RejectedCount = c.Interviews.Count(i => i.Status == InterviewStatus.Rejected),
                    InterviewRequestsReceived = c.InterviewRequests.Count,
                    CreatedAt = c.CreatedAt
                })
                .ToListAsync();

            return Ok(new
            {
                JobFairId = jobFairId,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize,
                TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
                Companies = companies
            });
        }

        // 22. Get Job Fair Students Detail
        [HttpGet("jobfairs/{jobFairId}/students")]
        public async Task<IActionResult> GetJobFairStudents(int jobFairId, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            _logger.LogInformation("GetJobFairStudents called for jobFairId: {JobFairId}", jobFairId);

            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 20;

            var jobFair = await _context.JobFairs.FirstOrDefaultAsync(jf => jf.JobFairId == jobFairId);
            if (jobFair == null)
                return NotFound(new { Message = "Job Fair not found." });

            var query = _context.Students
                .Include(s => s.User)
                .Include(s => s.Interviews)
                .Include(s => s.InterviewRequests)
                .Where(s => s.JobFairId == jobFairId);

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
                    InterviewsAttended = s.Interviews.Count,
                    InterviewsHired = s.Interviews.Count(i => i.Status == InterviewStatus.Hired),
                    InterviewsShortlisted = s.Interviews.Count(i => i.Status == InterviewStatus.Shortlisted),
                    InterviewsRejected = s.Interviews.Count(i => i.Status == InterviewStatus.Rejected),
                    ApplicationsSent = s.InterviewRequests.Count,
                    ApplicationsAccepted = s.InterviewRequests.Count(ir => ir.Status == RequestStatus.Accepted),
                    ApplicationsPending = s.InterviewRequests.Count(ir => ir.Status == RequestStatus.Pending),
                    ApplicationsRejected = s.InterviewRequests.Count(ir => ir.Status == RequestStatus.Rejected),
                    CreatedAt = s.CreatedAt
                })
                .ToListAsync();

            return Ok(new
            {
                JobFairId = jobFairId,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize,
                TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
                Students = students
            });
        }

        // 23. Get Job Fair Summary Report
        [HttpGet("jobfairs/{jobFairId}/report")]
        public async Task<IActionResult> GetJobFairReport(int jobFairId)
        {
            _logger.LogInformation("GetJobFairReport called for jobFairId: {JobFairId}", jobFairId);

            var jobFair = await _context.JobFairs
                .Include(jf => jf.Students)
                .Include(jf => jf.Companies)
                .Include(jf => jf.Interviews)
                .Include(jf => jf.InterviewRequests)
                .Include(jf => jf.Rooms)
                .Include(jf => jf.Jobs)
                .FirstOrDefaultAsync(jf => jf.JobFairId == jobFairId);

            if (jobFair == null)
                return NotFound(new { Message = "Job Fair not found." });

            var report = new
            {
                // --- Header Info ---
                JobFairId = jobFair.JobFairId,
                Semester = jobFair.Semester,
                Date = jobFair.date,
                IsActive = jobFair.IsActive,
                GeneratedAt = DateTime.UtcNow,

                // --- Executive Summary ---
                ExecutiveSummary = new
                {
                    TotalStudents = jobFair.Students.Count,
                    TotalCompanies = jobFair.Companies.Count,
                    TotalPositions = jobFair.Jobs.Sum(j => j.NumberOfJobs),
                    TotalApplications = jobFair.InterviewRequests.Count,
                    TotalInterviewsCompleted = jobFair.Interviews.Count(i =>
                        i.Status == InterviewStatus.Hired ||
                        i.Status == InterviewStatus.Shortlisted ||
                        i.Status == InterviewStatus.Rejected),
                    TotalHired = jobFair.Interviews.Count(i => i.Status == InterviewStatus.Hired),
                    TotalShortlisted = jobFair.Interviews.Count(i => i.Status == InterviewStatus.Shortlisted)
                },

                // --- Placement Rate ---
                PlacementMetrics = new
                {
                    StudentPlacementRate = jobFair.Students.Count > 0
                        ? Math.Round((double)jobFair.Interviews.Count(i => i.Status == InterviewStatus.Hired) / jobFair.Students.Count * 100, 2)
                        : 0,
                    AvgApplicationsPerStudent = jobFair.Students.Count > 0
                        ? Math.Round((double)jobFair.InterviewRequests.Count / jobFair.Students.Count, 2)
                        : 0,
                    AvgInterviewsPerStudent = jobFair.Students.Count > 0
                        ? Math.Round((double)jobFair.Interviews.Count / jobFair.Students.Count, 2)
                        : 0,
                    ApplicationSuccessRate = jobFair.InterviewRequests.Count > 0
                        ? Math.Round((double)jobFair.Interviews.Count / jobFair.InterviewRequests.Count * 100, 2)
                        : 0
                },

                // --- Company Performance ---
                TopRecruiters = jobFair.Companies
                    .OrderByDescending(c => jobFair.Interviews.Count(i => i.CompanyId == c.CompanyId && i.Status == InterviewStatus.Hired))
                    .Take(5)
                    .Select(c => new
                    {
                        CompanyId = c.CompanyId,
                        CompanyName = c.Name,
                        Industry = c.Industry,
                        Hired = jobFair.Interviews.Count(i => i.CompanyId == c.CompanyId && i.Status == InterviewStatus.Hired),
                        Shortlisted = jobFair.Interviews.Count(i => i.CompanyId == c.CompanyId && i.Status == InterviewStatus.Shortlisted),
                        Interviewed = jobFair.Interviews.Count(i => i.CompanyId == c.CompanyId)
                    })
                    .ToList(),

                // --- Department Wise Placement ---
                DepartmentPlacement = jobFair.Students
                    .GroupBy(s => s.Department)
                    .Select(g => new
                    {
                        Department = g.Key,
                        TotalStudents = g.Count(),
                        Placed = jobFair.Interviews.Count(i => i.Student.Department == g.Key && i.Status == InterviewStatus.Hired),
                        PlacementRate = g.Count() > 0
                            ? Math.Round((double)jobFair.Interviews.Count(i => i.Student.Department == g.Key && i.Status == InterviewStatus.Hired) / g.Count() * 100, 2)
                            : 0,
                        AverageCGPA = Math.Round(g.Average(s => s.CGPA), 2)
                    })
                    .OrderByDescending(d => d.PlacementRate)
                    .ToList(),

                // --- Infrastructure ---
                InfrastructureUtilization = new
                {
                    TotalRooms = jobFair.Rooms.Count,
                    RoomsUtilized = jobFair.Rooms.Count(r => r.CompanyId.HasValue),
                    UtilizationRate = jobFair.Rooms.Count > 0
                        ? Math.Round((double)jobFair.Rooms.Count(r => r.CompanyId.HasValue) / jobFair.Rooms.Count * 100, 2)
                        : 0
                }
            };

            return Ok(report);
        }

        [HttpDelete("notice/{id}")]
        [Authorize(Roles = "Admin")]
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
        [Authorize(Roles = "Admin")]
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
        // -----------------------------
        // 2. Get Notices (Dynamic based on Role)
        // -----------------------------
        [HttpGet("notices")]
        [Authorize]
        public async Task<IActionResult> GetNotices()
        {
            var activeJobFair = await _context.JobFairs.FirstOrDefaultAsync(j => j.IsActive);
            if (activeJobFair == null)
                return Ok(new List<NoticeResponseDto>());

            var isStudent = User.IsInRole("Student");
            var isCompany = User.IsInRole("Company");
            var isAdmin = User.IsInRole("Admin");

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
        [HttpPut("Notice/{id}/toggle-visibility")]
        [Authorize(Roles = "Admin")]
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
        // -----------------------------
        // Update Notice
        // -----------------------------
        [HttpPut("notices/{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> UpdateNotice(int id, [FromBody] NoticeCreateDto dto)
        {
            var notice = await _context.Notices.FindAsync(id);
            if (notice == null)
                return NotFound("Notice not found.");

            // Update fields
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
    }
}