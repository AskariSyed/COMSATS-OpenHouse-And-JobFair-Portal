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

// DbSet properties for each entity
        public DbSet<User> Users { get; set; } = null!;
        public DbSet<Student> Students { get; set; } = null!;
        public DbSet<Company> Companies { get; set; } = null!;
        public DbSet<Job> Jobs { get; set; } = null!;
        public DbSet<Room> Rooms { get; set; } = null!;
        public DbSet<InterviewRequest> InterviewRequests { get; set; } = null!;
        public DbSet<Interview> Interviews { get; set; } = null!;
        public DbSet<Survey> Surveys { get; set; } = null!;
        public DbSet<AuditLog> AuditLogs { get; set; } = null!;
        public DbSet<JobFair> JobFairs { get; set; } = null!;
        public DbSet<StudentProject> StudentProjects { get; set; } = null!;
        public DbSet<Project> Projects { get; set; } = null!;
        public DbSet<Achievement> Achievements { get; set; } = null!;
        public DbSet<Certification> Certifications { get; set; } = null!;
        public DbSet<ContactLink> ContactLinks { get; set; } = null!;
        public DbSet<Experience> Experiences { get; set; } = null!;
        public DbSet<Education> Educations { get; set; } = null!;
        public DbSet<CompanyContactLink> CompanyContactLinks { get; set; } = null!;
        public DbSet<Notice> Notices { get; set; } = null!;
        public DbSet<CompanyJobFairParticipation> CompanyJobFairParticipations { get; set; } = null!;
        public DbSet<StudentJobFairParticipation> StudentJobFairParticipations { get; set; } = null!;
        public DbSet<CompanyRequest> CompanyRequests { get; set; } = null!;
        // Add the new DbSet property near other DbSet declarations
        public DbSet<AdminAttendanceSession> AdminAttendanceSessions { get; set; } = null!;

        // Inside OnModelCreating: add configuration for AdminAttendanceSession (place near other modelBuilder.Entity(...) calls)
        


        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // ========================================
            // 1. User Relationships (One-to-One)
            // ========================================
            modelBuilder.Entity<User>()
                .HasOne(u => u.Student)
                .WithOne(s => s.User)
                .HasForeignKey<Student>(s => s.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<User>()
                .HasOne(u => u.Company)
                .WithOne(c => c.User)
                .HasForeignKey<Company>(c => c.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // ========================================
            // 2. Company Relationships
            // ========================================
            // Company ↔ Room (One-to-One)
            modelBuilder.Entity<Company>()
                .HasOne(c => c.Room)
                .WithOne(r => r.Company)
                .HasForeignKey<Room>(r => r.CompanyId)
                .OnDelete(DeleteBehavior.SetNull);

            // Company ↔ JobFair (Many-to-One via JobFairId)
            modelBuilder.Entity<Company>()
                .HasOne(c => c.JobFair)
                .WithMany()
                .HasForeignKey(c => c.JobFairId)
                .OnDelete(DeleteBehavior.Restrict); // Keep historical data

            // Company ↔ CurrentJobFair (Optional Many-to-One)
            modelBuilder.Entity<Company>()
                .HasOne(c => c.CurrentJobFair)
                .WithMany()
                .HasForeignKey(c => c.CurrentJobFairId)
                .OnDelete(DeleteBehavior.SetNull);

            // Company ↔ Jobs (One-to-Many)
            modelBuilder.Entity<Job>()
                .HasOne(j => j.Company)
                .WithMany(c => c.Jobs)
                .HasForeignKey(j => j.CompanyId)
                .OnDelete(DeleteBehavior.Cascade);

            // Company ↔ InterviewRequests (One-to-Many)
            modelBuilder.Entity<InterviewRequest>()
                .HasOne(ir => ir.Company)
                .WithMany(c => c.InterviewRequests)
                .HasForeignKey(ir => ir.CompanyId)
                .OnDelete(DeleteBehavior.Cascade);

            // Company ↔ Interviews (One-to-Many)
            modelBuilder.Entity<Interview>()
                .HasOne(i => i.Company)
                .WithMany(c => c.Interviews)
                .HasForeignKey(i => i.CompanyId)
                .OnDelete(DeleteBehavior.Cascade);

            // Company ↔ Surveys (One-to-Many)
            modelBuilder.Entity<Survey>()
                .HasOne(s => s.Company)
                .WithMany(c => c.Surveys)
                .HasForeignKey(s => s.CompanyId)
                .OnDelete(DeleteBehavior.Cascade);

            // Company ↔ CompanyContactLinks (One-to-Many)
            modelBuilder.Entity<CompanyContactLink>()
                .HasOne(ccl => ccl.Company)
                .WithMany(c => c.CompanyContactLinks)
                .HasForeignKey(ccl => ccl.CompanyId)
                .OnDelete(DeleteBehavior.Cascade);

            // Company ↔ CompanyJobFairParticipation (One-to-Many)
            modelBuilder.Entity<CompanyJobFairParticipation>()
                .HasOne(p => p.Company)
                .WithMany(c => c.JobFairParticipations)
                .HasForeignKey(p => p.CompanyId)
                .OnDelete(DeleteBehavior.Cascade);

            // Inside OnModelCreating (add alongside other Company/JobFair relationship configs)
            modelBuilder.Entity<CompanyRequest>()
               .HasOne(cr => cr.Company)
               .WithMany(c => c.CompanyRequests)   // <-- must point to Company.CompanyRequests
               .HasForeignKey(cr => cr.CompanyId)
               .OnDelete(DeleteBehavior.Cascade);

            // CompanyRequest -> JobFair
            modelBuilder.Entity<CompanyRequest>()
                .HasOne(cr => cr.JobFair)
                .WithMany()
                .HasForeignKey(cr => cr.JobFairId)
                .OnDelete(DeleteBehavior.Cascade);

            // Indexes for quick admin queries
            modelBuilder.Entity<CompanyRequest>()
                .HasIndex(cr => new { cr.JobFairId, cr.Status });


            modelBuilder.Entity<CompanyRequest>()
                .HasOne(cr => cr.Company)
                .WithMany(c => c.CompanyRequests)
                .HasForeignKey(cr => cr.CompanyId)
                .OnDelete(DeleteBehavior.Cascade);

            // CompanyRequest -> JobFair
            modelBuilder.Entity<CompanyRequest>()
                .HasOne(cr => cr.JobFair)
                .WithMany()
                .HasForeignKey(cr => cr.JobFairId)
                .OnDelete(DeleteBehavior.Cascade);

            // Indexes for quick admin queries
            modelBuilder.Entity<CompanyRequest>()
                .HasIndex(cr => new { cr.JobFairId, cr.Status });



            modelBuilder.Entity<AdminAttendanceSession>()
    .HasOne(s => s.JobFair)
    .WithMany()
    .HasForeignKey(s => s.JobFairId)
    .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<AdminAttendanceSession>()
        .HasIndex(s => s.SessionToken)
        .IsUnique();

            modelBuilder.Entity<AdminAttendanceSession>()
        .HasIndex(s => new {
            s.JobFairId,
            s.IsActive
        });

            // ========================================
            // 3. Student Relationships
            // ========================================
            // Student ↔ JobFair (Many-to-One)
            modelBuilder.Entity<Student>()
                .HasOne(s => s.JobFair)
                .WithMany()
                .HasForeignKey(s => s.JobFairId)
                .OnDelete(DeleteBehavior.Restrict);

            // Student ↔ CurrentJobFair (Optional Many-to-One)
            modelBuilder.Entity<Student>()
                .HasOne(s => s.CurrentJobFair)
                .WithMany()
                .HasForeignKey(s => s.CurrentJobFairId)
                .OnDelete(DeleteBehavior.SetNull);

            // Student ↔ InterviewRequests (One-to-Many)
            modelBuilder.Entity<InterviewRequest>()
                .HasOne(ir => ir.Student)
                .WithMany(s => s.InterviewRequests)
                .HasForeignKey(ir => ir.StudentId)
                .OnDelete(DeleteBehavior.Cascade);

            // Student ↔ Interviews (One-to-Many)
            modelBuilder.Entity<Interview>()
                .HasOne(i => i.Student)
                .WithMany(s => s.Interviews)
                .HasForeignKey(i => i.StudentId)
                .OnDelete(DeleteBehavior.Cascade);

            // Student ↔ StudentProject (Many-to-Many via Join Table)
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

            // Ensure unique student-project combinations
            modelBuilder.Entity<StudentProject>()
                .HasIndex(sp => new { sp.StudentId, sp.ProjectId })
                .IsUnique();

            // Student ↔ Achievement (One-to-Many)
            modelBuilder.Entity<Achievement>()
                .HasOne(a => a.Student)
                .WithMany(s => s.Achievements)
                .HasForeignKey(a => a.StudentId)
                .OnDelete(DeleteBehavior.Cascade);

            // Student ↔ Certification (One-to-Many)
            modelBuilder.Entity<Certification>()
                .HasOne(c => c.Student)
                .WithMany(s => s.Certifications)
                .HasForeignKey(c => c.StudentId)
                .OnDelete(DeleteBehavior.Cascade);

            // Student ↔ ContactLink (One-to-Many)
            modelBuilder.Entity<ContactLink>()
                .HasOne(cl => cl.Student)
                .WithMany(s => s.ContactLinks)
                .HasForeignKey(cl => cl.StudentId)
                .OnDelete(DeleteBehavior.Cascade);

            // Student ↔ Experience (One-to-Many)
            modelBuilder.Entity<Experience>()
                .HasOne(e => e.Student)
                .WithMany(s => s.Experiences)
                .HasForeignKey(e => e.StudentId)
                .OnDelete(DeleteBehavior.Cascade);

            // Student ↔ Education (One-to-Many)
            modelBuilder.Entity<Education>()
                .HasOne(e => e.Student)
                .WithMany(s => s.Educations)
                .HasForeignKey(e => e.StudentId)
                .OnDelete(DeleteBehavior.Cascade);

            // Student ↔ StudentJobFairParticipation (One-to-Many)
            modelBuilder.Entity<StudentJobFairParticipation>()
                .HasOne(p => p.Student)
                .WithMany(s => s.JobFairParticipations)
                .HasForeignKey(p => p.StudentId)
                .OnDelete(DeleteBehavior.Cascade);

            // ========================================
            // 4. JobFair Relationships (One-to-Many)
            // ========================================
            modelBuilder.Entity<Room>()
                .HasOne(r => r.JobFair)
                .WithMany()
                .HasForeignKey(r => r.JobFairId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Job>()
                .HasOne(j => j.JobFair)
                .WithMany()
                .HasForeignKey(j => j.JobFairId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Interview>()
                .HasOne(i => i.JobFair)
                .WithMany()
                .HasForeignKey(i => i.JobFairId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<InterviewRequest>()
                .HasOne(ir => ir.JobFair)
                .WithMany()
                .HasForeignKey(ir => ir.JobFairId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Survey>()
                .HasOne(s => s.JobFair)
                .WithMany()
                .HasForeignKey(s => s.JobFairId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Notice>()
                .HasOne(n => n.JobFair)
                .WithMany()
                .HasForeignKey(n => n.JobFairId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<CompanyJobFairParticipation>()
                .HasOne(p => p.JobFair)
                .WithMany()
                .HasForeignKey(p => p.JobFairId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<StudentJobFairParticipation>()
                .HasOne(p => p.JobFair)
                .WithMany()
                .HasForeignKey(p => p.JobFairId)
                .OnDelete(DeleteBehavior.Cascade);

            // ========================================
            // 5. Audit & Other Relationships
            // ========================================
            modelBuilder.Entity<AuditLog>()
                .HasOne(a => a.Actor)
                .WithMany()
                .HasForeignKey(a => a.UserId)
                .OnDelete(DeleteBehavior.SetNull);

            // ========================================
            // 6. Participation Unique Constraints
            // ========================================
            modelBuilder.Entity<CompanyJobFairParticipation>()
                .HasIndex(p => new { p.CompanyId, p.JobFairId })
                .IsUnique();

            modelBuilder.Entity<StudentJobFairParticipation>()
                .HasIndex(p => new { p.StudentId, p.JobFairId })
                .IsUnique();

            // ========================================
            // 7. Property Configurations
            // ========================================
            
            // Student Skills (JSON)
            modelBuilder.Entity<Student>()
                .Property(s => s.Skills)
                .HasConversion(
                    v => JsonSerializer.Serialize(v, new JsonSerializerOptions()),
                    v => JsonSerializer.Deserialize<List<string>>(v, new JsonSerializerOptions()) ?? new List<string>()
                )
                .HasColumnType("jsonb");

            // Student CGPA precision
            modelBuilder.Entity<Student>()
                .Property(s => s.CGPA)
                .HasPrecision(3, 2);

            // Job Required Skills (JSON)
            modelBuilder.Entity<Job>()
                .Property(j => j.RequiredSkills)
                .HasConversion(
                    v => JsonSerializer.Serialize(v, new JsonSerializerOptions()),
                    v => JsonSerializer.Deserialize<string[]>(v, new JsonSerializerOptions()) ?? new string[] { }
                )
                .HasColumnType("jsonb");

            // Project Type as string
            modelBuilder.Entity<Project>()
                .Property(p => p.Type)
                .HasConversion<string>();

            modelBuilder.Entity<Project>()
                .HasIndex(p => p.Type);

            modelBuilder.Entity<Project>()
                .HasIndex(p => p.CreatedAt);

            // StudentProject Status as string
            modelBuilder.Entity<StudentProject>()
                .Property(sp => sp.Status)
                .HasConversion<string>()
                .HasDefaultValue(ProjectInviteStatus.Pending);

            modelBuilder.Entity<StudentProject>()
                .Property(sp => sp.IsCreator)
                .HasDefaultValue(false);

            // ContactLink Platform as string
            modelBuilder.Entity<ContactLink>()
                .Property(cl => cl.Platform)
                .HasConversion<string>();

            modelBuilder.Entity<ContactLink>()
                .HasIndex(cl => new { cl.StudentId, cl.Platform })
                .IsUnique();

            // CompanyContactLink Platform as string
            modelBuilder.Entity<CompanyContactLink>()
                .Property(ccl => ccl.Platform)
                .HasConversion<string>();

            modelBuilder.Entity<CompanyContactLink>()
                .HasIndex(ccl => new { ccl.CompanyId, ccl.Platform })
                .IsUnique();

            // Achievement properties
            modelBuilder.Entity<Achievement>()
                .Property(a => a.Title)
                .IsRequired()
                .HasMaxLength(100);

            modelBuilder.Entity<Achievement>()
                .Property(a => a.Description)
                .HasMaxLength(500);

            // Certification properties
            modelBuilder.Entity<Certification>()
                .Property(c => c.Title)
                .IsRequired()
                .HasMaxLength(100);

            modelBuilder.Entity<Certification>()
                .Property(c => c.Issuer)
                .HasMaxLength(100);

            modelBuilder.Entity<Certification>()
                .Property(c => c.CredentialUrl)
                .HasMaxLength(500);

            // Experience properties
            modelBuilder.Entity<Experience>()
                .Property(e => e.CompanyName)
                .IsRequired()
                .HasMaxLength(100);

            modelBuilder.Entity<Experience>()
                .Property(e => e.Description)
                .HasMaxLength(500);

            modelBuilder.Entity<Experience>()
                .Property(e => e.IsCurrent)
                .HasDefaultValue(false);

            modelBuilder.Entity<Experience>()
                .HasIndex(e => new { e.StudentId, e.StartDate });

            // Education properties
            modelBuilder.Entity<Education>()
                .Property(e => e.InstitutionName)
                .IsRequired()
                .HasMaxLength(150);

            modelBuilder.Entity<Education>()
                .Property(e => e.Degree)
                .IsRequired()
                .HasMaxLength(100);
        }
    }
}
