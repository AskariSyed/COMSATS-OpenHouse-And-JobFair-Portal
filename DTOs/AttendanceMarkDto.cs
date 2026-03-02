namespace JobFairPortal.DTOs
{
    public class AttendanceMarkDto
    {
        // Company participation token (sent in email link)
        public string? Token { get; set; }

        // Admin session token encoded in QR (scanned from admin display)
        public string? Session { get; set; }
    }
}