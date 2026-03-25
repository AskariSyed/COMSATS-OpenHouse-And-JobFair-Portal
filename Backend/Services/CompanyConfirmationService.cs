using JobFairPortal.Data;
using JobFairPortal.DTOs;
using JobFairPortal.Models;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;
using static Org.BouncyCastle.Math.EC.ECCurve;

namespace JobFairPortal.Services
{
    public interface ICompanyConfirmationService
    {
        Task<RoomAllocationResponseDto> ConfirmCompanyAttendanceAsync(int companyId);
    }

    public class CompanyConfirmationService : ICompanyConfirmationService
    {
        private readonly JobFairRecruitmentDbContext _context;
        private readonly MailKitMailService _mailService;
        private readonly ILogger<CompanyConfirmationService> _logger;
        private readonly IParticipationService _participationService;

        public CompanyConfirmationService(
            JobFairRecruitmentDbContext context,
            MailKitMailService mailService,
            ILogger<CompanyConfirmationService> logger,
            IParticipationService participationService)
        {
            _context = context;
            _mailService = mailService;
            _logger = logger;
            _participationService = participationService;
        }

        /// <summary>
        /// Confirms company attendance for the active job fair and automatically allocates room
        /// Uses existing RepresentativeCount from database (RepsCount field)
        /// </summary>
        public async Task<RoomAllocationResponseDto> ConfirmCompanyAttendanceAsync(int companyId)
        {
            try
            {
                _logger.LogInformation("Starting company confirmation: CompanyId={CompanyId}", companyId);

                var company = await _context.Companies
                    .Include(c => c.User)
                    .Include(c => c.Room)
                    .FirstOrDefaultAsync(c => c.CompanyId == companyId);

                if (company == null)
                    throw new InvalidOperationException("Company not found.");

                if (company.RepsCount <= 0)
                    throw new InvalidOperationException(
                        "Company representative count is not set. Please update your company profile.");

                var activeJobFair = await _context.JobFairs
                    .AsNoTracking()
                    .FirstOrDefaultAsync(j => j.IsActive);

                if (activeJobFair == null)
                    throw new InvalidOperationException("No active Job Fair found.");

                _logger.LogInformation("Active job fair found: JobFairId={JobFairId}, Semester={Semester}",
                    activeJobFair.JobFairId, activeJobFair.Semester);

                // ? FIX: Get or create participation
                var participation = await _participationService.GetCompanyParticipationAsync(
                    companyId, activeJobFair.JobFairId);

                if (participation == null)
                {
                    participation = await _participationService.RegisterCompanyForJobFairAsync(
                        companyId, activeJobFair.JobFairId);
                }

                // ? FIX: Check if participation was created successfully
                if (participation == null)
                    throw new InvalidOperationException(
                        "Failed to register company for this job fair.");

                // ? FIX: Verify not already confirmed (using participation status)
                // Allow re-confirmation if status is Pending or OnSpot, but not if already PreRegistered
                _logger.LogInformation("Current participation status: {Status}", participation.ArrivalStatus);
                
                if (participation.ArrivalStatus == ArrivalStatus.PreRegistered)
                {
                    _logger.LogWarning("Company {CompanyId} already confirmed for JobFair {JobFairId}", 
                        companyId, activeJobFair.JobFairId);
                    throw new InvalidOperationException(
                        "Company has already confirmed attendance for this job fair.");
                }

                // Update participation status
                participation.ArrivalStatus = ArrivalStatus.PreRegistered;
                participation.RepsCount = company.RepsCount;
                participation.UpdatedAt = DateTime.UtcNow;

                var tokenBytes = RandomNumberGenerator.GetBytes(32);
                var token = Convert.ToBase64String(tokenBytes)
                    .TrimEnd('=')
                    .Replace('+', '-')
                    .Replace('/', '_');

                participation.AttendanceToken = token;
                // Set expiry to the end of jobfair day in UTC (you may adjust timezone if needed)
                var dayEnd = activeJobFair.date.Date.AddDays(1).AddTicks(-1); // end of day
                participation.AttendanceTokenExpiry = dayEnd;


                // Remove from old room
                if (company.Room != null)
                {
                    company.Room.CompanyId = null;
                    company.Room.Status = RoomStatus.Vacant;
                    company.Room.UpdatedAt = DateTime.UtcNow;
                }

                // Allocate new room
                Room? allocatedRoom = await AllocateOptimalRoomAsync(
                    companyId, 
                    activeJobFair.JobFairId, 
                    company.RepsCount);

                // ? FIX: Update participation's room reference if allocated
                if (allocatedRoom != null)
                {
                    participation.RoomId = allocatedRoom.RoomId;
                }

                // Update company's current job fair
                company.CurrentJobFairId = activeJobFair.JobFairId;
                company.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();
                // Build response
                var response = new RoomAllocationResponseDto
                {
                    CompanyId = companyId,
                    CompanyName = company.Name,
                    JobFairId = activeJobFair.JobFairId,
                    IsConfirmed = true,
                    RepresentativeCount = company.RepsCount,
                    RoomAllocated = allocatedRoom != null,
                    RoomId = allocatedRoom?.RoomId,
                    RoomName = allocatedRoom?.RoomName,
                    RoomCapacity = allocatedRoom?.Capacity,
                    AllocationStatus = allocatedRoom != null ? "Tentatively Alloted" : "Pending Physical Arrival",
                    ConfirmedAt = DateTime.UtcNow
                };

                // Send emails
                if (allocatedRoom != null)
                {
                    await SendRoomAllocationEmailAsync(company.User.Email, company.Name, allocatedRoom.RoomName, allocatedRoom.Capacity, activeJobFair);
                    response.Message = $"Room {allocatedRoom.RoomName} allocated successfully.";
                }
                else
                {
                    await SendPendingRoomAllocationEmailAsync(company.User.Email, company.Name, company.RepsCount, activeJobFair);
                    response.Message = "Room pending. Please check your company portal for updates.";
                }

                _logger.LogInformation(
                    "Company confirmation completed: CompanyId={CompanyId}, RoomAllocated={RoomAllocated}",
                    companyId, allocatedRoom != null);

                return response;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error confirming company attendance: CompanyId={CompanyId}", companyId);
                throw;
            }
        }

