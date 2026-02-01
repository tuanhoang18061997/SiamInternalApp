using System.ComponentModel.DataAnnotations.Schema;

namespace SiamInternalApi.Models
{
    [Table("profiles")]
    public class Profile
    {
        [Column("id")]
        public int Id { get; set; }

        [Column("primary")]
        public byte? Primary { get; set; }

        [Column("employee_id")]
        public int EmployeeId { get; set; }

        [ForeignKey("EmployeeId")]
        public Employee Employee { get; set; } = null!;

        [Column("department_id")]
        public int? DepartmentId { get; set; }

        [ForeignKey("DepartmentId")]
        public Department? Department { get; set; }

        [Column("position_id")]
        public int? PositionId { get; set; }

        [ForeignKey("PositionId")]
        public Position? Position { get; set; }

        [Column("branch_id")]
        public int? BranchId { get; set; }

        [ForeignKey("BranchId")]
        public Branch? Branch { get; set; }

        [Column("block_id")]
        public int? BlockId { get; set; }

        [ForeignKey("BlockId")]
        public Block? Block { get; set; }

    }
}
