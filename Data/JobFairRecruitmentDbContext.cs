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
        public DbSet<StudentProject> StudentProjects { get; set; } = null!;
        public DbSet<Project> Projects { get; set; } = null!;
        public DbSet<Achievement> Achievements { get; set; } = null!;
        public DbSet<Certification> Certifications { get; set; } = null!;
        public DbSet<ContactLink> ContactLinks { get; set; } = null!;
        public DbSet<Experience> Experiences { get; set; } = null!;
        public DbSet<Education> Educations { get; set; } = null!;
        public DbSet<CompanyContactLink> CompanyContactLinks { get; set; } = null!;


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

            modelBuilder.Entity<Job>(entity =>
            {
             
                entity.Property(j => j.RequiredSkills)
                    .HasConversion(
                        v => JsonSerializer.Serialize(v, (JsonSerializerOptions?)null),  // object -> JSON string
                        v => JsonSerializer.Deserialize<string[]>(v, (JsonSerializerOptions?)null) // JSON string -> object
                    )
                    .HasColumnType("jsonb"); 
            });

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


            // -----------------------------
            // Student ↔ StudentProject (Many-to-Many via Join Table)
            // -----------------------------
            modelBuilder.Entity<StudentProject>()
                .HasOne(sp => sp.Student)
                .WithMany(s => s.StudentProjects)
                .HasForeignKey(sp => sp.StudentId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<StudentProject>()
                .HasOne(sp => sp.Project)
                .WithMany(p => p.StudentProjects)
                .HasForeignKey(sp => sp.ProjectId)
                .OnDelete(DeleteBehavior.Cascade);

            // Ensure a student cannot be linked twice to the same project
            modelBuilder.Entity<StudentProject>()
                .HasIndex(sp => new { sp.StudentId, sp.ProjectId })
                .IsUnique();

            // Default values for status and creator flag
            modelBuilder.Entity<StudentProject>()
                .Property(sp => sp.Status)
                .HasConversion<string>() // store enum as string for readability
                .HasDefaultValue(ProjectInviteStatus.Pending);

            modelBuilder.Entity<StudentProject>()
                .Property(sp => sp.IsCreator)
                .HasDefaultValue(false);

            // -----------------------------
            // Project ↔ StudentProject (Many-to-Many already handled)
            // Add optional constraints for Project
            // -----------------------------
            modelBuilder.Entity<Project>()
                .Property(p => p.Type)
                .HasConversion<string>(); // store ProjectType as readable string

            modelBuilder.Entity<Project>()
                .Property(p => p.CreatedAt)
                .HasDefaultValueSql("CURRENT_TIMESTAMP");

            modelBuilder.Entity<Achievement>()
                .HasOne(a => a.Student)
                .WithMany(s => s.Achievements)
                .HasForeignKey(a => a.StudentId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Achievement>()
                .Property(a => a.Title)
                .IsRequired()
                .HasMaxLength(100);

            modelBuilder.Entity<Achievement>()
                .Property(a => a.Description)
                .HasMaxLength(500);

            modelBuilder.Entity<Achievement>()
                .Property(a => a.DateAchieved)
                .HasDefaultValueSql("CURRENT_TIMESTAMP");
            modelBuilder.Entity<Student>()
                .Property(s => s.CGPA)
                .HasPrecision(3, 2); // e.g., 3.75
            // -----------------------------
            // Student ↔ Certification (One-to-Many)
            // -----------------------------
            modelBuilder.Entity<Certification>()
                .HasOne(c => c.Student)
                .WithMany(s => s.Certifications)
                .HasForeignKey(c => c.StudentId)
                .OnDelete(DeleteBehavior.Cascade);

            // Configure Certification entity
            modelBuilder.Entity<Certification>()
                .Property(c => c.Title)
                .IsRequired()
                .HasMaxLength(100);

            modelBuilder.Entity<Certification>()
                .Property(c => c.Issuer)
                .HasMaxLength(100);

            modelBuilder.Entity<Certification>()
                .Property(c => c.CredentialUrl)
                .HasMaxLength(500); // safety limit for URL length

            modelBuilder.Entity<Certification>()
                .Property(c => c.IssueDate)
                .HasDefaultValueSql("CURRENT_TIMESTAMP");

            // -----------------------------
            // Student ↔ ContactLink (One-to-Many)
            // -----------------------------
            modelBuilder.Entity<ContactLink>()
                .HasOne(cl => cl.Student)
                .WithMany(s => s.ContactLinks)
                .HasForeignKey(cl => cl.StudentId)
                .OnDelete(DeleteBehavior.Cascade);
            modelBuilder.Entity<ContactLink>()
        .Property(c => c.Platform)
        .HasConversion<string>();

            // Configure ContactLink entity
            modelBuilder.Entity<ContactLink>()
                .Property(cl => cl.Platform)
                .IsRequired()
                .HasMaxLength(50)
                .HasConversion<string>();

            modelBuilder.Entity<ContactLink>()
                .Property(cl => cl.Url)
                .IsRequired();

            


            modelBuilder.Entity<ContactLink>()
                .HasIndex(cl => new { cl.StudentId, cl.Platform })
                .IsUnique(); // Prevent duplicate platforms for the same student
            // -----------------------------
            // Student ↔ Experience (One-to-Many)
            // -----------------------------
            modelBuilder.Entity<Experience>()
                .HasOne(e => e.Student)
                .WithMany(s => s.Experiences)
                .HasForeignKey(e => e.StudentId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Experience>()
                .Property(e => e.CompanyName)
                .IsRequired()
                .HasMaxLength(100);

            modelBuilder.Entity<Experience>()
                .Property(e => e.Description)
                .HasMaxLength(500);

            modelBuilder.Entity<Experience>()
                .Property(e => e.StartDate)
                .IsRequired();

            modelBuilder.Entity<Experience>()
                .Property(e => e.IsCurrent)
                .HasDefaultValue(false);

            modelBuilder.Entity<Experience>()
                .HasIndex(e => new { e.StudentId, e.StartDate });


            modelBuilder.Entity<Education>()
    .HasOne(e => e.Student)
    .WithMany(s => s.Educations)
    .HasForeignKey(e => e.StudentId)
    .OnDelete(DeleteBehavior.Cascade);

            // Configure properties
            modelBuilder.Entity<Education>()
                .Property(e => e.InstitutionName)
                .IsRequired()
                .HasMaxLength(150);

            modelBuilder.Entity<Education>()
                .Property(e => e.Degree)
                .IsRequired()
                .HasMaxLength(100);


            // Company ↔ CompanyContactLink (One-to-Many)
            modelBuilder.Entity<CompanyContactLink>()
                .HasOne(ccl => ccl.Company)
                .WithMany(c => c.CompanyContactLinks)
                .HasForeignKey(ccl => ccl.CompanyId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<CompanyContactLink>()
                .Property(ccl => ccl.Platform)
                .HasConversion<string>(); // Store enum as string for readability

            modelBuilder.Entity<CompanyContactLink>()
                .HasIndex(ccl => new { ccl.CompanyId, ccl.Platform })
                .IsUnique(); // Prevent duplicate platform entries per company
          
            


        }
    }
}
