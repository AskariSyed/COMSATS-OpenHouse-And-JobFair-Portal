using JobFairPortal.DTOs;
using JobFairPortal.Models;
using System.Text.RegularExpressions;

namespace JobFairPortal.Services
{
    public class AuthValidationService
    {
        private const string REGISTRATION_NO_PATTERN = @"^(FA|SP)\d{2}-[A-Z]{3}-\d{3}$";
        private const string EMAIL_PATTERN = @"^[^@\s]+@[^@\s]+\.[^@\s]+$";
        private const int PASSWORD_MIN_LENGTH = 8;

        public bool ValidateLoginDto(LoginDto dto, out string? error)
        {
            error = null;

            if (string.IsNullOrWhiteSpace(dto?.EmailOrRegNo))
            {
                error = "Email or Registration Number is required.";
                return false;
            }

            if (string.IsNullOrWhiteSpace(dto.Password))
            {
                error = "Password is required.";
                return false;
            }

            return true;
        }

        public bool ValidateStudentRegistration(StudentRegistrationDto dto, out string? error)
        {
            error = null;

            if (string.IsNullOrWhiteSpace(dto?.RegistrationNo))
            {
                error = "Registration number is required.";
                return false;
            }

            if (!Regex.IsMatch(dto.RegistrationNo.Trim(), REGISTRATION_NO_PATTERN, RegexOptions.IgnoreCase))
            {
                error = "Invalid registration number format. Example: FA22-BCS-155";
                return false;
            }

            return true;
        }

        public bool ValidateCompanySignup(CompanySignupDto dto, out string? error)
        {
            error = null;

            if (string.IsNullOrWhiteSpace(dto?.UserEmail) || !Regex.IsMatch(dto.UserEmail, EMAIL_PATTERN))
            {
                error = "Valid user email is required.";
                return false;
            }

            if (string.IsNullOrWhiteSpace(dto.UserFullName))
            {
                error = "User full name is required.";
                return false;
            }

            if (string.IsNullOrWhiteSpace(dto.UserPassword) || dto.UserPassword.Length < PASSWORD_MIN_LENGTH)
            {
                error = $"Password must be at least {PASSWORD_MIN_LENGTH} characters.";
                return false;
            }

            if (string.IsNullOrWhiteSpace(dto.Name))
            {
                error = "Company name is required.";
                return false;
            }

            if (string.IsNullOrWhiteSpace(dto.FocalPersonName) || string.IsNullOrWhiteSpace(dto.FocalPersonEmail))
            {
                error = "Focal person name and email are required.";
                return false;
            }

            if (dto.RepsCount <= 0 || dto.InterviewDurationMinutes <= 0)
            {
                error = "Representatives count and interview duration must be greater than 0.";
                return false;
            }

            return true;
        }

        public bool ValidateCompanyOtpVerify(CompanyOtpVerifyDto dto, out string? error)
        {
            error = null;

            if (string.IsNullOrWhiteSpace(dto?.RepEmail) || string.IsNullOrWhiteSpace(dto.UserEmail) || string.IsNullOrWhiteSpace(dto.Otp))
            {
                error = "Email and OTP are required.";
                return false;
            }

            if (dto.Otp.Length != 6 || !dto.Otp.All(char.IsDigit))
            {
                error = "OTP must be 6 digits.";
                return false;
            }

            return true;
        }

        public bool ValidateCompanyResendOtp(CompanyResendOtpDto dto, out string? error)
        {
            error = null;

            if (string.IsNullOrWhiteSpace(dto?.RepEmail) || string.IsNullOrWhiteSpace(dto.UserEmail))
            {
                error = "Email is required.";
                return false;
            }

            return true;
        }

        public bool ValidateForgotPassword(ForgotPasswordDto dto, out string? error)
        {
            error = null;

            if (string.IsNullOrWhiteSpace(dto?.Email) || !Regex.IsMatch(dto.Email, EMAIL_PATTERN))
            {
                error = "Valid email is required.";
                return false;
            }

            return true;
        }

