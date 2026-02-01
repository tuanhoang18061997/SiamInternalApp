using System.ComponentModel.DataAnnotations.Schema;

namespace SiamInternalApi.Models
{
    [Table("religions")]
    public class Religions
    {
        [Column("id")]
        public short? Id { get; set; }

        [Column("name")]
        public string? Name { get; set; }
        public ICollection<Employee>? Employees { get; set; }
    }
}
