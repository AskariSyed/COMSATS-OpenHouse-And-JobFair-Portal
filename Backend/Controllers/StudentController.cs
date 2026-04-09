using FirebaseAdmin.Messaging;
using JobFairPortal.Data;
using JobFairPortal.DTOs;
using JobFairPortal.Models;
using JobFairPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Org.BouncyCastle.Asn1.Ocsp;
using System.Security.Claims;

namespace JobFairPortal.Controllers
{

    [ApiController]
    [Route("api/[controller]")]


    [Authorize(Roles = "Student")]
    public class StudentController : ControllerBase
    {
        private readonly JobFairRecruitmentDbContext _context;
        private readonly ILogger<StudentController> _logger;
        private readonly MailKitMailService _mailService;
        private static readonly TimeZoneInfo JobFairTimeZone = ResolveJobFairTimeZone();
        private static readonly TimeSpan InterviewCutoffLocal = TimeSpan.FromHours(16.5);
        private static readonly TimeSpan WalkInStartLocal = new TimeSpan(9, 0, 0);
        private static readonly TimeSpan WalkInEndLocal = new TimeSpan(16, 30, 0);



        public StudentController(JobFairRecruitmentDbContext context, ILogger<StudentController> logger, MailKitMailService mailService)
        {
            _context = context;
            _logger = logger;
            _mailService = mailService;
        }

        [HttpDelete("interview-requests/{requestId}")]
        public async Task<IActionResult> RemoveInterviewRequest(int requestId)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            var interviewRequest = await _context.InterviewRequests
                .Include(r => r.Company)
                .ThenInclude(c => c.User)
                .FirstOrDefaultAsync(r => r.RequestId == requestId && r.StudentId == student.StudentId);

            if (interviewRequest == null)
                return NotFound("Interview request not found.");

            // Only allow removal of pending requests
            if (interviewRequest.Status != RequestStatus.Pending)
                return BadRequest($"Cannot remove a request with status: {interviewRequest.Status}. Only pending requests can be removed.");

            _context.InterviewRequests.Remove(interviewRequest);
            await _context.SaveChangesAsync();

            // Send FCM notification to company when student withdraws
            if (!string.IsNullOrWhiteSpace(interviewRequest.Company?.FcmToken))
            {
                try
                {
                    var message = new Message
                    {
                        Token = interviewRequest.Company.FcmToken,
                        Notification = new FirebaseAdmin.Messaging.Notification
                        {
                            Title = "Interview Request Withdrawn",
                            Body = $"{student.User.FullName} has withdrawn their interview request"
                        },
                        Data = new Dictionary<string, string>
                        {
                            { "RequestId", interviewRequest.RequestId.ToString() },
                            { "StudentId", student.StudentId.ToString() },
                            { "StudentName", student.User.FullName ?? "Unknown Student" },
                            { "Type", "RequestWithdrawn" }
                        }
                    };

                    await FirebaseMessaging.DefaultInstance.SendAsync(message);

                    _logger.LogInformation($"Withdrawal notification sent to company {interviewRequest.CompanyId}");
                }
                catch (Exception ex)
                {
                    _logger.LogWarning($"Failed to send withdrawal notification: {ex.Message}");
                }
            }

            return Ok(new
            {
                Message = "Interview request removed successfully.",
                RequestId = interviewRequest.RequestId,
                CompanyName = interviewRequest.Company?.Name
            });
        }
        [HttpPost("interview-requests/{requestId}/accept")]
        public async Task<IActionResult> AcceptInterviewRequest(int requestId)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            // Ensure the Student.User navigation is loaded to avoid NullReference when accessing student.User.FullName
            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            var activeJobFair = await _context.JobFairs.AsNoTracking().FirstOrDefaultAsync(j => j.IsActive);
            if (activeJobFair == null)
                return BadRequest("No active job fair.");
            if (HasInterviewCutoffPassed(activeJobFair.date, DateTime.UtcNow))
                return BadRequest("Job Fair has ended.");

            var interviewRequest = await _context.InterviewRequests
                .Include(r => r.Company)
                .ThenInclude(c => c.User)
                .FirstOrDefaultAsync(r => r.RequestId == requestId && r.StudentId == student.StudentId);

            if (interviewRequest == null)
                return NotFound("Interview request not found.");

            if (interviewRequest.Status != RequestStatus.Pending)
                return BadRequest($"Cannot accept a request with status: {interviewRequest.Status}");

            // Update request status
            interviewRequest.Status = RequestStatus.Accepted;
            interviewRequest.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            // Null-safe notification send
            var company = interviewRequest.Company;
            var studentName = student.User?.FullName ?? "A student";

            if (company != null && !string.IsNullOrWhiteSpace(company.FcmToken))
            {
                try
                {
                    var message = new Message
                    {
                        Token = company.FcmToken,
                        Notification = new FirebaseAdmin.Messaging.Notification
                        {
                            Title = "Interview Request Accepted",
                            Body = $"{studentName} has accepted your interview request"
                        },
                        Data = new Dictionary<string, string>
                {
                    { "RequestId", interviewRequest.RequestId.ToString() },
                    { "StudentId", student.StudentId.ToString() },
                    { "StudentName", studentName },
                    { "Type", "RequestAccepted" }
                }
                    };

                    await FirebaseMessaging.DefaultInstance.SendAsync(message);

                    _logger.LogInformation($"Acceptance notification sent to company {interviewRequest.CompanyId}");
                }
                catch (Exception ex)
                {
                    _logger.LogWarning($"Failed to send acceptance notification: {ex.Message}");
                }
            }

