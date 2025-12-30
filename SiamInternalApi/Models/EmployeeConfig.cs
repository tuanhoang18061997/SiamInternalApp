using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SiamInternalApi.Models
{
    [Table("employee_configs")]
    public class EmployeeConfig
    {
        [Column("id")]
        public int Id { get; set; }

        [Column("employee_id")]
        public int EmployeeId { get; set; }

        [Column("approver1_id")]
        public int? Approved1Id { get; set; }

        [Column("approver2_id")]
        public int? Approved2Id { get; set; }

        [Column("approver3_id")]
        public int? Approved3Id { get; set; }

        [Column("vacation_day", TypeName = "decimal(4,1)")]
        public decimal VacationDay { get; set; }

        public Employee? Employee { get; set; }
    }
}
