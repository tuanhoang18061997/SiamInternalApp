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

            if (groupId != 1 && groupId != 2)
            {
                // Nếu không phải admin/manager thì chỉ lấy đơn của mình + nhân viên mình quản lý
                var managedEmployeeIds = await _context.EmployeeConfigs
                    .Where(ec => ec.Approved1Id == employeeId
                            || ec.Approved2Id == employeeId
                            || ec.Approved3Id == employeeId)
                    .Select(ec => ec.EmployeeId)
                    .ToListAsync();

                query = query.Where(l => l.CreatorId == employeeId || managedEmployeeIds.Contains(l.CreatorId));
            }

            var letters = await query
                .OrderByDescending(l => l.Id)
                .ToListAsync();

            var result = letters
                .Select(MapToViewDto)
                .Where(dto => dto != null)
                .ToList();

            var myLetters = result.Where(dto => dto.CreatorId == employeeId).ToList();
            var managedLetters = result.Where(dto => dto.CreatorId != employeeId).ToList();

            return Ok(new
            {
                myLettersCount = myLetters.Count,
                managedLettersCount = managedLetters.Count,
                myLetters,
                managedLetters
            });
        }
        
        [HttpPut("{id}/submit")]
        [Authorize]
        public async Task<IActionResult> SubmitDraft(int id)
        {
            var employeeId = int.Parse(User.FindFirst("EmployeeId")!.Value);

            var letter = await _context.Letters
                .FirstOrDefaultAsync(l => l.Id == id && l.CreatorId == employeeId);

            if (letter == null) return NotFound("Letter not found");
            if (letter.StatusId != 1) return BadRequest("Only draft letters can be submitted");

            var config = await _context.EmployeeConfigs
                .FirstOrDefaultAsync(ec => ec.EmployeeId == employeeId);
            if (config == null) return NotFound("Employee config not found");

            // 👉 Tính số ngày nghỉ của đơn
            var totalDays = letter.DaysOff;

            // 👉 Nếu loại ngày nghỉ là Nghỉ phép thì check ngày phép còn lại
            if (letter.DayOffTypeId == 1 && config.VacationDay < totalDays)
            {
                return BadRequest("Bạn không đủ ngày phép để gửi đơn này.");
            }

            // Cập nhật trạng thái
            letter.StatusId = 2;
            letter.ApproverId = 0;
            letter.ApprovalDate = DateTime.MinValue;

            // 👉 Trừ ngày phép ngay khi gửi
            if (letter.DayOffTypeId == 1)
            {
                config.VacationDay -= totalDays;
                _context.EmployeeConfigs.Update(config);
            }

            await _context.SaveChangesAsync();

            return Ok(new { message = "Draft submitted successfully", id = letter.Id, code = letter.Code });
        }



        [HttpGet("balance")]
        public async Task<IActionResult> GetVacationBalance()
        {
            try
            {
                var employeeIdClaim = User.Claims.FirstOrDefault(c => c.Type == "EmployeeId");
                if (employeeIdClaim == null)
                    return Unauthorized("EmployeeId not found in token");

                int employeeId = int.Parse(employeeIdClaim.Value);

                var config = await _context.EmployeeConfigs
                    .FirstOrDefaultAsync(e => e.EmployeeId == employeeId); 

                if (config == null)
                    return NotFound("Employee not found");

                return Ok(new
                {
                    compensationDay = config.CompensationDay,
                    vacationDay = config.VacationDay
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error retrieving balance", detail = ex.Message });
            }
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
                if (letter.StatusId == 2) 
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
                    dto.DayOffTypeId,
                    currentUserGroupId = groupId,
                    canApprove 
                });
            }

            return Forbid("You can only view your own letters or those you manage");
        }
        
        [HttpDelete("{id}/delete")]
        [Authorize]
        public async Task<IActionResult> DeleteDraft(int id)
        {
            var employeeId = int.Parse(User.FindFirst("EmployeeId")!.Value);

            var letter = await _context.Letters
                .FirstOrDefaultAsync(l => l.Id == id && l.CreatorId == employeeId);

            if (letter == null) return NotFound("Letter not found");
            if (letter.StatusId != 1) return BadRequest("Only draft letters can be deleted");

            _context.Letters.Remove(letter);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Draft deleted successfully" });
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

            if (dto.FromDate.DayOfWeek == DayOfWeek.Sunday || dto.ToDate.DayOfWeek == DayOfWeek.Sunday) 
                return BadRequest("Không thể tạo đơn nghỉ vào Chủ Nhật.");
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
                StatusId = (byte?)dto.StatusId,
                CreateDate = DateTime.Now,
                ApprovalDate = DateTime.MinValue,
                ApproverId = 0
            };

            _context.Letters.Add(letter);
            await _context.SaveChangesAsync();

            // 👉 Chỉ trừ ngày phép nếu là đơn gửi đi 
            if (dto.StatusId == 2 && dto.DayOffTypeId == 1) 
            { 
                config.VacationDay -= (decimal)totalDays; 
                _context.EmployeeConfigs.Update(config); 
                await _context.SaveChangesAsync(); 
            }

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

            if (groupId != 1 && groupId != 2)
                return Forbid("Only admins/managers can update status");

            var letter = await _context.Letters.FindAsync(id);
            if (letter == null) return NotFound("Letter not found");

            if (letter.StatusId == newStatusId) { 
                return BadRequest("Status is already set to this value"); 
            }

            // 👉 Nếu chuyển sang Reject thì hoàn lại ngày phép
            if (newStatusId == 4 && letter.DayOffTypeId == 1 && letter.StatusId != 4)
            {
                var config = await _context.EmployeeConfigs
                    .FirstOrDefaultAsync(ec => ec.EmployeeId == letter.CreatorId);

                if (config != null)
                {
                    config.VacationDay += letter.DaysOff;
                    _context.EmployeeConfigs.Update(config);
                }
            }
            
            // 👉 Nếu chuyển từ Reject sang Pending/Approve thì trừ lại ngày phép
            if ((newStatusId == 2 || newStatusId == 3) && letter.DayOffTypeId == 1 && letter.StatusId == 4)
            {
                var config = await _context.EmployeeConfigs
                    .FirstOrDefaultAsync(ec => ec.EmployeeId == letter.CreatorId);

                if (config != null)
                {
                    config.VacationDay -= letter.DaysOff;
                    _context.EmployeeConfigs.Update(config);
                }
            }

            // Cập nhật trạng thái
            letter.StatusId = newStatusId;

            if (newStatusId == 2) // Pending
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

            if (letter.StatusId == 3) 
                return BadRequest("Letter is already approved");
            // Chỉ cho phép thay đổi nếu đơn đang pending hoặc đã được duyệt/từ chối
            if (letter.StatusId != 2 && letter.StatusId != 3 && letter.StatusId != 4)
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

            if (letter.DayOffTypeId == 1 && letter.StatusId == 4) 
            { 
                var config = await _context.EmployeeConfigs 
                    .FirstOrDefaultAsync(ec => ec.EmployeeId == letter.CreatorId); 
                if (config != null) 
                { 
                    config.VacationDay -= letter.DaysOff; 
                    _context.EmployeeConfigs.Update(config); 
                } 
            }
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
            
            if (letter.StatusId == 4) 
                return BadRequest("Letter is already rejected");

            if (letter.StatusId != 2 && letter.StatusId != 3 && letter.StatusId != 4)
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
            if (letter.DayOffTypeId == 1) 
            { 
                var config = await _context.EmployeeConfigs 
                    .FirstOrDefaultAsync(ec => ec.EmployeeId == letter.CreatorId); 
                if (config != null) 
                { 
                    config.VacationDay += letter.DaysOff; 
                    _context.EmployeeConfigs.Update(config); 
                } 
            }

            await _context.SaveChangesAsync();

            return Ok(new { message = "Letter rejected successfully", id = letter.Id, code = letter.Code });
        }



        [HttpPut("{id}/edit")]
        [Authorize]
        public async Task<IActionResult> EditDraft(int id, [FromBody] LetterCreateDto dto)
        {
            var employeeId = int.Parse(User.FindFirst("EmployeeId")!.Value);

            var letter = await _context.Letters.FirstOrDefaultAsync(l => l.Id == id && l.CreatorId == employeeId);
            if (letter == null) return NotFound("Letter not found");

            if (letter.StatusId != 1) return BadRequest("Only draft letters can be edited");

            var config = await _context.EmployeeConfigs.FirstOrDefaultAsync(ec => ec.EmployeeId == employeeId);
            if (config == null) return NotFound("Employee config not found");

            // 👉 Kiểm tra điều kiện giống CreateLetter
            if (dto.FromDate.DayOfWeek == DayOfWeek.Sunday || dto.ToDate.DayOfWeek == DayOfWeek.Sunday)
                return BadRequest("Không thể tạo đơn nghỉ vào Chủ Nhật.");

            var hasOverlap = await _context.Letters.AnyAsync(l =>
                l.CreatorId == employeeId &&
                l.Id != id &&
                l.StatusId != 4 &&
                l.FromDate <= dto.ToDate.Date &&
                l.ToDate >= dto.FromDate.Date
            );
            if (hasOverlap)
                return BadRequest("Bạn đã có đơn nghỉ trong khoảng ngày này, không thể tạo thêm.");

            double totalDays = 0;
            if (dto.OffTypeId == 1 || dto.OffTypeId == 2)
                totalDays = 0.5;
            else if (dto.OffTypeId == 3)
                totalDays = (dto.ToDate.Date - dto.FromDate.Date).TotalDays + 1;
            else
                return BadRequest("Invalid OffTypeId");

            if (dto.DayOffTypeId == 1 && config.VacationDay < (decimal)totalDays)
                return BadRequest("Bạn không đủ ngày phép để tạo đơn này.");

            // 👉 Cập nhật nội dung đơn nháp
            letter.FromDate = dto.FromDate.Date;
            letter.ToDate = dto.ToDate.Date;
            letter.DaysOff = (decimal)totalDays;
            letter.Reason = dto.Reason;
            letter.DayOffTypeId = (short?)dto.DayOffTypeId;
            letter.OffTypeId = (byte?)dto.OffTypeId;
            letter.ReplacePerson = string.IsNullOrWhiteSpace(dto.ReplacePerson) ? "" : dto.ReplacePerson;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Draft updated successfully", id = letter.Id, code = letter.Code });
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
                    CreatorId = l.CreatorId,
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
                    DayOffTypeName = l.DayOffType?.Name ?? "",
                    DayOffTypeId = l.DayOffTypeId ?? 0
                };
            }
            catch
            {
                return null!;
            }
        }
    }
}