        public bool ValidateVerifyResetToken(VerifyResetTokenDto dto, out string? error)
        {
            error = null;

            if (string.IsNullOrWhiteSpace(dto?.Token) || dto.UserId <= 0)
            {
                error = "Token and UserId are required.";
                return false;
            }

            return true;
        }

        public bool ValidateResetPassword(ResetPasswordDto dto, out string? error)
        {
            error = null;

            if (string.IsNullOrWhiteSpace(dto?.Token) || dto.UserId <= 0)
            {
                error = "Token and UserId are required.";
                return false;
            }

            if (string.IsNullOrWhiteSpace(dto.NewPassword) || dto.NewPassword.Length < PASSWORD_MIN_LENGTH)
            {
                error = $"Password must be at least {PASSWORD_MIN_LENGTH} characters.";
                return false;
            }

            if (dto.NewPassword != dto.ConfirmPassword)
            {
                error = "Passwords do not match.";
                return false;
            }

            return true;
        }

        public bool ValidateForgotPasswordOtp(ForgotPasswordOtpDto dto, out string? error)
        {
            error = null;

            if (string.IsNullOrWhiteSpace(dto?.EmailOrRegNo))
            {
                error = "Email or Registration Number is required.";
                return false;
            }

            return true;
        }

        public bool ValidateVerifyPasswordResetOtp(VerifyPasswordResetOtpDto dto, out string? error)
        {
            error = null;

            if (dto?.UserId <= 0 || string.IsNullOrWhiteSpace(dto.Otp))
            {
                error = "UserId and OTP are required.";
                return false;
            }

            if (dto.Otp.Length != 6 || !dto.Otp.All(char.IsDigit))
            {
                error = "OTP must be 6 digits.";
                return false;
            }

            if (string.IsNullOrWhiteSpace(dto.NewPassword) || dto.NewPassword.Length < PASSWORD_MIN_LENGTH)
            {
                error = $"Password must be at least {PASSWORD_MIN_LENGTH} characters.";
                return false;
            }

            if (dto.NewPassword != dto.ConfirmPassword)
            {
                error = "Passwords do not match.";
                return false;
            }

            return true;
        }

        public bool ValidateChangePassword(ChangePasswordDto dto, out string? error)
        {
            error = null;

            if (string.IsNullOrWhiteSpace(dto?.CurrentPassword))
            {
                error = "Current password is required.";
                return false;
            }

            if (string.IsNullOrWhiteSpace(dto.NewPassword) || dto.NewPassword.Length < PASSWORD_MIN_LENGTH)
            {
                error = $"New password must be at least {PASSWORD_MIN_LENGTH} characters long.";
                return false;
            }

            if (dto.NewPassword != dto.ConfirmPassword)
            {
                error = "Passwords do not match.";
                return false;
            }

            // Prevent using the same password
            if (dto.CurrentPassword.Equals(dto.NewPassword, StringComparison.Ordinal))
            {
                error = "New password must be different from the current password.";
                return false;
            }

            return true;
        }

        public bool IsStudentProfileComplete(Student student)
        {
            return !string.IsNullOrWhiteSpace(student.Department)
                && student.Skills != null && student.Skills.Count > 0
                && !string.IsNullOrWhiteSpace(student.ProfilePicUrl);
        }

        public string? ExtractDepartmentFromRegNo(string registrationNo)
        {
            var parts = registrationNo.Split('-');
            if (parts.Length < 2)
                return null;

            return parts[1].ToUpper() switch
            {
                "BCS" or "BSE" or "BAI" => "Computer Science",
                "CVE" => "Civil Engineering",
                "BME" => "Mechanical Engineering",
                "BEE" or "BCE" => "Electrical Engineering",
                "BBA" or "BAF" => "Management Sciences",
                _ => null
            };
        }
    }
}