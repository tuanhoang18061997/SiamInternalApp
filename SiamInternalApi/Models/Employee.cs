using System.ComponentModel.DataAnnotations.Schema;
using System.Runtime;

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

        [Column("gender")]
        public byte? Gender { get; set; }
        
        [Column("ethnic_id")]
        public short? EthnicId { get; set; }

        [Column("religion_id")]
        public short? ReligionId { get; set; }

        [Column("date_of_birth")]
        public DateTime? DateOfBirth { get; set; }

        [Column("place_of_birth_id")]
        public int? PlaceOfBirthId { get; set; }

        [Column("country_id")]
        public int? CountryId { get; set; }

        [Column("marital_status_id")]
        public int? MaritalStatusId { get; set; }
        
        [Column("permanent_address")]
        public string? PermanentAddress { get; set; }
        
        [Column("temporary_address")]
        public string? TemporaryAddress { get; set; }

        [Column("email")]
        public string? Email { get; set; }

        [Column("company_email")]
        public string? CompanyEmail { get; set; }

        [Column("phone_number")]
        public string? PhoneNumber { get; set; }

        [Column("mobile_number")]
        public string? MobileNumber { get; set; }

        [Column("status")]
        public int? Status { get; set; }
        
        [Column("attendance_code")]
        public string? AttendanceCode { get; set; }

        public Countries? Country {get; set;}
        public Ethnics? Ethnic {get; set;}
        public Religions? Religion {get; set;}
        public Profile? Profile { get; set; }
        public User? Users { get; set; }
    }
}
