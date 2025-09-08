using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace JobFairPortal.Migrations
{
    /// <inheritdoc />
    public partial class AddedSurveyType : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Interviews_InterviewRequests_RequestId",
                table: "Interviews");

            migrationBuilder.AddColumn<int>(
                name: "Type",
                table: "Surveys",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AlterColumn<int>(
                name: "RequestId",
                table: "Interviews",
                type: "integer",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "integer",
                oldNullable: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Interviews_InterviewRequests_RequestId",
                table: "Interviews",
                column: "RequestId",
                principalTable: "InterviewRequests",
                principalColumn: "RequestId",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Interviews_InterviewRequests_RequestId",
                table: "Interviews");

            migrationBuilder.DropColumn(
                name: "Type",
                table: "Surveys");

            migrationBuilder.AlterColumn<int>(
                name: "RequestId",
                table: "Interviews",
                type: "integer",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "integer");

            migrationBuilder.AddForeignKey(
                name: "FK_Interviews_InterviewRequests_RequestId",
                table: "Interviews",
                column: "RequestId",
                principalTable: "InterviewRequests",
                principalColumn: "RequestId");
        }
    }
}
