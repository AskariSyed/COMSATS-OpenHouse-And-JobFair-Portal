using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace JobFairPortal.Migrations
{
    /// <inheritdoc />
    public partial class UpdatedNoticeEntity : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsHidden",
                table: "Notices",
                type: "boolean",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsHidden",
                table: "Notices");
        }
    }
}
