using Microsoft.EntityFrameworkCore.Migrations;
using System.Collections.Generic;

#nullable disable

namespace JobFairPortal.Migrations
{
    public partial class FixSkillsColumn : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Drop the old Skills column
            migrationBuilder.DropColumn(
                name: "Skills",
                table: "Students");

            // Add a new proper JSONB column for skills
            migrationBuilder.AddColumn<List<string>>(
                name: "Skills",
                table: "Students",
                type: "jsonb",
                nullable: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // If rolling back, add Skills as text
            migrationBuilder.AddColumn<string>(
                name: "Skills",
                table: "Students",
                type: "text",
                nullable: true);
        }
    }
}
