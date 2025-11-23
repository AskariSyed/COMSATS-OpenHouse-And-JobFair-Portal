using global::JobFairPortal.Data;
using JobFairPortal.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

namespace JobFairPortal.Controllers
{
    [ApiController]
    [Route("api/admin/[controller]")]
    //[Authorize(Roles = "Admin")]
    public class SurveyController : ControllerBase
    {
        private readonly JobFairRecruitmentDbContext _context;

        public SurveyController(JobFairRecruitmentDbContext context)
        {
            _context = context;
        }

        public class CompanyFilter
        {
            public int? CompanyId { get; set; }
            public string? CompanyName { get; set; }
        }

        // POST: api/admin/survey/pending
        [HttpPost("pending")]
        public async Task<IActionResult> GetCompaniesWithPendingSurveys([FromBody] CompanyFilter filter)
        {
            var query = _context.Companies
                .Include(c => c.Surveys)
                .AsQueryable();

            // Apply filters
            if (filter.CompanyId.HasValue)
                query = query.Where(c => c.CompanyId == filter.CompanyId.Value);

            if (!string.IsNullOrWhiteSpace(filter.CompanyName))
                query = query.Where(c => c.Name.Contains(filter.CompanyName));

            var companies = await query
                .Select(c => new
                {
                    c.CompanyId,
                    c.Name,
                    HasCDC = c.Surveys.Any(s => s.Type == SurveyType.CDC),
                    HasDepartment = c.Surveys.Any(s => s.Type == SurveyType.Department)
                })
                .ToListAsync();

            // Handle invalid filters
            if (filter.CompanyId.HasValue && !companies.Any())
                return NotFound(new { Message = $"No company found with ID {filter.CompanyId}" });

            if (!string.IsNullOrWhiteSpace(filter.CompanyName) && !companies.Any())
                return NotFound(new { Message = $"No company found with name containing '{filter.CompanyName}'" });

            var pendingCompanies = companies
                .Where(c => !c.HasCDC || !c.HasDepartment)
                .Select(c => new
                {
                    c.CompanyId,
                    c.Name,
                    PendingCDC = !c.HasCDC,
                    PendingDepartment = !c.HasDepartment
                })
                .ToList();

            if (!pendingCompanies.Any())
            {
                return Ok(new
                {
                    Message = "All companies have submitted both CDC and Department surveys."
                });
            }

            return Ok(pendingCompanies);
        }

        // GET: api/admin/survey/all-companies
        [HttpGet("all-companies")]
        public async Task<IActionResult> GetAllCompaniesWithSurveys()
        {
            var companiesWithSurveys = await _context.Companies
                .Include(c => c.Surveys)
                .Select(c => new
                {
                    c.CompanyId,
                    c.Name,
                    Surveys = c.Surveys.Select(s => new
                    {
                        s.SurveyId,
                        Type = s.Type.ToString(),
                        s.SubmittedAt,
                        // UPDATED: Uses the specific Deserializer logic
                        Responses = DeserializeResponses(s.Responses)
                    }).ToList()
                })
                .ToListAsync();

            if (!companiesWithSurveys.Any())
            {
                return Ok(new
                {
                    Message = "No companies or surveys available."
                });
            }

            return Ok(companiesWithSurveys);
        }

        // GET: api/admin/survey/no-surveys
        [HttpGet("no-surveys")]
        public async Task<IActionResult> GetCompaniesWithNoSurveys()
        {
            var companies = await _context.Companies
                .Include(c => c.Surveys)
                .ToListAsync();

            if (!companies.Any())
            {
                return Ok(new
                {
                    Message = "No companies have been registered yet."
                });
            }

            var noSurveyCompanies = companies
                .Select(c => new
                {
                    c.CompanyId,
                    c.Name,
                    HasCDC = c.Surveys.Any(s => s.Type == SurveyType.CDC),
                    HasDepartment = c.Surveys.Any(s => s.Type == SurveyType.Department)
                })
                .Where(c => !c.HasCDC || !c.HasDepartment)
                .Select(c => new
                {
                    c.CompanyId,
                    c.Name,
                    PendingCDC = !c.HasCDC,
                    PendingDepartment = !c.HasDepartment
                })
                .ToList();

            if (!noSurveyCompanies.Any())
            {
                return Ok(new
                {
                    Message = "All companies have submitted both CDC and Department surveys."
                });
            }

            return Ok(noSurveyCompanies);
        }

        #region Helper
        // UPDATED: Tries to deserialize into your specific SurveyResponseData class
        private static object? DeserializeResponses(string? responses)
        {
            if (string.IsNullOrEmpty(responses))
                return null;

            try
            {
                // Try to deserialize into the specific SurveyResponseData structure
                return JsonSerializer.Deserialize<SurveyResponseData>(responses, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });
            }
            catch
            {
                try
                {
                    // Fallback to generic object if structure doesn't match
                    return JsonSerializer.Deserialize<object>(responses);
                }
                catch
                {
                    return responses; // Final fallback to raw string
                }
            }
        }
        #endregion
    }
}