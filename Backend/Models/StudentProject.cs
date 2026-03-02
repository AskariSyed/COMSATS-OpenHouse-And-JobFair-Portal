using JobFairPortal.Models;
using System.ComponentModel.DataAnnotations;

namespace JobFairPortal.Models
{
    public enum ProjectInviteStatus
    {
        Pending,
        Accepted,
        Rejected
    }
    public class StudentProject
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int StudentId { get; set; }

        [Required]
        public int ProjectId { get; set; }
        public string? role { get; set; }

        public bool IsCreator { get; set; } = false; 
        public ProjectInviteStatus Status { get; set; } = ProjectInviteStatus.Pending;

        public Student Student { get; set; } = null!;
        public Project Project { get; set; } = null!;
    }
}