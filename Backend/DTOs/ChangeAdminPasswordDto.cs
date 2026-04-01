namespace JobFairPortal.DTOs
{
    public class ChangeAdminPasswordDto
    {
        public string CurrentPassword { get; set; } = null!;
        public string NewPassword { get; set; } = null!;
    }
}
