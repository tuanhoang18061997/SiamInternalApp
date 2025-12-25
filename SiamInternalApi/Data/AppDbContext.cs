using Microsoft.EntityFrameworkCore;
using SiamInternalApi.Models;

namespace SiamInternalApi.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<User> Users { get; set; }
        public DbSet<Employee> Employees { get; set; }
        public DbSet<Letter> Letters { get; set; }
        public DbSet<DayOffType> DayOffTypes { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // User ↔ Employee
            modelBuilder.Entity<User>(entity =>
            {
                entity.HasOne(u => u.Employee)
                      .WithMany(e => e.Users)
                      .HasForeignKey(u => u.EmployeeId)
                      .OnDelete(DeleteBehavior.Restrict);
            });

            // Letter ↔ User, DayOffType
            modelBuilder.Entity<Letter>(entity =>
            {
                entity.HasOne(l => l.Creator)
                      .WithMany()
                      .HasForeignKey(l => l.CreatorId)
                      .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(l => l.Approver)
                      .WithMany()
                      .HasForeignKey(l => l.ApproverId)
                      .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(l => l.DayOffType)
                      .WithMany(d => d.Letters)
                      .HasForeignKey(l => l.DayOffTypeId)
                      .OnDelete(DeleteBehavior.Restrict);
            });
        }
    }
}
