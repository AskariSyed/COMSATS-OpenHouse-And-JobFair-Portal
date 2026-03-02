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

            // ✅ From must match Gmail account
            var gmailUser = _config["Smtp:User"];
            message.From.Add(new MailboxAddress("Job Fair Portal", gmailUser));

            //// ✅ Optional: set Reply-To to CUI email
            //message.ReplyTo.Add(new MailboxAddress("Job Fair Portal", "jobfair@cuiwah.edu.pk"));

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
            var port = int.Parse(_config["Smtp:Port"]);

            var socketOptions = port == 465
                ? SecureSocketOptions.SslOnConnect
                : SecureSocketOptions.StartTls;

            await client.ConnectAsync(host, port, socketOptions);

            // ✅ Authenticate with App Password
            await client.AuthenticateAsync(gmailUser, _config["Smtp:Pass"]);

            await client.SendAsync(message);
            await client.DisconnectAsync(true);
        }
    }
}
