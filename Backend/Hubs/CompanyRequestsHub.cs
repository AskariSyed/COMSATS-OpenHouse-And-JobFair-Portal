using Microsoft.AspNetCore.SignalR;

namespace JobFairPortal.Hubs
{
    public class CompanyRequestsHub : Hub
    {
        // Server methods can be added if needed (e.g., join groups)
        public Task JoinAdminsGroup()
        {
            return Groups.AddToGroupAsync(Context.ConnectionId, "admins");
        }

        public Task LeaveAdminsGroup()
        {
            return Groups.RemoveFromGroupAsync(Context.ConnectionId, "admins");
        }

        public Task NotifyDashboardUpdate()
        {
            return Clients.Group("admins").SendAsync("DashboardUpdated");
        }
    }
}
