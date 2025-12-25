using System;
using System.ComponentModel.DataAnnotations.Schema;

namespace SiamInternalApi.Models
{
    [Table("letters")]
    public class Letter
    {
        [Column("id")]
        public int Id { get; set; }

        [Column("code")]
        public string Code { get; set; } = "";

        [Column("from_date")]
        public DateTime FromDate { get; set; }

        [Column("to_date")]
        public DateTime ToDate { get; set; }

        [Column("days_off", TypeName = "decimal(4,1)")]
        public decimal DaysOff { get; set; }

        [Column("create_date")]
        public DateTime CreateDate { get; set; }

        [Column("approval_date")]
        public DateTime? ApprovalDate { get; set; }

        [Column("approver_id")]
        public int? ApproverId { get; set; }

        [Column("reason")]
        public string? Reason { get; set; }

        [Column("day_off_type_id")]
        public short? DayOffTypeId { get; set; }

        [Column("creator_id")]
        public int CreatorId { get; set; }

        [Column("status_id")]
        public byte? StatusId { get; set; }

        [Column("off_type_id")]
        public byte? OffTypeId { get; set; }

        [Column("replace_person")]
        public string? ReplacePerson { get; set; }

        // Navigation
        public User? Creator { get; set; }
        public User? Approver { get; set; }
        public DayOffType? DayOffType { get; set; }
    }
}
