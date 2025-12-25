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
    
        // Xem tất cả đơn theo role 
        [HttpGet]
        [Authorize]
        public async Task<IActionResult> GetLetters()
        {
            var userId = int.Parse(User.FindFirst("UserId")!.Value);
            var groupId = int.Parse(User.FindFirst(ClaimTypes.Role)!.Value);

            var query = _context.Letters
                .Include(l => l.Creator)
                .Include(l => l.Approver)
                .Include(l => l.DayOffType)
                .AsQueryable();

            if (groupId == 1 || groupId == 2)
            {
                // Manager → xem tất cả đơn
            }
            else if (groupId >= 3 && groupId <= 7)
            {
                // Employee → chỉ xem đơn của mình
                query = query.Where(l => l.CreatorId == userId);
            }
            else
            {
                return Forbid("Invalid group_id");
            }

            // Lấy toàn bộ record
            var letters = await query
                .OrderByDescending(l => l.Id)
                .ToListAsync();

            // Map sang DTO và lọc record hợp lệ
            var result = letters
                .Select(MapToViewDto)
                .Where(dto => dto != null)
                .ToList();

            return Ok(new
            {
                totalCount = result.Count, // tổng số record hợp lệ
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
            var userId = int.Parse(User.FindFirst("UserId")!.Value);
            var groupId = int.Parse(User.FindFirst(ClaimTypes.Role)!.Value);

            var letter = await _context.Letters
                .Include(l => l.Creator)
                .Include(l => l.Approver)
                .Include(l => l.DayOffType)
                .FirstOrDefaultAsync(l => l.Id == id);

            if (letter == null) return NotFound();

            if (groupId == 1 || groupId == 2 || (groupId >= 3 && groupId <= 7 && letter.CreatorId == userId))
            {
                var dto = MapToViewDto(letter); 
                return Ok(new 
                { 
                    dto.Id, dto.Code, dto.FromDate, dto.ToDate, dto.DaysOff, dto.CreateDate, dto.ApprovalDate, dto.Reason, dto.StatusId, dto.OffTypeId, dto.ReplacePerson, dto.CreatorName, dto.ApproverName, dto.DayOffTypeName, currentUserGroupId = groupId // thêm role hiện tại 
                });
            }

            return Forbid("You can only view your own letters");
        }

        [HttpPost]
        [Authorize]
        public async Task<IActionResult> CreateLetter([FromBody] LetterCreateDto dto)
        {
            var userId = int.Parse(User.FindFirst("UserId")!.Value);

            var totalDays = (dto.ToDate.Date - dto.FromDate.Date).TotalDays ;
            if (dto.OffTypeId == 1 || dto.OffTypeId == 2)
            {
                totalDays = 0.5;
            }

            var letter = new Letter
            {
                CreatorId = userId,
                FromDate = dto.FromDate.Date,
                ToDate = dto.ToDate.Date,
                DaysOff = (decimal)totalDays,
                Reason = dto.Reason,
                DayOffTypeId = (short?)dto.DayOffTypeId,
                OffTypeId = (byte?)dto.OffTypeId,
                ReplacePerson = string.IsNullOrWhiteSpace(dto.ReplacePerson) ? "" : dto.ReplacePerson,
                StatusId = (byte?)1, // pending
                CreateDate = DateTime.Now,

                // Gán giá trị mặc định để tránh null
                ApprovalDate = DateTime.MinValue, 
                ApproverId = 0 
            };


            _context.Letters.Add(letter);
            await _context.SaveChangesAsync();

            // Sau khi có Id thì sinh Code
            letter.Code = $"DXN{letter.Id.ToString().PadLeft(6, '0')}";
            await _context.SaveChangesAsync();

            return Ok(new { message = "Tạo đơn thành công", id = letter.Id, code = letter.Code });
        }

        [HttpPut("{id}/approve")]
        [Authorize]
        public async Task<IActionResult> ApproveLetter(int id)
        {
            var userId = int.Parse(User.FindFirst("UserId")!.Value);
            var groupId = int.Parse(User.FindFirst(ClaimTypes.Role)!.Value);

            if (groupId != 1 && groupId != 2)
                return Forbid("Only managers can approve letters");

            var letter = await _context.Letters.FindAsync(id);
            if (letter == null) return NotFound("Letter not found");

            if (letter.StatusId != 1)
                return BadRequest("Only pending letters can be approved");

            letter.StatusId = 3; // approved
            letter.ApproverId = userId;
            letter.ApprovalDate = DateTime.Now;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Letter approved successfully", id = letter.Id, code = letter.Code });
        }

        [HttpPut("{id}/reject")]
        [Authorize]
        public async Task<IActionResult> RejectLetter(int id)
        {
            var userId = int.Parse(User.FindFirst("UserId")!.Value);
            var groupId = int.Parse(User.FindFirst(ClaimTypes.Role)!.Value);

            if (groupId != 1 && groupId != 2)
                return Forbid("Only managers can reject letters");

            var letter = await _context.Letters.FindAsync(id);
            if (letter == null) return NotFound("Letter not found");

            if (letter.StatusId != 1)
                return BadRequest("Only pending letters can be rejected");

            letter.StatusId = 4; // rejected
            letter.ApproverId = userId;
            letter.ApprovalDate = DateTime.Now;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Letter rejected successfully", id = letter.Id, code = letter.Code });
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
