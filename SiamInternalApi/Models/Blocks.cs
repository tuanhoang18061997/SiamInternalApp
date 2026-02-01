using System.ComponentModel.DataAnnotations.Schema;

namespace SiamInternalApi.Models
{
    [Table("blocks")]
    public class Block
    {
        [Column("id")]
        public int Id { get; set; }

        [Column("name")]
        public string? Name { get; set; }

        public ICollection<Profile>? Profiles { get; set; }
    }
}
