using FirebaseAdmin.Messaging;
using JobFairPortal.Data;
using JobFairPortal.DTOs;
using JobFairPortal.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace JobFairPortal.Controllers.Admin
{
    [ApiController]
    [Route("api/admin/[controller]")]
    [Authorize(Roles = "Admin")]
    public class CompanyRequestsController : ControllerBase
    {
        private readonly JobFairRecruitmentDbContext _context;
        private readonly Microsoft.AspNetCore.SignalR.IHubContext<JobFairPortal.Hubs.CompanyRequestsHub> _hub;

        public CompanyRequestsController(JobFairRecruitmentDbContext context, Microsoft.AspNetCore.SignalR.IHubContext<JobFairPortal.Hubs.CompanyRequestsHub> hub)
        {
            _context = context;
            _hub = hub;
        }

        // GET: api/admin/companyrequests
        // Optional filters: status (string like "Pending"), jobFairId, companyId
        [HttpGet("")]
        public async Task<IActionResult> List([FromQuery] string? status = null, [FromQuery] int? jobFairId = null, [FromQuery] int? companyId = null)
        {
            var q = _context.CompanyRequests.Include(r => r.Company).AsQueryable();

            // Parse status from string if provided
            if (!string.IsNullOrWhiteSpace(status) && Enum.TryParse<CompanyRequestStatus>(status, out var statusEnum))
                q = q.Where(r => r.Status == statusEnum);
            if (jobFairId.HasValue) q = q.Where(r => r.JobFairId == jobFairId.Value);
            if (companyId.HasValue) q = q.Where(r => r.CompanyId == companyId.Value);

            var list = await q.OrderByDescending(r => r.CreatedAt)
                .Select(r => new
                {
                    r.CompanyRequestId,
                    r.CompanyId,
                    CompanyName = r.Company != null ? r.Company.Name : "Unknown",
                    r.JobFairId,
                    Type = r.Type.ToString(),
                    r.Description,
                    r.Quantity,
                    r.AdditionalInfo,
                    Status = r.Status.ToString(),
                    r.AdminNote,
                    r.CreatedAt,
                    r.UpdatedAt,
                    r.FulfilledAt
                }).ToListAsync();

            return Ok(list);
        }

        // PUT: api/admin/companyrequests/{id}/status
        [HttpPut("{id}/status")]
        public async Task<IActionResult> UpdateStatus(int id, [FromBody] AdminCompanyRequestUpdateDto dto)
        {
            var req = await _context.CompanyRequests.Include(r => r.Company).FirstOrDefaultAsync(r => r.CompanyRequestId == id);
            if (req == null) return NotFound("Request not found.");

            // Parse status from string
            if (!Enum.TryParse<CompanyRequestStatus>(dto.Status, out var newStatus))
                return BadRequest($"Invalid status value: {dto.Status}");

            req.Status = newStatus;
            req.AdminNote = dto.AdminNote;
            req.UpdatedAt = DateTime.UtcNow;
            if (newStatus == CompanyRequestStatus.Fulfilled) req.FulfilledAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            // Broadcast update to connected admin clients
            try
            {
                var payload = new
                {
                    req.CompanyRequestId,
                    req.CompanyId,
                    CompanyName = req.Company?.Name,
                    req.JobFairId,
                    Type = req.Type.ToString(),
                    req.Description,
                    req.Quantity,
                    req.AdditionalInfo,
                    Status = req.Status.ToString(),
                    req.AdminNote,
                    req.CreatedAt,
                    req.UpdatedAt,
                    req.FulfilledAt
                };

                await _hub.Clients.All.SendAsync("CompanyRequestUpdated", payload);
            }
            catch
            {
                // ignore hub failures
            }

            // Notify company via FCM if token available
            try
            {
                var token = req.Company.FcmToken;
                if (!string.IsNullOrWhiteSpace(token))
                {
                    var title = dto.Status.Equals(CompanyRequestStatus.Fulfilled) ? "Request Fulfilled" : $"Request {dto.Status}";
                    var body = dto.Status.Equals(CompanyRequestStatus.Fulfilled)
                        ? $"Your request (#{req.CompanyRequestId}) has been fulfilled."
                        : $"Your request (#{req.CompanyRequestId}) status changed to {dto.Status}. Note: {dto.AdminNote ?? "—"}";

                    var message = new Message
                    {
                        Token = token,
                        Notification = new FirebaseAdmin.Messaging.Notification
                        {
                            Title = title,
                            Body = body
                        },
                        Data = new Dictionary<string, string>
                        {
                            { "RequestId", req.CompanyRequestId.ToString() },
                            { "Status", req.Status.ToString() },
                            { "Type", "CompanyRequestStatus" }
                        }
                    };

                    await FirebaseMessaging.DefaultInstance.SendAsync(message);
                }
            }
            catch
            {
                // Do not surface notification failures to admin action; log if you have logger
            }

            return Ok(new { Message = "Status updated.", req.CompanyRequestId, Status = req.Status.ToString() });
        }
    }
}