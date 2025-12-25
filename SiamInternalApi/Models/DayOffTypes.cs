using System.ComponentModel.DataAnnotations.Schema;

namespace SiamInternalApi.Models
{
    [Table("day_off_types")]
    public class DayOffType
    {
        [Column("id")]
        public short Id { get; set; }   // smallint trong DB

        [Column("code")]
        public string Code { get; set; } = "";

        [Column("name")]
        public string Name { get; set; } = "";

        [Column("tinh_luong")]
        public bool TinhLuong { get; set; }

        [Column("deleted")]
        public bool Deleted { get; set; }

        // Quan hệ: 1 loại nghỉ có nhiều đơn
        public ICollection<Letter> Letters { get; set; } = new List<Letter>();
    }
}
