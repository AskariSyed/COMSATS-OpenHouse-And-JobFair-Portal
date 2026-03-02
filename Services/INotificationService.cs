using JobFairPortal.Models;
using System.Threading.Tasks;

namespace JobFairPortal.Services
{
    public interface INotificationService
    {
        Task<bool> SendProjectInvitationAsync(string fcmToken, string inviterName, int projectId);
        Task<bool> SendInterviewNotificationAsync(string fcmToken, string message, Dictionary<string, string> data);
        Task SendRoomAllocationEmailAsync(string email, string companyName, string roomName, int capacity, JobFair jobFair);
        Task SendPendingRoomAllocationEmailAsync(string email, string companyName, int representativeCount, JobFair jobFair);
        Task SendRoomChangeNotificationAsync(string email, string companyName, string oldRoomName, string newRoomName, JobFair jobFair);
    }
}