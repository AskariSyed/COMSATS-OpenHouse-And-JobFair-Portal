using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace JobFairPortal.Models
{
    [JsonConverter(typeof(JsonStringEnumConverter))]
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

    // 5-point Likert scale
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public enum LikertScale
    {
        Exceptionally,
        ToAGreatExtent,
        Moderately,
        Somewhat,
        NotAtAll
    }

    public class SurveyResponseData
    {
        // Existing questions
        [JsonConverter(typeof(JsonStringEnumConverter))]
        public SurveyRating FypQuality { get; set; }
        public string? FypComments { get; set; }

        [JsonConverter(typeof(JsonStringEnumConverter))]
        public SurveyRating ArrangementQuality { get; set; }
        public string? ArrangementComments { get; set; }

        [JsonConverter(typeof(JsonStringEnumConverter))]
        public SurveyRating LunchQuality { get; set; }
        public string? LunchComments { get; set; }

        // ----------------------------
        // New: Program Educational Objectives (PEOs)
        // PEO-1: Technical Knowledge & Creativity
        // ----------------------------
        [JsonConverter(typeof(JsonStringEnumConverter))]
        public LikertScale PEO1_Q1 { get; set; } = LikertScale.Moderately; // Possess adequate technical knowledge
        [JsonConverter(typeof(JsonStringEnumConverter))]
        public LikertScale PEO1_Q2 { get; set; } = LikertScale.Moderately; // Ability to analyze / investigate
        [JsonConverter(typeof(JsonStringEnumConverter))]
        public LikertScale PEO1_Q3 { get; set; } = LikertScale.Moderately; // Ability to design & implement solutions

        // ----------------------------
        // PEO-2: Adaptability & Entrepreneurship
        // ----------------------------
        [JsonConverter(typeof(JsonStringEnumConverter))]
        public LikertScale PEO2_Q1 { get; set; } = LikertScale.Moderately; // Desire to learn & adapt
        [JsonConverter(typeof(JsonStringEnumConverter))]
        public LikertScale PEO2_Q2 { get; set; } = LikertScale.Moderately; // Prepared to promote entrepreneurship

        // ----------------------------
        // PEO-3: Ethics & Communication
        // ----------------------------
        [JsonConverter(typeof(JsonStringEnumConverter))]
        public LikertScale PEO3_Q1 { get; set; } = LikertScale.Moderately; // Awareness about ethics
        [JsonConverter(typeof(JsonStringEnumConverter))]
        public LikertScale PEO3_Q2 { get; set; } = LikertScale.Moderately; // Oral & written communication skills

        // ----------------------------
        // PEO-4: Socio-Economic Contribution
        // ----------------------------
        [JsonConverter(typeof(JsonStringEnumConverter))]
        public LikertScale PEO4_Q1 { get; set; } = LikertScale.Moderately; // Educated & trained to contribute to society
        [JsonConverter(typeof(JsonStringEnumConverter))]
        public LikertScale PEO4_Q2 { get; set; } = LikertScale.Moderately; // Trained for economic growth contribution
        [JsonConverter(typeof(JsonStringEnumConverter))]
        public LikertScale PEO4_Q3 { get; set; } = LikertScale.Moderately; // Ability to support innovation

        // ----------------------------
        // New: Open-ended / Qualitative Questions
        // ----------------------------
        public string? TechnologiesSuggestion { get; set; } // "What additional technologies / programming languages / skills ..."
        public string? GeneralFeedback { get; set; }        // "Please feel free to give your input / feedback ..."
        public string? ImprovementSuggestions { get; set; } // "Any comments or suggestions that you may have ..."
    }

    public class Survey
    {
        [Key]
        public int SurveyId { get; set; }
        public SurveyType Type { get; set; }
        public int CompanyId { get; set; }

        // Stored as JSON in DB
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