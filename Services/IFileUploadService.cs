namespace JobFairPortal.Services
{
    public interface IFileUploadService
    {
        Task<string> UploadStudentProfilePicAsync(string registrationNo, IFormFile file);
        Task<bool> DeleteFileAsync(string fileUrl);
    }
}