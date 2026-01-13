using System.ComponentModel.DataAnnotations.Schema;

namespace SiamInternalApi.Models
{
    [Table("ethnics")]
    public class Ethnics
    {
        [Column("id")]
        public short? Id { get; set; }

        [Column("name")]
        public string? Name { get; set; }

        public ICollection<Employee>? Employees { get; set; }
    }
}
