using System.ComponentModel.DataAnnotations.Schema;

namespace SiamInternalApi.Models
{
    [Table("branches")]
    public class Branch
    {
        [Column("id")]
        public int Id { get; set; }

        [Column("name")]
        public string? Name { get; set; }

        public ICollection<Profile>? Profiles { get; set; }
    }
}
