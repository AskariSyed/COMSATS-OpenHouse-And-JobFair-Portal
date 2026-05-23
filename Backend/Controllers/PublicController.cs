using JobFairPortal.Data;
using JobFairPortal.DTOs;
using JobFairPortal.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

using Microsoft.Extensions.Caching.Memory;

namespace JobFairPortal.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PublicController : ControllerBase
    {
        private readonly JobFairRecruitmentDbContext _context;
        private readonly IMemoryCache _cache;
        private const string NoticeBannerPrefix = "[BANNER] ";

        public PublicController(JobFairRecruitmentDbContext context, IMemoryCache cache)
        {
            _context = context;
            _cache = cache;
        }

        [HttpGet("notices")]
        [AllowAnonymous]
        public async Task<IActionResult> GetPublicNotices()
        {
            const string cacheKey = "PublicNoticesList";

            var notices = await _cache.GetOrCreateAsync(cacheKey, async entry =>
            {
                // Cache for 5 minutes
                entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5);

                var activeJobFair = await _context.JobFairs.FirstOrDefaultAsync(j => j.IsActive);
                if (activeJobFair == null)
                    return new List<NoticeResponseDto>();

                var rawNotices = await _context.Notices
                    .Where(n =>
                        n.JobFairId == activeJobFair.JobFairId &&
                        !n.IsHidden &&
                        (n.Audience == NoticeAudience.Public || n.Audience == NoticeAudience.All))
                    .OrderByDescending(n => n.CreatedAt)
                    .Select(n => new
                    {
                        NoticeId = n.NoticeId,
                        Title = n.Title,
                        Content = n.Content,
                        Audience = n.Audience.ToString(),
                        CreatedAt = n.CreatedAt
                    })
                    .ToListAsync();

                return rawNotices
                    .Select(n => new NoticeResponseDto
                    {
                        NoticeId = n.NoticeId,
                        Title = StripNoticeBannerPrefix(n.Title),
                        Content = n.Content,
                        Audience = n.Audience,
                        IsBanner = HasNoticeBannerPrefix(n.Title),
                        CreatedAt = n.CreatedAt
                    })
                    .ToList();
            });

            return Ok(notices);
        }

        private static bool HasNoticeBannerPrefix(string? value)
        {
            return !string.IsNullOrWhiteSpace(value) && value.StartsWith(NoticeBannerPrefix, StringComparison.OrdinalIgnoreCase);
        }

        private static string StripNoticeBannerPrefix(string? value)
        {
            if (string.IsNullOrWhiteSpace(value))
                return string.Empty;

            return HasNoticeBannerPrefix(value) ? value.Substring(NoticeBannerPrefix.Length).TrimStart() : value;
        }
    }
}
