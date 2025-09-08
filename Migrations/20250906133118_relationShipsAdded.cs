using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace JobFairPortal.Migrations
{
    /// <inheritdoc />
    public partial class relationShipsAdded : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AuditLogs_Users_ActorId",
                table: "AuditLogs");

            migrationBuilder.RenameColumn(
                name: "FYPTitle",
                table: "Students",
                newName: "FypTitle");

            migrationBuilder.RenameColumn(
                name: "FYPDemoUrl",
                table: "Students",
                newName: "FypDemoUrl");

            migrationBuilder.RenameColumn(
                name: "FCMToken",
                table: "Students",
                newName: "FcmToken");

            migrationBuilder.AlterColumn<string>(
                name: "Department",
                table: "Students",
                type: "text",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);

            migrationBuilder.AlterColumn<decimal>(
                name: "CGPA",
                table: "Students",
                type: "numeric",
                nullable: false,
                defaultValue: 0m,
                oldClrType: typeof(decimal),
                oldType: "numeric",
                oldNullable: true);

            migrationBuilder.AddColumn<int>(
                name: "UserId",
                table: "AuditLogs",
                type: "integer",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_AuditLogs_UserId",
                table: "AuditLogs",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_AuditLogs_Users_ActorId",
                table: "AuditLogs",
                column: "ActorId",
                principalTable: "Users",
                principalColumn: "UserId",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_AuditLogs_Users_UserId",
                table: "AuditLogs",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AuditLogs_Users_ActorId",
                table: "AuditLogs");

            migrationBuilder.DropForeignKey(
                name: "FK_AuditLogs_Users_UserId",
                table: "AuditLogs");

            migrationBuilder.DropIndex(
                name: "IX_AuditLogs_UserId",
                table: "AuditLogs");

            migrationBuilder.DropColumn(
                name: "UserId",
                table: "AuditLogs");

            migrationBuilder.RenameColumn(
                name: "FypTitle",
                table: "Students",
                newName: "FYPTitle");

            migrationBuilder.RenameColumn(
                name: "FypDemoUrl",
                table: "Students",
                newName: "FYPDemoUrl");

            migrationBuilder.RenameColumn(
                name: "FcmToken",
                table: "Students",
                newName: "FCMToken");

            migrationBuilder.AlterColumn<string>(
                name: "Department",
                table: "Students",
                type: "text",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AlterColumn<decimal>(
                name: "CGPA",
                table: "Students",
                type: "numeric",
                nullable: true,
                oldClrType: typeof(decimal),
                oldType: "numeric");

            migrationBuilder.AddForeignKey(
                name: "FK_AuditLogs_Users_ActorId",
                table: "AuditLogs",
                column: "ActorId",
                principalTable: "Users",
                principalColumn: "UserId");
        }
    }
}
