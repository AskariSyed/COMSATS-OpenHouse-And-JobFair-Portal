using JobFairPortal.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using System.Text.Json;

namespace JobFairPortal.Data
{
    public class JobFairRecruitmentDbContext : DbContext
    {
        public JobFairRecruitmentDbContext(DbContextOptions<JobFairRecruitmentDbContext> options)
            : base(options)
        {
        }

        public DbSet<User> Users { get; set; } = null!;
        public DbSet<Student> Students { get; set; } = null!;
        public DbSet<Company> Companies { get; set; } = null!;
        public DbSet<Job> Jobs { get; set; } = null!;
        public DbSet<Room> Rooms { get; set; } = null!;
        public DbSet<InterviewRequest> InterviewRequests { get; set; } = null!;
        public DbSet<Interview> Interviews { get; set; } = null!;
        public DbSet<Notification> Notifications { get; set; } = null!;
        public DbSet<Survey> Surveys { get; set; } = null!;
        public DbSet<AuditLog> AuditLogs { get; set; } = null!;
        public DbSet<JobFair> JobFairs { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<Student>()
    .Property(s => s.Skills)
    .HasConversion(
        v => JsonSerializer.Serialize(v, new JsonSerializerOptions()), 
        v => JsonSerializer.Deserialize<List<string>>(v, new JsonSerializerOptions()) ?? new List<string>()
    )
    .HasColumnType("jsonb");


            base.OnModelCreating(modelBuilder);

            // -----------------------------
            // One-to-One: Company ↔ Room
            // -----------------------------
            modelBuilder.Entity<Company>()
                .HasOne(c => c.Room)
                .WithOne(r => r.Company)
                .HasForeignKey<Room>(r => r.CompanyId);

            // -----------------------------
            // One-to-One: User ↔ Student
            // -----------------------------
            modelBuilder.Entity<User>()
                .HasOne(u => u.Student)
                .WithOne(s => s.User)
                .HasForeignKey<Student>(s => s.UserId);

            // -----------------------------
            // One-to-One: User ↔ Company
            // -----------------------------
            modelBuilder.Entity<User>()
                .HasOne(u => u.Company)
                .WithOne(c => c.User)
                .HasForeignKey<Company>(c => c.UserId);

            // -----------------------------
            // One-to-Many: Company ↔ Jobs
            // -----------------------------
            modelBuilder.Entity<Job>()
                .HasOne(j => j.Company)
                .WithMany(c => c.Jobs)
                .HasForeignKey(j => j.CompanyId);

            // -----------------------------
            // One-to-Many: Student ↔ InterviewRequests
            // -----------------------------
            modelBuilder.Entity<InterviewRequest>()
                .HasOne(ir => ir.Student)
                .WithMany(s => s.InterviewRequests)
                .HasForeignKey(ir => ir.StudentId);

            modelBuilder.Entity<InterviewRequest>()
                .HasOne(ir => ir.Company)
                .WithMany(c => c.InterviewRequests)
                .HasForeignKey(ir => ir.CompanyId);

            // -----------------------------
            // One-to-Many: Student ↔ Interviews
            // -----------------------------
            modelBuilder.Entity<Interview>()
                .HasOne(i => i.Student)
                .WithMany(s => s.Interviews)
                .HasForeignKey(i => i.StudentId);

            modelBuilder.Entity<Interview>()
                .HasOne(i => i.Company)
                .WithMany(c => c.Interviews)
                .HasForeignKey(i => i.CompanyId);

            // -----------------------------
            // One-to-Many: Company ↔ Survey
            // -----------------------------
            modelBuilder.Entity<Survey>()
                .HasOne(s => s.Company)
                .WithMany(c => c.Surveys)
                .HasForeignKey(s => s.CompanyId);



            // -----------------------------
            // Optional: User ↔ AuditLog
            // -----------------------------
            modelBuilder.Entity<AuditLog>()
                .HasOne(a => a.Actor)
                .WithMany()
                .HasForeignKey(a => a.UserId)
                .OnDelete(DeleteBehavior.SetNull);
        }
    }
}
