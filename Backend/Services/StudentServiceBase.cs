using JobFairPortal.Data;
using JobFairPortal.Models;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace JobFairPortal.Services
{
    public abstract class StudentServiceBase
    {
        protected int GetCurrentUserId(ClaimsPrincipal user)
        {
            var userIdClaim = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
                throw new UnauthorizedAccessException("Invalid or missing user ID in token.");

            return userId;
        }

        protected Task<Student?> GetCurrentStudent(
            JobFairRecruitmentDbContext context,
            ClaimsPrincipal user)
        {
            var userId = GetCurrentUserId(user);
            return context.Students.FirstOrDefaultAsync(s => s.UserId == userId);
        }
    }
}