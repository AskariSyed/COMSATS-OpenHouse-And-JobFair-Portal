using System.IO;

namespace JobFairPortal.Services
{
    /// <summary>
    /// Generates branded HTML email templates for all system emails.
    /// The logo is embedded as a base64 inline data-URI so it renders
    /// without needing a publicly accessible URL.
    /// </summary>
    public static class EmailTemplateService
    {
        // ──────────────────────────────────────────────────────────────
        // Logo (lazy-loaded once per process lifetime)
        // ──────────────────────────────────────────────────────────────
        private static string? _logoBase64;

        private static string GetLogoBase64()
        {
            if (_logoBase64 != null) return _logoBase64;

            // Try to find the logo relative to the running executable
            var candidates = new[]
            {
                Path.Combine(AppContext.BaseDirectory, "wwwroot", "logo.png"),
                Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "logo.png"),
                Path.Combine(AppContext.BaseDirectory, "wwwroot", "LogoWithoutBg.png"),
                Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "LogoWithoutBg.png"),
            };

            foreach (var path in candidates)
            {
                if (File.Exists(path))
                {
                    var bytes = File.ReadAllBytes(path);
                    _logoBase64 = Convert.ToBase64String(bytes);
                    return _logoBase64;
                }
            }

            // Fallback: empty string (logo img tag will be hidden by the onerror handler)
            _logoBase64 = string.Empty;
            return _logoBase64;
        }

        private static string LogoImgTag()
        {
            var b64 = GetLogoBase64();
            if (string.IsNullOrEmpty(b64))
                return "<span style=\"font-size:22px;font-weight:800;color:#ffffff;letter-spacing:-0.5px;\">JF<span style=\"color:#fbbf24;\">.</span></span>";

            return $"<img src=\"data:image/png;base64,{b64}\" alt=\"Job Fair Portal\" " +
                   "style=\"height:52px;width:auto;display:block;margin:0 auto;\" " +
                   "onerror=\"this.style.display='none'\" />";
        }

        // ──────────────────────────────────────────────────────────────
        // Base layout wrapper
        // ──────────────────────────────────────────────────────────────
        private static string Wrap(string innerHtml, string previewText = "")
        {
            var logo = LogoImgTag();
            return $@"<!DOCTYPE html>
<html lang=""en"">
<head>
  <meta charset=""UTF-8"" />
  <meta name=""viewport"" content=""width=device-width,initial-scale=1"" />
  <title>Job Fair Portal</title>
</head>
<body style=""margin:0;padding:0;background:#f1f5f9;font-family:'Segoe UI',Arial,sans-serif;"">
  {(string.IsNullOrEmpty(previewText) ? "" : $"<div style=\"display:none;max-height:0;overflow:hidden;mso-hide:all;\">{previewText}</div>")}

  <table role=""presentation"" cellspacing=""0"" cellpadding=""0"" border=""0"" width=""100%"" style=""background:#f1f5f9;"">
    <tr><td align=""center"" style=""padding:40px 16px;"">
      <table role=""presentation"" cellspacing=""0"" cellpadding=""0"" border=""0"" width=""100%"" style=""max-width:560px;"">

        <!-- HEADER -->
        <tr>
          <td align=""center""
              style=""background:linear-gradient(135deg,#1e40af 0%,#4f46e5 100%);
                      border-radius:16px 16px 0 0;padding:32px 24px 28px;"">
            {logo}
            <p style=""margin:12px 0 0;color:#bfdbfe;font-size:13px;letter-spacing:0.5px;text-transform:uppercase;"">
              COMSATS Job Fair Portal &bull; WAH CANTT
            </p>
          </td>
        </tr>

        <!-- BODY -->
        <tr>
          <td style=""background:#ffffff;padding:36px 36px 28px;border-left:1px solid #e2e8f0;border-right:1px solid #e2e8f0;"">
            {innerHtml}
          </td>
        </tr>

        <!-- FOOTER -->
        <tr>
          <td align=""center""
              style=""background:#1e293b;border-radius:0 0 16px 16px;
                      padding:20px 24px;color:#94a3b8;font-size:12px;line-height:1.6;"">
            <p style=""margin:0 0 4px;"">
              &copy; {DateTime.UtcNow.Year} COMSATS Job Fair Portal &mdash; Wah Cantt Campus
            </p>
            <p style=""margin:0;color:#64748b;"">
              This is an automated email. Please do not reply directly to this message.
            </p>
          </td>
        </tr>

      </table>
    </td></tr>
  </table>
</body>
</html>";
        }

        // ──────────────────────────────────────────────────────────────
        // Reusable inner-block helpers
        // ──────────────────────────────────────────────────────────────
        private static string Greeting(string name) =>
            $"<h2 style=\"margin:0 0 8px;font-size:22px;font-weight:700;color:#1e293b;\">Hello, {HtmlEncode(name)} 👋</h2>";

        private static string P(string text) =>
            $"<p style=\"margin:0 0 16px;font-size:15px;color:#475569;line-height:1.7;\">{text}</p>";

        private static string Divider() =>
            "<hr style=\"border:none;border-top:1px solid #e2e8f0;margin:24px 0;\" />";

        private static string CredentialRow(string label, string value, bool highlight = false) =>
            $@"<tr>
                 <td style=""padding:10px 14px;font-size:13px;color:#64748b;width:120px;"">{HtmlEncode(label)}</td>
                 <td style=""padding:10px 14px;font-size:14px;color:#1e293b;font-weight:{(highlight ? "700" : "600")};"">
                   {(highlight
                       ? $"<code style=\"background:#f0fdf4;color:#15803d;padding:4px 10px;border-radius:6px;font-size:15px;letter-spacing:1px;\">{HtmlEncode(value)}</code>"
                       : HtmlEncode(value))}
                 </td>
               </tr>";

        private static string CredentialTable(params (string label, string value, bool highlight)[] rows)
        {
            var inner = string.Join("\n", rows.Select(r => CredentialRow(r.label, r.value, r.highlight)));
            return $@"<table role=""presentation"" cellspacing=""0"" cellpadding=""0"" border=""0"" width=""100%""
                        style=""background:#f8fafc;border:1px solid #e2e8f0;border-radius:10px;
                                border-collapse:separate;margin:20px 0;"">
                       {inner}
                     </table>";
        }

        private static string OtpBox(string otp) =>
            $@"<div style=""text-align:center;margin:24px 0;"">
                 <div style=""display:inline-block;background:linear-gradient(135deg,#eff6ff,#eef2ff);
                              border:2px solid #c7d2fe;border-radius:14px;padding:20px 36px;"">
                   <p style=""margin:0 0 6px;font-size:12px;color:#6366f1;text-transform:uppercase;
                               font-weight:600;letter-spacing:1px;"">Your Verification Code</p>
                   <p style=""margin:0;font-size:40px;font-weight:800;letter-spacing:8px;color:#1e40af;
                               font-family:'Courier New',monospace;"">{HtmlEncode(otp)}</p>
                 </div>
               </div>";

        private static string WarningBox(string text) =>
            $@"<div style=""background:#fff7ed;border:1px solid #fed7aa;border-radius:10px;
                            padding:14px 18px;margin:20px 0;"">
                 <p style=""margin:0;font-size:13px;color:#92400e;"">⚠️ &nbsp;{text}</p>
               </div>";

        private static string InfoBox(string text) =>
            $@"<div style=""background:#eff6ff;border:1px solid #bfdbfe;border-radius:10px;
                            padding:14px 18px;margin:20px 0;"">
                 <p style=""margin:0;font-size:13px;color:#1e40af;"">ℹ️ &nbsp;{text}</p>
               </div>";

        private static string PrimaryButton(string url, string label) =>
            $@"<table role=""presentation"" cellspacing=""0"" cellpadding=""0"" border=""0"" width=""100%"">
                 <tr><td align=""center"" style=""padding:8px 0 20px;"">
                   <a href=""{url}"" target=""_blank""
                      style=""display:inline-block;background:linear-gradient(135deg,#1e40af,#4f46e5);
                              color:#ffffff;text-decoration:none;font-size:15px;font-weight:600;
                              padding:14px 36px;border-radius:10px;letter-spacing:0.3px;"">
                     {label}
                   </a>
                 </td></tr>
               </table>";

        private static string HtmlEncode(string? s) =>
            System.Net.WebUtility.HtmlEncode(s ?? string.Empty);

        // ──────────────────────────────────────────────────────────────
        // PUBLIC TEMPLATE METHODS
        // ──────────────────────────────────────────────────────────────

        /// <summary>
        /// Welcome email sent to a newly created co-admin with their auto-generated credentials.
        /// </summary>
        public static string GetWelcomeAdminTemplate(string name, string email, string password)
        {
            var inner = $@"
              {Greeting(name)}
              {P("A <strong>Co-Admin account</strong> has been created for you on the COMSATS Job Fair Portal. You can now log in using the credentials below.")}
              {Divider()}
              <p style=""margin:0 0 10px;font-size:13px;font-weight:600;color:#64748b;text-transform:uppercase;letter-spacing:0.5px;"">YOUR LOGIN CREDENTIALS</p>
              {CredentialTable(
                  ("Email", email, false),
                  ("Password", password, true)
              )}
              {WarningBox("For security, please change your password immediately after your first login.")}
              {P("The admin portal is accessible at your organization's admin URL. Contact your super admin if you need the link.")}
              {Divider()}
              {P("<em>If you did not expect this email, please contact your system administrator immediately.</em>")}
            ";
            return Wrap(inner, $"Your Co-Admin account has been created — credentials inside");
        }

        /// <summary>
        /// OTP email sent to the super admin to confirm a co-admin creation action.
        /// </summary>
        public static string GetAdminActionOtpTemplate(string adminName, string otp, int expiryMinutes)
        {
            var inner = $@"
              {Greeting(adminName)}
              {P("You requested to <strong>create a new Co-Admin account</strong>. To confirm this action, enter the verification code below in the admin portal.")}
              {OtpBox(otp)}
              {WarningBox($"This code expires in <strong>{expiryMinutes} minutes</strong>. Do not share it with anyone.")}
              {Divider()}
              {P("<em>If you did not initiate this action, please secure your account immediately by changing your password.</em>")}
            ";
            return Wrap(inner, $"Your admin action OTP: {otp}");
        }

        /// <summary>
        /// OTP email for company registration verification.
        /// </summary>
        public static string GetCompanyOtpTemplate(string otp, int expiryMinutes)
        {
            var inner = $@"
              <h2 style=""margin:0 0 8px;font-size:22px;font-weight:700;color:#1e293b;"">Company Registration OTP 🏢</h2>
              {P("Thank you for registering on the COMSATS Job Fair Portal. Please verify your email address using the code below.")}
              {OtpBox(otp)}
              {WarningBox($"This code is valid for <strong>{expiryMinutes} minutes</strong> only. Do not share it with anyone.")}
              {Divider()}
              {P("<em>If you did not register on the Job Fair Portal, please ignore this email.</em>")}
            ";
            return Wrap(inner, $"Your company registration OTP: {otp}");
        }

        /// <summary>
        /// Welcome/credentials email sent to a newly registered student.
        /// </summary>
        public static string GetStudentWelcomeTemplate(string email, string tempPassword, string semester, string jobFairDate)
        {
            var inner = $@"
              <h2 style=""margin:0 0 8px;font-size:22px;font-weight:700;color:#1e293b;"">Welcome to the Job Fair Portal! 🎓</h2>
              {P("Your student account has been successfully created on the COMSATS Job Fair Portal.")}
              {Divider()}
              <p style=""margin:0 0 10px;font-size:13px;font-weight:600;color:#64748b;text-transform:uppercase;letter-spacing:0.5px;"">YOUR LOGIN CREDENTIALS</p>
              {CredentialTable(
                  ("Email", email, false),
                  ("Password", tempPassword, true)
              )}
              {InfoBox($"You are registered for <strong>{HtmlEncode(semester)}</strong> Job Fair scheduled on <strong>{HtmlEncode(jobFairDate)}</strong>.")}
              {WarningBox("Please log in and complete your profile as soon as possible. Change your password after the first login.")}
            ";
            return Wrap(inner, "Your Job Fair Portal credentials");
        }

        /// <summary>
        /// Password reset link email (token-based, for non-OTP flow).
        /// </summary>
        public static string GetPasswordResetLinkTemplate(string name, string resetLink, int expiryMinutes)
        {
            var inner = $@"
              {Greeting(name)}
              {P("We received a request to <strong>reset your password</strong>. Click the button below to proceed. This link will expire in <strong>{expiryMinutes} minutes</strong>.")}
              {PrimaryButton(resetLink, "Reset My Password")}
              {WarningBox("If you did not request a password reset, you can safely ignore this email. Your password will remain unchanged.")}
              {Divider()}
              {P($"If the button doesn't work, copy and paste this link into your browser:<br/><a href=\"{resetLink}\" style=\"color:#4f46e5;word-break:break-all;\">{HtmlEncode(resetLink)}</a>")}
            ";
            return Wrap(inner, "Reset your Job Fair Portal password");
        }

        /// <summary>
        /// OTP-based password reset email.
        /// </summary>
        public static string GetPasswordResetOtpTemplate(string name, string otp, int expiryMinutes)
        {
            var inner = $@"
              {Greeting(name)}
              {P("You requested to <strong>reset your password</strong>. Use the verification code below to proceed.")}
              {OtpBox(otp)}
              {WarningBox($"This code expires in <strong>{expiryMinutes} minutes</strong>. Do not share it with anyone.")}
              {Divider()}
              {P("<em>If you did not request a password reset, please ignore this email or contact support.</em>")}
            ";
            return Wrap(inner, $"Your password reset OTP: {otp}");
        }

        /// <summary>
        /// Confirmation email sent after a successful password change.
        /// </summary>
        public static string GetPasswordChangedTemplate(string name)
        {
            var inner = $@"
              {Greeting(name)}
              <div style=""text-align:center;padding:16px 0;"">
                <div style=""display:inline-block;background:#f0fdf4;border:2px solid #bbf7d0;
                             border-radius:50%;width:64px;height:64px;line-height:64px;font-size:32px;"">✅</div>
              </div>
              <h3 style=""text-align:center;margin:0 0 16px;color:#15803d;font-size:18px;"">Password Changed Successfully</h3>
              {P("Your account password has been updated successfully. You can now log in using your new password.")}
              {WarningBox("If you did not make this change, please contact your administrator or reset your password immediately.")}
            ";
            return Wrap(inner, "Your password has been changed");
        }

    }
}