            return Ok(new
            {
                Message = "Interview request accepted successfully.",
                RequestId = interviewRequest.RequestId,
                CompanyName = interviewRequest.Company?.Name ?? "Unknown",
                Status = interviewRequest.Status.ToString(),
                AcceptedAt = interviewRequest.UpdatedAt
            });
        }

        [HttpPost("interview-requests/{requestId}/reject")]
        public async Task<IActionResult> RejectInterviewRequest(int requestId, [FromBody] RejectInterviewRequestDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            var interviewRequest = await _context.InterviewRequests
                .Include(r => r.Company)
                .ThenInclude(c => c.User)
                .FirstOrDefaultAsync(r => r.RequestId == requestId && r.StudentId == student.StudentId);

            if (interviewRequest == null)
                return NotFound("Interview request not found.");

            if (interviewRequest.Status != RequestStatus.Pending)
                return BadRequest($"Cannot reject a request with status: {interviewRequest.Status}");

            // Update request status
            interviewRequest.Status = RequestStatus.Rejected;
            interviewRequest.ReasonForReject = dto.Reason;
            interviewRequest.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            // Send FCM notification to company when student rejects
            if (!string.IsNullOrWhiteSpace(interviewRequest.Company.FcmToken))
            {
                try
                {
                    var message = new Message
                    {
                        Token = interviewRequest.Company.FcmToken,
                        Notification = new FirebaseAdmin.Messaging.Notification
                        {
                            Title = "Interview Request Declined",
                            Body = $"{student.User.FullName} has declined your interview request"
                        },
                        Data = new Dictionary<string, string>
                        {
                            { "RequestId", interviewRequest.RequestId.ToString() },
                            { "StudentId", student.StudentId.ToString() },
                            { "StudentName", student.User.FullName ?? "Unknown Student" },
                            { "Reason", dto.Reason ?? "No reason provided" },
                            { "Type", "RequestRejected" }
                        }
                    };

                    await FirebaseMessaging.DefaultInstance.SendAsync(message);

                    _logger.LogInformation($"Rejection notification sent to company {interviewRequest.CompanyId}");
                }
                catch (Exception ex)
                {
                    _logger.LogWarning($"Failed to send rejection notification: {ex.Message}");
                }
            }

            return Ok(new
            {
                Message = "Interview request rejected successfully.",
                RequestId = interviewRequest.RequestId,
                CompanyName = interviewRequest.Company?.Name,
                Status = interviewRequest.Status.ToString(),
                RejectionReason = dto.Reason,
                RejectedAt = interviewRequest.UpdatedAt
            });
        }


        // GET: api/Student/profile
        [HttpGet("profile")]
        public async Task<IActionResult> GetProfile()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();
            var student = await _context.Students
                // A. Basic Info
                .Include(s => s.User)
                .Include(s => s.Educations)
                .Include(s => s.Certifications)
                .Include(s => s.Achievements)
                .Include(s => s.ContactLinks)
                .Include(s => s.Experiences)
                .Include(s => s.StudentProjects)
                    .ThenInclude(sp => sp.Project)
                        .ThenInclude(p => p.StudentProjects)
                            .ThenInclude(p_sp => p_sp.Student)
                                .ThenInclude(p_s => p_s.User)

                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student profile not found.");
            var response = new
            {
                student.StudentId,
                student.RegistrationNo,
                student.Department,
                student.ProfilePicUrl,
                student.CvUrl,
                student.Skills,
                student.CGPA,
                student.FcmToken,
                User = new
                {
                    student.User.UserId,
                    student.User.FullName,
                    student.User.Email,
                    student.User.Phone,
                    Role = student.User.Role.ToString(),
                    student.User.IsActive,
                    student.User.CreatedAt
                },
                Educations = student.Educations.Select(e => new
                {
                    e.EducationId,
                    e.InstitutionName,
                    e.Degree,
                    e.FieldOfStudy,
                    e.StartDate,
                    e.EndDate,
                    e.IsCurrent,
                    e.GradeType,
                    e.GradeValue,
                    e.MarksObtained,
                    e.TotalMarks,
                    e.CGPA,
                    e.Location
                }).ToList(),

                Certifications = student.Certifications.Select(c => new
                {
                    c.CertificationId,
                    c.Title,
                    c.Issuer,
                    c.IssueDate,
                    c.CredentialUrl,
                    c.CredentialId
                }).ToList(),

                Achievements = student.Achievements.Select(a => new
                {
                    a.AchievementId,
                    a.Title,
                    a.Description,
                    a.DateAchieved
                }).ToList(),

                ContactLinks = student.ContactLinks.Select(cl => new
                {
                    cl.LinkId,
                    Platform = cl.Platform.ToString(),
                    cl.Url
                }).ToList(),
                Experiences = student.Experiences.Select(ex => new
                {
                    ex.ExperienceId,
                    ex.CompanyName,
                    ex.Location,
                    ex.StartDate,
                    ex.EndDate,
                    ex.Description,
                    ex.IsCurrent,
                    ex.Role
                }).ToList(),

                Projects = student.StudentProjects
                    .Where(sp => sp.Project != null)
                    .Select(sp => new
                    {
                        sp.Project.ProjectId,
                        sp.Project.Title,
                        sp.Project.Description,
                        sp.Project.DemoUrl,
                        sp.Project.GitHubUrl,
                        Type = sp.Project.Type.ToString(),

                        // My Status in this project
                        CurrentStudentRole = sp.role,
                        CurrentStudentStatus = sp.Status.ToString(),
                        CurrentStudentIsCreator = sp.IsCreator,

                        // List of other members in this project
                        Partners = sp.Project.StudentProjects
                            .Where(p => p.Student != null && p.Student.User != null) // Safety Check
                            .Select(p => new
                            {
                                p.Student.StudentId,
                                p.Student.ProfilePicUrl,
                                Name = p.Student.User.FullName ?? "Unknown",
                                p.Student.RegistrationNo,
                                Role = p.role,
                                Status = p.Status.ToString(),
                                IsCreator = p.IsCreator,
                                IsCurrentStudent = p.Student.StudentId == student.StudentId
                            })
                            // Optional: Exclude myself from the partners list
                            .Where(p => p.StudentId != student.StudentId)
                            .ToList()
                    }).ToList()
            };

            return Ok(new { student = response });
        }

        [HttpGet("experiences")]
        public async Task<IActionResult> GetExperiences()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students
                .Include(s => s.Experiences)
                .FirstOrDefaultAsync(s => s.UserId == userId);
            if (student == null)
                return NotFound("Student not found.");

            var Response = student.Experiences.Select(ex => new
            {
                ex.ExperienceId,
                ex.CompanyName,
                ex.Location,
                ex.StartDate,
                ex.EndDate,
                ex.Description,
                ex.IsCurrent,
                ex.Role
            }).ToList();

            return Ok(Response);
        }
        [HttpPost("experiences")]
        public async Task<IActionResult> AddExperience([FromBody] ExperienceAddDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students.FirstOrDefaultAsync(s => s.UserId == userId);
            if (student == null)
                return NotFound("Student not found.");

            var experience = new Experience
            {
                CompanyName = dto.CompanyName,
                Location = dto.Location,
                StartDate = dto.StartDate,
                EndDate = dto.EndDate,
                Description = dto.Description,
                StudentId = student.StudentId,
                IsCurrent = dto.IsCurrent,
                Role = dto.Role
            };

            _context.Experiences.Add(experience);
            await _context.SaveChangesAsync();

            // ---------------------------------------------------------
            // 🟢 FIX: Map to an anonymous object to break the cycle
            // ---------------------------------------------------------
            var responseDto = new
            {
                experience.ExperienceId,
                experience.CompanyName,
                experience.Location,
                experience.StartDate,
                experience.EndDate,
                experience.Description,
                experience.IsCurrent,
                experience.Role,
                // Do NOT include 'experience.Student' here
            };

            return Ok(new { Message = "Experience added successfully", Experience = responseDto });
        }

        [HttpDelete("experiences/{experienceId}")]
        public async Task<IActionResult> DeleteExperience(int experienceId)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();
            var experience = await _context.Experiences
                .Include(e => e.Student)
                .FirstOrDefaultAsync(e => e.ExperienceId == experienceId && e.Student != null && e.Student.UserId == userId);

            if (experience == null)
                return NotFound("Experience not found or does not belong to this student.");

            _context.Experiences.Remove(experience);
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Experience deleted successfully" });
        }


        [HttpGet("certifications")]
        public async Task<IActionResult> GetCertifications()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students
                .Include(s => s.Certifications)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            return Ok(student.Certifications);
        }
        [HttpPost("certifications")]
        public async Task<IActionResult> AddCertification([FromBody] CertificationAddDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students.FirstOrDefaultAsync(s => s.UserId == userId);
            if (student == null)
                return NotFound("Student not found.");

            // 1. Create the Certification Entity (Ensure DateKind=Utc fix is applied here too, if needed)
            var certification = new Certification
            {
                StudentId = student.StudentId,
                Title = dto.Title,
                Issuer = dto.Issuer,
                IssueDate = dto.IssueDate, // FIX: Apply DateTime.SpecifyKind(dto.IssueDate.Value, DateTimeKind.Utc) if necessary
                CredentialUrl = dto.CredentialUrl,
                CredentialId = dto.CredentialId
            };

            _context.Certifications.Add(certification);
            await _context.SaveChangesAsync();

            // 2. 🔹 FIX: Map to a flattened DTO/Anonymous Object before returning
            var responseDto = new
            {
                certification.CertificationId,
                certification.Title,
                certification.Issuer,
                certification.IssueDate,
                certification.CredentialUrl,
                certification.CredentialId
                // DO NOT include 'Student' navigation property
            };

            return Ok(new
            {
                Message = "Certification added successfully",
                Certification = responseDto // Return the flattened DTO
            });
        }
        [HttpPut("certifications/{certificationId}")]
        public async Task<IActionResult> UpdateCertification(int certificationId, [FromBody] CertificationUpdateDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var certification = await _context.Certifications
                .Include(c => c.Student)
                .FirstOrDefaultAsync(c => c.CertificationId == certificationId && c.Student != null && c.Student.UserId == userId);

            if (certification == null)
                return NotFound("Certification not found or does not belong to this student.");

            if (!string.IsNullOrWhiteSpace(dto.Title))
                certification.Title = dto.Title;

            if (!string.IsNullOrWhiteSpace(dto.Issuer))
                certification.Issuer = dto.Issuer;

            if (dto.IssueDate.HasValue)
                certification.IssueDate = dto.IssueDate.Value;

            if (!string.IsNullOrWhiteSpace(dto.CredentialUrl))
                certification.CredentialUrl = dto.CredentialUrl;

            if (!string.IsNullOrWhiteSpace(dto.CredentialId))
                certification.CredentialId = dto.CredentialId;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Certification updated successfully",
                Certification = certification
            });
        }

        // ✅ DELETE - Delete a certification
        [HttpDelete("certifications/{certificationId}")]
        public async Task<IActionResult> DeleteCertification(int certificationId)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var certification = await _context.Certifications
                .Include(c => c.Student)
                .FirstOrDefaultAsync(c => c.CertificationId == certificationId && c.Student != null && c.Student.UserId == userId);

            if (certification == null)
                return NotFound("Certification not found or does not belong to this student.");

            _context.Certifications.Remove(certification);
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Certification deleted successfully" });
        }


        [HttpPost("projects")]
        public async Task<IActionResult> CreateProject([FromBody] ProjectAddDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students.FirstOrDefaultAsync(s => s.UserId == userId);
            if (student == null)
                return NotFound("Student not found.");

            var project = new Project
            {
                Title = dto.Title,
                Type = dto.Type,
                Description = dto.Description,
                Skills = dto.Skills,
                ClientName = dto.ClientName,
                Supervisor = dto.Supervisor,
                DemoUrl = dto.DemoUrl,
                GitHubUrl = dto.GitHubUrl,
                StartDate = dto.StartDate,
                EndDate = dto.EndDate
            };

            _context.Projects.Add(project);
            await _context.SaveChangesAsync();
            var studentProject = new StudentProject
            {
                ProjectId = project.ProjectId,
                StudentId = student.StudentId,
                IsCreator = true,
                Status = ProjectInviteStatus.Accepted,
                role = "Creator"
            };

            _context.StudentProjects.Add(studentProject);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Project created successfully",
                Project = new
                {
                    project.ProjectId,
                    project.Title,
                    project.Type,
                    project.Description,
                    project.DemoUrl,
                    project.GitHubUrl
                }
            });

        }
        [HttpPost("projects/{projectId}/invite")]
        public async Task<IActionResult> InviteStudentToProject(int projectId, [FromBody] ProjectInviteDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var inviter = await _context.Students
                .Include(s => s.StudentProjects)
                .Include(s => s.User) // Ensure User is included for FullName
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (inviter == null)
                return NotFound("Inviting student not found.");

            // 🔹 FIX: Handle null StudentProjects safely
            bool isInProject = inviter.StudentProjects != null &&
                               inviter.StudentProjects.Any(sp => sp.ProjectId == projectId && sp.Status == ProjectInviteStatus.Accepted);

            if (!isInProject)
                return BadRequest("You must be part of the project to invite others.");

            var invitee = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.RegistrationNo == dto.RegistrationNumber);

            if (invitee == null)
                return NotFound("Student not found with this registration number.");

            var existingInvite = await _context.StudentProjects
                .FirstOrDefaultAsync(sp => sp.ProjectId == projectId && sp.StudentId == invitee.StudentId);

            if (existingInvite != null)
                return BadRequest("This student has already been invited or is already a member.");

            var newInvite = new StudentProject
            {
                ProjectId = projectId,
                StudentId = invitee.StudentId,
                IsCreator = false,
                Status = ProjectInviteStatus.Pending,
                role = "Member"
            };

            _context.StudentProjects.Add(newInvite);
            await _context.SaveChangesAsync();

            if (!string.IsNullOrWhiteSpace(invitee.FcmToken))
            {
                var message = new Message
                {
                    Token = invitee.FcmToken,
                    Notification = new FirebaseAdmin.Messaging.Notification
                    {
                        Title = "Project Invitation",
                        Body = $"{inviter.User.FullName} invited you to join a project."
                    },
                    Data = new Dictionary<string, string>
                    {
                        { "ProjectId", projectId.ToString() },
                        { "Type", "ProjectInvite" }
                    }
                };

                try
                {
                    await FirebaseMessaging.DefaultInstance.SendAsync(message);
                }
                catch (Exception ex)
                {
                    return StatusCode(500, new { Message = "Invite sent, but failed to send FCM notification.", Error = ex.Message });
                }
            }

            return Ok(new { Message = "Invitation sent successfully." });
        }

        [HttpGet("projects/invitations")]
        public async Task<IActionResult> GetProjectInvitations()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students
                .Include(s => s.StudentProjects)
                .ThenInclude(sp => sp.Project)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            var invitations = student.StudentProjects
                .Where(sp => sp.Status == ProjectInviteStatus.Pending)
                .Select(sp => new
                {
                    sp.Id,
                    sp.ProjectId,
                    ProjectTitle = sp.Project.Title,
                    sp.Project.Type,
                    sp.Project.Description
                }).ToList();

            return Ok(invitations);
        }


        [HttpPost("projects/invitations/{inviteId}/respond")]
        public async Task<IActionResult> RespondToInvitation(int inviteId, [FromQuery] bool accept)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students.FirstOrDefaultAsync(s => s.UserId == userId);
            if (student == null)
                return NotFound("Student not found.");

            var invite = await _context.StudentProjects
                .Include(sp => sp.Project)
                .FirstOrDefaultAsync(sp => sp.Id == inviteId && sp.StudentId == student.StudentId);

            if (invite == null)
                return NotFound("Invitation not found.");

            invite.Status = accept ? ProjectInviteStatus.Accepted : ProjectInviteStatus.Rejected;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = accept ? "Invitation accepted." : "Invitation rejected.",
                invite.Project.Title,
                invite.Status
            });
        }
        [HttpGet("projects/{projectId}/members")]
        public async Task<IActionResult> GetProjectMembers(int projectId)
        {
            var project = await _context.Projects
                .Include(p => p.StudentProjects)
                .ThenInclude(sp => sp.Student)
                    .ThenInclude(s => s.User)
                .FirstOrDefaultAsync(p => p.ProjectId == projectId);

            if (project == null)
                return NotFound("Project not found.");

            var members = project.StudentProjects.Select(sp => new
            {
                sp.StudentId,
                // Now User is loaded, so this won't crash
                FullName = sp.Student.User?.FullName ?? "Unknown",
                sp.Student.RegistrationNo,
                sp.role,
                sp.Status,
                sp.IsCreator
            });

            return Ok(members);
        }
        [HttpDelete("projects/{projectId}/members/{studentId}")]
        public async Task<IActionResult> RemoveMember(int projectId, int studentId)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var currentUser = await _context.Students
                .Include(s => s.StudentProjects)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (currentUser == null)
                return NotFound("Current student not found.");

            var targetMembership = await _context.StudentProjects
                .Include(sp => sp.Project)
                .FirstOrDefaultAsync(sp => sp.ProjectId == projectId && sp.StudentId == studentId);

            if (targetMembership == null)
                return NotFound("Member not found in this project.");

            var currentUserMembership = await _context.StudentProjects
                .FirstOrDefaultAsync(sp => sp.ProjectId == projectId && sp.StudentId == currentUser.StudentId);

            if (currentUserMembership == null)
                return BadRequest("You are not part of this project.");

            bool isCreator = currentUserMembership.IsCreator;
            bool isRemovingSelf = currentUser.StudentId == studentId;

            if (!isCreator && !isRemovingSelf)
                return Forbid("You are not authorized to remove other members.");

            _context.StudentProjects.Remove(targetMembership);
            await _context.SaveChangesAsync();
            if (targetMembership.IsCreator)
            {
                var newCreator = await _context.StudentProjects
                    .FirstOrDefaultAsync(sp => sp.ProjectId == projectId && sp.Status == ProjectInviteStatus.Accepted);

                if (newCreator != null)
                {
                    newCreator.IsCreator = true;
                    newCreator.role = "Creator";
                    await _context.SaveChangesAsync();
                }
            }

            return Ok(new { Message = isRemovingSelf ? "You left the project." : "Member removed successfully." });
        }



        [HttpGet("contactLinks")]
        public async Task<IActionResult> GetContactLinks()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students
                .Include(s => s.ContactLinks)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            var links = student.ContactLinks.Select(cl => new
            {
                cl.LinkId,
                Platform = cl.Platform.ToString(),
                cl.Url
            });

            return Ok(links);
        }


        [HttpPost("ContactLink")]
        public async Task<IActionResult> AddContactLink([FromBody] ContactLinkAddDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students
                .Include(s => s.ContactLinks)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            // 🔥 Convert string to enum safely
            if (!Enum.TryParse<ContactPlatform>(dto.Platform, true, out var platformEnum))
                return BadRequest("Invalid platform value.");

            if (student.ContactLinks.Any(cl => cl.Platform == platformEnum))
                return BadRequest($"You already have a {platformEnum} link.");

            var contactLink = new ContactLink
            {
                StudentId = student.StudentId,
                Platform = platformEnum,
                Url = dto.Url
            };

            _context.ContactLinks.Add(contactLink);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Contact link added successfully",
                ContactLink = new
                {
                    contactLink.LinkId,
                    Platform = contactLink.Platform.ToString(),
                    contactLink.Url
                }
            });
        }

        [HttpPut("{linkId}")]
        public async Task<IActionResult> UpdateContactLink(int linkId, [FromBody] ContactLinkUpdateDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var contactLink = await _context.ContactLinks
                .Include(cl => cl.Student)
                .FirstOrDefaultAsync(cl => cl.LinkId == linkId && cl.Student.UserId == userId);

            if (contactLink == null)
                return NotFound("Contact link not found or does not belong to you.");
            if (!string.IsNullOrWhiteSpace(dto.Platform))
            {
                if (!Enum.TryParse<ContactPlatform>(dto.Platform, true, out var platformEnum))
                    return BadRequest("Invalid platform value.");
                if (platformEnum != contactLink.Platform)
                {
                    bool exists = await _context.ContactLinks
                        .AnyAsync(cl => cl.StudentId == contactLink.StudentId && cl.Platform == platformEnum);

                    if (exists)
                        return BadRequest($"You already have a {platformEnum} link.");

                    contactLink.Platform = platformEnum;
                }
            }

            // 🔗 Update URL if provided
            if (!string.IsNullOrWhiteSpace(dto.Url))
                contactLink.Url = dto.Url;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Contact link updated successfully",
                ContactLink = new
                {
                    contactLink.LinkId,
                    Platform = contactLink.Platform.ToString(),
                    contactLink.Url
                }
            });
        }

        [HttpDelete("{linkId}")]
        public async Task<IActionResult> DeleteContactLink(int linkId)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var contactLink = await _context.ContactLinks
                .Include(cl => cl.Student)
                .FirstOrDefaultAsync(cl => cl.LinkId == linkId && cl.Student.UserId == userId);

            if (contactLink == null)
                return NotFound("Contact link not found or does not belong to you.");

            _context.ContactLinks.Remove(contactLink);
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Contact link deleted successfully" });
        }

        [HttpPost("profile-pic")]
        public async Task<IActionResult> UploadProfilePic([FromForm] FileUploadDto dto)

        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim))
                return Unauthorized("User ID not found in token.");

            if (!int.TryParse(userIdClaim, out int userId))
                return BadRequest("Invalid user ID format in token.");


            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");
            var file = dto.File;

            if (student == null)
                return NotFound("Student not found.");

            if (file == null || file.Length == 0)
                return BadRequest(new { Code = "NO_FILE", Message = "No file uploaded." });

            // ✅ FILE SIZE VALIDATION: Max 1MB
            const long MAX_FILE_SIZE = 1048576; // 1MB in bytes
            if (file.Length > MAX_FILE_SIZE)
            {
                return BadRequest(new
                {
                    Code = "FILE_TOO_LARGE",
                    Message = "Profile picture must not exceed 1MB.",
                    FileSizeInMB = Math.Round(file.Length / (1024.0 * 1024.0), 2),
                    AllowedSizeInMB = 1,
                    Suggestion = "Please resize the image and try again."
                });
            }

            // ✅ VALIDATE FILE TYPE
            var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp" };
            var fileExtension = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (!allowedExtensions.Contains(fileExtension))
            {
                return BadRequest(new
                {
                    Code = "INVALID_FILE_TYPE",
                    Message = "Invalid file type. Only JPG, JPEG, PNG, and WEBP are allowed.",
                    AllowedTypes = allowedExtensions
                });
            }

            var uploadsFolder = Path.Combine("uploads", "student", "profilepics");
            Directory.CreateDirectory(uploadsFolder);

            var fileName = $"{student.RegistrationNo}_{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
            var filePath = Path.Combine(uploadsFolder, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            student.ProfilePicUrl = $"/uploads/student/profilepics/{fileName}";
            student.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new 
            { 
                Code = "SUCCESS",
                Message = "Profile picture uploaded successfully.", 
                ProfilePicUrl = student.ProfilePicUrl,
                FileSizeInMB = Math.Round(file.Length / (1024.0 * 1024.0), 2)
            });
        }

        [HttpPost("cv")]
        public async Task<IActionResult> UploadCv([FromForm] FileUploadDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim))
                return Unauthorized("User ID not found in token.");

            if (!int.TryParse(userIdClaim, out int userId))
                return BadRequest("Invalid user ID format in token.");

            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            var file = dto.File;
            if (file == null || file.Length == 0)
                return BadRequest("No file uploaded.");

            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (extension != ".pdf")
                return BadRequest("Only PDF files are allowed for CV upload.");

            if (!string.IsNullOrWhiteSpace(student.CvUrl))
            {
                var oldCvFile = student.CvUrl.Split('/').LastOrDefault();
                if (!string.IsNullOrWhiteSpace(oldCvFile))
                {
                    var oldCvPath = Path.Combine("uploads", "student", "cvs", oldCvFile);
                    if (System.IO.File.Exists(oldCvPath))
                        System.IO.File.Delete(oldCvPath);
                }
            }

            var uploadsFolder = Path.Combine("uploads", "student", "cvs");
            Directory.CreateDirectory(uploadsFolder);

            var safeRegNo = student.RegistrationNo.Replace("/", "_").Replace("\\", "_");
            var fileName = $"{safeRegNo}_{Guid.NewGuid()}.pdf";
            var filePath = Path.Combine(uploadsFolder, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            student.CvUrl = $"/uploads/student/cvs/{fileName}";
            student.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { Message = "CV uploaded successfully.", CvUrl = student.CvUrl });
        }

        [HttpGet("Education")]
        public async Task<IActionResult> GetEducations()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students
                .Include(s => s.Educations)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            return Ok(student.Educations);
        }

        [HttpPost("Education")]
        public async Task<IActionResult> AddEducation([FromBody] EducationAddDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students.FirstOrDefaultAsync(s => s.UserId == userId);
            if (student == null)
                return NotFound("Student not found.");

            var normalizedGradeType = string.IsNullOrWhiteSpace(dto.GradeType)
                ? "CGPA"
                : dto.GradeType.Trim();

            var gradeTypeLower = normalizedGradeType.ToLowerInvariant();
            var cgpaValue = gradeTypeLower == "cgpa" ? dto.CGPA : null;
            var gradeValue = gradeTypeLower == "marks" ? null : dto.GradeValue;
            var marksObtained = gradeTypeLower == "marks" ? dto.MarksObtained : null;
            var totalMarks = gradeTypeLower == "marks" ? dto.TotalMarks : null;

            var education = new Education
            {
                StudentId = student.StudentId,
                InstitutionName = dto.InstitutionName,
                Degree = dto.Degree,
                FieldOfStudy = dto.FieldOfStudy,
                StartDate = DateTime.SpecifyKind(dto.StartDate, DateTimeKind.Utc), // Ensure UTC fix is here
                EndDate = dto.EndDate.HasValue
                    ? DateTime.SpecifyKind(dto.EndDate.Value, DateTimeKind.Utc)
                    : null,
                IsCurrent = dto.IsCurrent,
                GradeType = normalizedGradeType,
                GradeValue = gradeValue,
                MarksObtained = marksObtained,
                TotalMarks = totalMarks,
                CGPA = cgpaValue,
                Location = dto.Location
            };

            _context.Educations.Add(education);
            await _context.SaveChangesAsync();
            var responseDto = new EducationDto
            {
                EducationId = education.EducationId,
                InstitutionName = education.InstitutionName,
                Degree = education.Degree,
                FieldOfStudy = education.FieldOfStudy,
                StartDate = education.StartDate,
                EndDate = education.EndDate,
                IsCurrent = education.IsCurrent,
                GradeType = education.GradeType,
                GradeValue = education.GradeValue,
                MarksObtained = education.MarksObtained,
                TotalMarks = education.TotalMarks,
                CGPA = education.CGPA,
                Location = education.Location
            };
            return Ok(new { Message = "Education added successfully", Education = responseDto });
        }

        [HttpPut("education/{educationId}")]
        public async Task<IActionResult> UpdateEducation(int educationId, [FromBody] EducationUpdateDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var education = await _context.Educations
                .Include(e => e.Student)
                .FirstOrDefaultAsync(e => e.EducationId == educationId && e.Student.UserId == userId);

            if (education == null)
                return NotFound("Education record not found or does not belong to you.");

            // Null-safe updates
            if (!string.IsNullOrWhiteSpace(dto.InstitutionName))
                education.InstitutionName = dto.InstitutionName;

            if (!string.IsNullOrWhiteSpace(dto.Degree))
                education.Degree = dto.Degree;

            if (!string.IsNullOrWhiteSpace(dto.FieldOfStudy))
                education.FieldOfStudy = dto.FieldOfStudy;

            if (dto.StartDate.HasValue)
                education.StartDate = dto.StartDate.Value;

            if (dto.EndDate.HasValue)
                education.EndDate = dto.EndDate.Value;

            if (dto.IsCurrent.HasValue)
                education.IsCurrent = dto.IsCurrent.Value;

            if (!string.IsNullOrWhiteSpace(dto.GradeType))
                education.GradeType = dto.GradeType.Trim();

            var effectiveGradeType = (education.GradeType ?? "CGPA").Trim().ToLowerInvariant();

            if (dto.GradeValue.HasValue)
                education.GradeValue = dto.GradeValue.Value;

            if (dto.MarksObtained.HasValue)
                education.MarksObtained = dto.MarksObtained.Value;

            if (dto.TotalMarks.HasValue)
                education.TotalMarks = dto.TotalMarks.Value;

            if (dto.CGPA.HasValue)
                education.CGPA = dto.CGPA.Value;

            // Keep only fields relevant to current grade type.
            if (effectiveGradeType == "percentage")
            {
                education.CGPA = null;
                education.MarksObtained = null;
                education.TotalMarks = null;
            }
            else if (effectiveGradeType == "marks")
            {
                education.CGPA = null;
                education.GradeValue = null;
            }
            else
            {
                education.MarksObtained = null;
                education.TotalMarks = null;
            }

            if (!string.IsNullOrWhiteSpace(dto.Location))
                education.Location = dto.Location;

            await _context.SaveChangesAsync();

            var responseDto = new EducationDto
            {
                EducationId = education.EducationId,
                InstitutionName = education.InstitutionName,
                Degree = education.Degree,
                FieldOfStudy = education.FieldOfStudy,
                StartDate = education.StartDate,
                EndDate = education.EndDate,
                IsCurrent = education.IsCurrent,
                GradeType = education.GradeType,
                GradeValue = education.GradeValue,
                MarksObtained = education.MarksObtained,
                TotalMarks = education.TotalMarks,
                CGPA = education.CGPA,
                Location = education.Location
            };

            return Ok(new { Message = "Education updated successfully", Education = responseDto });
        }


        [HttpDelete("education/{educationId}")]
        public async Task<IActionResult> DeleteEducation(int educationId)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var education = await _context.Educations
                .Include(e => e.Student)
                .FirstOrDefaultAsync(e => e.EducationId == educationId && e.Student.UserId == userId);

            if (education == null)
                return NotFound("Education record not found or does not belong to you.");

            _context.Educations.Remove(education);
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Education deleted successfully" });
        }

        [HttpPost("skills/add")]
        public async Task<IActionResult> AddSkills([FromBody] SkillsDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim))
                return Unauthorized("User ID not found in token.");

            if (!int.TryParse(userIdClaim, out int userId))
                return BadRequest("Invalid user ID format in token.");


            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");
            if (dto.Skills == null || dto.Skills.Count == 0)
                return BadRequest("No skills provided.");


            var existingSkills = student.Skills?.ToList() ?? new List<string>();

            foreach (var skill in dto.Skills)
            {
                if (!string.IsNullOrWhiteSpace(skill) &&
                    !existingSkills.Contains(skill, StringComparer.OrdinalIgnoreCase))
                {
                    existingSkills.Add(skill.Trim());
                }
            }

            student.Skills = existingSkills;

            student.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Skills added.", Skills = student.Skills });
        }

        [HttpPost("skills/remove")]
        public async Task<IActionResult> RemoveSkill(int studentId, [FromBody] string skill)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim))
                return Unauthorized("User ID not found in token.");

            if (!int.TryParse(userIdClaim, out int userId))
                return BadRequest("Invalid user ID format in token.");


            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            if (string.IsNullOrWhiteSpace(skill))
                return BadRequest("Skill cannot be empty.");

            var skills = student.Skills?.ToList() ?? new List<string>();
            var removed = skills.RemoveAll(s => string.Equals(s, skill, StringComparison.OrdinalIgnoreCase));
            if (removed == 0)
                return BadRequest("Skill not found.");

            student.Skills = skills;
            student.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Skill removed.", Skills = student.Skills });
        }


        [HttpPut("skills")]
        public async Task<IActionResult> PutSkills(int studentId, [FromBody] SkillsDto dto)
        {
            if (dto.Skills == null || dto.Skills.Count == 0)
                return BadRequest("No skills provided.");

            var student = await _context.Students.FirstOrDefaultAsync(s => s.StudentId == studentId);
            if (student == null)
                return NotFound("Student not found.");

            student.Skills = dto.Skills;
            student.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Skills updated.", Skills = student.Skills });
        }

        [Authorize]
        [HttpGet("debug-claims")]
        public IActionResult DebugClaims()
        {
            Console.WriteLine("🧩 DEBUGGING CLAIMS -------------------");
            foreach (var claim in User.Claims)
            {
                Console.WriteLine($"👉 Type: {claim.Type} | Value: {claim.Value}");
            }
            Console.WriteLine("--------------------------------------");

            return Ok(User.Claims.Select(c => new { c.Type, c.Value }));
        }

        // 6. Get Student Profile for Mobile App
        [HttpPut("phone")]
        public async Task<IActionResult> UpdatePhone(int studentId, [FromBody] PhoneDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim))
                return Unauthorized("User ID not found in token.");

            if (!int.TryParse(userIdClaim, out int userId))
                return BadRequest("Invalid user ID format in token.");


            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");
            if (string.IsNullOrWhiteSpace(dto.Phone))
                return BadRequest("Phone number is required.");

            student.User.Phone = dto.Phone;
            student.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Phone number updated successfully.", Phone = student.User.Phone });
        }

        [HttpGet("achievements")]
        public async Task<IActionResult> GetAchievements()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students
                .Include(s => s.Achievements)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            return Ok(student.Achievements);
        }

        [HttpPost("achievements")]
        public async Task<IActionResult> AddAchievement([FromBody] AchievementAddDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students.FirstOrDefaultAsync(s => s.UserId == userId);
            if (student == null)
                return NotFound("Student not found.");

            var achievement = new Achievement
            {
                StudentId = student.StudentId,
                Title = dto.Title,
                Description = dto.Description,
                DateAchieved = dto.DateAchieved ?? DateTime.UtcNow
            };

            _context.Achievements.Add(achievement);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Achievement added successfully",
                Achievement = new
                {
                    achievement.AchievementId,
                    achievement.Title,
                    achievement.Description,
                    achievement.DateAchieved
                }
            });
        }

        [HttpPut("achievements/{achievementId}")]
        public async Task<IActionResult> UpdateAchievement(int achievementId, [FromBody] AchievementUpdateDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var achievement = await _context.Achievements
                .Include(a => a.Student)
                .FirstOrDefaultAsync(a => a.AchievementId == achievementId && a.Student != null && a.Student.UserId == userId);

            if (achievement == null)
                return NotFound("Achievement not found or does not belong to this student.");

            if (!string.IsNullOrWhiteSpace(dto.Title))
                achievement.Title = dto.Title;

            if (!string.IsNullOrWhiteSpace(dto.Description))
                achievement.Description = dto.Description;

            if (dto.DateAchieved.HasValue)
                achievement.DateAchieved = dto.DateAchieved.Value;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Achievement updated successfully",
                Achievement = new
                {
                    achievement.AchievementId,
                    achievement.Title,
                    achievement.Description,
                    achievement.DateAchieved
                }
            });
        }

        [HttpDelete("achievements/{achievementId}")]
        public async Task<IActionResult> DeleteAchievement(int achievementId)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var achievement = await _context.Achievements
                .Include(a => a.Student)
                .FirstOrDefaultAsync(a => a.AchievementId == achievementId && a.Student != null && a.Student.UserId == userId);

            if (achievement == null)
                return NotFound("Achievement not found or does not belong to this student.");

            _context.Achievements.Remove(achievement);
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Achievement deleted successfully" });
        }

        [HttpPut("projects/{projectId}")]
        public async Task<IActionResult> UpdateProject(int projectId, [FromBody] ProjectUpdateDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students.FirstOrDefaultAsync(s => s.UserId == userId);
            if (student == null)
                return NotFound("Student not found.");

            var project = await _context.Projects
                .Include(p => p.StudentProjects)
                .FirstOrDefaultAsync(p => p.ProjectId == projectId);

            if (project == null)
                return NotFound("Project not found.");

            // Check if student is the creator
            var studentProject = project.StudentProjects
                .FirstOrDefault(sp => sp.StudentId == student.StudentId && sp.IsCreator);

            if (studentProject == null)
                return Forbid("Only the project creator can edit this project.");

            // Update project fields
            if (!string.IsNullOrWhiteSpace(dto.Title))
                project.Title = dto.Title;

            if (!string.IsNullOrWhiteSpace(dto.Description))
                project.Description = dto.Description;

            if (!string.IsNullOrWhiteSpace(dto.Skills))
                project.Skills = dto.Skills;

            if (dto.Type.HasValue)
                project.Type = dto.Type.Value;

            if (!string.IsNullOrWhiteSpace(dto.ClientName))
                project.ClientName = dto.ClientName;

            if (!string.IsNullOrWhiteSpace(dto.Supervisor))
                project.Supervisor = dto.Supervisor;

            if (!string.IsNullOrWhiteSpace(dto.DemoUrl))
                project.DemoUrl = dto.DemoUrl;

            if (!string.IsNullOrWhiteSpace(dto.GitHubUrl))
                project.GitHubUrl = dto.GitHubUrl;

            if (dto.StartDate.HasValue)
                project.StartDate = dto.StartDate.Value;

            if (dto.EndDate.HasValue)
                project.EndDate = dto.EndDate.Value;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Project updated successfully",
                Project = new
                {
                    project.ProjectId,
                    project.Title,
                    project.Type,
                    project.Description,
                    project.Skills,
                    project.ClientName,
                    project.Supervisor,
                    project.DemoUrl,
                    project.GitHubUrl,
                    project.StartDate,
                    project.EndDate
                }
            });
        }
        [HttpPut("profile-pic")]
        public async Task<IActionResult> UpdateProfilePic([FromForm] FileUploadDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim))
                return Unauthorized("User ID not found in token.");

            if (!int.TryParse(userIdClaim, out int userId))
                return BadRequest("Invalid user ID format in token.");

            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            var file = dto.File;

            if (file == null || file.Length == 0)
                return BadRequest(new { Code = "NO_FILE", Message = "No file uploaded." });

            // ✅ FILE SIZE VALIDATION: Max 1MB
            const long MAX_FILE_SIZE = 1048576; // 1MB in bytes
            if (file.Length > MAX_FILE_SIZE)
            {
                return BadRequest(new
                {
                    Code = "FILE_TOO_LARGE",
                    Message = "Profile picture must not exceed 1MB.",
                    FileSizeInMB = Math.Round(file.Length / (1024.0 * 1024.0), 2),
                    AllowedSizeInMB = 1,
                    Suggestion = "Please resize the image and try again."
                });
            }

            // ✅ VALIDATE FILE TYPE
            var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp" };
            var fileExtension = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (!allowedExtensions.Contains(fileExtension))
            {
                return BadRequest(new
                {
                    Code = "INVALID_FILE_TYPE",
                    Message = "Invalid file type. Only JPG, JPEG, PNG, and WEBP are allowed.",
                    AllowedTypes = allowedExtensions
                });
            }

            // Delete old profile picture if it exists
            if (!string.IsNullOrWhiteSpace(student.ProfilePicUrl))
            {
                var oldFileName = student.ProfilePicUrl.Split('/').Last();
                var oldUploadsFolder = Path.Combine("uploads", "student", "profilepics");
                var oldFilePath = Path.Combine(oldUploadsFolder, oldFileName);

                if (System.IO.File.Exists(oldFilePath))
                {
                    try
                    {
                        System.IO.File.Delete(oldFilePath);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning("Failed to delete old profile picture: {Error}", ex.Message);
                    }
                }
            }

            // Upload new profile picture
            var uploadsFolder = Path.Combine("uploads", "student", "profilepics");
            Directory.CreateDirectory(uploadsFolder);

            var fileName = $"{student.RegistrationNo}_{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
            var filePath = Path.Combine(uploadsFolder, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            student.ProfilePicUrl = $"/uploads/student/profilepics/{fileName}";
            student.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new 
            { 
                Code = "SUCCESS",
                Message = "Profile picture updated successfully.", 
                ProfilePicUrl = student.ProfilePicUrl,
                FileSizeInMB = Math.Round(file.Length / (1024.0 * 1024.0), 2)
            });
        }

        [HttpPost("name")]
        public async Task<IActionResult> AddName([FromBody] NameDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim))
                return Unauthorized("User ID not found in token.");

            if (!int.TryParse(userIdClaim, out int userId))
                return BadRequest("Invalid user ID format in token.");


            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            if (string.IsNullOrWhiteSpace(dto.FullName))
                return BadRequest("Full name is required.");

            student.User.FullName = dto.FullName.Trim();
            student.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Name added successfully.", FullName = student.User.FullName });
        }

        [HttpPut("name")]
        public async Task<IActionResult> UpdateName([FromBody] NameDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim))
                return Unauthorized("User ID not found in token.");

            if (!int.TryParse(userIdClaim, out int userId))
                return BadRequest("Invalid user ID format in token.");

            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            if (string.IsNullOrWhiteSpace(dto.FullName))
                return BadRequest("Full name is required.");

            student.User.FullName = dto.FullName.Trim();
            student.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Name updated successfully.", FullName = student.User.FullName });
        }

        [HttpGet("name")]
        public async Task<IActionResult> GetName()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim))
                return Unauthorized("User ID not found in token.");

            if (!int.TryParse(userIdClaim, out int userId))
                return BadRequest("Invalid user ID format in token.");

            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            return Ok(new { FullName = student.User.FullName });
        }

        [HttpGet("interviews/scheduled")]
        public async Task<IActionResult> GetScheduledInterviews()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId)) return Unauthorized();

            var student = await _context.Students.FirstOrDefaultAsync(s => s.UserId == userId);
            if (student == null) return NotFound("Student not found.");

            // 1. Get Active Job Fair
            var activeJobFairId = await _context.JobFairs
                .Where(j => j.IsActive)
                .Select(j => j.JobFairId)
                .FirstOrDefaultAsync();

            if (activeJobFairId == 0) return NotFound("No active job fair.");

            var interviews = await _context.Interviews
                .Include(i => i.Company)
                    .ThenInclude(c => c.Room) // Fixed the Include chain here as well
                .Where(i => i.StudentId == student.StudentId && i.JobFairId == activeJobFairId) // 🟢 Added Filter
                .OrderBy(i => i.ScheduledTime)
                .Select(i => new
                {
                    i.InterviewId,
                    CompanyId = i.CompanyId,
                    CompanyName = i.Company.Name,
                    CompanyLogo = i.Company.LogoUrl,
                    ScheduledTime = i.ScheduledTime,
                    StartedAt = i.StartedAt,
                    EndedAt = i.EndedAt,
                    DurationMinutes = i.Company.InterviewDurationMinutes,
                    Room = i.Company.Room != null ? i.Company.Room.RoomName : "TBD",
                    Status = i.Status.ToString()
                })
                .ToListAsync();

            return Ok(interviews);
        } // -----------------------------

        [HttpPost("interviews/{interviewId}/notify-company")]
        public async Task<IActionResult> NotifyCompanyForQueuedInterview(int interviewId, [FromBody] StudentInterviewQueueNotificationDto dto)
        {
            if (dto == null || string.IsNullOrWhiteSpace(dto.Type))
                return BadRequest("Type is required.");

            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId)) return Unauthorized();

            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.UserId == userId);
            if (student == null) return NotFound("Student not found.");

            var interview = await _context.Interviews
                .Include(i => i.Company)
                    .ThenInclude(c => c.User)
                .FirstOrDefaultAsync(i => i.InterviewId == interviewId && i.StudentId == student.StudentId);

            if (interview == null)
                return NotFound("Interview not found.");

            if (interview.Status != InterviewStatus.Queued && interview.Status != InterviewStatus.InProgress)
                return BadRequest("Notification is allowed only for queued or in-progress interviews.");

            if (!interview.ScheduledTime.HasValue)
                return BadRequest("Interview is not scheduled yet.");

            var minutesLeft = (interview.ScheduledTime.Value - DateTime.UtcNow).TotalMinutes;
            if (minutesLeft > 5)
                return BadRequest("This quick notification is only available within 5 minutes of interview time.");

            var normalizedType = dto.Type.Trim().ToLowerInvariant();
            string title;
            string body;
            string eventType;

            switch (normalizedType)
            {
                case "studentarrivingsoon":
                case "iamcoming":
                case "coming":
                    title = "Student Is On The Way";
                    body = $"{student.User.FullName} is on the way and expects to arrive in a few minutes.";
                    eventType = "StudentArrivingSoon";
                    break;

                case "studentreschedulerequest":
                case "requestreschedule":
                case "reschedule":
                    title = "Reschedule Request";
                    body = $"{student.User.FullName} requested to reschedule the interview timing.";
                    eventType = "StudentRescheduleRequest";
                    break;

                default:
                    return BadRequest("Type must be one of: StudentArrivingSoon, StudentRescheduleRequest.");
            }

            var pushSent = false;
            var emailSent = false;

            if (!string.IsNullOrWhiteSpace(interview.Company?.FcmToken))
            {
                try
                {
                    var message = new Message
                    {
                        Token = interview.Company.FcmToken,
                        Notification = new FirebaseAdmin.Messaging.Notification
                        {
                            Title = title,
                            Body = body
                        },
                        Data = new Dictionary<string, string>
                        {
                            { "Type", eventType },
                            { "InterviewId", interview.InterviewId.ToString() },
                            { "CompanyId", interview.CompanyId.ToString() },
                            { "StudentId", student.StudentId.ToString() },
                            { "StudentName", student.User.FullName ?? "Student" }
                        }
                    };

                    await FirebaseMessaging.DefaultInstance.SendAsync(message);
                    pushSent = true;
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to send student queue push notification. InterviewId={InterviewId}", interview.InterviewId);
                }
            }

            var companyEmail = interview.Company?.User?.Email;
            if (!string.IsNullOrWhiteSpace(companyEmail))
            {
                try
                {
                    var emailBody = $@"
<p>Dear {interview.Company?.Name},</p>
<p>{body}</p>
<p><strong>Interview ID:</strong> {interview.InterviewId}</p>
<p>Regards,<br/>COMSATS Job Fair Team</p>";

                    await _mailService.SendMailAsync(companyEmail, title, emailBody);
                    emailSent = true;
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to send student queue email notification. InterviewId={InterviewId}", interview.InterviewId);
                }
            }

            return Ok(new
            {
                Message = "Notification processed.",
                interview.InterviewId,
                Type = eventType,
                PushSent = pushSent,
                EmailSent = emailSent
            });
        }

        [HttpGet("companies")]
        public async Task<IActionResult> GetAvailableCompanies(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 8)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId)) return Unauthorized();

            page = Math.Max(page, 1);
            pageSize = Math.Clamp(pageSize, 1, 50);

            var student = await _context.Students.FirstOrDefaultAsync(s => s.UserId == userId);
            if (student == null) return NotFound("Student not found.");

            // 1. Find Active Job Fair
            var activeJobFair = await _context.JobFairs.AsNoTracking().FirstOrDefaultAsync(j => j.IsActive);
            if (activeJobFair == null) return NotFound("No active job fair found.");

            // 2. Verify Student Participation
            var isParticipant = await _context.StudentJobFairParticipations
                .AnyAsync(p => p.StudentId == student.StudentId && p.JobFairId == activeJobFair.JobFairId);

            if (!isParticipant)
                return BadRequest("You are not registered for the current job fair. Please join via the dashboard.");

            // 3. Fetch Companies via Participation Table
            var companies = await _context.CompanyJobFairParticipations
                .Where(p => p.JobFairId == activeJobFair.JobFairId)
                .Include(p => p.Company)
                    .ThenInclude(c => c.Jobs.Where(j => j.JobFairId == activeJobFair.JobFairId)) // Filter jobs by fair
                .Include(p => p.Company)
                    .ThenInclude(c => c.InterviewRequests.Where(ir => ir.StudentId == student.StudentId && ir.JobFairId == activeJobFair.JobFairId))
                .Select(p => new
                {
                    p.Company.CompanyId,
                    p.Company.Name,
                    p.Company.Industry,
                    p.Company.LogoUrl,
                    p.Company.Website,
                    JobCount = _context.Jobs.Count(j => j.CompanyId == p.CompanyId && j.JobFairId == activeJobFair.JobFairId),
                    OpenPositions = _context.Jobs
                        .Where(j => j.CompanyId == p.CompanyId && j.JobFairId == activeJobFair.JobFairId)
                        .Sum(j => (int?)j.NumberOfJobs) ?? 0,
                    InterviewRequestStatus = p.Company.InterviewRequests
                        .Select(ir => ir.Status.ToString())
                        .FirstOrDefault() ?? "None",
                    CanRequestInterview = !p.Company.InterviewRequests.Any(),
                    IsWalkInInterviewing = p.IsPresent
                        && p.Company.IsWalkInInterviewing
                        && IsWithinWalkInWindow(activeJobFair.date, DateTime.UtcNow)
                })
                .ToListAsync();

            var totalCompanies = companies.Count;
            var totalPages = Math.Max(1, (int)Math.Ceiling(totalCompanies / (double)pageSize));
            var pagedCompanies = companies
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList();

            return Ok(new
            {
                JobFair = activeJobFair.Semester,
                TotalCompanies = totalCompanies,
                Page = page,
                PageSize = pageSize,
                TotalPages = totalPages,
                Companies = pagedCompanies
            });
        }

        [HttpGet("companies/search")]
        public async Task<IActionResult> SearchCompanies(
            [FromQuery] string? keyword,
            [FromQuery] string? industries = null,
            [FromQuery] bool onlyHiring = false,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 8)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId)) return Unauthorized();

            page = Math.Max(page, 1);
            pageSize = Math.Clamp(pageSize, 1, 50);

            var student = await _context.Students.FirstOrDefaultAsync(s => s.UserId == userId);
            if (student == null) return NotFound("Student not found.");

            var activeJobFair = await _context.JobFairs.AsNoTracking().FirstOrDefaultAsync(j => j.IsActive);
            if (activeJobFair == null) return NotFound("No active job fair found.");

            var isParticipant = await _context.StudentJobFairParticipations
                .AnyAsync(p => p.StudentId == student.StudentId && p.JobFairId == activeJobFair.JobFairId);

            if (!isParticipant)
                return BadRequest("You are not registered for the current job fair. Please join via the dashboard.");

            var companiesQuery = _context.CompanyJobFairParticipations
                .Where(p => p.JobFairId == activeJobFair.JobFairId)
                .Include(p => p.Company)
                    .ThenInclude(c => c.Jobs.Where(j => j.JobFairId == activeJobFair.JobFairId))
                .Include(p => p.Company)
                    .ThenInclude(c => c.InterviewRequests.Where(ir => ir.StudentId == student.StudentId && ir.JobFairId == activeJobFair.JobFairId))
                .AsQueryable();

            var participatingCompanies = await companiesQuery
                .ToListAsync();

            if (!string.IsNullOrWhiteSpace(keyword))
            {
                var lowerKeyword = keyword.Trim().ToLowerInvariant();
                participatingCompanies = participatingCompanies
                    .Where(p =>
                        (p.Company.Name ?? string.Empty).ToLowerInvariant().Contains(lowerKeyword) ||
                        (p.Company.Industry ?? string.Empty).ToLowerInvariant().Contains(lowerKeyword) ||
                        (p.Company.Jobs ?? new List<Job>()).Any(j =>
                            (j.JobTitle ?? string.Empty).ToLowerInvariant().Contains(lowerKeyword) ||
                            (j.JobDescription ?? string.Empty).ToLowerInvariant().Contains(lowerKeyword) ||
                            (j.RequiredSkills ?? Array.Empty<string>()).Any(skill =>
                                !string.IsNullOrWhiteSpace(skill) &&
                                skill.ToLowerInvariant().Contains(lowerKeyword)))
                    )
                    .ToList();
            }

            var companies = participatingCompanies
                .Select(p => new
                {
                    p.Company.CompanyId,
                    p.Company.Name,
                    p.Company.Industry,
                    p.Company.LogoUrl,
                    p.Company.Website,
                    JobCount = _context.Jobs.Count(j => j.CompanyId == p.CompanyId && j.JobFairId == activeJobFair.JobFairId),
                    OpenPositions = _context.Jobs
                        .Where(j => j.CompanyId == p.CompanyId && j.JobFairId == activeJobFair.JobFairId)
                        .Sum(j => (int?)j.NumberOfJobs) ?? 0,
                    InterviewRequestStatus = p.Company.InterviewRequests
                        .Select(ir => ir.Status.ToString())
                        .FirstOrDefault() ?? "None",
                    CanRequestInterview = !p.Company.InterviewRequests.Any(),
                    IsWalkInInterviewing = p.IsPresent
                        && p.Company.IsWalkInInterviewing
                        && IsWithinWalkInWindow(activeJobFair.date, DateTime.UtcNow)
                })
                .Where(c => !onlyHiring || c.JobCount > 0)
                .ToList();

            if (!string.IsNullOrWhiteSpace(industries))
            {
                var allowedIndustries = industries
                    .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                    .ToHashSet(StringComparer.OrdinalIgnoreCase);

                companies = companies
                    .Where(c => string.IsNullOrWhiteSpace(c.Industry) || allowedIndustries.Contains(c.Industry))
                    .ToList();
            }

            if (companies.Count == 0)
            {
                return NotFound("No companies found matching your criteria.");
            }

            var totalCompanies = companies.Count;
            var totalPages = Math.Max(1, (int)Math.Ceiling(totalCompanies / (double)pageSize));
            var pagedCompanies = companies
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList();

            return Ok(new
            {
                JobFair = activeJobFair.Semester,
                TotalCompanies = totalCompanies,
                Page = page,
                PageSize = pageSize,
                TotalPages = totalPages,
                Companies = pagedCompanies
            });
        }

        // -----------------------------
        // Get All Jobs (Active Fair Only)
        // -----------------------------
        [HttpGet("jobs")]
        public async Task<IActionResult> GetAllJobs(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 6)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId)) return Unauthorized();

            page = Math.Max(page, 1);
            pageSize = Math.Clamp(pageSize, 1, 50);

            // 1. Get Active Fair
            var activeJobFairId = await _context.JobFairs
                .Where(j => j.IsActive)
                .Select(j => j.JobFairId)
                .FirstOrDefaultAsync();

            if (activeJobFairId == 0)
            {
                return Ok(new
                {
                    JobFairId = 0,
                    TotalJobs = 0,
                    Jobs = new List<object>(),
                    Message = "No active job fair."
                });
            }

            // 2. Filter Jobs by Active Fair
            var jobs = await _context.Jobs
                .Include(j => j.Company)
                .Where(j => j.JobFairId == activeJobFairId)
                .Where(j => _context.CompanyJobFairParticipations
                    .Any(p => p.JobFairId == activeJobFairId && p.CompanyId == j.CompanyId))
                .Select(j => new
                {
                    j.JobId,
                    j.JobTitle,
                    j.JobDescription,
                    j.RequiredSkills,
                    j.JobType,
                    j.NumberOfJobs,
                    Company = new
                    {
                        j.Company.CompanyId,
                        j.Company.Name,
                        j.Company.Industry,
                        j.Company.LogoUrl,
                        j.Company.Website,
                        j.Company.CompanyEmail,
                        j.Company.CompanyPhone
                    }
                })
                .ToListAsync();

            var totalJobs = jobs.Count;
            var totalPages = Math.Max(1, (int)Math.Ceiling(totalJobs / (double)pageSize));
            var pagedJobs = jobs
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList();

            if (jobs.Count == 0)
            {
                return Ok(new
                {
                    JobFairId = activeJobFairId,
                    TotalJobs = 0,
                    Page = page,
                    PageSize = pageSize,
                    TotalPages = 1,
                    Jobs = new List<object>(),
                    Message = "No jobs available for your job fair."
                });
            }

            return Ok(new
            {
                JobFairId = activeJobFairId,
                TotalJobs = totalJobs,
                Page = page,
                PageSize = pageSize,
                TotalPages = totalPages,
                Jobs = pagedJobs
            });
        }
        [HttpGet("jobs/search")]
        public async Task<IActionResult> SearchJobs(
            [FromQuery] string? keyword,
            [FromQuery] string? jobTypes = null,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 6)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId)) return Unauthorized();

            page = Math.Max(page, 1);
            pageSize = Math.Clamp(pageSize, 1, 50);

            var activeJobFairId = await _context.JobFairs
                .Where(j => j.IsActive)
                .Select(j => j.JobFairId)
                .FirstOrDefaultAsync();

            if (activeJobFairId == 0) return NotFound("No active job fair.");

            var jobsQuery = _context.Jobs
                .Include(j => j.Company)
                .Where(j => j.JobFairId == activeJobFairId)
                .Where(j => _context.CompanyJobFairParticipations
                    .Any(p => p.JobFairId == activeJobFairId && p.CompanyId == j.CompanyId));

            if (!string.IsNullOrWhiteSpace(keyword))
            {
                var lowerKeyword = keyword.ToLower();
                jobsQuery = jobsQuery.Where(j =>
                    j.JobTitle.ToLower().Contains(lowerKeyword) ||
                    (j.JobDescription != null && j.JobDescription.ToLower().Contains(lowerKeyword))
                );
            }

            if (!string.IsNullOrWhiteSpace(jobTypes))
            {
                var allowedJobTypes = jobTypes
                    .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                    .Select(value => Enum.TryParse<JobType>(value, true, out var parsed) ? parsed : (JobType?)null)
                    .Where(value => value.HasValue)
                    .Select(value => value!.Value)
                    .ToHashSet();

                if (allowedJobTypes.Count > 0)
                {
                    jobsQuery = jobsQuery.Where(j => allowedJobTypes.Contains(j.JobType));
                }
            }

            var jobs = await jobsQuery
                .Select(j => new
                {
                    j.JobId,
                    j.JobTitle,
                    j.JobDescription,
                    j.RequiredSkills,
                    j.JobType,
                    j.NumberOfJobs,
                    Company = new
                    {
                        j.Company.CompanyId,
                        j.Company.Name,
                        j.Company.Industry,
                        j.Company.LogoUrl,
                        j.Company.Website,
                        j.Company.CompanyEmail,
                        j.Company.CompanyPhone
                    }
                })
                .ToListAsync();

            if (jobs.Count == 0)
                return NotFound("No jobs found matching your criteria.");

            var totalJobs = jobs.Count;
            var totalPages = Math.Max(1, (int)Math.Ceiling(totalJobs / (double)pageSize));
            var pagedJobs = jobs
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList();

            return Ok(new
            {
                JobFairId = activeJobFairId,
                TotalJobs = totalJobs,
                Page = page,
                PageSize = pageSize,
                TotalPages = totalPages,
                Jobs = pagedJobs
            });
        }

        // -----------------------------
        // Get Jobs By Company (Active Fair Only)
        // -----------------------------
        [HttpGet("jobs/by-company/{companyId}")]
        public async Task<IActionResult> GetJobsByCompany(int companyId)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId)) return Unauthorized();

            var activeJobFairId = await _context.JobFairs
                .Where(j => j.IsActive)
                .Select(j => j.JobFairId)
                .FirstOrDefaultAsync();

            if (activeJobFairId == 0) return NotFound("No active job fair.");

            // Check if company is participating in the active fair
            var isParticipating = await _context.CompanyJobFairParticipations
                .AnyAsync(p => p.CompanyId == companyId && p.JobFairId == activeJobFairId);

            if (!isParticipating)
                return NotFound("Company not found in the current job fair.");


            var company = await _context.Companies
                .FirstOrDefaultAsync(c => c.CompanyId == companyId && c.JobFairParticipations.Any(p => p.JobFairId == activeJobFairId));

            var jobs = await _context.Jobs
                .Where(j => j.CompanyId == companyId && j.JobFairId == activeJobFairId)
                .Select(j => new
                {
                    j.JobId,
                    j.JobTitle,
                    j.JobDescription,
                    j.RequiredSkills,
                    j.JobType,
                    j.NumberOfJobs,
                    Company = new
                    {
                        j.Company.CompanyId,
                        j.Company.Name,
                        j.Company.Industry,
                        j.Company.LogoUrl
                    }
                })
                .ToListAsync();

            if (jobs.Count == 0)
                return NotFound("No jobs available for this company in the current fair.");

            return Ok(new
            {
                CompanyId = companyId,
                CompanyName = company?.Name,
                TotalJobs = jobs.Count,
                Jobs = jobs
            });
        }


        // -----------------------------
        // Get Company Profile (Active Fair Context)
        // -----------------------------
        [HttpGet("companies/{companyId}")]
        public async Task<IActionResult> GetCompanyProfile(int companyId)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId)) return Unauthorized();

            var student = await _context.Students.FirstOrDefaultAsync(s => s.UserId == userId);
            if (student == null) return NotFound("Student not found.");

            var activeJobFair = await _context.JobFairs.AsNoTracking().FirstOrDefaultAsync(j => j.IsActive);
            if (activeJobFair == null) return NotFound("No active job fair found.");

            // Fetch Company Participation
            var participation = await _context.CompanyJobFairParticipations
                .Include(p => p.Company)
                    .ThenInclude(c => c.User)
                .Include(p => p.Room)
                .Include(p => p.Company)
                    .ThenInclude(c => c.CompanyContactLinks)
                .Include(p => p.Company)
                    .ThenInclude(c => c.Jobs.Where(j => j.JobFairId == activeJobFair.JobFairId))
                .Include(p => p.Company)
                    .ThenInclude(c => c.InterviewRequests.Where(ir => ir.StudentId == student.StudentId && ir.JobFairId == activeJobFair.JobFairId))
                .FirstOrDefaultAsync(p => p.CompanyId == companyId && p.JobFairId == activeJobFair.JobFairId);

            if (participation == null)
                return NotFound("Company not found in the current job fair.");

            var company = participation.Company;
            var interviewRequest = company.InterviewRequests.FirstOrDefault();
            var latestInterview = await _context.Interviews
                .Where(i => i.StudentId == student.StudentId && i.CompanyId == companyId && i.JobFairId == activeJobFair.JobFairId)
                .OrderByDescending(i => i.UpdatedAt)
                .FirstOrDefaultAsync();

            var companyProfile = new
            {
                company.CompanyId,
                company.Name,
                company.Description,
                company.Industry,
                company.LogoUrl,
                company.Website,
                company.Address,
                CompanyContact = new
                {
                    Email = company.CompanyEmail,
                    Phone = company.CompanyPhone,
                    FocalPersonName = company.FocalPersonName,
                    FocalPersonEmail = company.FocalPersonEmail,
                    FocalPersonPhone = company.FocalPersonPhone
                },
                company.InterviewDurationMinutes,
                company.RepsCount,
                ContactLinks = company.CompanyContactLinks.Select(cl => new
                {
                    cl.LinkId,
                    Platform = cl.Platform.ToString(),
                    cl.Url
                }).ToList(),
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
                UniqueSkillsRequired = company.Jobs
                    .Where(j => j.RequiredSkills != null)
                    .SelectMany(j => j.RequiredSkills!)
                    .Distinct()
                    .ToList(),
                InterviewRequest = interviewRequest != null ? new
                {
                    RequestId = interviewRequest.RequestId,
                    Status = interviewRequest.Status.ToString(),
                    RequestedBy = interviewRequest.RequestedBy.ToString(),
                    CurrentInterviewStatus = latestInterview?.Status.ToString(),
                    InterviewScheduledTime = latestInterview?.ScheduledTime,
                    InterviewRoom = participation.Room != null ? participation.Room.RoomName : null,
                    ReasonForReject = interviewRequest.ReasonForReject,
                    RequestDate = interviewRequest.CreatedAt,
                    ResponseDate = interviewRequest.UpdatedAt,
                    IsPending = interviewRequest.Status == RequestStatus.Pending,
                    CanAccept = interviewRequest.Status == RequestStatus.Pending && interviewRequest.RequestedBy == RequestedBy.Company,
                    CanReject = interviewRequest.Status == RequestStatus.Pending && interviewRequest.RequestedBy == RequestedBy.Company,
                    CanWithdraw = interviewRequest.Status == RequestStatus.Pending && interviewRequest.RequestedBy == RequestedBy.Student,
                    StatusMessage = interviewRequest.RequestedBy == RequestedBy.Student
                        ? $"You sent a request on {interviewRequest.CreatedAt:MMM dd, yyyy}"
                        : $"{company.Name} sent you a request on {interviewRequest.CreatedAt:MMM dd, yyyy}",
                } : null,
                LatestInterview = latestInterview != null ? new
                {
                    latestInterview.InterviewId,
                    Status = latestInterview.Status.ToString(),
                    latestInterview.ScheduledTime,
                    latestInterview.StartedAt,
                    latestInterview.EndedAt,
                    Room = participation.Room != null ? participation.Room.RoomName : null
                } : null,
                CanRequestInterview = interviewRequest == null && latestInterview == null,
                IsWalkInInterviewing = participation.IsPresent
                    && company.IsWalkInInterviewing
                    && IsWithinWalkInWindow(activeJobFair.date, DateTime.UtcNow),
                IsInterviewWindowOpen = !HasInterviewCutoffPassed(activeJobFair.date, DateTime.UtcNow),
                InterviewCutoffLocal = activeJobFair.date.Date.Add(InterviewCutoffLocal),
                company.CreatedAt,
                company.UpdatedAt
            };

            return Ok(new { company = companyProfile });
        }

        // -----------------------------
        // Send Interview Request (Active Fair Context)
        // -----------------------------
        [HttpPost("interview-requests/send")]
        public async Task<IActionResult> SendInterviewRequest([FromBody] SendInterviewRequestDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId)) return Unauthorized();

            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null) return NotFound("Student not found.");

            var activeJobFair = await _context.JobFairs.AsNoTracking().FirstOrDefaultAsync(j => j.IsActive);
            if (activeJobFair == null) return BadRequest("No active job fair.");
            if (HasInterviewCutoffPassed(activeJobFair.date, DateTime.UtcNow))
                return BadRequest("Job Fair has ended.");

            // Validate Student Participation
            var isStudentParticipating = await _context.StudentJobFairParticipations
                .AnyAsync(p => p.StudentId == student.StudentId && p.JobFairId == activeJobFair.JobFairId);
            if (!isStudentParticipating) return BadRequest("You are not registered for the current job fair.");

            // Validate Company Participation
            var companyParticipation = await _context.CompanyJobFairParticipations
                .Include(p => p.Company)
                .FirstOrDefaultAsync(p => p.CompanyId == dto.CompanyId && p.JobFairId == activeJobFair.JobFairId);

            if (companyParticipation == null) return NotFound("Company not found in the current job fair.");

            // Check existing request
            var existingRequest = await _context.InterviewRequests
                .AnyAsync(r => r.StudentId == student.StudentId &&
                               r.CompanyId == dto.CompanyId &&
                               r.JobFairId == activeJobFair.JobFairId &&
                               r.Status == RequestStatus.Pending);

            if (existingRequest)
                return BadRequest("You already have a pending interview request with this company.");

            var interviewRequest = new InterviewRequest
            {
                CompanyId = dto.CompanyId,
                StudentId = student.StudentId,
                JobFairId = activeJobFair.JobFairId,
                Status = RequestStatus.Pending,
                RequestedBy = RequestedBy.Student,
                CreatedAt = DateTime.UtcNow
            };

            _context.InterviewRequests.Add(interviewRequest);
            await _context.SaveChangesAsync();

            // FCM Notification
            if (!string.IsNullOrWhiteSpace(companyParticipation.Company.FcmToken))
            {
                try
                {
                    var message = new Message
                    {
                        Token = companyParticipation.Company.FcmToken,
                        Notification = new FirebaseAdmin.Messaging.Notification
                        {
                            Title = "New Interview Request",
                            Body = $"{student.User.FullName} has requested an interview with your company."
                        },
                        Data = new Dictionary<string, string>
                        {
                            { "RequestId", interviewRequest.RequestId.ToString() },
                            { "StudentId", student.StudentId.ToString() },
                            { "StudentName", student.User.FullName ?? "Unknown" },
                            { "StudentRegistration", student.RegistrationNo },
                            { "Type", "InterviewRequest" }
                        }
                    };
                    await FirebaseMessaging.DefaultInstance.SendAsync(message);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning($"Failed to send FCM: {ex.Message}");
                }
            }

            return Ok(new
            {
                Message = "Interview request sent successfully.",
                RequestId = interviewRequest.RequestId,
                CompanyName = companyParticipation.Company.Name,
                Status = interviewRequest.Status.ToString()
            });
        }

        private static bool HasInterviewCutoffPassed(DateTime jobFairDateUtc, DateTime currentUtc)
        {
            var nowLocal = TimeZoneInfo.ConvertTimeFromUtc(DateTime.SpecifyKind(currentUtc, DateTimeKind.Utc), JobFairTimeZone);
            var fairLocalDate = TimeZoneInfo.ConvertTimeFromUtc(DateTime.SpecifyKind(jobFairDateUtc, DateTimeKind.Utc), JobFairTimeZone).Date;

            if (nowLocal.Date > fairLocalDate)
                return true;

            return nowLocal.Date == fairLocalDate && nowLocal.TimeOfDay > InterviewCutoffLocal;
        }

        private static bool IsWithinWalkInWindow(DateTime jobFairDateUtc, DateTime currentUtc)
        {
            var currentLocal = TimeZoneInfo.ConvertTimeFromUtc(DateTime.SpecifyKind(currentUtc, DateTimeKind.Utc), JobFairTimeZone);
            var fairLocalDate = TimeZoneInfo.ConvertTimeFromUtc(DateTime.SpecifyKind(jobFairDateUtc, DateTimeKind.Utc), JobFairTimeZone).Date;

            if (currentLocal.Date != fairLocalDate)
                return false;

            var localTime = currentLocal.TimeOfDay;
            return localTime >= WalkInStartLocal && localTime <= WalkInEndLocal;
        }

        private static TimeZoneInfo ResolveJobFairTimeZone()
        {
            try
            {
                return TimeZoneInfo.FindSystemTimeZoneById("Pakistan Standard Time");
            }
            catch
            {
                try
                {
                    return TimeZoneInfo.FindSystemTimeZoneById("Asia/Karachi");
                }
                catch
                {
                    return TimeZoneInfo.Utc;
                }
            }
        }

        // -----------------------------
        // Student Dashboard (Fixed Include Error & Updated Logic)
        // -----------------------------
        [HttpGet("dashboard")]
        public async Task<IActionResult> GetStudentDashboard()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId)) return Unauthorized();

            // 1. Fetch Active Job Fair
            var activeJobFair = await _context.JobFairs.AsNoTracking().FirstOrDefaultAsync(j => j.IsActive);
            var activeJobFairId = activeJobFair?.JobFairId;

            // 2. Fetch Student with InterviewRequests (Filtered by Active Fair)
            var studentQuery = _context.Students
                .Include(s => s.User)
                .Include(s => s.Educations)
                .Include(s => s.StudentProjects)
                .AsQueryable();

            if (activeJobFairId.HasValue)
            {
                studentQuery = studentQuery
                    .Include(s => s.InterviewRequests.Where(ir => ir.JobFairId == activeJobFairId.Value))
                    .ThenInclude(ir => ir.Company);
            }
            else
            {
                studentQuery = studentQuery
                    .Include(s => s.InterviewRequests)
                    .ThenInclude(ir => ir.Company);
            }

            var student = await studentQuery.FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null) return NotFound("Student not found.");

            // 3. Fetch Interviews for the student in the active fair
            var interviews = new List<Interview>();
            if (activeJobFairId.HasValue)
            {
                interviews = await _context.Interviews
                    .Include(i => i.Company)
                    .Where(i => i.StudentId == student.StudentId && i.JobFairId == activeJobFairId.Value)
                    .OrderBy(i => i.ScheduledTime)
                    .ToListAsync();
            }

            // 4. Dashboard Logic
            bool isRegistered = false;
            int totalCompanies = 0;
            int totalJobs = 0;
            DateTime? currentFairDate = null;
            string? currentFairDay = null;
            int? currentFairDaysUntil = null;

            if (activeJobFair != null)
            {
                isRegistered = await _context.StudentJobFairParticipations
                    .AnyAsync(p => p.StudentId == student.StudentId && p.JobFairId == activeJobFair.JobFairId);

                totalCompanies = await _context.CompanyJobFairParticipations
                    .CountAsync(c => c.JobFairId == activeJobFair.JobFairId);

                totalJobs = await _context.Jobs
                    .CountAsync(j => j.JobFairId == activeJobFair.JobFairId);

                currentFairDate = activeJobFair.date;
                currentFairDay = activeJobFair.date.ToString("dddd");
                currentFairDaysUntil = (activeJobFair.date.Date - DateTime.UtcNow.Date).Days;
            }

            var upcomingBaseDate = activeJobFair?.date.Date ?? DateTime.UtcNow.Date;
            var upcomingJobFair = await _context.JobFairs
                .AsNoTracking()
                .Where(j => (!activeJobFairId.HasValue || j.JobFairId != activeJobFairId.Value) && j.date > upcomingBaseDate)
                .OrderBy(j => j.date)
                .FirstOrDefaultAsync();

            int upcomingTotalCompanies = 0;
            int upcomingTotalJobs = 0;
            bool isRegisteredUpcoming = false;

            if (upcomingJobFair != null)
            {
                upcomingTotalCompanies = await _context.CompanyJobFairParticipations
                    .CountAsync(c => c.JobFairId == upcomingJobFair.JobFairId);

                upcomingTotalJobs = await _context.Jobs
                    .CountAsync(j => j.JobFairId == upcomingJobFair.JobFairId);

                isRegisteredUpcoming = await _context.StudentJobFairParticipations
                    .AnyAsync(p => p.StudentId == student.StudentId && p.JobFairId == upcomingJobFair.JobFairId);
            }

            int score = 0;
            int totalChecks = 5;
            if (!string.IsNullOrWhiteSpace(student.User.FullName)) score++;
            if (!string.IsNullOrWhiteSpace(student.User.Phone)) score++;
            if (student.CGPA > 0) score++;
            if (student.Skills != null && student.Skills.Any()) score++;
            if (student.Educations != null && student.Educations.Any()) score++;
            int completeness = (int)((double)score / totalChecks * 100);

            var interviewRequests = student.InterviewRequests.ToList();

            // Pending Requests (All)
            var pendingRequests = interviewRequests
                .Where(r => r.Status == RequestStatus.Pending)
                .Select(r => new
                {
                    r.RequestId,
                    CompanyName = r.Company.Name,
                    CompanyLogo = r.Company.LogoUrl,
                    RequestedBy = r.RequestedBy.ToString(),
                    Date = r.CreatedAt
                })
                .OrderByDescending(r => r.Date)
                .ToList();

            // Accepted Requests (All)
            var acceptedRequests = interviewRequests
                .Where(r => r.Status == RequestStatus.Accepted)
                .Select(r => new
                {
                    r.RequestId,
                    CompanyName = r.Company.Name,
                    CompanyLogo = r.Company.LogoUrl,
                    Date = r.UpdatedAt
                })
                .OrderByDescending(r => r.Date)
                .ToList();

            // Next Interview
            var nextInterview = interviews
                .Where(i => i.ScheduledTime.HasValue && i.ScheduledTime.Value > DateTime.UtcNow)
                .OrderBy(i => i.ScheduledTime!.Value)
                .Select(i => new
                {
                    i.InterviewId,
                    CompanyName = i.Company.Name,
                    CompanyLogo = i.Company.LogoUrl,
                    ScheduledTime = i.ScheduledTime,
                    Status = i.Status.ToString()
                })
                .FirstOrDefault();

            // All Interviews with Status (Hired, Shortlisted, Rejected, etc.)
            var allInterviews = interviews.Select(i => new
            {
                i.InterviewId,
                CompanyName = i.Company.Name,
                CompanyLogo = i.Company.LogoUrl,
                ScheduledTime = i.ScheduledTime,
                Status = i.Status.ToString()
            }).ToList();

            var recommendedJobs = new List<object>();
            if (activeJobFairId.HasValue && student.Skills != null && student.Skills.Any())
            {
                var fairJobs = await _context.Jobs
                    .Include(j => j.Company)
                    .Where(j => j.JobFairId == activeJobFairId.Value)
                    .Where(j => _context.CompanyJobFairParticipations
                        .Any(p => p.JobFairId == activeJobFairId.Value && p.CompanyId == j.CompanyId))
                    .ToListAsync();

                recommendedJobs = fairJobs
                    .Select(job => new
                    {
                        Job = job,
                        MatchCount = job.RequiredSkills?.Intersect(student.Skills, StringComparer.OrdinalIgnoreCase).Count() ?? 0,
                        MatchedSkills = job.RequiredSkills?.Intersect(student.Skills, StringComparer.OrdinalIgnoreCase).ToList() ?? new List<string>()
                    })
                    .Where(x => x.MatchCount > 0)
                    .OrderByDescending(x => x.MatchCount)
                    .ThenByDescending(x => x.MatchedSkills.Count)
                    .Take(6)
                    .Select(x => (object)new
                    {
                        x.Job.JobId,
                        x.Job.JobTitle,
                        x.Job.JobType,
                        CompanyId = x.Job.CompanyId,
                        CompanyName = x.Job.Company.Name,
                        CompanyLogo = x.Job.Company.LogoUrl,
                        MatchCount = x.MatchCount,
                        MatchedSkills = x.MatchedSkills
                    })
                    .ToList();
            }

            var pendingInvites = student.StudentProjects.Count(sp => sp.Status == ProjectInviteStatus.Pending);

            var notices = new List<object>();
            if (activeJobFair != null)
            {
                notices = await _context.Notices
                    .Where(n => n.JobFairId == activeJobFair.JobFairId &&
                               (n.Audience == NoticeAudience.All || n.Audience == NoticeAudience.Student) &&
                               !n.IsHidden)
                    .OrderByDescending(n => n.CreatedAt)
                    .Take(3)
                    .Select(n => new { n.NoticeId, n.Title, n.CreatedAt, n.Content })
                    .ToListAsync<object>();
            }

            var dashboard = new
            {
                StudentProfile = new
                {
                    Name = student.User.FullName,
                    RegistrationNo = student.RegistrationNo,
                    ProfilePicUrl = student.ProfilePicUrl,
                    Completeness = completeness,
                    IsRegisteredForFair = isRegistered
                },
                MarketOverview = new
                {
                    ActiveFairSemester = activeJobFair?.Semester,
                    TotalCompanies = totalCompanies,
                    TotalJobs = totalJobs,
                    CurrentFairDate = currentFairDate,
                    CurrentFairDay = currentFairDay,
                    CurrentFairDaysUntil = currentFairDaysUntil,
                    UpcomingFair = upcomingJobFair == null ? null : new
                    {
                        Semester = upcomingJobFair.Semester,
                        Date = upcomingJobFair.date,
                        DaysUntil = (upcomingJobFair.date.Date - DateTime.UtcNow.Date).Days,
                        TotalCompanies = upcomingTotalCompanies,
                        TotalJobs = upcomingTotalJobs,
                        IsRegistered = isRegisteredUpcoming
                    }
                },
                ActionsRequired = new
                {
                    PendingInterviewRequestsCount = pendingRequests.Count(r => r.RequestedBy == "Company"),
                    PendingProjectInvitesCount = pendingInvites
                },
                InterviewStats = new
                {
                    PendingRequests = pendingRequests,
                    AcceptedRequests = acceptedRequests,
                    AllInterviews = allInterviews,
                    NextInterview = nextInterview
                },
                RecommendedJobs = recommendedJobs,
                Notices = notices
            };

            return Ok(dashboard);
        }

        [HttpGet("jobs/recommended")]
        public async Task<IActionResult> GetRecommendedJobs()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId)) return Unauthorized();

            var student = await _context.Students.FirstOrDefaultAsync(s => s.UserId == userId);
            if (student == null) return NotFound("Student not found.");

            if (student.Skills == null || !student.Skills.Any())
                return BadRequest("Please add skills to your profile to get recommendations.");

            var activeJobFair = await _context.JobFairs.AsNoTracking().FirstOrDefaultAsync(j => j.IsActive);
            if (activeJobFair == null) return NotFound("No active job fair.");

            // Fetch all jobs for the fair
            var allJobs = await _context.Jobs
                .Include(j => j.Company)
                .Where(j => j.JobFairId == activeJobFair.JobFairId)
                .Where(j => _context.CompanyJobFairParticipations
                    .Any(p => p.JobFairId == activeJobFair.JobFairId && p.CompanyId == j.CompanyId))
                .ToListAsync();

            // In-memory matching
            var recommendations = allJobs
                .Select(job => new
                {
                    Job = job,
                    MatchCount = job.RequiredSkills?.Intersect(student.Skills, StringComparer.OrdinalIgnoreCase).Count() ?? 0,
                    TotalRequired = (job.RequiredSkills != null ? job.RequiredSkills.Length : 0)
                })
                .Where(x => x.MatchCount > 0) // Only show jobs with at least one matching skill
                .OrderByDescending(x => x.MatchCount)
                .Select(x => new
                {
                    CompanyId = x.Job.CompanyId,
                    x.Job.JobId,
                    x.Job.JobTitle,
                    x.Job.JobType,
                    CompanyName = x.Job.Company.Name,
                    CompanyLogo = x.Job.Company.LogoUrl,
                    MatchCount = x.MatchCount,
                    MatchedSkills = x.Job.RequiredSkills?.Intersect(student.Skills, StringComparer.OrdinalIgnoreCase).ToList()
                })
                .Take(10) // Limit to top 10
                .ToList();

            return Ok(recommendations);
        }

        [HttpGet("companies/recommended")]
        public async Task<IActionResult> GetRecommendedCompanies()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId)) return Unauthorized();

            var student = await _context.Students.FirstOrDefaultAsync(s => s.UserId == userId);
            if (student == null) return NotFound("Student not found.");

            if (student.Skills == null || !student.Skills.Any())
                return BadRequest("Please add skills to your profile to get recommendations.");

            var activeJobFair = await _context.JobFairs.AsNoTracking().FirstOrDefaultAsync(j => j.IsActive);
            if (activeJobFair == null) return NotFound("No active job fair.");

            // Fetch participating companies and their active-fair jobs.
            var companiesWithJobs = await _context.CompanyJobFairParticipations
                .Where(p => p.JobFairId == activeJobFair.JobFairId)
                .Include(p => p.Company)
                .ThenInclude(c => c.Jobs.Where(j => j.JobFairId == activeJobFair.JobFairId))
                .AsNoTracking()
                .ToListAsync();

            // Calculate skill matches for each company based on their job requirements
            var recommendations = companiesWithJobs
                .Select(participation => new
                {
                    Company = participation.Company,
                    JobsInCurrentFair = participation.Company.Jobs
                        .Where(j => j.JobFairId == activeJobFair.JobFairId)
                        .ToList()
                })
                .Select(x => new
                {
                    x.Company,
                    MatchCount = x.JobsInCurrentFair
                        .SelectMany(j => j.RequiredSkills ?? new string[] { })
                        .Distinct(StringComparer.OrdinalIgnoreCase)
                        .Intersect(student.Skills, StringComparer.OrdinalIgnoreCase)
                        .Count(),
                    TotalUniqueSkillsRequired = x.JobsInCurrentFair
                        .SelectMany(j => j.RequiredSkills ?? new string[] { })
                        .Distinct(StringComparer.OrdinalIgnoreCase)
                        .Count(),
                    MatchedSkills = x.JobsInCurrentFair
                        .SelectMany(j => j.RequiredSkills ?? new string[] { })
                        .Distinct(StringComparer.OrdinalIgnoreCase)
                        .Intersect(student.Skills, StringComparer.OrdinalIgnoreCase)
                        .ToList(),
                    JobCount = x.JobsInCurrentFair.Count,
                    OpenPositions = x.JobsInCurrentFair.Sum(j => j.NumberOfJobs)
                })
                .Where(x => x.MatchCount > 0) // Only show companies with at least one matching skill
                .OrderByDescending(x => x.MatchCount)
                .Select(x => new
                {
                    x.Company.CompanyId,
                    x.Company.Name,
                    x.Company.Industry,
                    x.Company.LogoUrl,
                    x.Company.Website,
                    MatchCount = x.MatchCount,
                    TotalSkillsRequired = x.TotalUniqueSkillsRequired,
                    JobCount = x.JobCount,
                    OpenPositions = x.OpenPositions,
                    OpenJobs = x.JobCount,
                    MatchedSkills = x.MatchedSkills
                })
                .Take(10) // Limit to top 10
                .ToList();

            return Ok(recommendations);
        }



        [HttpGet("notices")]
        [Authorize] // Requires login (Admin, Student, or Company)
        public async Task<IActionResult> GetNotices()
        {
            // 1. Get Active Job Fair
            var activeJobFair = await _context.JobFairs.FirstOrDefaultAsync(j => j.IsActive);
            if (activeJobFair == null)
                return Ok(new List<NoticeResponseDto>()); // Return empty if no event

            // 2. Determine User Role
            var isStudent = User.IsInRole("Student");
            var isCompany = User.IsInRole("Company");
            var isAdmin = User.IsInRole("Admin");

            // 3. Build Query
            var query = _context.Notices
                .Where(n => n.JobFairId == activeJobFair.JobFairId)
                .AsQueryable();

            // 4. Filter based on Visibility & Audience
            if (isAdmin)
            {
                // Admins see everything (both hidden and visible)
            }
            else
            {
                // Everyone else only sees NOT HIDDEN items
                query = query.Where(n => n.IsHidden == false);

                if (isStudent)
                {
                    // Students see "Student" AND "All"
                    query = query.Where(n => n.Audience == NoticeAudience.Student || n.Audience == NoticeAudience.All);
                }
                else if (isCompany)
                {
                    // Companies see "Company" AND "All"
                    query = query.Where(n => n.Audience == NoticeAudience.Company || n.Audience == NoticeAudience.All);
                }
                else
                {
                    // Fallback for unknown roles
                    return Forbid();
                }
            }

            // 5. Execute and Return
            var notices = await query
                .OrderByDescending(n => n.CreatedAt)
                .Select(n => new NoticeResponseDto
                {
                    NoticeId = n.NoticeId,
                    Title = n.Title,
                    Content = n.Content,
                    Audience = n.Audience.ToString(),
                    CreatedAt = n.CreatedAt
                })
                .ToListAsync();

            return Ok(notices);
        }
        [HttpGet("participation-history")]
        public async Task<IActionResult> GetParticipationHistory()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId)) return Unauthorized();

            var student = await _context.Students.FirstOrDefaultAsync(s => s.UserId == userId);
            if (student == null) return NotFound("Student not found.");

            var history = await _context.StudentJobFairParticipations
                .Include(p => p.JobFair)
                .Where(p => p.StudentId == student.StudentId)
                .OrderByDescending(p => p.JobFair.date)
                .Select(p => new
                {
                    p.JobFair.Semester,
                    Date = p.JobFair.date,
                    RegisteredAt = p.RegisteredAt,
                    IsActive = p.JobFair.IsActive
                })
                .ToListAsync();

            return Ok(history);
        }
        [HttpGet("interview-requests")]
        public async Task<IActionResult> GetInterviewRequests([FromQuery] string? status = null)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null) return NotFound("Student not found.");

            // 1. Get Active Job Fair
            var activeJobFairId = await _context.JobFairs
                .Where(j => j.IsActive)
                .Select(j => j.JobFairId)
                .FirstOrDefaultAsync();

            if (activeJobFairId == 0) return NotFound("No active job fair.");

            var requestsQuery = _context.InterviewRequests
                .Include(r => r.Company)
                .Where(r => r.StudentId == student.StudentId && r.JobFairId == activeJobFairId)
                // 🟢 FIX: Ensure the company is actually participating in the current job fair
                .Where(r => _context.CompanyJobFairParticipations
                    .Any(p => p.CompanyId == r.CompanyId && p.JobFairId == activeJobFairId))
                .AsQueryable(); // Ensure queryable for dynamic filtering

            // Filter by status if provided
            if (!string.IsNullOrWhiteSpace(status))
            {
                if (Enum.TryParse<RequestStatus>(status, true, out var statusEnum))
                {
                    requestsQuery = requestsQuery.Where(r => r.Status == statusEnum);
                }
                else
                {
                    return BadRequest("Invalid status. Valid: Pending, Accepted, Rejected");
                }
            }

            var requests = await requestsQuery
                .OrderByDescending(r => r.CreatedAt) // Usually prefer sorting by CreatedAt
                .Select(r => new
                {
                    r.RequestId,
                    CompanyName = r.Company.Name,
                    CompanyId = r.Company.CompanyId,
                    r.Company.LogoUrl,
                    r.Company.Industry,
                    r.Company.Website,
                    Status = r.Status.ToString(),
                    ReasonForReject = r.ReasonForReject,
                    RequestDate = r.CreatedAt,
                    ResponseDate = r.UpdatedAt,
                    RequestedBy = r.RequestedBy.ToString(),
                })
                .ToListAsync();

            // ✅ FIX: Return empty list with 200 OK instead of 404
            return Ok(new
            {
                JobFairId = activeJobFairId,
                TotalRequests = requests.Count,
                Requests = requests
            });
        }

        // Add this method inside the existing StudentController class.

        [HttpPut("cgpa")]
        public async Task<IActionResult> UpdateCgpa([FromBody] UpdateCGPADto dto)
        {
            if (dto == null)
                return BadRequest("Request body is required.");

            // Basic validation: CGPA must be between 0.0 and 4.0
            if (dto.CGPA < 0m || dto.CGPA > 4.0m)
                return BadRequest("CGPA must be between 0.0 and 4.0.");

            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized("Invalid or missing user id in token.");

            var student = await _context.Students.FirstOrDefaultAsync(s => s.UserId == userId);
            if (student == null)
                return NotFound("Student not found.");

            student.CGPA = dto.CGPA;
            student.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "CGPA updated successfully.",
                StudentId = student.StudentId,
                Cgpa = student.CGPA
            });
        }
    }
}