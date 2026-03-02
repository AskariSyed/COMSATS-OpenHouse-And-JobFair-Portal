using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.Models
{
    public class Student
    {
        [Key]
        public int StudentId { get; set; }

        [Required]
        public int UserId { get; set; }

        [Required]
        public string RegistrationNo { get; set; } = null!;

        public decimal CGPA { get; set; }

        public string? ProfilePicUrl { get; set; }

        public string Department { get; set; } = null!;

        public List<string>? Skills { get; set; }

        public string? FcmToken { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Relationships
        public User User { get; set; } = null!;
        public ICollection<ContactLink> ContactLinks { get; set; } = new List<ContactLink>();
        public ICollection<Experience> Experiences { get; set; } = new List<Experience>();

        public ICollection<StudentProject> StudentProjects { get; set; } = new List<StudentProject>();

        public ICollection<InterviewRequest> InterviewRequests { get; set; } = new List<InterviewRequest>();
        public ICollection<Interview> Interviews { get; set; } = new List<Interview>();
        public ICollection<Achievement> Achievements { get; set; } = new List<Achievement>();
        public ICollection<Certification> Certifications { get; set; } = new List<Certification>();
        public ICollection<Education> Educations { get; set; } = new List<Education>();


        public int JobFairId { get; set; }
        public JobFair JobFair { get; set; } = null!;

        public ICollection<StudentJobFairParticipation> JobFairParticipations { get; set; } = 
            new List<StudentJobFairParticipation>();

        public int? CurrentJobFairId { get; set; }  // Optional: tracks their primary job fair
        public JobFair? CurrentJobFair { get; set; }
    }
}

