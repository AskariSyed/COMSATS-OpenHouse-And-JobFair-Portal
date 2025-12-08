using FirebaseAdmin.Messaging;
using JobFairPortal.Data;
using JobFairPortal.DTOs;
using JobFairPortal.Models;
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
        
       
        
        public StudentController(JobFairRecruitmentDbContext context, ILogger<StudentController> logger)
        {
            _context = context;
            _logger = logger;
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
                .Include(s=>s.Experiences)
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
                Experiences=student.Experiences.Select(ex=>new {
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
                .FirstOrDefaultAsync(e => e.ExperienceId == experienceId && e.Student.UserId == userId);

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
                .FirstOrDefaultAsync(c => c.CertificationId == certificationId && c.Student.UserId == userId);

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
                .FirstOrDefaultAsync(c => c.CertificationId == certificationId && c.Student.UserId == userId);

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

            return Ok(student.ContactLinks);
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

            return Ok(new { Message = "Contact link added successfully", ContactLink = contactLink });
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
                ContactLink = contactLink
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
                return BadRequest("No file uploaded.");

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

            return Ok(new { Message = "Profile picture uploaded.", ProfilePicUrl = student.ProfilePicUrl });
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
                CGPA = dto.CGPA,
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

            if (dto.CGPA.HasValue)
                education.CGPA = dto.CGPA.Value;

            if (!string.IsNullOrWhiteSpace(dto.Location))
                education.Location = dto.Location;

            await _context.SaveChangesAsync();

            return Ok(new { Message = "Education updated successfully", Education = education });
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
                .FirstOrDefaultAsync(a => a.AchievementId == achievementId && a.Student.UserId == userId);

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
                .FirstOrDefaultAsync(a => a.AchievementId == achievementId && a.Student.UserId == userId);

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
                return BadRequest("No file uploaded.");

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

            return Ok(new { Message = "Profile picture updated successfully.", ProfilePicUrl = student.ProfilePicUrl });
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
        [HttpGet("companies")]
        public async Task<IActionResult> GetAvailableCompanies()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students
                .Include(s => s.InterviewRequests)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            // Get all companies for the job fair the student is registered in
            var companies = await _context.Companies
                .Where(c => c.JobFairId == student.JobFairId)
                .Include(c => c.User)
                .Include(c => c.Jobs)
                .Include(c => c.CompanyContactLinks)
                .Select(c => new
                {
                    c.CompanyId,
                    c.Name,
                    c.Description,
                    c.Industry,
                    c.LogoUrl,
                    c.Website,
                    c.CompanyEmail,
                    c.CompanyPhone,
                    c.Address,
                    FocalPersonName = c.FocalPersonName,
                    FocalPersonEmail = c.FocalPersonEmail,
                    FocalPersonPhone = c.FocalPersonPhone,
                    c.RepsCount,
                    c.InterviewDurationMinutes,
                    c.ArrivalStatus,
                    JobCount = c.Jobs.Count,

                    // --- Interview Request Status ---
                    InterviewRequest = c.InterviewRequests
                        .Where(ir => ir.StudentId == student.StudentId)
                        .Select(ir => new
                        {
                            RequestId = ir.RequestId,
                            Status = ir.Status.ToString(),
                            RequestedBy = ir.RequestedBy.ToString(),
                            ReasonForReject = ir.ReasonForReject,
                            RequestDate = ir.CreatedAt,
                            ResponseDate = ir.UpdatedAt,

                            // Flags for UI/UX
                            CanRequest = false,
                            CanAccept = ir.Status == RequestStatus.Pending && ir.RequestedBy == RequestedBy.Company,
                            CanReject = ir.Status == RequestStatus.Pending && ir.RequestedBy == RequestedBy.Company,
                            CanWithdraw = ir.Status == RequestStatus.Pending && ir.RequestedBy == RequestedBy.Student,
                            RequestStatus = ir.Status == RequestStatus.Pending
                                ? "Pending"
                                : ir.Status == RequestStatus.Accepted
                                    ? "Accepted"
                                    : "Rejected"
                        })
                        .FirstOrDefault(),

                    // Check if student can request (no existing request)
                    CanRequestInterview = !c.InterviewRequests.Any(ir => ir.StudentId == student.StudentId),

                    Jobs = c.Jobs.Select(j => new
                    {
                        j.JobId,
                        j.JobTitle,
                        j.JobDescription,
                        j.RequiredSkills,
                        j.JobType
                    }).ToList(),

                    // --- Contact Links ---
                    ContactLinks = c.CompanyContactLinks.Select(cl => new
                    {
                        cl.LinkId,
                        Platform = cl.Platform.ToString(),
                        cl.Url
                    }).ToList()
                })
                .ToListAsync();

            if (companies.Count == 0)
                return NotFound("No companies available for your job fair.");

            return Ok(new
            {
                JobFairId = student.JobFairId,
                TotalCompanies = companies.Count,
                Companies = companies
            });
        }

        [HttpGet("jobs")]
        public async Task<IActionResult> GetAllJobs()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            // Get all jobs from companies in the same job fair
            var jobs = await _context.Jobs
                .Include(j => j.Company)
                .Where(j => j.Company.JobFairId == student.JobFairId)
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
                return NotFound("No jobs available for your job fair.");

            return Ok(new
            {
                JobFairId = student.JobFairId,
                TotalJobs = jobs.Count,
                Jobs = jobs
            });
        }

        [HttpGet("jobs/search")]
        public async Task<IActionResult> SearchJobs([FromQuery] string? keyword, [FromQuery] string? jobType)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            var jobsQuery = _context.Jobs
                .Include(j => j.Company)
                .Where(j => j.Company.JobFairId == student.JobFairId);

            // Filter by keyword (searches in job title and description)
            if (!string.IsNullOrWhiteSpace(keyword))
            {
                jobsQuery = jobsQuery.Where(j =>
                    j.JobTitle.ToLower().Contains(keyword.ToLower()) ||
                    j.JobDescription.ToLower().Contains(keyword.ToLower())
                );
            }

            // Filter by job type
            if (!string.IsNullOrWhiteSpace(jobType))
            {
                jobsQuery = jobsQuery.Where(j => j.JobType.ToString().ToLower() == jobType.ToLower());
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

            return Ok(new
            {
                JobFairId = student.JobFairId,
                TotalJobs = jobs.Count,
                Jobs = jobs
            });
        }

        [HttpGet("jobs/by-company/{companyId}")]
        public async Task<IActionResult> GetJobsByCompany(int companyId)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            var company = await _context.Companies
                .FirstOrDefaultAsync(c => c.CompanyId == companyId && c.JobFairId == student.JobFairId);

            if (company == null)
                return NotFound("Company not found in your job fair.");

            var jobs = await _context.Jobs
                .Where(j => j.CompanyId == companyId)
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
                return NotFound("No jobs available for this company.");

            return Ok(new
            {
                CompanyId = companyId,
                CompanyName = company.Name,
                TotalJobs = jobs.Count,
                Jobs = jobs
            });
        }

        // Update the GetCompanyProfile endpoint to include interview request status
        [HttpGet("companies/{companyId}")]
        public async Task<IActionResult> GetCompanyProfile(int companyId)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students
                .Include(s => s.InterviewRequests)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            // Get company profile with all details
            var company = await _context.Companies
                .Where(c => c.CompanyId == companyId && c.JobFairId == student.JobFairId)
                .Include(c => c.User)
                .Include(c => c.Jobs)
                .Include(c => c.CompanyContactLinks)
                .Include(c => c.InterviewRequests)
                .FirstOrDefaultAsync();

            if (company == null)
                return NotFound("Company not found in your job fair.");

            // Get interview request status between this student and company
            var interviewRequest = company.InterviewRequests
                .FirstOrDefault(ir => ir.StudentId == student.StudentId);

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

                // --- Contact Links (Social Media, LinkedIn, etc.) ---
                ContactLinks = company.CompanyContactLinks.Select(cl => new
                {
                    cl.LinkId,
                    Platform = cl.Platform.ToString(),
                    cl.Url
                }).ToList(),

                // --- All Job Openings ---
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

                // --- Unique Skills Required Across All Jobs ---
                UniqueSkillsRequired = company.Jobs
                    .Where(j => j.RequiredSkills != null)
                    .SelectMany(j => j.RequiredSkills)
                    .Distinct()
                    .ToList(),

                // --- Interview Request Status Between Student and Company ---
                InterviewRequest = interviewRequest != null ? new
                {
                    RequestId = interviewRequest.RequestId,
                    Status = interviewRequest.Status.ToString(),
                    RequestedBy = interviewRequest.RequestedBy.ToString(),
                    ReasonForReject = interviewRequest.ReasonForReject,
                    RequestDate = interviewRequest.CreatedAt,
                    ResponseDate = interviewRequest.UpdatedAt,

                    // --- UI/UX Flags ---
                    IsPending = interviewRequest.Status == RequestStatus.Pending,
                    IsAccepted = interviewRequest.Status == RequestStatus.Accepted,
                    IsRejected = interviewRequest.Status == RequestStatus.Rejected,

                    // Request action flags
                    CanAccept = interviewRequest.Status == RequestStatus.Pending && interviewRequest.RequestedBy == RequestedBy.Company,
                    CanReject = interviewRequest.Status == RequestStatus.Pending && interviewRequest.RequestedBy == RequestedBy.Company,
                    CanWithdraw = interviewRequest.Status == RequestStatus.Pending && interviewRequest.RequestedBy == RequestedBy.Student,

                    // Message for student
                    StatusMessage = interviewRequest.RequestedBy == RequestedBy.Student
                        ? $"You sent a request on {interviewRequest.CreatedAt:MMM dd, yyyy}"
                        : $"{company.Name} sent you a request on {interviewRequest.CreatedAt:MMM dd, yyyy}",

                    
                } : null,


                // Flag: Can student send interview request
                CanRequestInterview = interviewRequest == null,

                // --- Timestamps ---
                company.CreatedAt,
                company.UpdatedAt
            };

            return Ok(new { company = companyProfile });
        }




        [HttpPost("interview-requests/send")]
        public async Task<IActionResult> SendInterviewRequest([FromBody] SendInterviewRequestDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null) return NotFound("Student not found.");

            // Validate company exists
            var company = await _context.Companies
                .Include(c => c.User)
                .FirstOrDefaultAsync(c => c.CompanyId == dto.CompanyId && c.JobFairId == student.JobFairId);

            if (company == null) return NotFound("Company not found in your job fair.");

            // Check if request already exists
            var existingRequest = await _context.InterviewRequests
                .AnyAsync(r => r.StudentId == student.StudentId &&
                               r.CompanyId == dto.CompanyId &&
                               r.Status == RequestStatus.Pending);

            if (existingRequest)
                return BadRequest("You already have a pending interview request with this company.");

            // Create new interview request
            var interviewRequest = new InterviewRequest
            {
                CompanyId = dto.CompanyId,
                StudentId = student.StudentId,
                Status = RequestStatus.Pending,
                RequestedBy = RequestedBy.Student,
                CreatedAt = DateTime.UtcNow,

                JobFair = _context.JobFairs.Attach(new JobFair { JobFairId = student.JobFairId }).Entity
            };

            _context.InterviewRequests.Add(interviewRequest);
            await _context.SaveChangesAsync();
            // Send FCM notification
            if (!string.IsNullOrWhiteSpace(company.FcmToken))
            {
                try
                {
                    var message = new Message
                    {
                        Token = company.FcmToken,
                        Notification = new FirebaseAdmin.Messaging.Notification
                        {
                            Title = "New Interview Request",
                            // ✅ FIX: Generic message instead of guessing the job
                            Body = $"{student.User.FullName} has requested an interview with your company."
                        },
                        Data = new Dictionary<string, string>
                {
                    { "RequestId", interviewRequest.RequestId.ToString() },
                    { "StudentId", student.StudentId.ToString() },
                    { "StudentName", student.User.FullName },
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
                CompanyName = company.Name,
                Status = interviewRequest.Status.ToString()
            });
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

            var requestsQuery = _context.InterviewRequests
                .Include(r => r.Company)
                .Where(r => r.StudentId == student.StudentId)
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
                TotalRequests = requests.Count,
                Requests = requests
            });
        }
        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> CreateNotice([FromBody] NoticeCreateDto dto)
        {
            // Find active job fair
            var activeJobFair = await _context.JobFairs.FirstOrDefaultAsync(j => j.IsActive);
            if (activeJobFair == null)
                return BadRequest("No active Job Fair found. Cannot create notice.");

            var notice = new Notice
            {
                Title = dto.Title,
                Content = dto.Content,
                Audience = dto.Audience,
                JobFairId = activeJobFair.JobFairId,
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
                CreatedAt = notice.CreatedAt
            });
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

            // 4. Filter based on Audience
            if (isAdmin)
            {
                // Admins see everything
            }
            else if (isStudent)
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
        [HttpPost("interview-requests/{requestId}/accept")]
        public async Task<IActionResult> AcceptInterviewRequest(int requestId)
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

            if (interviewRequest.Status != RequestStatus.Pending)
                return BadRequest($"Cannot accept a request with status: {interviewRequest.Status}");

            // Update request status
            interviewRequest.Status = RequestStatus.Accepted;
            interviewRequest.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            // Send FCM notification to company when student accepts
            if (!string.IsNullOrWhiteSpace(interviewRequest.Company.FcmToken))
            {
                try
                {
                    var message = new Message
                    {
                        Token = interviewRequest.Company.FcmToken,
                        Notification = new FirebaseAdmin.Messaging.Notification
                        {
                            Title = "Interview Request Accepted",
                            Body = $"{student.User.FullName} has accepted your interview request"
                        },
                        Data = new Dictionary<string, string>
                        {
                            { "RequestId", interviewRequest.RequestId.ToString() },
                            { "StudentId", student.StudentId.ToString() },
                            { "StudentName", student.User.FullName },
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
                CompanyName = interviewRequest.Company.Name,
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
                            { "StudentName", student.User.FullName },
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
                CompanyName = interviewRequest.Company.Name,
                Status = interviewRequest.Status.ToString(),
                RejectionReason = dto.Reason,
                RejectedAt = interviewRequest.UpdatedAt
            });
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
                            { "StudentName", student.User.FullName },
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
                CompanyName = interviewRequest.Company.Name
            });
        }
    
        [HttpGet("cgpa")]
        public async Task<IActionResult> GetCGPA()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            return Ok(new
            {
                StudentId = student.StudentId,
                CGPA = student.CGPA,
                UpdatedAt = student.UpdatedAt
            });
        }

        
        [HttpPut("cgpa")]
        public async Task<IActionResult> UpdateCGPA([FromBody] UpdateCGPADto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            // Validate CGPA range (typically 0 to 4.0)
            // Add 'm' to 0 and 4.0
            if (dto.CGPA < 0m || dto.CGPA > 4.0m)
                return BadRequest("CGPA must be between 0.0 and 4.0.");

            var oldCGPA = student.CGPA;
            student.CGPA = dto.CGPA;
            student.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "CGPA updated successfully.",
                StudentId = student.StudentId,
                OldCGPA = oldCGPA,
                NewCGPA = student.CGPA,
                UpdatedAt = student.UpdatedAt
            });
        }

      
        [HttpPost("cgpa")]
        public async Task<IActionResult> AddCGPA([FromBody] UpdateCGPADto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            // Validate CGPA range
            // Add 'm' to 0 and 4.0
            if (dto.CGPA < 0m || dto.CGPA > 4.0m)
                return BadRequest("CGPA must be between 0.0 and 4.0.");

            // Check if CGPA already exists (not 0)
            if (student.CGPA > 0)
                return BadRequest("CGPA already exists. Use PUT to update it.");

            student.CGPA = dto.CGPA;
            student.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "CGPA added successfully.",
                StudentId = student.StudentId,
                CGPA = student.CGPA,
                CreatedAt = student.UpdatedAt
            });
        }

       
        [HttpDelete("cgpa")]
        public async Task<IActionResult> DeleteCGPA()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            if (student.CGPA == 0)
                return BadRequest("CGPA is not set or already deleted.");

            var oldCGPA = student.CGPA;
            student.CGPA = 0;
            student.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "CGPA deleted successfully.",
                StudentId = student.StudentId,
                DeletedCGPA = oldCGPA,
                NewCGPA = student.CGPA,
                DeletedAt = student.UpdatedAt
            });
        }

      
        [HttpPut("experiences/{experienceId}")]
        public async Task<IActionResult> UpdateExperience(int experienceId, [FromBody] ExperienceUpdateDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var experience = await _context.Experiences
                .Include(e => e.Student)
                .FirstOrDefaultAsync(e => e.ExperienceId == experienceId && e.Student.UserId == userId);

            if (experience == null)
                return NotFound("Experience not found or does not belong to this student.");

            // Update fields if provided
            if (!string.IsNullOrWhiteSpace(dto.CompanyName))
                experience.CompanyName = dto.CompanyName;

            if (!string.IsNullOrWhiteSpace(dto.Role))
                experience.Role = dto.Role;

            if (!string.IsNullOrWhiteSpace(dto.Location))
                experience.Location = dto.Location;

            if (!string.IsNullOrWhiteSpace(dto.Description))
                experience.Description = dto.Description;

            if (dto.StartDate.HasValue)
                experience.StartDate = dto.StartDate.Value;

            if (dto.EndDate.HasValue)
                experience.EndDate = dto.EndDate.Value;
            else if (dto.IsCurrent.HasValue && dto.IsCurrent.Value)
                experience.EndDate = null; // Clear end date if current

            if (dto.IsCurrent.HasValue)
                experience.IsCurrent = dto.IsCurrent.Value;

            // Validate dates
            if (experience.EndDate.HasValue && experience.EndDate.Value < experience.StartDate && !experience.IsCurrent)
                return BadRequest("End date cannot be before start date.");

            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Experience updated successfully.",
                Experience = new
                {
                    experience.ExperienceId,
                    experience.CompanyName,
                    experience.Role,
                    experience.Location,
                    experience.Description,
                    experience.StartDate,
                    experience.EndDate,
                    experience.IsCurrent,
                    Duration = CalculateDuration(experience.StartDate, experience.EndDate, experience.IsCurrent)
                }
            });
        }
        private string CalculateDuration(DateTime startDate, DateTime? endDate, bool isCurrent)
        {
            var end = isCurrent ? DateTime.UtcNow : (endDate ?? DateTime.UtcNow);
            var duration = end - startDate;

            int years = duration.Days / 365;
            int months = (duration.Days % 365) / 30;

            return (years, months) switch
            {
                ( > 0, > 0) => $"{years}y {months}m",
                ( > 0, _) => $"{years}y",
                (_, > 0) => $"{months}m",
                _ => $"{duration.Days}d"
            };
        }
        

        [HttpGet("interview-requests/all")]
        public async Task<IActionResult> GetAllInterviewRequests([FromQuery] string? status = null, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 20;

            // Query interview requests where student is involved
            var requestsQuery = _context.InterviewRequests
                .Include(r => r.Company)
                .Include(r => r.Student)
                .Where(r => r.StudentId == student.StudentId)
                .AsQueryable();

            // Filter by status if provided
            if (!string.IsNullOrWhiteSpace(status))
            {
                if (Enum.TryParse<RequestStatus>(status, true, out var statusEnum))
                {
                    requestsQuery = requestsQuery.Where(r => r.Status == statusEnum);
                }
                else
                {
                    return BadRequest("Invalid status. Valid values: Pending, Accepted, Rejected");
                }
            }

            var totalCount = await requestsQuery.CountAsync();

            var requests = await requestsQuery
                .OrderByDescending(r => r.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(r => new
                {
                    r.RequestId,
                    CompanyId = r.Company.CompanyId,
                    CompanyName = r.Company.Name,
                    CompanyLogoUrl = r.Company.LogoUrl,
                    CompanyIndustry = r.Company.Industry,
                    CompanyEmail = r.Company.CompanyEmail,
                    CompanyPhone = r.Company.CompanyPhone,
                    CompanyWebsite = r.Company.Website,
                    Status = r.Status.ToString(),
                    RequestedBy = r.RequestedBy.ToString(),
                    ReasonForReject = r.ReasonForReject,
                    RequestDate = r.CreatedAt,
                    ResponseDate = r.UpdatedAt
                })
                .ToListAsync();

            return Ok(new
            {
                StudentId = student.StudentId,
                TotalRequests = totalCount,
                Page = page,
                PageSize = pageSize,
                TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
                InterviewRequests = requests
            });
        }

        
        [HttpGet("interview-requests/sent")]
        public async Task<IActionResult> GetSentInterviewRequests([FromQuery] string? status = null, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 20;

            // Only requests sent BY the student
            var requestsQuery = _context.InterviewRequests
                .Include(r => r.Company)
                .Where(r => r.StudentId == student.StudentId && r.RequestedBy == RequestedBy.Student)
                .AsQueryable();

            // Filter by status if provided
            if (!string.IsNullOrWhiteSpace(status))
            {
                if (Enum.TryParse<RequestStatus>(status, true, out var statusEnum))
                {
                    requestsQuery = requestsQuery.Where(r => r.Status == statusEnum);
                }
                else
                {
                    return BadRequest("Invalid status. Valid values: Pending, Accepted, Rejected");
                }
            }

            var totalCount = await requestsQuery.CountAsync();

            var requests = await requestsQuery
                .OrderByDescending(r => r.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(r => new
                {
                    r.RequestId,
                    CompanyId = r.Company.CompanyId,
                    CompanyName = r.Company.Name,
                    CompanyLogoUrl = r.Company.LogoUrl,
                    CompanyIndustry = r.Company.Industry,
                    CompanyEmail = r.Company.CompanyEmail,
                    CompanyPhone = r.Company.CompanyPhone,
                    Status = r.Status.ToString(),
                    ReasonForReject = r.ReasonForReject,
                    SentDate = r.CreatedAt,
                    ResponseDate = r.UpdatedAt,
                    TimeInQueue = DateTime.UtcNow - r.CreatedAt
                })
                .ToListAsync();

            return Ok(new
            {
                StudentId = student.StudentId,
                Type = "Sent by Student",
                TotalRequests = totalCount,
                Page = page,
                PageSize = pageSize,
                TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
                InterviewRequests = requests
            });
        }
        [HttpGet("interview-requests/received")]
        public async Task<IActionResult> GetReceivedInterviewRequests([FromQuery] string? status = null, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 20;

            // Only requests sent BY the company TO the student
            var requestsQuery = _context.InterviewRequests
                .Include(r => r.Company)
                .Where(r => r.StudentId == student.StudentId && r.RequestedBy == RequestedBy.Company)
                .AsQueryable();

            // Filter by status if provided
            if (!string.IsNullOrWhiteSpace(status))
            {
                if (Enum.TryParse<RequestStatus>(status, true, out var statusEnum))
                {
                    requestsQuery = requestsQuery.Where(r => r.Status == statusEnum);
                }
                else
                {
                    return BadRequest("Invalid status. Valid values: Pending, Accepted, Rejected");
                }
            }

            var totalCount = await requestsQuery.CountAsync();

            var requests = await requestsQuery
                .OrderByDescending(r => r.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(r => new
                {
                    r.RequestId,
                    CompanyId = r.Company.CompanyId,
                    CompanyName = r.Company.Name,
                    CompanyLogoUrl = r.Company.LogoUrl,
                    CompanyIndustry = r.Company.Industry,
                    CompanyEmail = r.Company.CompanyEmail,
                    CompanyPhone = r.Company.CompanyPhone,
                    CompanyWebsite = r.Company.Website,
                    Status = r.Status.ToString(),
                    ReasonForReject = r.ReasonForReject,
                    ReceivedDate = r.CreatedAt,
                    ResponseDate = r.UpdatedAt,
                    IsActionRequired = r.Status == RequestStatus.Pending
                })
                .ToListAsync();

            return Ok(new
            {
                StudentId = student.StudentId,
                Type = "Received from Company",
                TotalRequests = totalCount,
                Page = page,
                PageSize = pageSize,
                TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
                InterviewRequests = requests
            });
        }

        [HttpGet("interview-requests/statistics")]
        public async Task<IActionResult> GetInterviewRequestStatistics()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var student = await _context.Students
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student not found.");

            var statistics = new
            {
                StudentId = student.StudentId,

                // Total Statistics
                TotalRequests = await _context.InterviewRequests
                    .Where(r => r.StudentId == student.StudentId)
                    .CountAsync(),

                // Sent by Student
                SentByStudent = new
                {
                    Total = await _context.InterviewRequests
                        .Where(r => r.StudentId == student.StudentId && r.RequestedBy == RequestedBy.Student)
                        .CountAsync(),
                    Pending = await _context.InterviewRequests
                        .Where(r => r.StudentId == student.StudentId && r.RequestedBy == RequestedBy.Student && r.Status == RequestStatus.Pending)
                        .CountAsync(),
                    Accepted = await _context.InterviewRequests
                        .Where(r => r.StudentId == student.StudentId && r.RequestedBy == RequestedBy.Student && r.Status == RequestStatus.Accepted)
                        .CountAsync(),
                    Rejected = await _context.InterviewRequests
                        .Where(r => r.StudentId == student.StudentId && r.RequestedBy == RequestedBy.Student && r.Status == RequestStatus.Rejected)
                        .CountAsync()
                },

                // Received from Company
                ReceivedFromCompany = new
                {
                    Total = await _context.InterviewRequests
                        .Where(r => r.StudentId == student.StudentId && r.RequestedBy == RequestedBy.Company)
                        .CountAsync(),
                    Pending = await _context.InterviewRequests
                        .Where(r => r.StudentId == student.StudentId && r.RequestedBy == RequestedBy.Company && r.Status == RequestStatus.Pending)
                        .CountAsync(),
                    Accepted = await _context.InterviewRequests
                        .Where(r => r.StudentId == student.StudentId && r.RequestedBy == RequestedBy.Company && r.Status == RequestStatus.Accepted)
                        .CountAsync(),
                    Rejected = await _context.InterviewRequests
                        .Where(r => r.StudentId == student.StudentId && r.RequestedBy == RequestedBy.Company && r.Status == RequestStatus.Rejected)
                        .CountAsync()
                },

                // Action Required
                ActionRequired = new
                {
                    PendingSentRequests = await _context.InterviewRequests
                        .Where(r => r.StudentId == student.StudentId && r.RequestedBy == RequestedBy.Student && r.Status == RequestStatus.Pending)
                        .CountAsync(),
                    PendingReceivedRequests = await _context.InterviewRequests
                        .Where(r => r.StudentId == student.StudentId && r.RequestedBy == RequestedBy.Company && r.Status == RequestStatus.Pending)
                        .CountAsync()
                }
            };

            return Ok(statistics);
        }

        [HttpGet("interview-requests/{requestId}")]
        public async Task<IActionResult> GetInterviewRequestDetails(int requestId)
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
                .Include(r => r.Student)
                    .ThenInclude(s => s.User)
                .FirstOrDefaultAsync(r => r.RequestId == requestId && r.StudentId == student.StudentId);

            if (interviewRequest == null)
                return NotFound("Interview request not found.");

            var detail = new
            {
                RequestId = interviewRequest.RequestId,

                // Student Info
                Student = new
                {
                    StudentId = interviewRequest.Student.StudentId,
                    Name = interviewRequest.Student.User.FullName,
                    Email = interviewRequest.Student.User.Email,
                    Phone = interviewRequest.Student.User.Phone,
                    RegistrationNo = interviewRequest.Student.RegistrationNo,
                    Department = interviewRequest.Student.Department,
                    CGPA = interviewRequest.Student.CGPA
                },

                // Company Info
                Company = new
                {
                    CompanyId = interviewRequest.Company.CompanyId,
                    Name = interviewRequest.Company.Name,
                    Industry = interviewRequest.Company.Industry,
                    LogoUrl = interviewRequest.Company.LogoUrl,
                    Website = interviewRequest.Company.Website,
                    Email = interviewRequest.Company.CompanyEmail,
                    Phone = interviewRequest.Company.CompanyPhone,
                    Address = interviewRequest.Company.Address
                },

                // Request Details
                RequestStatus = interviewRequest.Status.ToString(),
                RequestedBy = interviewRequest.RequestedBy.ToString(),
                RejectionReason = interviewRequest.ReasonForReject,

                // Timeline
                RequestDate = interviewRequest.CreatedAt,
                ResponseDate = interviewRequest.UpdatedAt,
                TimeInQueue = DateTime.UtcNow - interviewRequest.CreatedAt,

                // Additional Context
                IsPending = interviewRequest.Status == RequestStatus.Pending,
                CanAccept = interviewRequest.Status == RequestStatus.Pending,
                CanReject = interviewRequest.Status == RequestStatus.Pending,
                CanWithdraw = interviewRequest.Status == RequestStatus.Pending && interviewRequest.RequestedBy == RequestedBy.Student
            };

            return Ok(detail);
        }
    }
    
     

    }