using JobFairPortal.Data;
using JobFairPortal.Models;
using JobFairPortal.DTOs;
using JobFairPortal.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace JobFairPortal.Controllers
{ 
    [ApiController]
    [Route("api/[controller]")]
    public class AttendanceController : ControllerBase
    {
        private readonly JobFairRecruitmentDbContext _context;
        private readonly ILogger<AttendanceController> _logger;
        private readonly MailKitMailService _mailService;

        public AttendanceController(JobFairRecruitmentDbContext context, ILogger<AttendanceController> logger, MailKitMailService mailService)
        {
            _context = context;
            _logger = logger;
            _mailService = mailService;
        }

        // GET /attendance/scan?token=...
        // Returns a small HTML page (camera + QR scanning) that posts the scanned token to /attendance/mark.
        // Note: the page uses the browser BarcodeDetector API when available; otherwise instruct user to copy token.
        [HttpGet("scan")]
        public IActionResult ScanPage([FromQuery] string token)
        {
            // Encode token for safe inlining into JS
            var encodedToken = System.Text.Encodings.Web.JavaScriptEncoder.Default.Encode(token ?? "");

            // Use a non-interpolated raw string literal and a small placeholder to avoid C# interpolation/braces issues.
            var html = """
                <!doctype html>
                <html>
                <head>
                  <meta charset="utf-8"/>
                  <title>Mark Attendance</title>
                  <meta name="viewport" content="width=device-width,initial-scale=1"/>
                  <style>body{font-family:Segoe UI,Arial;margin:0;padding:1rem}#video{width:100%;max-width:720px}button{padding:.5rem 1rem}</style>
                </head>
                <body>
                  <h2>Mark Physical Attendance</h2>
                  <p>Point your camera at the QR code provided at the registration desk.</p>
                  <video id="video" autoplay playsinline></video>
                  <p id="status">Initializing camera...</p>
                  <script>
                    const tokenFromQuery = '___TOKEN___';

                    async function mark(token) {
                      try {
                        const resp = await fetch('/attendance/mark', {
                          method: 'POST',
                          headers: { 'Content-Type': 'application/json' },
                          body: JSON.stringify({ token })
                        });
                        const json = await resp.json();
                        if (resp.ok) {
                          document.getElementById('status').innerText = 'Attendance marked: ' + (json.message ?? 'OK');
                        } else {
                          document.getElementById('status').innerText = 'Failed: ' + (json.error ?? JSON.stringify(json));
                        }
                      } catch (e) {
                        document.getElementById('status').innerText = 'Error: ' + e.message;
                      }
                    }

                    // If token provided in URL, allow user to submit it directly
                    if (tokenFromQuery) {
                      document.getElementById('status').innerText = 'Token provided in link. Tap to mark.';
                      const btn = document.createElement('button');
                      btn.innerText = 'Mark Attendance';
                      btn.onclick = () => mark(tokenFromQuery);
                      document.body.appendChild(btn);
                    }

                    // Try BarcodeDetector (modern browsers)
                    if ('BarcodeDetector' in window) {
                      const formats = ['qr_code'];
                      const detector = new BarcodeDetector({ formats });
                      const video = document.getElementById('video');
                      navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } }).then(stream => {
                        video.srcObject = stream;
                        const tick = async () => {
                          try {
                            const barcodes = await detector.detect(video);
                            if (barcodes && barcodes.length) {
                              const value = barcodes[0].rawValue;
                              document.getElementById('status').innerText = 'QR detected: ' + value;
                              // stop stream
                              stream.getTracks().forEach(t => t.stop());
                              // post the decoded token/value to mark endpoint
                              await mark(value);
                              return;
                            }
                          } catch (err) {
                            console.error(err);
                          }
                          requestAnimationFrame(tick);
                        };
                        tick();
                      }).catch(err => {
                        document.getElementById('status').innerText = 'Camera access denied or not available: ' + err.message;
                      });
                    } else {
                      // Fallback: ask user to paste the token contained in QR
                      const note = document.createElement('p');
                      note.innerText = 'Your browser does not support camera QR decoding. You may paste the token from the QR into the box below.';
                      document.body.appendChild(note);
                      const input = document.createElement('input');
                      input.type = 'text';
                      input.placeholder = 'Paste token from QR here';
                      document.body.appendChild(input);
                      const btn = document.createElement('button');
                      btn.innerText = 'Mark Attendance';
                      btn.onclick = () => mark(input.value);
                      document.body.appendChild(btn);
                    }
                  </script>
                </body>
                </html>
                """;

            // Replace placeholder with the encoded token
            html = html.Replace("___TOKEN___", encodedToken);

            return Content(html, "text/html");
        }

        // POST /attendance/mark
        // Company endpoint to mark attendance using session QR code
        // Body: { "sessionToken": "..." } - The company is identified by JWT token
        [HttpPost("mark")]
        [Authorize(Roles = "Company")]
        public async Task<IActionResult> MarkAttendance([FromBody] MarkAttendanceRequest? payload)
        {
            try
            {
                if (payload == null)
                    return BadRequest(new { error = "Invalid request body" });

                var sessionToken = payload.SessionToken;

                if (string.IsNullOrWhiteSpace(sessionToken))
                    return BadRequest(new { error = "sessionToken is required" });

                var now = DateTime.UtcNow;

                // Validate admin session exists and is active
                var session = await _context.AdminAttendanceSessions
                    .AsNoTracking()
                    .FirstOrDefaultAsync(s => s.SessionToken == sessionToken && s.IsActive);

                if (session == null)
                    return BadRequest(new { error = "Invalid or inactive session" });

                if (session.ExpiresAt < now)
                    return BadRequest(new { error = "Session has expired" });

                var activeJobFair = await _context.JobFairs
                    .AsNoTracking()
                    .FirstOrDefaultAsync(j => j.IsActive);

                if (activeJobFair == null)
                    return BadRequest(new { error = "No active Job Fair found" });

                if (session.JobFairId != activeJobFair.JobFairId)
                    return BadRequest(new { error = "This QR session is not for the active Job Fair" });

                // Resolve company from JWT user id
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrWhiteSpace(userIdClaim) || !int.TryParse(userIdClaim, out var userId))
                    return Unauthorized(new { error = "Invalid authentication token" });

                var company = await _context.Companies
                    .AsNoTracking()
                    .FirstOrDefaultAsync(c => c.UserId == userId);

                if (company == null)
                    return NotFound(new { error = "Company not found for current user" });

                // Find participation for this company in this job fair
                var participation = await _context.CompanyJobFairParticipations
                    .Include(p => p.Company)
                        .ThenInclude(c => c.Room)
                    .Include(p => p.Company)
                        .ThenInclude(c => c.User)
                    .Include(p => p.JobFair)
                    .Include(p => p.Room)
                    .FirstOrDefaultAsync(p => p.CompanyId == company.CompanyId && p.JobFairId == session.JobFairId);

                if (participation == null)
                    return NotFound(new { error = "Company is not registered for this Job Fair" });

                // Date check: allow marking only on job fair day
                if (participation.JobFair != null)
                {
                    var jfDate = participation.JobFair.date.Date;
                    if (jfDate != now.Date)
                        return BadRequest(new { error = "Attendance can only be marked on the Job Fair date" });
                }

                if (participation.IsPresent)
                {
                    var alreadyRoom = participation.Room ?? participation.Company?.Room;
                    var alreadyHasCurrentFairRoom = alreadyRoom != null && alreadyRoom.JobFairId == session.JobFairId;
                    return Ok(new
                    {
                        message = alreadyHasCurrentFairRoom
                            ? "Attendance already marked"
                            : "Attendance already marked, but no room is allotted for this job fair. Please ask administration for manual room allotment.",
                        companyId = company.CompanyId,
                        companyName = participation.Company?.Name,
                        roomName = alreadyHasCurrentFairRoom ? alreadyRoom?.RoomName : null,
                        roomCapacity = alreadyHasCurrentFairRoom ? alreadyRoom?.Capacity : null,
                        needsManualRoomAllotment = !alreadyHasCurrentFairRoom
                    });
                }

                // Mark attendance
                participation.IsPresent = true;
                participation.ArrivalStatus = ArrivalStatus.OnSpot;
                participation.UpdatedAt = DateTime.UtcNow;

                Room? effectiveRoom = participation.Room ?? participation.Company?.Room;
                var hasRoomForCurrentFair = effectiveRoom != null && effectiveRoom.JobFairId == session.JobFairId;

                // If no room assigned for this job fair, allocate greedily (smallest suitable capacity)
                if (!hasRoomForCurrentFair)
                {
                    effectiveRoom = null;

                    // Release any old room linked to this company (from previous fair or stale assignment)
                    var oldRoom = participation.Company?.Room;
                    if (oldRoom != null && oldRoom.JobFairId != session.JobFairId)
                    {
                        oldRoom.CompanyId = null;
                        oldRoom.Status = RoomStatus.Vacant;
                        oldRoom.UpdatedAt = DateTime.UtcNow;
                    }

                    var requiredCapacity = participation.RepsCount > 0
                        ? participation.RepsCount
                        : (participation.Company?.RepsCount ?? 1);

                    var allocatedRoom = await _context.Rooms
                        .Where(r => r.JobFairId == session.JobFairId && r.Status == RoomStatus.Vacant && r.Capacity >= requiredCapacity)
                        .OrderBy(r => r.Capacity)
                        .FirstOrDefaultAsync();

                    if (allocatedRoom != null)
                    {
                        allocatedRoom.CompanyId = company.CompanyId;
                        allocatedRoom.Status = RoomStatus.Alloted;
                        allocatedRoom.UpdatedAt = DateTime.UtcNow;

                        participation.RoomId = allocatedRoom.RoomId;
                        participation.UpdatedAt = DateTime.UtcNow;
                        effectiveRoom = allocatedRoom;

                        if (!string.IsNullOrWhiteSpace(participation.Company?.User?.Email))
                        {
                            await SendRoomAllocatedOnArrivalEmailAsync(
                                participation.Company.User.Email,
                                participation.Company.Name,
                                allocatedRoom.RoomName,
                                allocatedRoom.Capacity,
                                participation.JobFair?.Semester,
                                participation.JobFair?.date);
                        }
                    }
                }

                if (participation.Company != null)
                {
                    participation.Company.IsPresent = true;
                    participation.Company.CurrentJobFairId = session.JobFairId;
                    participation.Company.UpdatedAt = DateTime.UtcNow;
                }

                // Invalidate old attendance token if exists
                participation.AttendanceToken = null;
                participation.AttendanceTokenExpiry = null;

                await _context.SaveChangesAsync();

                var needsManualRoomAllotment = effectiveRoom == null || effectiveRoom.JobFairId != session.JobFairId;

                return Ok(new
                {
                    message = needsManualRoomAllotment
                        ? "Attendance marked successfully. No suitable room is currently available; please ask administration for manual room allotment."
                        : "Attendance marked successfully. Room allotted.",
                    companyId = company.CompanyId,
                    companyName = participation.Company?.Name,
                    roomName = effectiveRoom?.RoomName,
                    roomCapacity = effectiveRoom?.Capacity,
                    needsManualRoomAllotment
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error marking attendance");
                return StatusCode(500, new { error = "Internal server error" });
            }
        }

        private async Task SendRoomAllocatedOnArrivalEmailAsync(string email, string companyName, string roomName, int capacity, string? semester, DateTime? jobFairDate)
        {
            try
            {
                var subject = $"Room Allotted - {semester ?? "Job Fair"}";
                var body = $"""
                Dear {companyName},

                Your attendance has been marked and room has been allotted.

                Room Details:
                - Room Name: {roomName}
                - Capacity: {capacity}
                - Job Fair: {semester ?? "Current"}
                - Date: {(jobFairDate.HasValue ? jobFairDate.Value.ToString("MMMM dd, yyyy") : "N/A")}

                Please proceed to your allotted room.

                Regards,
                Job Fair Management Team
                """;

                await _mailService.SendMailAsync(email, subject, body);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to send room-allotted email to {Email}", email);
            }
        }

        // POST /attendance/generate-daily-qr
        // Admin endpoint to generate (or reuse) one static QR token for the current Job Fair day.
        [HttpPost("generate-daily-qr")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> GenerateDailyQr([FromBody] StartSessionRequest? payload)
        {
            try
            {
                if (payload == null)
                    return BadRequest(new { error = "Invalid request body" });

                var jobFairId = payload.JobFairId;
                if (jobFairId <= 0)
                    return BadRequest(new { error = "Invalid jobFairId; expected positive integer id" });

                var jobFair = await _context.JobFairs
                    .AsNoTracking()
                    .FirstOrDefaultAsync(jf => jf.JobFairId == jobFairId);

                if (jobFair == null)
                    return NotFound(new { error = "Job Fair not found" });

                var todayDate = DateTime.UtcNow.Date;
                var jobFairDate = jobFair.date.Date;
                if (todayDate != jobFairDate)
                    return BadRequest(new { error = "Daily QR can only be generated on the Job Fair date." });

                var existingSession = await _context.AdminAttendanceSessions
                    .FirstOrDefaultAsync(s => s.JobFairId == jobFairId && s.IsActive && s.ExpiresAt >= DateTime.UtcNow);

                if (existingSession != null)
                {
                    return Ok(new
                    {
                        sessionToken = existingSession.SessionToken,
                        jobFairId = jobFairId,
                        expiresAt = existingSession.ExpiresAt,
                        message = "Daily QR already generated for today"
                    });
                }

                var sessionToken = Guid.NewGuid().ToString();
                var expiresAt = DateTime.UtcNow.Date.AddDays(1).AddSeconds(-1);

                var adminSession = new AdminAttendanceSession
                {
                    JobFairId = jobFairId,
                    SessionToken = sessionToken,
                    IsActive = true,
                    ExpiresAt = expiresAt,
                    CreatedAt = DateTime.UtcNow
                };

                _context.AdminAttendanceSessions.Add(adminSession);
                await _context.SaveChangesAsync();

                return Ok(new
                {
                    sessionToken,
                    jobFairId,
                    expiresAt,
                    message = "Daily attendance QR generated"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating daily QR");
                return StatusCode(500, new { error = "Internal server error" });
            }
        }

        // POST /attendance/generate-token
        // DEPRECATED: Use start-session instead for dynamic QR codes
        [HttpPost("generate-token")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> GenerateAttendanceToken([FromBody] dynamic payload)
        {
            try
            {
                if (payload == null)
                    return BadRequest(new { error = "Invalid request body" });

                string jobFairIdStr = Convert.ToString(payload.jobFairId);
                string companyIdStr = Convert.ToString(payload.companyId);

                if (!int.TryParse(jobFairIdStr, out var jobFairId) || !int.TryParse(companyIdStr, out var companyId))
                    return BadRequest(new { error = "Invalid jobFairId or companyId format; expected integer ids" });

                // Verify job fair exists
                var jobFair = await _context.JobFairs
                    .AsNoTracking()
                    .FirstOrDefaultAsync(jf => jf.JobFairId == jobFairId);

                if (jobFair == null)
                    return NotFound(new { error = "Job Fair not found" });

                // Get or create company-jobfair participation
                var participation = await _context.CompanyJobFairParticipations
                    .Include(p => p.Company)
                    .FirstOrDefaultAsync(p => p.CompanyId == companyId && p.JobFairId == jobFairId);

                if (participation == null)
                    return NotFound(new { error = "Company is not registered for this Job Fair" });

                // Generate a new attendance token (UUID)
                var token = Guid.NewGuid().ToString();
                var expiresAt = DateTime.UtcNow.AddHours(8); // Token valid for 8 hours

                participation.AttendanceToken = token;
                participation.AttendanceTokenExpiry = expiresAt;
                participation.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                return Ok(new
                {
                    token = token,
                    expiresAt = expiresAt,
                    companyId = companyId,
                    companyName = participation.Company?.Name
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating attendance token");
                return StatusCode(500, new { error = "Internal server error" });
            }
        }

        // POST /attendance/start-session
        // Admin endpoint to start a dynamic attendance session for a job fair
        // This creates a single session QR code that all companies scan
        // Body: { "jobFairId": "..." }
        // Replace the StartAttendanceSession and GetAttendanceStats methods with these fixed versions.

        [HttpPost("start-session")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> StartAttendanceSession([FromBody] StartSessionRequest? payload)
        {
            try
            {
                if (payload == null)
                    return BadRequest(new { error = "Invalid request body" });

                var jobFairId = payload.JobFairId;

                if (jobFairId <= 0)
                    return BadRequest(new { error = "Invalid jobFairId; expected positive integer id" });

                // Verify job fair exists
                var jobFair = await _context.JobFairs
                    .AsNoTracking()
                    .FirstOrDefaultAsync(jf => jf.JobFairId == jobFairId);

                if (jobFair == null)
                    return NotFound(new { error = "Job Fair not found" });

                // Check if today is the job fair date
                var todayDate = DateTime.UtcNow.Date;
                var jobFairDate = jobFair.date.Date;
                if (todayDate != jobFairDate)
                {
                    var daysUntil = (jobFairDate - todayDate).Days;
                    if (daysUntil > 0)
                        return BadRequest(new { error = $"Attendance session can only be started on the job fair date. Job fair is in {daysUntil} days." });
                    else
                        return BadRequest(new { error = $"Attendance session can only be started on the job fair date. Job fair was {Math.Abs(daysUntil)} days ago." });
                }

                // Check if there's already an active session
                var existingSession = await _context.AdminAttendanceSessions
                    .FirstOrDefaultAsync(s => s.JobFairId == jobFairId && s.IsActive);

                if (existingSession != null)
                {
                    // Return existing active session
                    return Ok(new
                    {
                        sessionToken = existingSession.SessionToken,
                        jobFairId = jobFairId,
                        expiresAt = existingSession.ExpiresAt,
                        message = "Active session already exists"
                    });
                }

                // Generate a new session token
                var sessionToken = Guid.NewGuid().ToString();
                var expiresAt = DateTime.UtcNow.AddHours(8); // Session valid for 8 hours

                // Create admin attendance session
                var adminSession = new AdminAttendanceSession
                {
                    // Do NOT set a property called 'id' � model uses AdminAttendanceSessionId (int) and EF will generate it.
                    JobFairId = jobFairId,
                    SessionToken = sessionToken,
                    IsActive = true,
                    ExpiresAt = expiresAt,
                    CreatedAt = DateTime.UtcNow
                };

                _context.AdminAttendanceSessions.Add(adminSession);
                await _context.SaveChangesAsync();

                return Ok(new
                {
                    sessionToken = sessionToken,
                    jobFairId = jobFairId,
                    expiresAt = expiresAt,
                    message = "Attendance session started"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error starting attendance session");
                return StatusCode(500, new { error = "Internal server error" });
            }
        }

        [HttpGet("stats/{jobFairId}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> GetAttendanceStats(int jobFairId)
        {
            try
            {
                var participations = await _context.CompanyJobFairParticipations
                    .Include(p => p.Company)
                    .Where(p => p.JobFairId == jobFairId)
                    .Select(p => new
                    {
                        id = p.CompanyId,
                        companyName = p.Company.Name,
                        isPresent = p.IsPresent,
                        markedAt = p.UpdatedAt
                    })
                    .ToListAsync();

                return Ok(participations);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting attendance stats");
                return StatusCode(500, new { error = "Internal server error" });
            }
        }  // POST /attendance/end-session

        [HttpPut("mark-absent")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> MarkCompanyAbsent([FromBody] MarkAbsentRequest? payload)
        {
            try
            {
                if (payload == null)
                    return BadRequest(new { error = "Invalid request body" });

                if (payload.JobFairId <= 0 || payload.CompanyId <= 0)
                    return BadRequest(new { error = "jobFairId and companyId must be positive integers" });

                var participation = await _context.CompanyJobFairParticipations
                    .Include(p => p.Company)
                    .FirstOrDefaultAsync(p => p.JobFairId == payload.JobFairId && p.CompanyId == payload.CompanyId);

                if (participation == null)
                    return NotFound(new { error = "Company participation not found for this job fair" });

                if (!participation.IsPresent)
                    return Ok(new
                    {
                        message = "Company is already marked absent",
                        companyId = payload.CompanyId,
                        jobFairId = payload.JobFairId
                    });

                participation.IsPresent = false;
                participation.ArrivalStatus = ArrivalStatus.Pending;
                participation.UpdatedAt = DateTime.UtcNow;

                if (participation.Company != null)
                {
                    participation.Company.IsPresent = false;
                    participation.Company.UpdatedAt = DateTime.UtcNow;
                }

                await _context.SaveChangesAsync();

                return Ok(new
                {
                    message = "Company marked absent successfully",
                    companyId = payload.CompanyId,
                    jobFairId = payload.JobFairId
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error marking company absent");
                return StatusCode(500, new { error = "Internal server error" });
            }
        }

        [HttpPut("mark-present")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> MarkCompanyPresent([FromBody] MarkPresentRequest? payload)
        {
            try
            {
                if (payload == null)
                    return BadRequest(new { error = "Invalid request body" });

                if (payload.JobFairId <= 0 || payload.CompanyId <= 0)
                    return BadRequest(new { error = "jobFairId and companyId must be positive integers" });

                var participation = await _context.CompanyJobFairParticipations
                    .Include(p => p.Company)
                    .FirstOrDefaultAsync(p => p.JobFairId == payload.JobFairId && p.CompanyId == payload.CompanyId);

                if (participation == null)
                    return NotFound(new { error = "Company participation not found for this job fair" });

                if (participation.IsPresent)
                    return Ok(new
                    {
                        message = "Company is already marked present",
                        companyId = payload.CompanyId,
                        jobFairId = payload.JobFairId
                    });

                participation.IsPresent = true;
                participation.ArrivalStatus = participation.ArrivalStatus == ArrivalStatus.PreRegistered
                    ? ArrivalStatus.PreRegistered
                    : ArrivalStatus.OnSpot;
                participation.UpdatedAt = DateTime.UtcNow;

                if (participation.Company != null)
                {
                    participation.Company.IsPresent = true;
                    participation.Company.UpdatedAt = DateTime.UtcNow;
                }

                await _context.SaveChangesAsync();

                return Ok(new
                {
                    message = "Company marked present successfully",
                    companyId = payload.CompanyId,
                    jobFairId = payload.JobFairId
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error marking company present");
                return StatusCode(500, new { error = "Internal server error" });
            }
        }

        // Admin endpoint to end a dynamic attendance session
        // Body: { "sessionToken": "..." }
        [HttpPost("end-session")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> EndAttendanceSession([FromBody] EndSessionRequest? payload)
        {
            try
            {
                if (payload == null)
                    return BadRequest(new { error = "Invalid request body" });

                var sessionToken = payload.SessionToken;

                if (string.IsNullOrWhiteSpace(sessionToken))
                    return BadRequest(new { error = "sessionToken is required" });

                var session = await _context.AdminAttendanceSessions
                    .FirstOrDefaultAsync(s => s.SessionToken == sessionToken && s.IsActive);

                if (session == null)
                    return NotFound(new { error = "Session not found or already inactive" });

                session.IsActive = false;

                await _context.SaveChangesAsync();

                return Ok(new { message = "Attendance session ended" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error ending attendance session");
                return StatusCode(500, new { error = "Internal server error" });
            }
        }

        // GET /attendance/stats/{jobFairId}
        // Get attendance statistics for a job fair
        // Shows which companies have marked attendance in current session
       
    }

    public class StartSessionRequest
    {
        public int JobFairId { get; set; }
    }

    public class EndSessionRequest
    {
        public string SessionToken { get; set; } = string.Empty;
    }

    public class MarkAttendanceRequest
    {
        public string SessionToken { get; set; } = string.Empty;
    }

    public class MarkAbsentRequest
    {
        public int JobFairId { get; set; }
        public int CompanyId { get; set; }
    }

    public class MarkPresentRequest
    {
        public int JobFairId { get; set; }
        public int CompanyId { get; set; }
    }
}