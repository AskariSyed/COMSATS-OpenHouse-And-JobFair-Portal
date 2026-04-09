using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;
using Microsoft.Extensions.Configuration;
using System.Threading.Tasks;
using System.Text.RegularExpressions;

namespace JobFairPortal.Services
{
    public class MailKitMailService
    {
        private readonly IConfiguration _config;

        public MailKitMailService(IConfiguration config)
        {
            _config = config;
        }

        public async Task SendMailAsync(string toEmail, string subject, string body)
        {
            var message = new MimeMessage();

        
            var gmailUser = _config["Smtp:User"];
            if (string.IsNullOrWhiteSpace(gmailUser))
            {
                throw new InvalidOperationException("SMTP user is not configured (Smtp:User).");
            }
            message.From.Add(new MailboxAddress("Job Fair Portal", gmailUser));
            message.To.Add(MailboxAddress.Parse(toEmail));
            message.Subject = subject;
            message.ReplyTo.Add(new MailboxAddress("Job Fair Portal", "askari.syed04@gmail.com"));

            var builder = new BodyBuilder();
            var looksLikeHtml = !string.IsNullOrWhiteSpace(body) && body.Contains("<") && body.Contains(">") && body.Contains("</");

            if (looksLikeHtml)
            {
                builder.HtmlBody = body;
                builder.TextBody = Regex.Replace(body, "<.*?>", string.Empty);
            }
            else
            {
                builder.TextBody = body;
            }

            message.Body = builder.ToMessageBody();


            using var client = new SmtpClient();

            var host = _config["Smtp:Host"];
            if (string.IsNullOrWhiteSpace(host))
            {
                throw new InvalidOperationException("SMTP host is not configured (Smtp:Host).");
            }

            if (!int.TryParse(_config["Smtp:Port"], out var port))
            {
                throw new InvalidOperationException("SMTP port is invalid or missing (Smtp:Port).");
            }

            var smtpPass = _config["Smtp:Pass"];
            if (string.IsNullOrWhiteSpace(smtpPass))
            {
                throw new InvalidOperationException("SMTP password is not configured (Smtp:Pass).");
            }

            var socketOptions = port == 465
                ? SecureSocketOptions.SslOnConnect
                : SecureSocketOptions.StartTls;

            await client.ConnectAsync(host, port, socketOptions);

            // ✅ Authenticate with App Password
            await client.AuthenticateAsync(gmailUser, smtpPass);

            await client.SendAsync(message);
            await client.DisconnectAsync(true);
        }
    }
}
