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
using FirebaseAdmin.Messaging;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FirebaseAdmin.Messaging;
using Notification = FirebaseAdmin.Messaging.Notification;


namespace JobFairPortal.Controllers

{
    // -----------------------------
    // Controller
    // -----------------------------
    [ApiController]
    [Route("api/[controller]")]
    //[Authorize(Roles = "Admin")]
    public class AdminController : ControllerBase
    {
        private readonly JobFairRecruitmentDbContext _context;

        private readonly ILogger<AdminController> _logger;


        public AdminController(JobFairRecruitmentDbContext context, ILogger<AdminController> logger)
        {
            _context = context;
            _logger = logger;
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
        public async Task<IActionResult> AddRoom([FromBody] RoomCreateDto dto)
        {
            var room = new Room
            {
                RoomName = dto.RoomName,
                Capacity = dto.Capacity,
                Status = RoomStatus.Vacant,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.Rooms.Add(room);
            await _context.SaveChangesAsync();

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
            // Basic file validation
            if (file == null || file.Length == 0)
            {
                return BadRequest(new { Message = "No file was uploaded." });
            }

            var fileExtension = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (fileExtension != ".csv" && fileExtension != ".xlsx")
            {
                return BadRequest(new { Message = "Invalid file format. Please upload a .csv or .xlsx file." });
            }


            var roomsToCreate = new List<Room>();
            var roomsToUpdate = new List<Room>();
            var errors = new List<string>();

            ExcelPackage.License.SetNonCommercialPersonal("Hassan Askari");

            using (var stream = new MemoryStream())
            {
                await file.CopyToAsync(stream);
                stream.Position = 0;

                if (fileExtension == ".xlsx")
                {
                    await ParseXlsxStream(stream, roomsToCreate, roomsToUpdate, errors);
                }
                else // .csv
                {
                    await ParseCsvStream(stream, roomsToCreate, roomsToUpdate, errors);
                }
            }

            if (!roomsToCreate.Any() && !roomsToUpdate.Any())
            {
                return BadRequest(new
                {
                    Message = "No valid room data found in the file.",
                    Errors = errors
                });
            }

            // Add new rooms and update only the necessary existing ones
            if (roomsToCreate.Any())
            {
                await _context.Rooms.AddRangeAsync(roomsToCreate);
            }
            if (roomsToUpdate.Any())
            {
                _context.Rooms.UpdateRange(roomsToUpdate);
            }

            await _context.SaveChangesAsync();

            var message = $"Bulk upload finished. Successfully added {roomsToCreate.Count} new rooms and updated {roomsToUpdate.Count} existing rooms.";
            string errorSummary = errors.Any() ? string.Join(", ", errors) : "No errors.";

            return Ok(new
            {
                Message = message,
                Errors = errorSummary
            });
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
        public async Task<IActionResult> GetCompanies()
        {
            var companies = await _context.Companies
                .Include(c => c.User)
                .Include(c => c.Room)
                .Select(c => new CompanyResponseDto
                {
                    CompanyId = c.CompanyId,
                    Name = c.Name,
                    Industry = c.Industry,
                    UserEmail = c.User != null ? c.User.Email : null,
                    RoomName = c.Room != null ? c.Room.RoomName : null
                })
                .ToListAsync();

            return Ok(companies);
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
            var surveys = await _context.Surveys
                .Include(s => s.Company)
                .OrderByDescending(s => s.SubmittedAt)
                .Select(s => new SurveyResponseDto
                {
                    SurveyId = s.SurveyId,
                    Type = s.Type.ToString(),
                    Responses = string.IsNullOrEmpty(s.Responses)
                        ? null
                        : JsonSerializer.Deserialize<object>(s.Responses, new JsonSerializerOptions()), // Explicitly provide JsonSerializerOptions to avoid optional argument issue
                    CompanyName = s.Company != null ? s.Company.Name : null,
                    SubmittedAt = s.SubmittedAt
                })
                .ToListAsync();

            return Ok(surveys);
        }
        // -----------------------------
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
            var dashboard = new DashboardOverviewDto
            {
                TotalStudents = await _context.Students.CountAsync(),
                TotalCompanies = await _context.Companies.CountAsync(),
                TotalRooms = await _context.Rooms.CountAsync(),
                StudentsHired = await _context.Interviews.CountAsync(i => i.Status == InterviewStatus.Hired),
                StudentsShortlisted = await _context.Interviews.CountAsync(i => i.Status == InterviewStatus.Shortlisted),
                CDCSurveysReceived = await _context.Surveys.CountAsync(s => s.Type == SurveyType.CDC),
                DepartmentSurveysReceived = await _context.Surveys.CountAsync(s => s.Type == SurveyType.Department)
            };

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


        [HttpGet("companies/overview")]
        public async Task<IActionResult> GetCompaniesOverview()
        {
            var companies = await _context.Companies
                .Include(c => c.Room)
                .Include(c => c.Interviews)
                .ToListAsync();

            var result = companies.Select(c => new CompanyOverviewDto
            {
                CompanyId = c.CompanyId,
                CompanyName = c.Name,
                Field = c.Industry, // Assuming you have a "Field" column (else add one)
                InterviewingStatus = c.IsPresent ? "Present" : "Not Present",
                RoomAllotted = c.Room != null ? c.Room.RoomName : null,
                TotalInterviews = c.Interviews.Count,
                StudentsShortlisted = c.Interviews.Count(i => i.Status == InterviewStatus.Shortlisted),
                StudentsHired = c.Interviews.Count(i => i.Status == InterviewStatus.Hired),
                StudentsRejected = c.Interviews.Count(i => i.Status == InterviewStatus.Rejected),
                StudentsQueued = c.Interviews.Count(i => i.Status == InterviewStatus.Queued)
            });

            return Ok(result);
        }
        [HttpPut("companies/change-room")]
        public async Task<IActionResult> ChangeCompanyRoom([FromBody] ChangeCompanyRoomDto dto)
        {
            var company = await _context.Companies.FindAsync(dto.CompanyId);
            if (company == null)
                return NotFound("Company not found.");

            var room = await _context.Rooms.FindAsync(dto.RoomId);
            if (room == null)
                return NotFound("Room not found.");

            // Check if room is already allotted to another company
            if (room.Status == RoomStatus.Alloted && room.CompanyId != company.CompanyId)
                return BadRequest("Room already allotted to another company.");

            // Reset old room if this company already has one
            var oldRoom = await _context.Rooms.FirstOrDefaultAsync(r => r.CompanyId == company.CompanyId);
            if (oldRoom != null)
            {
                oldRoom.CompanyId = null;
                oldRoom.Status = RoomStatus.Vacant;
                oldRoom.UpdatedAt = DateTime.UtcNow;
            }
            // Assign new room
            room.CompanyId = company.CompanyId;
            room.Status = RoomStatus.Alloted;
            room.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return Ok(new { Message = $"Room {room.RoomName} assigned to {company.Name}" });
        }

        [HttpGet("companies/{companyId}/details")]
        public async Task<IActionResult> GetCompanyDetails(int companyId)
        {
            try
            {
                var company = await _context.Companies
                    .Include(c => c.Room)
                    .Include(c => c.Jobs)
                    .Include(c => c.Interviews)
                    .Include(c => c.User)
                    .FirstOrDefaultAsync(c => c.CompanyId == companyId);

                if (company == null)
                    return NotFound(new { Message = "Company not found." });

                string? logoUrl = null;
                if (!string.IsNullOrEmpty(company.LogoUrl))
                {

                    var filePath = Path.Combine("", "companies", "logo", company.LogoUrl);
                    if (System.IO.File.Exists(filePath))
                        logoUrl = $"/uploads/companies/logo/{company.LogoUrl}";
                    else
                        logoUrl = "/uploads/companies/logo/default.png";
                }
                else
                {
                    logoUrl = "/uploads/companies/logo/default.png";
                }

                var companyDetails = new
                {
                    CompanyId = company.CompanyId,
                    CompanyName = company.Name,
                    Industry = company.Industry,
                    ContactEmail = company.User?.Email,
                    LogoUrl = logoUrl,
                    RoomAllotted = company.Room?.RoomName,
                    Jobs = company.Jobs.Select(j => new
                    {
                        JobId = j.JobId,
                        JobTitle = j.JobTitle,
                        JobType = j.JobType.ToString(),
                        JobDescription = j.JobDescription
                    }),
                    InterviewStats = new
                    {
                        TotalInterviews = company.Interviews.Count,
                        StudentsQueued = company.Interviews.Count(i => i.Status == InterviewStatus.Queued),
                        StudentsShortlisted = company.Interviews.Count(i => i.Status == InterviewStatus.Shortlisted),
                        StudentsHired = company.Interviews.Count(i => i.Status == InterviewStatus.Hired),
                        StudentsRejected = company.Interviews.Count(i => i.Status == InterviewStatus.Rejected),
                        InterviewedStudents = company.Interviews.Select(i => new
                        {
                            StudentId = i.Student.StudentId,
                            StudentName = i.Student.User.FullName,
                            InterviewStatus = i.Status.ToString()
                        })
                    }
                };

                return Ok(companyDetails);
            }
            catch (Exception ex)
            {
                // Log the error if needed
                return StatusCode(500, new { Message = "An unexpected error occurred.", Details = ex.Message });
            }
        }

        // -----------------------------
        // 16. Get All Students
        // -----------------------------
        [HttpGet("students")]
        public async Task<IActionResult> GetAllStudents()
        {
            _logger.LogInformation("GetAllStudents called by admin.");

            var students = await _context.Students
                .Include(s => s.User)
                .Select(s => new
                {
                    StudentId = s.StudentId,
                    Name = s.User.FullName,
                    RegistrationNo = s.RegistrationNo,
                    Department = s.Department,
                    FypTitle = s.FypTitle,
                    CGPA = s.CGPA
                })
                .ToListAsync();

            return Ok(students);
        }

        // -----------------------------
        // 17. Filter Students by Department, Min CGPA, or Registration Number
        // -----------------------------
        [HttpGet("students/filter")]
        public async Task<IActionResult> FilterStudents(
            [FromQuery] string? department,
            [FromQuery] decimal? minCgpa
            )
        {
            _logger.LogInformation("FilterStudents called with department: {Department}, minCgpa: {MinCgpa}, ", department, minCgpa);

            var query = _context.Students.Include(s => s.User).AsQueryable();

            if (!string.IsNullOrWhiteSpace(department))
                query = query.Where(s => s.Department == department);

            if (minCgpa.HasValue)
                query = query.Where(s => s.CGPA >= minCgpa.Value);


            var students = await query
                .Select(s => new
                {
                    Name = s.User.FullName,
                    RegistrationNo = s.RegistrationNo,
                    Department = s.Department,
                    FypTitle = s.FypTitle,
                    CGPA = s.CGPA
                })
                .ToListAsync();

            return Ok(students);
        }

        // -----------------------------
        // 18. Get Student Detail by Id
        // -----------------------------
        [HttpGet("students/{studentId}/details")]
        public async Task<IActionResult> GetStudentDetail(int studentId)
        {
            _logger.LogInformation("GetStudentDetail called for studentId: {StudentId}", studentId);

            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.StudentId == studentId);

            if (student == null || student.User == null)
                return NotFound(new { Message = "Student not found." });

            var detail = new
            {
                Name = student.User.FullName,
                RegistrationNo = student.RegistrationNo,
                FypDemoUrl = student.FypDemoUrl,
                FypTitle = student.FypTitle,
                FypDescription = student.FypDescription,
                CGPA = student.CGPA,
                ContactDetails = new
                {
                    Email = student.User.Email,
                    Phone = student.User.Phone,
                    LinkedIn = student.LinkedIn,
                    GitHub = student.GitHub
                    // Add more fields if needed
                }
            };

            return Ok(detail);
        }
        private async Task ParseXlsxStream(Stream stream, List<Room> roomsToCreate, List<Room> roomsToUpdate, List<string> errors)
        {
            using (var package = new ExcelPackage(stream))
            {
                var worksheet = package.Workbook.Worksheets.FirstOrDefault();
                if (worksheet == null)
                {
                    errors.Add("The XLSX file is empty or does not contain any worksheets.");
                    return;
                }

                var existingRooms = await _context.Rooms.ToDictionaryAsync(r => r.RoomName, r => r);

                for (int row = 2; row <= worksheet.Dimension.End.Row; row++)
                {
                    try
                    {
                        var roomName = worksheet.Cells[row, 1].Value?.ToString()?.Trim();
                        var capacityStr = worksheet.Cells[row, 2].Value?.ToString()?.Trim();
                        var statusStr = worksheet.Cells[row, 3].Value?.ToString()?.Trim();


                        if (string.IsNullOrWhiteSpace(roomName))
                        {
                            errors.Add($"Row {row}: RoomName is required.");
                            continue;
                        }

                        if (!int.TryParse(capacityStr, out int capacity))
                        {
                            errors.Add($"Row {row}: Invalid Capacity value '{capacityStr}'. It must be a number.");
                            continue;
                        }

                        if (!Enum.TryParse<RoomStatus>(statusStr, true, out RoomStatus status))
                        {
                            errors.Add($"Row {row}: Invalid Status value '{statusStr}'.");
                            continue;
                        }




                        if (existingRooms.TryGetValue(roomName, out var existingRoom))
                        {
                            // Check if an update is needed
                            if (existingRoom.Capacity != capacity || existingRoom.Status != status)
                            {
                                // Update only if values have changed
                                existingRoom.Capacity = capacity;
                                existingRoom.Status = status;
                                existingRoom.UpdatedAt = DateTime.UtcNow;
                                roomsToUpdate.Add(existingRoom); // Add to the update list
                            }
                        }
                        else
                        {
                            // Room is new, create a new object
                            roomsToCreate.Add(new Room
                            {
                                RoomName = roomName,
                                Capacity = capacity,
                                Status = status,
                                CreatedAt = DateTime.UtcNow,
                                UpdatedAt = DateTime.UtcNow
                            });
                        }
                    }
                    catch (Exception ex)
                    {
                        errors.Add($"Row {row}: An unexpected error occurred. Details: {ex.Message}");
                    }
                }
            }
        }
        private async Task ParseCsvStream(Stream stream, List<Room> roomsToCreate, List<Room> roomsToUpdate, List<string> errors)
        {
            using (var reader = new StreamReader(stream))
            using (var csv = new CsvReader(reader, CultureInfo.InvariantCulture))
            {
                var existingRooms = await _context.Rooms.ToDictionaryAsync(r => r.RoomName, r => r);

                csv.Context.RegisterClassMap<RoomMap>();
                var records = csv.GetRecords<RoomBulkCreateDto>();
                int row = 2;

                foreach (var record in records)
                {
                    try
                    {
                        if (existingRooms.TryGetValue(record.RoomName, out var existingRoom))
                        {
                            // Check if an update is needed
                            if (existingRoom.Capacity != record.Capacity || existingRoom.Status != record.Status)
                            {
                                // Update only if values have changed
                                existingRoom.Capacity = record.Capacity;
                                existingRoom.Status = record.Status;
                                existingRoom.UpdatedAt = DateTime.UtcNow;
                                roomsToUpdate.Add(existingRoom); // Add to the update list
                            }
                        }
                        else
                        {
                            // Room is new, create it
                            roomsToCreate.Add(new Room
                            {
                                RoomName = record.RoomName,
                                Capacity = record.Capacity,
                                Status = record.Status,
                                CreatedAt = DateTime.UtcNow,
                                UpdatedAt = DateTime.UtcNow
                            });
                        }
                    }
                    catch (Exception ex)
                    {
                        errors.Add($"Row {row}: An unexpected error occurred. Details: {ex.Message}");
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

    }
}
