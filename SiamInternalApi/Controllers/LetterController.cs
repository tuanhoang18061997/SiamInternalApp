using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SiamInternalApi.Data;
using SiamInternalApi.Models;
using SiamInternalApi.DTO;
using System.Security.Claims;

namespace SiamInternalApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class LettersController : ControllerBase
    {
        private readonly AppDbContext _context;

        public LettersController(AppDbContext context)
        {
            _context = context;
        }
        

        // Xem tất cả đơn  
        [HttpGet]
        [Authorize]
        public async Task<IActionResult> GetLetters()
        {
            var employeeIdClaim = User.FindFirst("EmployeeId")?.Value;
            var roleClaim = User.FindFirst(ClaimTypes.Role)?.Value;
            if (string.IsNullOrEmpty(employeeIdClaim) || string.IsNullOrEmpty(roleClaim))
                return Problem("Missing EmployeeId or Role claim.");

            var employeeId = int.Parse(employeeIdClaim);
            var groupId = int.Parse(roleClaim);

            var query = _context.Letters
                .Include(l => l.Creator)
                .Include(l => l.Approver)
                .Include(l => l.DayOffType)
                .AsQueryable();

            if (groupId == 1 || groupId == 2)
            {
                // Admin/Manager → xem tất cả đơn
            }
            else
            {
                // Lấy danh sách nhân viên mà current employee là approver
                var managedEmployeeIds = await _context.EmployeeConfigs
                    .Where(ec => ec.Approved1Id == employeeId
                            || ec.Approved2Id == employeeId
                            || ec.Approved3Id == employeeId)
                    .Select(ec => ec.EmployeeId)
                    .ToListAsync();

                // Đơn của mình + đơn nhân viên mình quản lý
                query = query.Where(l => l.CreatorId == employeeId || managedEmployeeIds.Contains(l.CreatorId));
            }

            var letters = await query
                .OrderByDescending(l => l.Id)
                .ToListAsync();

            var result = letters
                .Select(MapToViewDto)
                .Where(dto => dto != null)
                .ToList();

            return Ok(new
            {
                totalCount = result.Count,
                items = result
            });
        }




        [HttpGet("dayofftypes")]
        [Authorize]
        public async Task<IActionResult> GetDayOffTypes()
        {
            var types = await _context.DayOffTypes
                .OrderBy(t => t.Id)
                .Select(t => new {
                    id = t.Id,
                    name = t.Name
                })
                .ToListAsync();

            return Ok(types);
        }

        // Xem chi tiết đơn theo role
        [HttpGet("{id}")]
        [Authorize]
        public async Task<IActionResult> GetLetterById(int id)
        {
            var employeeId = int.Parse(User.FindFirst("EmployeeId")!.Value);
            var groupId = int.Parse(User.FindFirst(ClaimTypes.Role)!.Value);

            var letter = await _context.Letters
                .Include(l => l.Creator)
                .Include(l => l.Approver)
                .Include(l => l.DayOffType)
                .FirstOrDefaultAsync(l => l.Id == id);

            if (letter == null) return NotFound();

            var managedEmployeeIds = await _context.EmployeeConfigs
                .Where(ec => ec.Approved1Id == employeeId
                        || ec.Approved2Id == employeeId
                        || ec.Approved3Id == employeeId)
                .Select(ec => ec.EmployeeId)
                .ToListAsync();

            // 👉 Kiểm tra quyền duyệt/từ chối
            bool canApprove = false;
            if (groupId == 1 || groupId == 2) 
            { 
                if (letter.StatusId == 1) 
                    canApprove = true; 
                else canApprove = false; 
            }
            else
            {
                var config = await _context.EmployeeConfigs
                    .FirstOrDefaultAsync(ec => ec.EmployeeId == letter.CreatorId);

                if (config != null)
                {
                    // Không cho phép người đã duyệt trước đó tự thay đổi quyết định
                    if (letter.ApproverId == employeeId)
                    {
                        canApprove = false;
                    }
                    else
                    {
                        // Leader cấp 1: duyệt khi pending
                        if (config.Approved1Id == employeeId && letter.ApproverId == 0)
                            canApprove = true;

                        // Leader cấp 2: duyệt khi pending hoặc override quyết định của cấp 1
                        if (config.Approved2Id == employeeId &&
                            (letter.ApproverId == 0 || letter.ApproverId == config.Approved1Id))
                            canApprove = true;

                        // Leader cấp 3: duyệt khi pending hoặc override quyết định của cấp 1 và 2
                        if (config.Approved3Id == employeeId &&
                            (letter.ApproverId == 0 ||
                            letter.ApproverId == config.Approved1Id ||
                            letter.ApproverId == config.Approved2Id))
                            canApprove = true;
                    }
                }

            }


            if (groupId == 1 || groupId == 2 
                || letter.CreatorId == employeeId 
                || managedEmployeeIds.Contains(letter.CreatorId))
            {
                var dto = MapToViewDto(letter);
                return Ok(new {
                    dto.Id,
                    dto.Code,
                    dto.FromDate,
                    dto.ToDate,
                    dto.DaysOff,
                    dto.CreateDate,
                    dto.ApprovalDate,
                    dto.Reason,
                    dto.StatusId,
                    dto.OffTypeId,
                    dto.ReplacePerson,
                    dto.CreatorName,
                    dto.ApproverName,
                    dto.DayOffTypeName,
                    currentUserGroupId = groupId,
                    canApprove 
                });
            }

            return Forbid("You can only view your own letters or those you manage");
        }
        
        //Tạo đơn
        [HttpPost]
        [Authorize]
        public async Task<IActionResult> CreateLetter([FromBody] LetterCreateDto dto)
        {
            if (string.IsNullOrWhiteSpace(dto.Reason))
            {
                return BadRequest("Reason is required");
            }

            var employeeId = int.Parse(User.FindFirst("EmployeeId")!.Value);

            var config = await _context.EmployeeConfigs 
                .FirstOrDefaultAsync(ec => ec.EmployeeId == employeeId); 

            if (config == null) return NotFound("Employee config not found");

            //  Kiểm tra trùng ngày
            var hasOverlap = await _context.Letters.AnyAsync(l =>
                l.CreatorId == employeeId &&
                l.StatusId != 4 && // bỏ qua đơn đã bị reject
                l.FromDate <= dto.ToDate.Date &&
                l.ToDate >= dto.FromDate.Date
            );

            if (hasOverlap)
            {
                return BadRequest("Bạn đã có đơn nghỉ trong khoảng ngày này, không thể tạo thêm.");
            }

            double totalDays = 0;
            if (dto.OffTypeId == 1 || dto.OffTypeId == 2)
            {
                totalDays = 0.5;
            }
            else if (dto.OffTypeId == 3)
            {
                totalDays = (dto.ToDate.Date - dto.FromDate.Date).TotalDays + 1;
            }
            else
            {
                return BadRequest("Invalid OffTypeId");
            }
            
            //Nếu loại ngày nghỉ là Nghỉ phép check ngày nghỉ còn lại
            if (dto.DayOffTypeId == 1 && config.VacationDay < (decimal)totalDays) { 
                return BadRequest("Bạn không đủ ngày phép để tạo đơn này."); 
            }

            var letter = new Letter
            {
                CreatorId = employeeId,
                FromDate = dto.FromDate.Date,
                ToDate = dto.ToDate.Date,
                DaysOff = (decimal)totalDays,
                Reason = dto.Reason,
                DayOffTypeId = (short?)dto.DayOffTypeId,
                OffTypeId = (byte?)dto.OffTypeId,
                ReplacePerson = string.IsNullOrWhiteSpace(dto.ReplacePerson) ? "" : dto.ReplacePerson,
                StatusId = (byte?)1, // pending
                CreateDate = DateTime.Now,
                ApprovalDate = DateTime.MinValue,
                ApproverId = 0
            };

            _context.Letters.Add(letter);
            await _context.SaveChangesAsync();

            // Sinh mã đơn sau khi có Id
            letter.Code = $"DXN{letter.Id.ToString().PadLeft(6, '0')}";
            await _context.SaveChangesAsync();

            return Ok(new { message = "Tạo đơn thành công", id = letter.Id, code = letter.Code });
        }



        [HttpPut("{id}/update")]
        [Authorize]
        public async Task<IActionResult> UpdateStatus(int id, [FromBody] byte newStatusId)
        {
            var employeeId = int.Parse(User.FindFirst("EmployeeId")!.Value);
            var groupId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.Role)!.Value);

            // Chỉ admin/manager mới được phép
            if (groupId != 1 && groupId != 2)
                return Forbid("Only admins/managers can update status");

            var letter = await _context.Letters.FindAsync(id);
            if (letter == null) return NotFound("Letter not found");

            // Cập nhật trạng thái
            letter.StatusId = newStatusId;

            if (newStatusId == 1) // 👉 Nếu cập nhật về Pending
            {
                letter.ApproverId = 0;
                letter.ApprovalDate = DateTime.MinValue;
            }
            else
            {
                letter.ApproverId = employeeId;
                letter.ApprovalDate = DateTime.Now;
            }

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Status updated successfully",
                id = letter.Id,
                code = letter.Code,
                status = newStatusId
            });
        }



        [HttpPut("{id}/approve")]
        [Authorize]
        public async Task<IActionResult> ApproveLetter(int id)
        {
            var employeeId = int.Parse(User.FindFirst("EmployeeId")!.Value);
            var groupId = int.Parse(User.FindFirst(ClaimTypes.Role)!.Value);

            var letter = await _context.Letters
                .Include(l => l.Creator)
                .FirstOrDefaultAsync(l => l.Id == id);

            if (letter == null) return NotFound("Letter not found");

            // Chỉ cho phép thay đổi nếu đơn đang pending hoặc đã được duyệt/từ chối
            if (letter.StatusId != 1 && letter.StatusId != 3 && letter.StatusId != 4)
                return BadRequest("Only pending or decided letters can be changed");

            bool canApprove = false;

            if (groupId == 1 || groupId == 2)
            {
                canApprove = true; // Admin/Manager luôn có quyền
            }
            else
            {
                var config = await _context.EmployeeConfigs
                    .FirstOrDefaultAsync(ec => ec.EmployeeId == letter.CreatorId);

                if (config != null)
                {
                    // Không cho phép cùng một người thay đổi quyết định của chính mình
                    if (letter.ApproverId == employeeId)
                        return Forbid("You cannot change your own decision");

                    // Leader cấp 1: duyệt khi pending
                    if (config.Approved1Id == employeeId && letter.ApproverId == 0)
                        canApprove = true;

                    // Leader cấp 2: duyệt khi pending hoặc thay đổi quyết định của cấp 1
                    if (config.Approved2Id == employeeId &&
                        (letter.ApproverId == 0 || letter.ApproverId == config.Approved1Id))
                        canApprove = true;

                    // Leader cấp 3: duyệt khi pending hoặc thay đổi quyết định của cấp 1 và 2
                    if (config.Approved3Id == employeeId &&
                        (letter.ApproverId == 0 ||
                        letter.ApproverId == config.Approved1Id ||
                        letter.ApproverId == config.Approved2Id))
                        canApprove = true;
                }


            }

            if (!canApprove)
                return Forbid("You are not allowed to approve this letter");

            // Cập nhật trạng thái
            letter.StatusId = 3; // approved
            letter.ApproverId = employeeId;
            letter.ApprovalDate = DateTime.Now;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Letter approved successfully", id = letter.Id, code = letter.Code });
        }

        [HttpPut("{id}/reject")]
        [Authorize]
        public async Task<IActionResult> RejectLetter(int id)
        {
            var employeeId = int.Parse(User.FindFirst("EmployeeId")!.Value);
            var groupId = int.Parse(User.FindFirst(ClaimTypes.Role)!.Value);

            var letter = await _context.Letters
                .Include(l => l.Creator)
                .FirstOrDefaultAsync(l => l.Id == id);

            if (letter == null) return NotFound("Letter not found");

            if (letter.StatusId != 1 && letter.StatusId != 3 && letter.StatusId != 4)
                return BadRequest("Only pending or decided letters can be changed");

            bool canReject = false;

            if (groupId == 1 || groupId == 2)
            {
                canReject = true;
            }
            else
            {
                var config = await _context.EmployeeConfigs
                    .FirstOrDefaultAsync(ec => ec.EmployeeId == letter.CreatorId);

                if (config != null)
                {
                    // Không cho phép cùng một người thay đổi quyết định của chính mình
                    if (letter.ApproverId == employeeId)
                        return Forbid("You cannot change your own decision");

                    // Leader cấp 1: duyệt khi pending
                    if (config.Approved1Id == employeeId && letter.ApproverId == 0)
                        canReject = true;

                    // Leader cấp 2: duyệt khi pending hoặc thay đổi quyết định của cấp 1
                    if (config.Approved2Id == employeeId &&
                        (letter.ApproverId == 0 || letter.ApproverId == config.Approved1Id))
                        canReject = true;

                    // Leader cấp 3: duyệt khi pending hoặc thay đổi quyết định của cấp 1 và 2
                    if (config.Approved3Id == employeeId &&
                        (letter.ApproverId == 0 ||
                        letter.ApproverId == config.Approved1Id ||
                        letter.ApproverId == config.Approved2Id))
                        canReject = true;
                }


            }

            if (!canReject)
                return Forbid("You are not allowed to reject this letter");

            letter.StatusId = 4; // rejected
            letter.ApproverId = employeeId;
            letter.ApprovalDate = DateTime.Now;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Letter rejected successfully", id = letter.Id, code = letter.Code });
        }



        [HttpGet("export")]
        [Authorize]
        public async Task<IActionResult> ExportMonthlyReport([FromQuery] int year, [FromQuery] int month)
        {
            var groupId = int.Parse(User.FindFirst(ClaimTypes.Role)!.Value);

            if (groupId != 1 && groupId != 2)
                return Forbid("Only managers can export reports");

            var startDate = new DateTime(year, month, 1);
            var endDate = startDate.AddMonths(1).AddDays(-1);

            var letters = await _context.Letters
                .Include(l => l.Creator)
                .Include(l => l.Approver)
                .Include(l => l.DayOffType)
                .Where(l => l.FromDate >= startDate && l.ToDate <= endDate)
                .OrderBy(l => l.CreatorId)
                .ToListAsync();

            var lines = new List<string> { "Code,Creator,FromDate,ToDate,DaysOff,Reason,Status,DayOffType,CreateDate,ReplacePerson" };
            foreach (var l in letters)
            {
                lines.Add($"{l.Code},{l.Creator?.Name},{l.FromDate:yyyy-MM-dd},{l.ToDate:yyyy-MM-dd},{l.DaysOff},{l.Reason},{l.StatusId},{l.DayOffType?.Name},{l.CreateDate:yyyy-MM-dd},{l.ReplacePerson}");
            }
            var csv = string.Join("\n", lines);

            var bytes = System.Text.Encoding.UTF8.GetBytes(csv);
            return File(bytes, "text/csv", $"LeaveReport_{year}_{month}.csv");
        }

        [HttpGet("balance")]
        [Authorize]
        public async Task<IActionResult> GetVacationBalance()
        {
            var employeeId = int.Parse(User.FindFirst("EmployeeId")!.Value);

            var config = await _context.EmployeeConfigs
                .FirstOrDefaultAsync(ec => ec.EmployeeId == employeeId);

            if (config == null)
                return NotFound("Employee config not found");

            return Ok(new
            {
                employeeId = employeeId,
                vacationDay = config.VacationDay
            });
        }



        // Helper để map sang DTO hiển thị
        private static LetterViewDto MapToViewDto(Letter l)
        {
            try
            {
                return new LetterViewDto
                {
                    Id = l.Id,
                    Code = l.Code,
                    FromDate = l.FromDate,
                    ToDate = l.ToDate,
                    DaysOff = l.DaysOff,
                    CreateDate = l.CreateDate,
                    ApprovalDate = l.ApprovalDate,
                    Reason = l.Reason ?? "",
                    StatusId = l.StatusId ?? 0,
                    OffTypeId = l.OffTypeId ?? 0,
                    ReplacePerson = string.IsNullOrEmpty(l.ReplacePerson) ? "" : l.ReplacePerson,
                    CreatorName = l.Creator?.Name ?? "",
                    ApproverName = l.Approver?.Name ?? "",
                    DayOffTypeName = l.DayOffType?.Name ?? ""
                };
            }
            catch
            {
                return null!;
            }
        }
    }
}
