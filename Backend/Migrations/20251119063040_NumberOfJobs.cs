using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace JobFairPortal.Migrations
{
    /// <inheritdoc />
    public partial class NumberOfJobs : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "NumberOfJobs",
                table: "Jobs",
                type: "integer",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "NumberOfJobs",
                table: "Jobs");
        }
    }
}
