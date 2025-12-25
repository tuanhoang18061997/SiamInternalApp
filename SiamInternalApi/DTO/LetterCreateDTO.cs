namespace SiamInternalApi.DTO
{
    public class LetterCreateDto
    {
        public DateTime FromDate { get; set; }
        public DateTime ToDate { get; set; }
        public int DayOffTypeId { get; set; }   // loại nghỉ (phép, bù, công tác…)
        public int OffTypeId { get; set; }      // buổi nghỉ (1 = sáng, 2 = chiều, 3 = cả ngày)
        public string Reason { get; set; } = "";
        public string? ReplacePerson { get; set; } // bàn giao (nếu có)
    }
}
