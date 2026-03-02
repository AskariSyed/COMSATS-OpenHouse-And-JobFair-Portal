using Microsoft.AspNetCore.Http;
using System.Collections.Generic;

public class UpdateStudentDto
{
    public string? Name { get; set; }
    public string? CVUrl { get; set; }
    public string? FypTitle { get; set; }
    public string? FypDemoUrl { get; set; }
    public string? FypDescription { get; set; }
    public string? Department { get; set; }
    public decimal? CGPA { get; set; }
    public string? Phone { get; set; }

    // Change Links from List<string> to Dictionary<string, string>
    public Dictionary<string, string>? Links { get; set; }
    public List<string>? Skills { get; set; }

    public IFormFile? ProfilePic { get; set; }
}
