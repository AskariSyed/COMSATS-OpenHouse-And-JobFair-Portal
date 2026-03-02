using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace JobFairPortal.Migrations
{
    /// <inheritdoc />
    public partial class AddedRepEmailPhoneAddress : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Address",
                table: "Companies",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "RepEmail",
                table: "Companies",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "RepPhone",
                table: "Companies",
                type: "text",
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Address",
                table: "Companies");

            migrationBuilder.DropColumn(
                name: "RepEmail",
                table: "Companies");

            migrationBuilder.DropColumn(
                name: "RepPhone",
                table: "Companies");
        }
    }
}
