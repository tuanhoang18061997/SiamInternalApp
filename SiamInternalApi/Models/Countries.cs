using System.ComponentModel.DataAnnotations.Schema;

namespace SiamInternalApi.Models
{
    [Table("countries")]
    public class Countries
    {
        [Column("id")]
        public int? Id { get; set; }

        [Column("name")]
        public string? Name { get; set; }
        public ICollection<Employee>? Employees { get; set; }
    }
}
