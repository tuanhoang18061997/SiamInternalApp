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
        public DbSet<EmployeeConfig> EmployeeConfigs { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            
            modelBuilder.Entity<EmployeeConfig>(entity => 
            { 
                entity.HasOne(ec => ec.Employee) 
                    .WithOne()
                    .HasForeignKey<EmployeeConfig>(ec => ec.EmployeeId) 
                    .OnDelete(DeleteBehavior.Restrict); 
            });

            
            // User ↔ Employee
            modelBuilder.Entity<User>(entity =>
            {
                entity.HasOne(u => u.Employee)
                      .WithOne(e => e.Users)
                      .HasForeignKey<User>(u => u.EmployeeId)
                      .OnDelete(DeleteBehavior.Restrict);
            });
            // Employee ↔ Profile
            modelBuilder.Entity<Employee>(entity => 
            { 
                entity.HasOne(e => e.Profile) 
                    .WithOne(p => p.Employee) 
                    .HasForeignKey<Profile>(p => p.EmployeeId) 
                    .OnDelete(DeleteBehavior.Restrict); 

                entity.HasOne(e => e.Ethnic)
                    .WithMany(et => et.Employees)
                    .HasForeignKey(e => e.EthnicId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(e => e.Religion)
                    .WithMany(r => r.Employees)
                    .HasForeignKey(e => e.ReligionId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(e => e.Country)
                    .WithMany(c => c.Employees)
                    .HasForeignKey(e => e.CountryId)
                    .OnDelete(DeleteBehavior.Restrict);

            }); 
            // Profile ↔ Department, Position, Block, Branch
            modelBuilder.Entity<Profile>(entity => 
            {   
                entity.HasOne(p => p.Department) 
                    .WithMany(d => d.Profiles) 
                    .HasForeignKey(p => p.DepartmentId) 
                    .OnDelete(DeleteBehavior.Restrict); 

                entity.HasOne(p => p.Position) 
                    .WithMany(pos => pos.Profiles) 
                    .HasForeignKey(p => p.PositionId) 
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(p => p.Block)
                    .WithMany(b => b.Profiles)
                    .HasForeignKey(p => p.BlockId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(p => p.Branch)
                    .WithMany(br => br.Profiles)
                    .HasForeignKey(p => p.BranchId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // Letter ↔ Employee, DayOffType
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
