using JobFairPortal.Models;
using System.ComponentModel.DataAnnotations;

public class JobFair
{
    [Key]
    public int JobFairId { get; set; }
    [Required]
    public string Semester { get; set; } = null!; // e.g. "Spring 2025"
    public DateTime date { get; set; }
    public bool IsActive { get; set; } = true;
    public ICollection<Student>? Students { get; set; }
    public ICollection<Company>? Companies { get; set; }
    public ICollection<Interview>? Interviews { get; set; }
    public ICollection<InterviewRequest>? InterviewRequests{ get; set; }
    public ICollection<Room>? Rooms { get; set; }
    public ICollection<Job>? Jobs { get; set; }
    public ICollection<Survey>? Surveys { get; set; }

}