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

        [Column("meal_support")]
        public byte MealSupport { get; set; }

        [Column("phi_cong_doan")]
        public byte PhiCongDoan { get; set; }

        [Column("bhtn")]
        public byte BHTN { get; set; }

        [Column("on_saturday")]
        public byte OnSaturday { get; set; }

        [Column("on_sunday")]
        public byte OnSunday { get; set; }

        [Column("morning_in")]
        public TimeSpan MorningIn { get; set; }

        [Column("morning_out")]
        public TimeSpan MorningOut { get; set; }

        [Column("afternoon_in")]
        public TimeSpan AfternoonIn { get; set; }

        [Column("afternoon_out")]
        public TimeSpan AfternoonOut  { get; set; }

        [Column("work_hours")]
        public decimal WorkHour  { get; set; }

        [Column("compensation_day")]
        public decimal CompensationDay {get; set;}
        
        [Column("vacation_day")]
        public decimal VacationDay { get; set; }

        public Employee? Employee { get; set; }
    }
}
