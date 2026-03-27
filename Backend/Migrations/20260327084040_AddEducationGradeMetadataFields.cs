using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace JobFairPortal.Migrations
{
    /// <inheritdoc />
    public partial class AddEducationGradeMetadataFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "GradeType",
                table: "Educations",
                type: "character varying(20)",
                maxLength: 20,
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "GradeValue",
                table: "Educations",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "MarksObtained",
                table: "Educations",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "TotalMarks",
                table: "Educations",
                type: "double precision",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "GradeType",
                table: "Educations");

            migrationBuilder.DropColumn(
                name: "GradeValue",
                table: "Educations");

            migrationBuilder.DropColumn(
                name: "MarksObtained",
                table: "Educations");

            migrationBuilder.DropColumn(
                name: "TotalMarks",
                table: "Educations");
        }
    }
}
