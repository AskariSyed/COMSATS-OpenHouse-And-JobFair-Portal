namespace JobFairPortal.DTOs
{
    public class FcmMessageDto
    {
        public string Title { get; set; } = null!;
        public string Body { get; set; } = null!;
        public Dictionary<string, string>? Data { get; set; }
    }
}