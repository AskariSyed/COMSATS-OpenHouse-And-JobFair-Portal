namespace JobFairPortal.DTOs
{
    public class CompanyOtpVerifyDto
    {
        public string RepEmail { get; set; } = null!;
        public string UserEmail { get; set; } = null!;
        public string Otp { get; set; } = null!;
    }
}