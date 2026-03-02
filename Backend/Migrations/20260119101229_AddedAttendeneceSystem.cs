using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace JobFairPortal.Migrations
{
    /// <inheritdoc />
    public partial class AddedAttendeneceSystem : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "AttendanceToken",
                table: "CompanyJobFairParticipations",
                type: "character varying(200)",
                maxLength: 200,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "AttendanceTokenExpiry",
                table: "CompanyJobFairParticipations",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "AdminAttendanceSessions",
                columns: table => new
                {
                    AdminAttendanceSessionId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    SessionToken = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    JobFairId = table.Column<int>(type: "integer", nullable: false),
                    CreatedByAdmin = table.Column<string>(type: "text", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AdminAttendanceSessions", x => x.AdminAttendanceSessionId);
                    table.ForeignKey(
                        name: "FK_AdminAttendanceSessions_JobFairs_JobFairId",
                        column: x => x.JobFairId,
                        principalTable: "JobFairs",
                        principalColumn: "JobFairId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_AdminAttendanceSessions_JobFairId_IsActive",
                table: "AdminAttendanceSessions",
                columns: new[] { "JobFairId", "IsActive" });

            migrationBuilder.CreateIndex(
                name: "IX_AdminAttendanceSessions_SessionToken",
                table: "AdminAttendanceSessions",
                column: "SessionToken",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AdminAttendanceSessions");

            migrationBuilder.DropColumn(
                name: "AttendanceToken",
                table: "CompanyJobFairParticipations");

            migrationBuilder.DropColumn(
                name: "AttendanceTokenExpiry",
                table: "CompanyJobFairParticipations");
        }
    }
}
