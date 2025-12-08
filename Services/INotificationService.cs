namespace JobFairPortal.Services
{
    public interface INotificationService
    {
        Task<bool> SendProjectInvitationAsync(string fcmToken, string inviterName, int projectId);
        Task<bool> SendInterviewNotificationAsync(string fcmToken, string message, Dictionary<string, string> data);
    }
}