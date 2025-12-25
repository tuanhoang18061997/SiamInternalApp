using System.ComponentModel.DataAnnotations.Schema;

namespace SiamInternalApi.Models
{
    [Table("employees")]
    public class Employee
    {
        [Column("id")]
        public int Id { get; set; }

        [Column("code")]
        public string? Code { get; set; }

        [Column("name")]
        public string? Name { get; set; }

        [Column("alias")]
        public string? Alias { get; set; }

        // Quan hệ: 1 nhân viên có thể có nhiều user login
        public ICollection<User>? Users { get; set; }
    }
}
