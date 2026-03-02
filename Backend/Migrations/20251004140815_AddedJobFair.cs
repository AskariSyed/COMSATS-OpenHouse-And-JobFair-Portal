using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace JobFairPortal.Migrations
{
    /// <inheritdoc />
    public partial class AddedJobFair : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "JobFairId",
                table: "Surveys",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "JobFairId",
                table: "Rooms",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "JobFairId",
                table: "Jobs",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "JobFairId",
                table: "Interviews",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "JobFairId",
                table: "Companies",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "JobFairs",
                columns: table => new
                {
                    JobFairId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Semester = table.Column<string>(type: "text", nullable: false),
                    date = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_JobFairs", x => x.JobFairId);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Surveys_JobFairId",
                table: "Surveys",
                column: "JobFairId");

            migrationBuilder.CreateIndex(
                name: "IX_Rooms_JobFairId",
                table: "Rooms",
                column: "JobFairId");

            migrationBuilder.CreateIndex(
                name: "IX_Jobs_JobFairId",
                table: "Jobs",
                column: "JobFairId");

            migrationBuilder.CreateIndex(
                name: "IX_Interviews_JobFairId",
                table: "Interviews",
                column: "JobFairId");

            migrationBuilder.CreateIndex(
                name: "IX_Companies_JobFairId",
                table: "Companies",
                column: "JobFairId");

            migrationBuilder.AddForeignKey(
                name: "FK_Companies_JobFairs_JobFairId",
                table: "Companies",
                column: "JobFairId",
                principalTable: "JobFairs",
                principalColumn: "JobFairId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Interviews_JobFairs_JobFairId",
                table: "Interviews",
                column: "JobFairId",
                principalTable: "JobFairs",
                principalColumn: "JobFairId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Jobs_JobFairs_JobFairId",
                table: "Jobs",
                column: "JobFairId",
                principalTable: "JobFairs",
                principalColumn: "JobFairId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Rooms_JobFairs_JobFairId",
                table: "Rooms",
                column: "JobFairId",
                principalTable: "JobFairs",
                principalColumn: "JobFairId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Surveys_JobFairs_JobFairId",
                table: "Surveys",
                column: "JobFairId",
                principalTable: "JobFairs",
                principalColumn: "JobFairId",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Companies_JobFairs_JobFairId",
                table: "Companies");

            migrationBuilder.DropForeignKey(
                name: "FK_Interviews_JobFairs_JobFairId",
                table: "Interviews");

            migrationBuilder.DropForeignKey(
                name: "FK_Jobs_JobFairs_JobFairId",
                table: "Jobs");

            migrationBuilder.DropForeignKey(
                name: "FK_Rooms_JobFairs_JobFairId",
                table: "Rooms");

            migrationBuilder.DropForeignKey(
                name: "FK_Surveys_JobFairs_JobFairId",
                table: "Surveys");

            migrationBuilder.DropTable(
                name: "JobFairs");

            migrationBuilder.DropIndex(
                name: "IX_Surveys_JobFairId",
                table: "Surveys");

            migrationBuilder.DropIndex(
                name: "IX_Rooms_JobFairId",
                table: "Rooms");

            migrationBuilder.DropIndex(
                name: "IX_Jobs_JobFairId",
                table: "Jobs");

            migrationBuilder.DropIndex(
                name: "IX_Interviews_JobFairId",
                table: "Interviews");

            migrationBuilder.DropIndex(
                name: "IX_Companies_JobFairId",
                table: "Companies");

            migrationBuilder.DropColumn(
                name: "JobFairId",
                table: "Surveys");

            migrationBuilder.DropColumn(
                name: "JobFairId",
                table: "Rooms");

            migrationBuilder.DropColumn(
                name: "JobFairId",
                table: "Jobs");

            migrationBuilder.DropColumn(
                name: "JobFairId",
                table: "Interviews");

            migrationBuilder.DropColumn(
                name: "JobFairId",
                table: "Companies");
        }
    }
}
