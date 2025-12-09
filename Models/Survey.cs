using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace JobFairPortal.Models
{
    public enum SurveyType
    {
        CDC,
        Department
    }
    public enum SurveyRating
    {
        Good,
        Average,
        Bad
    }

    public class SurveyResponseData
    {
        [JsonConverter(typeof(JsonStringEnumConverter))]
        public SurveyRating FypQuality { get; set; }
        public string? FypComments { get; set; }

        [JsonConverter(typeof(JsonStringEnumConverter))]
        public SurveyRating ArrangementQuality { get; set; }
        public string? ArrangementComments { get; set; }

        [JsonConverter(typeof(JsonStringEnumConverter))]
        public SurveyRating LunchQuality { get; set; }
        public string? LunchComments { get; set; }
    }

    public class Survey
    {
        [Key]
        public int SurveyId { get; set; }
        public SurveyType Type { get; set; }
        public int CompanyId { get; set; }

        public string? Responses { get; set; }

        [NotMapped]
        public SurveyResponseData? ResponseData
        {
            get => string.IsNullOrEmpty(Responses)
                ? null
                : JsonSerializer.Deserialize<SurveyResponseData>(Responses);
            set => Responses = JsonSerializer.Serialize(value);
        }

        public DateTime SubmittedAt { get; set; } = DateTime.UtcNow;

        public Company Company { get; set; } = null!;
        public int JobFairId { get; set; }
        public JobFair JobFair { get; set; } = null!;
    }
}