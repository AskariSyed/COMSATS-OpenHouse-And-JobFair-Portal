using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace JobFairPortal.Migrations
{
    /// <inheritdoc />
    public partial class MultiJobFairSupport : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // 1. Drop existing constraints first
            migrationBuilder.DropForeignKey(
                name: "FK_Companies_JobFairs_JobFairId",
                table: "Companies");

            migrationBuilder.DropForeignKey(
                name: "FK_Jobs_JobFairs_JobFairId",
                table: "Jobs");

            migrationBuilder.DropForeignKey(
                name: "FK_Rooms_Companies_CompanyId",
                table: "Rooms");

            migrationBuilder.DropForeignKey(
                name: "FK_Students_JobFairs_JobFairId",
                table: "Students");

            // 2. Add new columns endpoi (nullable initially or with default values)
            migrationBuilder.AddColumn<int>(
                name: "JobFairId1",
                table: "Surveys",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "CurrentJobFairId",
                table: "Students",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "JobFairId1",
                table: "Students",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "JobFairId1",
                table: "Rooms",
                type: "integer",
                nullable: true);

            // 3. Alter existing columns
            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "Projects",
                type: "timestamp with time zone",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "timestamp with time zone",
                oldDefaultValueSql: "CURRENT_TIMESTAMP");

            // IMPORTANT: Alter JobFairId to be non-nullable, but we need to fix data first!
            // We'll do this in two steps: 
            // A. Alter column to integer (if it wasn't already) but keep it nullable or default 0 for a moment
            // B. Fix data
            // C. Add FK constraint

            // Since the generated code tries to set it to NOT NULL immediately, we must ensure data is valid.

            // ==============================================================================
            // ✅ CRITICAL DATA FIX: INSERT DEFAULT JOB FAIR & UPDATE ORPHANED RECORDS
            // ==============================================================================

            // 1. Ensure at least one JobFair exists
            migrationBuilder.Sql(@"
                    INSERT INTO ""JobFairs"" (""Semester"", ""date"", ""IsActive"")
                    SELECT 'Default Job Fair', NOW(), true
                    WHERE NOT EXISTS (SELECT 1 FROM ""JobFairs"");
                ");

            // 2. Update all tables to point to a valid JobFairId (instead of 0 or NULL)
            // We use the most recent JobFairId found in the database
            migrationBuilder.Sql(@"
                    DO $$
                    DECLARE
                        valid_id integer;
                    BEGIN
                        SELECT ""JobFairId"" INTO valid_id FROM ""JobFairs"" ORDER BY ""date"" DESC LIMIT 1;
                        
                        -- Update Jobs (Handle NULLs and 0s)
                        UPDATE ""Jobs"" SET ""JobFairId"" = valid_id WHERE ""JobFairId"" IS NULL OR ""JobFairId"" = 0;
                        
                        -- Update Companies
                        UPDATE ""Companies"" SET ""JobFairId"" = valid_id WHERE ""JobFairId"" IS NULL OR ""JobFairId"" = 0;

                        -- Update Students
                        UPDATE ""Students"" SET ""JobFairId"" = valid_id WHERE ""JobFairId"" IS NULL OR ""JobFairId"" = 0;
                    END $$;
                ");

            // ==============================================================================
            // END DATA FIX
            // ==============================================================================

            // Now we can safely alter the column to be non-nullable
            migrationBuilder.AlterColumn<int>(
                name: "JobFairId",
                table: "Jobs",
                type: "integer",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "integer",
                oldNullable: true);

            migrationBuilder.AddColumn<int>(
                name: "JobFairId1",
                table: "Jobs",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "JobFairId1",
                table: "Interviews",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "JobFairId1",
                table: "InterviewRequests",
                type: "integer",
                nullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Platform",
                table: "ContactLinks",
                type: "text",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(50)",
                oldMaxLength: 50);

            migrationBuilder.AddColumn<int>(
                name: "CurrentJobFairId",
                table: "Companies",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "JobFairId1",
                table: "Companies",
                type: "integer",
                nullable: true);

            migrationBuilder.AlterColumn<DateTime>(
                name: "IssueDate",
                table: "Certifications",
                type: "timestamp with time zone",
                nullable: true,
                oldClrType: typeof(DateTime),
                oldType: "timestamp with time zone",
                oldNullable: true,
                oldDefaultValueSql: "CURRENT_TIMESTAMP");

            migrationBuilder.AlterColumn<DateTime>(
                name: "DateAchieved",
                table: "Achievements",
                type: "timestamp with time zone",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "timestamp with time zone",
                oldDefaultValueSql: "CURRENT_TIMESTAMP");

            // Create new tables
            migrationBuilder.CreateTable(
                name: "CompanyJobFairParticipations",
                columns: table => new
                {
                    ParticipationId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    CompanyId = table.Column<int>(type: "integer", nullable: false),
                    JobFairId = table.Column<int>(type: "integer", nullable: false),
                    ArrivalStatus = table.Column<int>(type: "integer", nullable: false),
                    IsPresent = table.Column<bool>(type: "boolean", nullable: false),
                    RepsCount = table.Column<int>(type: "integer", nullable: false),
                    InterviewDurationMinutes = table.Column<int>(type: "integer", nullable: false),
                    RoomId = table.Column<int>(type: "integer", nullable: true),
                    RegisteredAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CompanyJobFairParticipations", x => x.ParticipationId);
                    table.ForeignKey(
                        name: "FK_CompanyJobFairParticipations_Companies_CompanyId",
                        column: x => x.CompanyId,
                        principalTable: "Companies",
                        principalColumn: "CompanyId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CompanyJobFairParticipations_JobFairs_JobFairId",
                        column: x => x.JobFairId,
                        principalTable: "JobFairs",
                        principalColumn: "JobFairId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CompanyJobFairParticipations_Rooms_RoomId",
                        column: x => x.RoomId,
                        principalTable: "Rooms",
                        principalColumn: "RoomId");
                });

            migrationBuilder.CreateTable(
                name: "StudentJobFairParticipations",
                columns: table => new
                {
                    ParticipationId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    StudentId = table.Column<int>(type: "integer", nullable: false),
                    JobFairId = table.Column<int>(type: "integer", nullable: false),
                    HasRegistered = table.Column<bool>(type: "boolean", nullable: false),
                    InterviewsAttended = table.Column<int>(type: "integer", nullable: false),
                    OffersReceived = table.Column<int>(type: "integer", nullable: false),
                    RegisteredAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StudentJobFairParticipations", x => x.ParticipationId);
                    table.ForeignKey(
                        name: "FK_StudentJobFairParticipations_JobFairs_JobFairId",
                        column: x => x.JobFairId,
                        principalTable: "JobFairs",
                        principalColumn: "JobFairId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_StudentJobFairParticipations_Students_StudentId",
                        column: x => x.StudentId,
                        principalTable: "Students",
                        principalColumn: "StudentId",
                        onDelete: ReferentialAction.Cascade);
                });

            // Create Indexes
            migrationBuilder.CreateIndex(
                name: "IX_Surveys_JobFairId1",
                table: "Surveys",
                column: "JobFairId1");

            migrationBuilder.CreateIndex(
                name: "IX_Students_CurrentJobFairId",
                table: "Students",
                column: "CurrentJobFairId");

            migrationBuilder.CreateIndex(
                name: "IX_Students_JobFairId1",
                table: "Students",
                column: "JobFairId1");

            migrationBuilder.CreateIndex(
                name: "IX_Rooms_JobFairId1",
                table: "Rooms",
                column: "JobFairId1");

            migrationBuilder.CreateIndex(
                name: "IX_Jobs_JobFairId1",
                table: "Jobs",
                column: "JobFairId1");

            migrationBuilder.CreateIndex(
                name: "IX_Interviews_JobFairId1",
                table: "Interviews",
                column: "JobFairId1");

            migrationBuilder.CreateIndex(
                name: "IX_InterviewRequests_JobFairId1",
                table: "InterviewRequests",
                column: "JobFairId1");

            migrationBuilder.CreateIndex(
                name: "IX_Companies_CurrentJobFairId",
                table: "Companies",
                column: "CurrentJobFairId");

            migrationBuilder.CreateIndex(
                name: "IX_Companies_JobFairId1",
                table: "Companies",
                column: "JobFairId1");

            migrationBuilder.CreateIndex(
                name: "IX_CompanyJobFairParticipations_CompanyId_JobFairId",
                table: "CompanyJobFairParticipations",
                columns: new[] { "CompanyId", "JobFairId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_CompanyJobFairParticipations_JobFairId",
                table: "CompanyJobFairParticipations",
                column: "JobFairId");

            migrationBuilder.CreateIndex(
                name: "IX_CompanyJobFairParticipations_RoomId",
                table: "CompanyJobFairParticipations",
                column: "RoomId");

            migrationBuilder.CreateIndex(
                name: "IX_StudentJobFairParticipations_JobFairId",
                table: "StudentJobFairParticipations",
                column: "JobFairId");

            migrationBuilder.CreateIndex(
                name: "IX_StudentJobFairParticipations_StudentId_JobFairId",
                table: "StudentJobFairParticipations",
                columns: new[] { "StudentId", "JobFairId" },
                unique: true);

            // Add Foreign Keys
            migrationBuilder.AddForeignKey(
                name: "FK_Companies_JobFairs_CurrentJobFairId",
                table: "Companies",
                column: "CurrentJobFairId",
                principalTable: "JobFairs",
                principalColumn: "JobFairId",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Companies_JobFairs_JobFairId",
                table: "Companies",
                column: "JobFairId",
                principalTable: "JobFairs",
                principalColumn: "JobFairId",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Companies_JobFairs_JobFairId1",
                table: "Companies",
                column: "JobFairId1",
                principalTable: "JobFairs",
                principalColumn: "JobFairId");

            migrationBuilder.AddForeignKey(
                name: "FK_InterviewRequests_JobFairs_JobFairId1",
                table: "InterviewRequests",
                column: "JobFairId1",
                principalTable: "JobFairs",
                principalColumn: "JobFairId");

            migrationBuilder.AddForeignKey(
                name: "FK_Interviews_JobFairs_JobFairId1",
                table: "Interviews",
                column: "JobFairId1",
                principalTable: "JobFairs",
                principalColumn: "JobFairId");

            migrationBuilder.AddForeignKey(
                name: "FK_Jobs_JobFairs_JobFairId",
                table: "Jobs",
                column: "JobFairId",
                principalTable: "JobFairs",
                principalColumn: "JobFairId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Jobs_JobFairs_JobFairId1",
                table: "Jobs",
                column: "JobFairId1",
                principalTable: "JobFairs",
                principalColumn: "JobFairId");

            migrationBuilder.AddForeignKey(
                name: "FK_Rooms_Companies_CompanyId",
                table: "Rooms",
                column: "CompanyId",
                principalTable: "Companies",
                principalColumn: "CompanyId",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Rooms_JobFairs_JobFairId1",
                table: "Rooms",
                column: "JobFairId1",
                principalTable: "JobFairs",
                principalColumn: "JobFairId");

            migrationBuilder.AddForeignKey(
                name: "FK_Students_JobFairs_CurrentJobFairId",
                table: "Students",
                column: "CurrentJobFairId",
                principalTable: "JobFairs",
                principalColumn: "JobFairId",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Students_JobFairs_JobFairId",
                table: "Students",
                column: "JobFairId",
                principalTable: "JobFairs",
                principalColumn: "JobFairId",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Students_JobFairs_JobFairId1",
                table: "Students",
                column: "JobFairId1",
                principalTable: "JobFairs",
                principalColumn: "JobFairId");

            migrationBuilder.AddForeignKey(
                name: "FK_Surveys_JobFairs_JobFairId1",
                table: "Surveys",
                column: "JobFairId1",
                principalTable: "JobFairs",
                principalColumn: "JobFairId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // ... (Keep existing Down method as is) ...
            migrationBuilder.DropForeignKey(
                name: "FK_Companies_JobFairs_CurrentJobFairId",
                table: "Companies");

            migrationBuilder.DropForeignKey(
                name: "FK_Companies_JobFairs_JobFairId",
                table: "Companies");

            migrationBuilder.DropForeignKey(
                name: "FK_Companies_JobFairs_JobFairId1",
                table: "Companies");

            migrationBuilder.DropForeignKey(
                name: "FK_InterviewRequests_JobFairs_JobFairId1",
                table: "InterviewRequests");

            migrationBuilder.DropForeignKey(
                name: "FK_Interviews_JobFairs_JobFairId1",
                table: "Interviews");

            migrationBuilder.DropForeignKey(
                name: "FK_Jobs_JobFairs_JobFairId",
                table: "Jobs");

            migrationBuilder.DropForeignKey(
                name: "FK_Jobs_JobFairs_JobFairId1",
                table: "Jobs");

            migrationBuilder.DropForeignKey(
                name: "FK_Rooms_Companies_CompanyId",
                table: "Rooms");

            migrationBuilder.DropForeignKey(
                name: "FK_Rooms_JobFairs_JobFairId1",
                table: "Rooms");

            migrationBuilder.DropForeignKey(
                name: "FK_Students_JobFairs_CurrentJobFairId",
                table: "Students");

            migrationBuilder.DropForeignKey(
                name: "FK_Students_JobFairs_JobFairId",
                table: "Students");

            migrationBuilder.DropForeignKey(
                name: "FK_Students_JobFairs_JobFairId1",
                table: "Students");

            migrationBuilder.DropForeignKey(
                name: "FK_Surveys_JobFairs_JobFairId1",
                table: "Surveys");

            migrationBuilder.DropTable(
                name: "CompanyJobFairParticipations");

            migrationBuilder.DropTable(
                name: "StudentJobFairParticipations");

            migrationBuilder.DropIndex(
                name: "IX_Surveys_JobFairId1",
                table: "Surveys");

            migrationBuilder.DropIndex(
                name: "IX_Students_CurrentJobFairId",
                table: "Students");

            migrationBuilder.DropIndex(
                name: "IX_Students_JobFairId1",
                table: "Students");

            migrationBuilder.DropIndex(
                name: "IX_Rooms_JobFairId1",
                table: "Rooms");

            migrationBuilder.DropIndex(
                name: "IX_Jobs_JobFairId1",
                table: "Jobs");

            migrationBuilder.DropIndex(
                name: "IX_Interviews_JobFairId1",
                table: "Interviews");

            migrationBuilder.DropIndex(
                name: "IX_InterviewRequests_JobFairId1",
                table: "InterviewRequests");

            migrationBuilder.DropIndex(
                name: "IX_Companies_CurrentJobFairId",
                table: "Companies");

            migrationBuilder.DropIndex(
                name: "IX_Companies_JobFairId1",
                table: "Companies");

            migrationBuilder.DropColumn(
                name: "JobFairId1",
                table: "Surveys");

            migrationBuilder.DropColumn(
                name: "CurrentJobFairId",
                table: "Students");

            migrationBuilder.DropColumn(
                name: "JobFairId1",
                table: "Students");

            migrationBuilder.DropColumn(
                name: "JobFairId1",
                table: "Rooms");

            migrationBuilder.DropColumn(
                name: "JobFairId1",
                table: "Jobs");

            migrationBuilder.DropColumn(
                name: "JobFairId1",
                table: "Interviews");

            migrationBuilder.DropColumn(
                name: "JobFairId1",
                table: "InterviewRequests");

            migrationBuilder.DropColumn(
                name: "CurrentJobFairId",
                table: "Companies");

            migrationBuilder.DropColumn(
                name: "JobFairId1",
                table: "Companies");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "Projects",
                type: "timestamp with time zone",
                nullable: false,
                defaultValueSql: "CURRENT_TIMESTAMP",
                oldClrType: typeof(DateTime),
                oldType: "timestamp with time zone");

            migrationBuilder.AlterColumn<int>(
                name: "JobFairId",
                table: "Jobs",
                type: "integer",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "integer");

            migrationBuilder.AlterColumn<string>(
                name: "Platform",
                table: "ContactLinks",
                type: "character varying(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AlterColumn<DateTime>(
                name: "IssueDate",
                table: "Certifications",
                type: "timestamp with time zone",
                nullable: true,
                defaultValueSql: "CURRENT_TIMESTAMP",
                oldClrType: typeof(DateTime),
                oldType: "timestamp with time zone",
                oldNullable: true);

            migrationBuilder.AlterColumn<DateTime>(
                name: "DateAchieved",
                table: "Achievements",
                type: "timestamp with time zone",
                nullable: false,
                defaultValueSql: "CURRENT_TIMESTAMP",
                oldClrType: typeof(DateTime),
                oldType: "timestamp with time zone");

            migrationBuilder.AddForeignKey(
                name: "FK_Companies_JobFairs_JobFairId",
                table: "Companies",
                column: "JobFairId",
                principalTable: "JobFairs",
                principalColumn: "JobFairId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Jobs_JobFairs_JobFairId",
                table: "Jobs",
                column: "JobFairId",
                principalTable: "JobFairs",
                principalColumn: "JobFairId");

            migrationBuilder.AddForeignKey(
                name: "FK_Rooms_Companies_CompanyId",
                table: "Rooms",
                column: "CompanyId",
                principalTable: "Companies",
                principalColumn: "CompanyId");

            migrationBuilder.AddForeignKey(
                name: "FK_Students_JobFairs_JobFairId",
                table: "Students",
                column: "JobFairId",
                principalTable: "JobFairs",
                principalColumn: "JobFairId",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
