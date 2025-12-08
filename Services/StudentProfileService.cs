//using JobFairPortal.Data;
//using JobFairPortal.DTOs;
//using JobFairPortal.Models;
//using Microsoft.EntityFrameworkCore;

//namespace JobFairPortal.Services
//{
//    public class StudentProfileService
//    {
//        private readonly JobFairRecruitmentDbContext _context;
//        private readonly ILogger<StudentProfileService> _logger;

//        public StudentProfileService(
//            JobFairRecruitmentDbContext context,
//            ILogger<StudentProfileService> logger)
//        {
//            _context = context ?? throw new ArgumentNullException(nameof(context));
//            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
//        }

//        public async Task<Student?> GetStudentWithAllDataAsync(int userId)
//        {
//            return await _context.Students
//                .Include(s => s.User)
//                .Include(s => s.Educations)
//                .Include(s => s.Certifications)
//                .Include(s => s.Achievements)
//                .Include(s => s.ContactLinks)
//                .Include(s => s.Experiences)
//                .Include(s => s.StudentProjects)
//                    .ThenInclude(sp => sp.Project)
//                        .ThenInclude(p => p.StudentProjects)
//                            .ThenInclude(p_sp => p_sp.Student)
//                                .ThenInclude(p_s => p_s.User)
//                .FirstOrDefaultAsync(s => s.UserId == userId);
//        }

//        public async Task<Student?> GetStudentWithInterviewRequestsAsync(int userId)
//        {
//            return await _context.Students
//                .Include(s => s.InterviewRequests)
//                .FirstOrDefaultAsync(s => s.UserId == userId);
//        }

//        public object BuildProfileResponse(Student student)
//        {
//            return new
//            {
//                student.StudentId,
//                student.RegistrationNo,
//                student.Department,
//                student.ProfilePicUrl,
//                student.Skills,
//                student.CGPA,
//                student.FcmToken,
//                User = new UserDto
//                {
//                    UserId = student.User.UserId,
//                    FullName = student.User.FullName,
//                    Email = student.User.Email,
//                    Phone = student.User.Phone,
//                    Role = student.User.Role.ToString(),
//                    IsActive = student.User.IsActive,
//                    CreatedAt = student.User.CreatedAt
//                },
//                Educations = student.Educations.Select(BuildEducationResponse).ToList(),
//                Certifications = student.Certifications.Select(BuildCertificationResponse).ToList(),
//                Achievements = student.Achievements.Select(BuildAchievementResponse).ToList(),
//                ContactLinks = student.ContactLinks.Select(BuildContactLinkResponse).ToList(),
//                Experiences = student.Experiences.Select(BuildExperienceResponse).ToList(),
//                Projects = BuildProjectsResponse(student)
//            };
//        }

//        private object BuildEducationResponse(Education e) => new
//        {
//            e.EducationId,
//            e.InstitutionName,
//            e.Degree,
//            e.FieldOfStudy,
//            e.StartDate,
//            e.EndDate,
//            e.IsCurrent,
//            e.CGPA,
//            e.Location
//        };

//        private object BuildCertificationResponse(Certification c) => new
//        {
//            c.CertificationId,
//            c.Title,
//            c.Issuer,
//            c.IssueDate,
//            c.CredentialUrl,
//            c.CredentialId
//        };

//        private object BuildAchievementResponse(Achievement a) => new
//        {
//            a.AchievementId,
//            a.Title,
//            a.Description,
//            a.DateAchieved
//        };

//        private object BuildContactLinkResponse(ContactLink cl) => new
//        {
//            cl.LinkId,
//            Platform = cl.Platform.ToString(),
//            cl.Url
//        };

//        private object BuildExperienceResponse(Experience ex) => new
//        {
//            ex.ExperienceId,
//            ex.CompanyName,
//            ex.Location,
//            ex.StartDate,
//            ex.EndDate,
//            ex.Description,
//            ex.IsCurrent,
//            ex.Role
//        };

//        //private List<object> BuildProjectsResponse(Student student)
//        //{
//        //    return student.StudentProjects
//        //        .Where(sp => sp.Project != null)
//        //        .Select(sp => new
//        //        {
//        //            sp.Project.ProjectId,
//        //            sp.Project.Title,
//        //            sp.Project.Description,
//        //            sp.Project.DemoUrl,
//        //            sp.Project.GitHubUrl,
//        //            Type = sp.Project.Type.ToString(),
//        //            CurrentStudentRole = sp.role,
//        //            CurrentStudentStatus = sp.Status.ToString(),
//        //            CurrentStudentIsCreator = sp.IsCreator,
//        //            Partners = sp.Project.StudentProjects
//        //                .Where(p => p.Student?.User != null)
//        //                .Where(p => p.StudentId != student.StudentId)
//        //                .Select(p => new
//        //                {
//        //                    p.Student.StudentId,
//        //                    p.Student.ProfilePicUrl,
//        //                    Name = p.Student.User.FullName ?? "Unknown",
//        //                    p.Student.RegistrationNo,
//        //                    Role = p.role,
//        //                    Status = p.Status.ToString(),
//        //                    IsCreator = p.IsCreator
//        //                })
//        //                .ToList()
//        //        })
//        //        .ToList();
//        //}
//    }
//}