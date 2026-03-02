using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace JobFairPortal.Migrations
{
    /// <inheritdoc />
    public partial class AddedJobFairEntity : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "JobFairId",
                table: "Students",
                type: "integer",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Students_JobFairId",
                table: "Students",
                column: "JobFairId");

            migrationBuilder.AddForeignKey(
                name: "FK_Students_JobFairs_JobFairId",
                table: "Students",
                column: "JobFairId",
                principalTable: "JobFairs",
                principalColumn: "JobFairId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Students_JobFairs_JobFairId",
                table: "Students");

            migrationBuilder.DropIndex(
                name: "IX_Students_JobFairId",
                table: "Students");

            migrationBuilder.DropColumn(
                name: "JobFairId",
                table: "Students");
        }
    }
}
