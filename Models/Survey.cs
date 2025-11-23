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

    // 1. Define the Rating Options
    public enum SurveyRating
    {
        Good,
        Average,
        Bad
    }

    // 2. Define the Structure of your Questionnaire
    public class SurveyResponseData
    {
        // Q1: Overall Student’s FYP quality
        [JsonConverter(typeof(JsonStringEnumConverter))]
        public SurveyRating FypQuality { get; set; }
        public string? FypComments { get; set; }

        // Q2: Overall arrangements in this Job fair
        [JsonConverter(typeof(JsonStringEnumConverter))]
        public SurveyRating ArrangementQuality { get; set; }
        public string? ArrangementComments { get; set; }

        // Q3: Refreshment and Lunch quality
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

        // The raw JSON string stored in the database
        public string? Responses { get; set; }

        // 3. Helper property to work with the data as an Object in your code
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