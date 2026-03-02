using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace JobFairPortal.Migrations
{
    /// <inheritdoc />
    public partial class AddedJobFairEntityUpdated : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Jobs_JobFairs_JobFairId",
                table: "Jobs");

            migrationBuilder.DropForeignKey(
                name: "FK_Students_JobFairs_JobFairId",
                table: "Students");

            migrationBuilder.AlterColumn<int>(
                name: "JobFairId",
                table: "Students",
                type: "integer",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "integer",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "JobFairId",
                table: "Jobs",
                type: "integer",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "integer");

            migrationBuilder.AddColumn<int>(
                name: "JobFairId",
                table: "InterviewRequests",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateIndex(
                name: "IX_InterviewRequests_JobFairId",
                table: "InterviewRequests",
                column: "JobFairId");

            migrationBuilder.AddForeignKey(
                name: "FK_InterviewRequests_JobFairs_JobFairId",
                table: "InterviewRequests",
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
                name: "FK_Students_JobFairs_JobFairId",
                table: "Students",
                column: "JobFairId",
                principalTable: "JobFairs",
                principalColumn: "JobFairId",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_InterviewRequests_JobFairs_JobFairId",
                table: "InterviewRequests");

            migrationBuilder.DropForeignKey(
                name: "FK_Jobs_JobFairs_JobFairId",
                table: "Jobs");

            migrationBuilder.DropForeignKey(
                name: "FK_Students_JobFairs_JobFairId",
                table: "Students");

            migrationBuilder.DropIndex(
                name: "IX_InterviewRequests_JobFairId",
                table: "InterviewRequests");

            migrationBuilder.DropColumn(
                name: "JobFairId",
                table: "InterviewRequests");

            migrationBuilder.AlterColumn<int>(
                name: "JobFairId",
                table: "Students",
                type: "integer",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "integer");

            migrationBuilder.AlterColumn<int>(
                name: "JobFairId",
                table: "Jobs",
                type: "integer",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "integer",
                oldNullable: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Jobs_JobFairs_JobFairId",
                table: "Jobs",
                column: "JobFairId",
                principalTable: "JobFairs",
                principalColumn: "JobFairId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Students_JobFairs_JobFairId",
                table: "Students",
                column: "JobFairId",
                principalTable: "JobFairs",
                principalColumn: "JobFairId");
        }
    }
}
