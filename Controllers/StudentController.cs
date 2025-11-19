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
            // 1. Get User ID from Token
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            // 2. Fetch Data (Include all related tables)
            var student = await _context.Students
                .Include(s => s.User)
                .Include(s => s.Educations)
                .Include(s => s.Certifications)
                .Include(s => s.Achievements)
                .Include(s => s.StudentProjects)
                    .ThenInclude(sp => sp.Project) // Important to get Project details
                .Include(s => s.ContactLinks)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if (student == null)
                return NotFound("Student profile not found.");

            // 3. Flatten EVERYTHING manually
            var response = new
            {
                // --- Main Student Info ---
                student.StudentId,
                student.RegistrationNo,
                student.Department,
                student.ProfilePicUrl,
                student.Skills, // List<string> is primitive, so it's safe
                student.CGPA,
                student.FcmToken,

                // --- User Info (Flattened) ---
                User = new
                {
                    student.User.UserId,
                    student.User.FullName,
                    student.User.Email,
                    student.User.Phone,
                    student.User.IsActive,
                    student.User.CreatedAt
                },

                // --- Educations (Flattened List) ---
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

                // --- Certifications (Flattened List) ---
                Certifications = student.Certifications.Select(c => new
                {
                    c.CertificationId,
                    c.Title,
                    c.Issuer,
                    c.IssueDate,
                    c.CredentialUrl,
                    c.CredentialId
                }).ToList(),

                // --- Achievements (Flattened List) ---
                Achievements = student.Achievements.Select(a => new
                {
                    a.AchievementId,
                    a.Title,
                    a.Description,
                    a.DateAchieved
                }).ToList(),

                // --- Contact Links (Flattened List) ---
                ContactLinks = student.ContactLinks.Select(cl => new
                {
                    cl.LinkId,
                    Platform = cl.Platform.ToString(), // Convert Enum to String (e.g., "LinkedIn")
                    cl.Url
                }).ToList(),

                // --- Projects (Flattened List) ---
                // Note: We access sp.Project because we are querying the Join Table
                Projects = student.StudentProjects
                    .Where(sp => sp.Project != null) // Safety check
                    .Select(sp => new
                    {
                        sp.Project.ProjectId,
                        sp.Project.Title,
                        sp.Project.Description,
                        sp.Project.DemoUrl,
                        sp.Project.GitHubUrl,
                        Type = sp.Project.Type.ToString() // Convert Enum to String (e.g., "FinalYear")
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

            return Ok(student.Experiences);
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

            return Ok(new { Message = "Experience added successfully", Experience = experience });
        }


        [HttpPut("experiences/{experienceId}")]
        public async Task<IActionResult> UpdateExperience(int experienceId, [FromBody] ExperienceUpdateDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized();

            var experience = await _context.Experiences
                .Include(e => e.Student)
                .FirstOrDefaultAsync(e => e.ExperienceId == experienceId && e.Student.UserId == userId);

            if (experience == null)
                return NotFound("Experience not found or does not belong to this student.");

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

            if (dto.IsCurrent.HasValue)
                experience.IsCurrent = dto.IsCurrent.Value;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Experience updated successfully",
                Experience = new
                {
                    experience.CompanyName,
                    experience.Role,
                    experience.StartDate,
                    experience.EndDate,
                    experience.IsCurrent,
                    experience.Description,
                    experience.Location
                }
            });
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

            var certification = new Certification
            {
                StudentId = student.StudentId,
                Title = dto.Title,
                Issuer = dto.Issuer,
                IssueDate = dto.IssueDate,
                CredentialUrl = dto.CredentialUrl,
                CredentialId = dto.CredentialId
            };

            _context.Certifications.Add(certification);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Certification added successfully",
                Certification = certification
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
                    .ThenInclude(s => s.User) // 👈 THIS WAS MISSING
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



        [HttpGet]
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

            // 🔥 Convert string → enum if sent
            if (!string.IsNullOrWhiteSpace(dto.Platform))
            {
                if (!Enum.TryParse<ContactPlatform>(dto.Platform, true, out var platformEnum))
                    return BadRequest("Invalid platform value.");

                // Check for duplicates
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

            // 🔹 1. Add to Context
            _context.Educations.Add(education);

            // 🔹 2. Save Once (Database generates the ID here)
            await _context.SaveChangesAsync();

            // 🔹 3. Map to DTO (Using the ID generated above)
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

            // ❌ REMOVED THE DUPLICATE SAVE CODE HERE

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

        /// <summary>
        /// Replace all skills for a student (PUT).
        /// </summary>
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
    }
}
