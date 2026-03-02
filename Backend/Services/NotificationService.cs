using JobFairPortal.Models;
using Microsoft.Extensions.Configuration;
using FirebaseAdmin.Messaging;
using System.Net;
using System.Net.Mail;
using System.Threading.Tasks;

namespace JobFairPortal.Services
{
    public class NotificationService : INotificationService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<NotificationService> _logger;

        public NotificationService(IConfiguration configuration, ILogger<NotificationService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }
        public async Task<bool> SendProjectInvitationAsync(string fcmToken, string inviterName, int projectId)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(fcmToken))
                {
                    _logger.LogWarning("SendProjectInvitationAsync: FCM token is empty");
                    return false;
                }

                var message = new Message
                {
                    Token = fcmToken,
                    Notification = new Notification
                    {
                        Title = "Project Invitation",
                        Body = $"{inviterName} has invited you to join their project"
                    },
                    Data = new Dictionary<string, string>
                    {
                        { "ProjectId", projectId.ToString() },
                        { "InviterName", inviterName },
                        { "Type", "ProjectInvitation" }
                    }
                };

                await FirebaseMessaging.DefaultInstance.SendAsync(message);
                _logger.LogInformation("Project invitation sent successfully to FCM token: {Token}", fcmToken);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send project invitation to FCM token");
                return false;
            }
        }

        /// <summary>
        /// Sends FCM notification for interview-related events
        /// </summary>
        public async Task<bool> SendInterviewNotificationAsync(string fcmToken, string message, Dictionary<string, string> data)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(fcmToken))
                {
                    _logger.LogWarning("SendInterviewNotificationAsync: FCM token is empty");
                    return false;
                }

                if (string.IsNullOrWhiteSpace(message))
                {
                    _logger.LogWarning("SendInterviewNotificationAsync: Message is empty");
                    return false;
                }

                var notificationMessage = new Message
                {
                    Token = fcmToken,
                    Notification = new Notification
                    {
                        Title = "Interview Update",
                        Body = message
                    },
                    Data = data ?? new Dictionary<string, string>()
                };

                await FirebaseMessaging.DefaultInstance.SendAsync(notificationMessage);
                _logger.LogInformation("Interview notification sent successfully to FCM token: {Token}", fcmToken);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send interview notification to FCM token");
                return false;
            }
        }

        /// <summary>
        /// Sends welcome email when room is tentatively allocated
        /// </summary>
        public async Task SendRoomAllocationEmailAsync(string email, string companyName, string roomName, int capacity, JobFair jobFair)
        {
            try
            { 
                var subject = $"Room Allocated - {jobFair.Semester} Job Fair";
                var htmlBody = BuildRoomAllocationEmailTemplate(companyName, roomName, capacity, jobFair);

                await SendEmailAsync(email, subject, htmlBody);

                _logger.LogInformation("Room allocation email sent to: {Email}, Room: {RoomName}", email, roomName);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send room allocation email to: {Email}", email);
                throw;
            }
        }

        /// <summary>
        /// Sends email notifying company that room will be allocated on physical arrival
        /// </summary>
        public async Task SendPendingRoomAllocationEmailAsync(string email, string companyName, int representativeCount, JobFair jobFair)
        {
            try
            {
                var subject = $"Confirmation Received - {jobFair.Semester} Job Fair";
                var htmlBody = BuildPendingRoomAllocationEmailTemplate(companyName, representativeCount, jobFair);

                await SendEmailAsync(email, subject, htmlBody);

                _logger.LogInformation("Pending room allocation email sent to: {Email}", email);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send pending room allocation email to: {Email}", email);
                throw;
            }
        }

        /// <summary>
        /// Sends email notifying about room change
        /// </summary>
        public async Task SendRoomChangeNotificationAsync(string email, string companyName, string oldRoomName, string newRoomName, JobFair jobFair)
        {
            try
            {
                var subject = $"Room Assignment Updated - {jobFair.Semester} Job Fair";
                var htmlBody = BuildRoomChangeEmailTemplate(companyName, oldRoomName, newRoomName, jobFair);

                await SendEmailAsync(email, subject, htmlBody);

                _logger.LogInformation("Room change notification sent to: {Email}, New Room: {RoomName}", email, newRoomName);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send room change email to: {Email}", email);
                throw;
            }
        }

        /// <summary>
        /// Sends email via SMTP (handles null reference safely)
        /// </summary>
        private async Task SendEmailAsync(string recipientEmail, string subject, string htmlBody)
        {
            try
            {
                // ✅ FIX: Handle null reference for senderEmail
                var smtpServer = _configuration["Email:SmtpServer"];
                var smtpPort = int.Parse(_configuration["Email:SmtpPort"] ?? "587");
                var senderEmail = _configuration["Email:SenderEmail"];
                var senderPassword = _configuration["Email:SenderPassword"];

                // Validate required configuration
                if (string.IsNullOrWhiteSpace(senderEmail))
                {
                    _logger.LogError("SMTP sender email is not configured. Check appsettings.json");
                    throw new InvalidOperationException("Email:SenderEmail is not configured.");
                }

                if (string.IsNullOrWhiteSpace(smtpServer))
                {
                    _logger.LogError("SMTP server is not configured. Check appsettings.json");
                    throw new InvalidOperationException("Email:SmtpServer is not configured.");
                }

                using (var client = new SmtpClient(smtpServer, smtpPort))
                {
                    client.EnableSsl = true;
                    client.Credentials = new NetworkCredential(senderEmail, senderPassword);

                    var mailMessage = new MailMessage
                    {
                        From = new MailAddress(senderEmail),  // ✅ FIX: Now safe - we validated it's not null
                        Subject = subject,
                        Body = htmlBody,
                        IsBodyHtml = true
                    };

                    mailMessage.To.Add(recipientEmail);

                    await client.SendMailAsync(mailMessage);
                    _logger.LogInformation("Email sent successfully to: {Email}", recipientEmail);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send email to: {Email}", recipientEmail);
                throw;
            }
        }

        private string BuildRoomAllocationEmailTemplate(string companyName, string roomName, int capacity, JobFair jobFair)
        {
            return $@"
                <!DOCTYPE html>
                <html>
                <head>
                    <style>
                        body {{ font-family: Arial, sans-serif; color: #333; }}
                        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; }}
                        .header {{ background-color: #2c3e50; color: white; padding: 20px; text-align: center; }}
                        .content {{ padding: 20px; }}
                        .room-info {{ background-color: #ecf0f1; padding: 15px; border-radius: 5px; margin: 15px 0; }}
                        .footer {{ background-color: #f5f5f5; padding: 15px; text-align: center; font-size: 12px; }}
                    </style>
                </head>
                <body>
                    <div class='container'>
                        <div class='header'>
                            <h1>Welcome to {jobFair.Semester} Job Fair!</h1>
                        </div>
                        <div class='content'>
                            <p>Dear <strong>{companyName}</strong>,</p>
                            <p>Thank you for confirming your participation in our job fair. We're excited to have you with us!</p>
                            
                            <div class='room-info'>
                                <h2>Your Room Assignment</h2>
                                <p><strong>Room Name:</strong> {roomName}</p>
                                <p><strong>Capacity:</strong> {capacity} people</p>
                                <p><strong>Job Fair:</strong> {jobFair.Semester}</p>
                                <p><strong>Date:</strong> {jobFair.date:MMMM dd, yyyy}</p>
                            </div>

                            <p><strong>Important Instructions:</strong></p>
                            <ul>
                                <li>Please arrive 15 minutes before the scheduled time</li>
                                <li>Your representatives should check in at the registration desk</li>
                                <li>Ensure all necessary materials and equipment are brought</li>
                                <li>If you need any assistance, please contact the organizing committee</li>
                            </ul>

                            <p>We look forward to meeting you and your team!</p>
                            <p>Best regards,<br>Job Fair Organizing Committee</p>
                        </div>
                        <div class='footer'>
                            <p>This is an automated message. Please do not reply directly to this email.</p>
                        </div>
                    </div>
                </body>
                </html>";
        }

        private string BuildPendingRoomAllocationEmailTemplate(string companyName, int representativeCount, JobFair jobFair)
        {
            return $@"
                <!DOCTYPE html>
                <html>
                <head>
                    <style>
                        body {{ font-family: Arial, sans-serif; color: #333; }}
                        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; }}
                        .header {{ background-color: #2c3e50; color: white; padding: 20px; text-align: center; }}
                        .content {{ padding: 20px; }}
                        .notice {{ background-color: #fff3cd; padding: 15px; border-left: 4px solid #ffc107; margin: 15px 0; }}
                        .footer {{ background-color: #f5f5f5; padding: 15px; text-align: center; font-size: 12px; }}
                    </style>
                </head>
                <body>
                    <div class='container'>
                        <div class='header'>
                            <h1>Confirmation Received - {jobFair.Semester} Job Fair</h1>
                        </div>
                        <div class='content'>
                            <p>Dear <strong>{companyName}</strong>,</p>
                            <p>Thank you for confirming your participation in our job fair!</p>
                            
                            <div class='notice'>
                                <h3>Important Notice</h3>
                                <p>We currently don't have a suitable room available for {representativeCount} representatives. 
                                   However, when you arrive at the job fair, our team will ensure a room is allocated to you 
                                   based on availability.</p>
                            </div>

                            <p><strong>What to Do:</strong></p>
                            <ul>
                                <li>Arrive at the job fair venue on time</li>
                                <li>Proceed to the registration desk</li>
                                <li>Our team will assign you to an appropriate room</li>
                                <li>Check in with your representatives</li>
                            </ul>

                            <p><strong>Job Fair Details:</strong></p>
                            <p>Date: {jobFair.date:MMMM dd, yyyy}</p>
                            <p>Number of Representatives: {representativeCount}</p>

                            <p>If you have any questions, please don't hesitate to contact us.</p>
                            <p>Best regards,<br>Job Fair Organizing Committee</p>
                        </div>
                        <div class='footer'>
                            <p>This is an automated message. Please do not reply directly to this email.</p>
                        </div>
                    </div>
                </body>
                </html>";
        }

        private string BuildRoomChangeEmailTemplate(string companyName, string oldRoomName, string newRoomName, JobFair jobFair)
        {
            return $@"
                <!DOCTYPE html>
                <html>
                <head>
                    <style>
                        body {{ font-family: Arial, sans-serif; color: #333; }}
                        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; }}
                        .header {{ background-color: #2c3e50; color: white; padding: 20px; text-align: center; }}
                        .content {{ padding: 20px; }}
                        .update {{ background-color: #d4edda; padding: 15px; border-left: 4px solid #28a745; margin: 15px 0; }}
                        .footer {{ background-color: #f5f5f5; padding: 15px; text-align: center; font-size: 12px; }}
                    </style>
                </head>
                <body>
                    <div class='container'>
                        <div class='header'>
                            <h1>Room Assignment Updated</h1>
                        </div>
                        <div class='content'>
                            <p>Dear <strong>{companyName}</strong>,</p>
                            <p>We have updated your room assignment for the {jobFair.Semester} Job Fair.</p>
                            
                            <div class='update'>
                                <h3>Updated Room Assignment</h3>
                                <p><strong>Previous Room:</strong> {oldRoomName}</p>
                                <p><strong>New Room:</strong> {newRoomName}</p>
                            </div>

                            <p>Please note the change and update any internal communications within your team.</p>
                            <p>We look forward to your participation!</p>
                            <p>Best regards,<br>Job Fair Organizing Committee</p>
                        </div>
                        <div class='footer'>
                            <p>This is an automated message. Please do not reply directly to this email.</p>
                        </div>
                    </div>
                </body>
                </html>";
        }
    }
}