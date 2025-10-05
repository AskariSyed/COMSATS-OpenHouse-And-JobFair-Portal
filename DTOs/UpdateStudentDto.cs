using Microsoft.AspNetCore.Http;
using System.Collections.Generic;

namespace JobFairPortal.DTOs
{
    public class UpdateStudentDto
    {
        // File
        public IFormFile? ProfilePic { get; set; }

        // Basic info
        public string? Name { get; set; }
        public string? CVUrl { get; set; }
        public string? Department { get; set; }
        public double? CGPA { get; set; }

        // FYP details
        public string? FypTitle { get; set; }
        public string? FypDemoUrl { get; set; }
        public string? FypDescription { get; set; }

        // Skills & Links
        public string[]? Skills { get; set; }
        public Dictionary<string, string>? Links { get; set; }
    }
}
