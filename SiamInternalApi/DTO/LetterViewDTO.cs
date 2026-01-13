namespace SiamInternalApi.DTO
{
    public class LetterViewDto
    {
        public int Id { get; set; }
        public int CreatorId { get; set; }
        public string Code { get; set; } = "";
        public DateTime FromDate { get; set; }
        public DateTime ToDate { get; set; }
        public decimal DaysOff { get; set; }
        public DateTime CreateDate { get; set; }
        public DateTime? ApprovalDate { get; set; }
        public string Reason { get; set; } = "";
        public byte StatusId { get; set; }
        public byte OffTypeId { get; set; }
        public string ReplacePerson { get; set; } = "";

        // Thông tin hiển thị thêm
        public string CreatorName { get; set; } = "";
        public string ApproverName { get; set; } = "";
        public string DayOffTypeName { get; set; } = "";
    }
}