        /// <summary>
        /// Allocates the optimal room based on representative count
        /// Uses best-fit algorithm: smallest room that fits the representatives
        /// </summary>
        private async Task<Room?> AllocateOptimalRoomAsync(int companyId, int jobFairId, int representativeCount)
        {
            try
            {
                _logger.LogInformation(
                    "Finding optimal room: CompanyId={CompanyId}, RepsCount={RepsCount}, JobFairId={JobFairId}",
                    companyId, representativeCount, jobFairId);

                // Get all vacant rooms for this job fair, ordered by capacity (ascending)
                // This ensures we pick the smallest room that fits the representatives
                var availableRoom = await _context.Rooms
                    .Where(r => r.JobFairId == jobFairId &&
                               r.Status == RoomStatus.Vacant &&
                               r.Capacity >= representativeCount) // Room must accommodate reps
                    .OrderBy(r => r.Capacity) // Best-fit: pick smallest suitable room
                    .FirstOrDefaultAsync();

                if (availableRoom == null)
                {
                    _logger.LogWarning(
                        "No suitable vacant room found: CompanyId={CompanyId}, RepsCount={RepsCount}, JobFairId={JobFairId}",
                        companyId, representativeCount, jobFairId);
                    return null;
                }

                // Allocate the room
                availableRoom.CompanyId = companyId;
                availableRoom.Status = RoomStatus.TentativelyAlloted;
                availableRoom.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                _logger.LogInformation(
                    "Room allocated successfully: CompanyId={CompanyId}, RoomId={RoomId}, RoomName={RoomName}, Capacity={Capacity}",
                    companyId, availableRoom.RoomId, availableRoom.RoomName, availableRoom.Capacity);

                return availableRoom;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error allocating room for CompanyId={CompanyId}", companyId);
                return null;
            }
        }

        /// <summary>
        /// Sends welcome email when room is allocated
        /// </summary>
        private async Task SendRoomAllocationEmailAsync(string email, string companyName, string roomName, int capacity, JobFair jobFair)
        {
            try
            {
                var subject = $"Room Allocated - {jobFair.Semester} Job Fair";
                var body = $"""
                Dear {companyName},

                Your room has been allocated:
                - Room Name: {roomName}
                - Capacity: {capacity}
                - Job Fair: {jobFair.Semester}
                - Date: {jobFair.date:MMMM dd, yyyy}

                Best regards,
                Job Fair Management Team
                """;

                await _mailService.SendMailAsync(email, subject, body);
                _logger.LogInformation("Room allocation email sent to: {Email}", email);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send room allocation email to: {Email}", email);
            }
        }


        /// <summary>
        /// Sends email when no room is available at confirmation time
        /// </summary>
        private async Task SendPendingRoomAllocationEmailAsync(string email, string companyName, int representativeCount, JobFair jobFair)
        {
            try
            {
                var subject = $"Confirmation Received - {jobFair.Semester} Job Fair";
                var body = $"""
                Dear {companyName},

                Thank you for confirming. We will allocate a room on arrival.

                Best regards,
                Job Fair Management Team
                """;

                await _mailService.SendMailAsync(email, subject, body);
                _logger.LogInformation("Pending room allocation email sent to: {Email}", email);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send pending room allocation email to: {Email}", email);
            }
        }
    }
}