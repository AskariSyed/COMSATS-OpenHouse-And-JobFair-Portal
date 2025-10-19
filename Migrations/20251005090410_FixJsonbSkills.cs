using System.Collections.Generic;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace JobFairPortal.Migrations
{
    /// <inheritdoc />
    public partial class FixJsonbSkills : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<List<string>>(
                name: "Skills",
                table: "Students",
                type: "jsonb",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "json",
                oldNullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "Skills",
                table: "Students",
                type: "json",
                nullable: true,
                oldClrType: typeof(List<string>),
                oldType: "jsonb",
                oldNullable: true);
        }
    }
}
