using System.ComponentModel.DataAnnotations.Schema;

namespace SiamInternalApi.Models
{
    [Table("departments")]
    public class Department
    {
        [Column("id")]
        public int Id { get; set; }

        [Column("code")]
        public string? Code { get; set; }

        [Column("name")]
        public string? Name { get; set; }

        public ICollection<Profile>? Profiles { get; set; }
    }
}
