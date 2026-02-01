namespace SiamInternalApi.DTO
{
    public class LetterCreateDto
    {
        public DateTime FromDate { get; set; }
        public DateTime ToDate { get; set; }
        public int DayOffTypeId { get; set; } 
        public int OffTypeId { get; set; }    
        public string Reason { get; set; } = "";
        public string? ReplacePerson { get; set; }
        public byte? StatusId { get; set; }
    }
}
