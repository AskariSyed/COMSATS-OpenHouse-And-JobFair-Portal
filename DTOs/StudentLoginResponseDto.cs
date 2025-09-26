public class StudentLoginResponseDto
{
    public int StudentId { get; set; }
    public string Name { get; set; } = null!;
    public string RegistrationNo { get; set; } = null!;
    public string? ProfilePicUrl { get; set; }
    public string? CVUrl { get; set; }
    public string? FypTitle { get; set; }
    public string? FypDemoUrl { get; set; }
    public string? FypDescription { get; set; }
    public string? Department { get; set; }
    public decimal CGPA { get; set; }
    public string[]? Skills { get; set; }   
    public string Email { get; set; } = null!;
    public string? Phone { get; set; }
    public string? LinkedIn { get; set; }
    public string? GitHub { get; set; }
    public string? FcmToken { get; set; }
}
