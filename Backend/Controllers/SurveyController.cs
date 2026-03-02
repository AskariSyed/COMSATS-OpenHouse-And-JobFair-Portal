using global::JobFairPortal.Data;
using JobFairPortal.DTOs;
using JobFairPortal.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using System.Text.Json;

namespace JobFairPortal.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
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

        // DTO used for survey submissions
        public class SurveySubmissionDto
        {
            
            public SurveyType Type { get; set; }
            public int CompanyId { get; set; }
            public int JobFairId { get; set; } 
            public SurveyResponseData? ResponseData { get; set; }
        }

        [HttpGet("template/{type}")]
        public IActionResult GetSurveyTemplate([FromRoute] SurveyType type)
        {
            if (type == SurveyType.Department)
            {
                return Ok(new
                {
                    Type = "Department",
                    LikertScale = new[] { "Exceptionally", "ToAGreatExtent", "Moderately", "Somewhat", "NotAtAll" },
                    PEOs = new
                    {
                        PEO1 = new[]
                        {
                            "Q1: Students Possess adequate technical knowledge to successfully perform in the professional computing environment.",
                            "Q2: Students Have the ability to analyze / investigate the computing problems.",
                            "Q3: Students Have the ability to design and implement solutions to complex computing problems."
                        },
                        PEO2 = new[]
                        {
                            "Q1: Students Have the desire to learn and adapt to new technology trends.",
                            "Q2: Students Are prepared to share and utilize the acquired knowledge to promote entrepreneurship in the society."
                        },
                        PEO3 = new[]
                        {
                            "Q1: Students Have awareness about ethical and moral concerns pertinent to the computing domain.",
                            "Q2: Students Have effective oral and written communication skills."
                        },
                        PEO4 = new[]
                        {
                            "Q1: Students Are educated and trained well to contribute to society in general.",
                            "Q2: Students Are trained to utilize their knowledge and skills for economic growth of the country.",
                            "Q3: Students Have the ability to capitalize the knowledge to support innovation."
                        }
                    },
                    OpenEnded = new[]
                    {
                        "Technologies/Skills Suggestion: What additional technologies / programming languages / skills you think are currently in demand and should be taught to our computing students at CUI, Islamabad?",
                        "General Feedback: Please feel free to give your input / feedback about the CUI graduates in terms of their professional attributes (specific strengths and weaknesses) that may be connected to their education before joining your organization.",
                        "Improvement Suggestions: Any comments or suggestions that you may have in the future to help us improve the quality of our educational program objectives and the graduates."
                    }
                });
            }

            // CDC survey template (original questions)
            return Ok(new
            {
                Type = "CDC",
                Questions = new[]
                {
                    "FYP Quality (Good / Average / Bad) and optional comments",
                    "Arrangement Quality (Good / Average / Bad) and optional comments",
                    "Lunch Quality (Good / Average / Bad) and optional comments"
                }
            });
        }

        [HttpGet("my-status")]
        [Authorize(Roles = "Company")]
        public async Task<IActionResult> GetMySurveyStatus()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
                return Unauthorized("Invalid or missing user id in token.");

            var company = await _context.Companies.AsNoTracking().FirstOrDefaultAsync(c => c.UserId == userId);
            if (company == null)
                return NotFound("Company not found for current token.");

            var activeJobFair = await _context.JobFairs.AsNoTracking().FirstOrDefaultAsync(j => j.IsActive);
            if (activeJobFair == null)
            {
                return Ok(new
                {
                    CompanyId = company.CompanyId,
                    HasActiveJobFair = false,
                    Submitted = new { Cdc = false, Department = false, All = false }
                });
            }

            var submittedTypes = await _context.Surveys
                .Where(s => s.CompanyId == company.CompanyId && s.JobFairId == activeJobFair.JobFairId)
                .Select(s => s.Type)
                .ToListAsync();

            var hasCdc = submittedTypes.Contains(SurveyType.CDC);
            var hasDepartment = submittedTypes.Contains(SurveyType.Department);

            return Ok(new
            {
                CompanyId = company.CompanyId,
                JobFairId = activeJobFair.JobFairId,
                HasActiveJobFair = true,
                Submitted = new
                {
                    Cdc = hasCdc,
                    Department = hasDepartment,
                    All = hasCdc && hasDepartment
                }
            });
        }

        // POST: api/admin/survey/submit
        // Submits a survey. This endpoint is intended for companies submitting surveys.
        // Enforces:
        //  - Company identity is extracted from JWT and must match (if CompanyId provided)
        //  - There is an active JobFair
        //  - Company is registered and IsPresent for the active JobFair
        //  - PEO/open-ended fields are saved only for Department surveys
        [HttpPost("submit")]
        [Authorize(Roles = "Company")]
        public async Task<IActionResult> SubmitSurvey([FromBody] SurveySubmissionDto dto)
        {
            if (dto == null) return BadRequest("Request body is required.");

            // 1. Extract user id from token and resolve company
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
                return Unauthorized("Invalid or missing user id in token.");

            var company = await _context.Companies.FirstOrDefaultAsync(c => c.UserId == userId);
            if (company == null)
                return NotFound("Company not found for current token.");

            // If client included CompanyId, ensure it matches token's company
            if (dto.CompanyId > 0 && dto.CompanyId != company.CompanyId)
                return BadRequest("CompanyId in payload does not match authenticated company.");

            // 2. Ensure there is an active JobFair
            var activeJobFair = await _context.JobFairs
                .AsNoTracking()
                .FirstOrDefaultAsync(j => j.IsActive);

            if (activeJobFair == null)
                return BadRequest("No active job fair. Surveys can only be submitted during an active job fair.");

            // If client provided a JobFairId, ensure it matches the active fair
            if (dto.JobFairId > 0 && dto.JobFairId != activeJobFair.JobFairId)
                return BadRequest("Survey must be submitted for the currently active job fair.");

            // 3. Verify company participation and presence in active fair
            var participation = await _context.CompanyJobFairParticipations
                .FirstOrDefaultAsync(p => p.CompanyId == company.CompanyId && p.JobFairId == activeJobFair.JobFairId);

            if (participation == null)
                return BadRequest("Company is not registered for the active job fair.");

            // Ensure company is marked present (IsPresent) for the fair
            if (!participation.IsPresent)
                return BadRequest("Company is not marked present for the active job fair and cannot submit survey.");

            // 4. Prepare the SurveyResponseData to persist.
            SurveyResponseData? toSave;
            if (dto.ResponseData == null)
            {
                toSave = null;
            }
            else if (dto.Type == SurveyType.Department)
            {
                // Persist full payload for Department surveys (PEO + open-ended included)
                toSave = dto.ResponseData;
            }
            else
            {
                // For CDC or other types persist only original CDC fields
                toSave = new SurveyResponseData
                {
                    FypQuality = dto.ResponseData.FypQuality,
                    FypComments = dto.ResponseData.FypComments,
                    ArrangementQuality = dto.ResponseData.ArrangementQuality,
                    ArrangementComments = dto.ResponseData.ArrangementComments,
                    LunchQuality = dto.ResponseData.LunchQuality,
                    LunchComments = dto.ResponseData.LunchComments
                    // PEO/qualitative fields intentionally omitted
                };
            }

            var options = new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                Converters = { new System.Text.Json.Serialization.JsonStringEnumConverter() }
            };

            var survey = new Survey
            {
                Type = dto.Type,
                CompanyId = company.CompanyId,
                JobFairId = activeJobFair.JobFairId,
                Responses = toSave == null ? null : JsonSerializer.Serialize(toSave, options),
                SubmittedAt = DateTime.UtcNow
            };

            _context.Surveys.Add(survey);
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Survey submitted successfully.", survey.SurveyId });
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
                        // Uses the specific Deserializer logic
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
        [HttpPost("submit-both")]
        [Authorize(Roles = "Company")]
        public async Task<IActionResult> SubmitBothSurveys([FromBody] CombinedSurveySubmissionDto dto)
        {
            if (dto == null) return BadRequest("Request body is required.");
            if (dto.CdcResponse == null && dto.DepartmentResponse == null)
                return BadRequest("At least one survey (CDC or Department) must be provided.");

            // 1. Resolve company from token
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
                return Unauthorized("Invalid or missing user id in token.");

            var company = await _context.Companies.FirstOrDefaultAsync(c => c.UserId == userId);
            if (company == null)
                return NotFound("Company not found for current token.");

            if (dto.CompanyId.HasValue && dto.CompanyId.Value != company.CompanyId)
                return BadRequest("CompanyId in payload does not match authenticated company.");

            // 2. Ensure active job fair
            var activeJobFair = await _context.JobFairs.AsNoTracking().FirstOrDefaultAsync(j => j.IsActive);
            if (activeJobFair == null)
                return BadRequest("No active job fair. Surveys can only be submitted during an active job fair.");

            if (dto.JobFairId.HasValue && dto.JobFairId.Value != activeJobFair.JobFairId)
                return BadRequest("Survey must be submitted for the currently active job fair.");

            // 3. Verify company participation and presence
            var participation = await _context.CompanyJobFairParticipations
                .FirstOrDefaultAsync(p => p.CompanyId == company.CompanyId && p.JobFairId == activeJobFair.JobFairId);

            if (participation == null)
                return BadRequest("Company is not registered for the active job fair.");

            if (!participation.IsPresent)
                return BadRequest("Company is not marked present for the active job fair and cannot submit survey.");

            // 4. Check existing submissions
            var existingTypes = await _context.Surveys
                .Where(s => s.CompanyId == company.CompanyId && s.JobFairId == activeJobFair.JobFairId)
                .Select(s => s.Type)
                .ToListAsync();

            var created = new List<object>();
            var skipped = new List<object>();

            var options = new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                Converters = { new System.Text.Json.Serialization.JsonStringEnumConverter() }
            };

            // Use transaction so both inserts are atomic when both provided
            using (var tx = await _context.Database.BeginTransactionAsync())
            {
                try
                {
                    // CDC
                    if (dto.CdcResponse != null)
                    {
                        if (existingTypes.Contains(SurveyType.CDC))
                        {
                            skipped.Add(new { Type = "CDC", Reason = "Already submitted" });
                        }
                        else
                        {
                            var survey = new Survey
                            {
                                Type = SurveyType.CDC,
                                CompanyId = company.CompanyId,
                                JobFairId = activeJobFair.JobFairId,
                                Responses = JsonSerializer.Serialize(dto.CdcResponse, options),
                                SubmittedAt = DateTime.UtcNow
                            };
                            _context.Surveys.Add(survey);
                            await _context.SaveChangesAsync();
                            created.Add(new { Type = "CDC", SurveyId = survey.SurveyId });
                        }
                    }

                    // Department
                    if (dto.DepartmentResponse != null)
                    {
                        if (existingTypes.Contains(SurveyType.Department))
                        {
                            skipped.Add(new { Type = "Department", Reason = "Already submitted" });
                        }
                        else
                        {
                            var survey = new Survey
                            {
                                Type = SurveyType.Department,
                                CompanyId = company.CompanyId,
                                JobFairId = activeJobFair.JobFairId,
                                Responses = JsonSerializer.Serialize(dto.DepartmentResponse, options),
                                SubmittedAt = DateTime.UtcNow
                            };
                            _context.Surveys.Add(survey);
                            await _context.SaveChangesAsync();
                            created.Add(new { Type = "Department", SurveyId = survey.SurveyId });
                        }
                    }

                    await tx.CommitAsync();

                    return Ok(new
                    {
                        Message = "Combined survey processing completed.",
                        Created = created,
                        Skipped = skipped
                    });
                }
                catch (Exception ex)
                {
                    await tx.RollbackAsync();
                    // preserve existing error patterns in controller
                    return StatusCode(500, new { Message = "Failed to submit surveys.", Error = ex.Message });
                }
            }
        }


        // GET: api/survey/company/{companyId}
        [HttpGet("company/{companyId}")]
        public async Task<IActionResult> GetCompanySurveys(int companyId)
        {
            var surveys = await _context.Surveys
                .Include(s => s.Company)
                .Where(s => s.CompanyId == companyId)
                .OrderByDescending(s => s.SubmittedAt)
                .ToListAsync();

            if (!surveys.Any())
                return Ok(new { Message = $"No surveys found for company ID {companyId}", Surveys = new List<object>() });

            var surveyList = surveys.Select(s => new
            {
                SurveyId = s.SurveyId,
                Type = s.Type.ToString(),
                Responses = DeserializeResponses(s.Responses),
                CompanyName = s.Company?.Name,
                SubmittedAt = s.SubmittedAt
            }).ToList();

            return Ok(new
            {
                CompanyId = companyId,
                CompanyName = surveys.First().Company?.Name,
                TotalSurveys = surveys.Count,
                CDCSurveys = surveys.Count(s => s.Type == SurveyType.CDC),
                DepartmentSurveys = surveys.Count(s => s.Type == SurveyType.Department),
                Surveys = surveyList
            });
        }

        #region Helper
            // Tries to deserialize into your specific SurveyResponseData class
        private static object? DeserializeResponses(string? responses)
        {
            if (string.IsNullOrEmpty(responses))
                return null;

            var options = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true,
                Converters = { new System.Text.Json.Serialization.JsonStringEnumConverter() }
            };

            try
            {
                // Try to deserialize into the specific SurveyResponseData structure
                return JsonSerializer.Deserialize<SurveyResponseData>(responses, options);
            }
            catch
            {
                try
                {
                    // Fallback to generic object if structure doesn't match
                    return JsonSerializer.Deserialize<object>(responses, options);
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