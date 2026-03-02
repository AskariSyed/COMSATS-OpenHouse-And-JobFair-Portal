using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace JobFairPortal.Migrations
{
    /// <inheritdoc />
    public partial class CompanyContactLinks : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "RepPhone",
                table: "Companies",
                newName: "FocalPersonPhone");

            migrationBuilder.RenameColumn(
                name: "RepEmail",
                table: "Companies",
                newName: "FocalPersonName");
            // Instead of AlterColumn
            migrationBuilder.Sql(
    @"ALTER TABLE ""Jobs""
          ALTER COLUMN ""RequiredSkills""
          TYPE jsonb
          USING to_jsonb(""RequiredSkills"");");

            migrationBuilder.AlterColumn<string>(
                name: "JobTitle",
                table: "Jobs",
                type: "character varying(200)",
                maxLength: 200,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AlterColumn<string>(
                name: "JobDescription",
                table: "Jobs",
                type: "character varying(2000)",
                maxLength: 2000,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Address",
                table: "Companies",
                type: "text",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AddColumn<string>(
                name: "CompanyEmail",
                table: "Companies",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CompanyPhone",
                table: "Companies",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "FocalPersonEmail",
                table: "Companies",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Website",
                table: "Companies",
                type: "text",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "CompanyContactLinks",
                columns: table => new
                {
                    LinkId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    CompanyId = table.Column<int>(type: "integer", nullable: false),
                    Platform = table.Column<string>(type: "text", nullable: false),
                    Url = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CompanyContactLinks", x => x.LinkId);
                    table.ForeignKey(
                        name: "FK_CompanyContactLinks_Companies_CompanyId",
                        column: x => x.CompanyId,
                        principalTable: "Companies",
                        principalColumn: "CompanyId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_CompanyContactLinks_CompanyId_Platform",
                table: "CompanyContactLinks",
                columns: new[] { "CompanyId", "Platform" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "CompanyContactLinks");

            migrationBuilder.DropColumn(
                name: "CompanyEmail",
                table: "Companies");

            migrationBuilder.DropColumn(
                name: "CompanyPhone",
                table: "Companies");

            migrationBuilder.DropColumn(
                name: "FocalPersonEmail",
                table: "Companies");

            migrationBuilder.DropColumn(
                name: "Website",
                table: "Companies");

            migrationBuilder.RenameColumn(
                name: "FocalPersonPhone",
                table: "Companies",
                newName: "RepPhone");

            migrationBuilder.RenameColumn(
                name: "FocalPersonName",
                table: "Companies",
                newName: "RepEmail");

            migrationBuilder.AlterColumn<string[]>(
                name: "RequiredSkills",
                table: "Jobs",
                type: "text[]",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "jsonb",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "JobTitle",
                table: "Jobs",
                type: "text",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(200)",
                oldMaxLength: 200);

            migrationBuilder.AlterColumn<string>(
                name: "JobDescription",
                table: "Jobs",
                type: "text",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "character varying(2000)",
                oldMaxLength: 2000,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Address",
                table: "Companies",
                type: "text",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);
        }
    }
}
