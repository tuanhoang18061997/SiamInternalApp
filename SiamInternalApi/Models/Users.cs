using System.ComponentModel.DataAnnotations.Schema;

namespace SiamInternalApi.Models
{
    [Table("users")]
    public class User
    {
        [Column("id")]
        public int Id { get; set; }

        [Column("username")]
        public string Username { get; set; } = "";

        [Column("password")]
        public string Password { get; set; } = "";

        [Column("active")]
        public bool Active { get; set; }

        [Column("name")]
        public string Name { get; set; } = "";

        [Column("employee_id")]
        public int EmployeeId { get; set; }

        [Column("group_id")]
        public int GroupId { get; set; }

        [Column("created")]
        public DateTime Created { get; set; }

        [Column("modified")]
        public DateTime Modified { get; set; }

        // Navigation sang Employee
        public Employee? Employee { get; set; }
    }
}
