public class PasswordResetToken
{
    public string Token { get; set; } = null!;
    public DateTime ExpiryTime { get; set; }
    public string Email { get; set; } = null!;
    public bool IsUsed { get; set; }
}