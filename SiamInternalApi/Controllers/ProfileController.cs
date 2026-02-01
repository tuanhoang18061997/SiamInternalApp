using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using Microsoft.EntityFrameworkCore;
using SiamInternalApi.Data;
using SiamInternalApi.Models;
using System.Collections.Immutable;
using System.Security.Claims;

namespace SiamInternalApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ProfileController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ProfileController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet("config")]
        [Authorize]
        public async Task<IActionResult> GetConfig()
        {
            var employeeIdClaim = User.FindFirst("EmployeeId")?.Value;
            if (string.IsNullOrEmpty(employeeIdClaim))
                return Problem("Missing EmployeeId claim");

            var employeeId = int.Parse(employeeIdClaim);

            var config = await _context.EmployeeConfigs
                .Include(c => c.Employee)
                .FirstOrDefaultAsync(c => c.EmployeeId == employeeId);
            
            if (config == null)
                return NotFound("Employee config not found");

            return Ok(new
            {   
                employeeId = config.EmployeeId,
                employeeName = config.Employee?.Name,
                mealSupport = config.MealSupport,
                phiCongDoan = config.PhiCongDoan,
                bhtn = config.BHTN,
                onSaturday = config.OnSaturday,
                onSunday = config.OnSunday,
                morningIn = config.MorningIn.ToString(@"hh\:mm"),
                morningOut = config.MorningOut.ToString(@"hh\:mm"),
                afternoonIn = config.AfternoonIn.ToString(@"hh\:mm"),
                afternoonOut = config.AfternoonOut.ToString(@"hh\:mm"),
                workHours = config.WorkHour
            });
        }   
        
        [HttpGet("profile")]
        [Authorize]
        public async Task<IActionResult> GetProfile()
        {
            var employeeIdClaim = User.FindFirst("EmployeeId")?.Value;
            if (string.IsNullOrEmpty(employeeIdClaim))
                return Problem("Missing EmployeeId claim");

            var employeeId = int.Parse(employeeIdClaim);

            var employee = await _context.Employees
                .Include(e => e.Profile) 
                    .ThenInclude(p => p.Department) 
                .Include(e => e.Profile) 
                    .ThenInclude(p => p.Position) 
                .Include(e => e.Profile) 
                    .ThenInclude(p => p.Block) 
                .Include(e => e.Profile) 
                    .ThenInclude(p => p.Branch) 
                .FirstOrDefaultAsync(e => e.Id == employeeId);
            

            if (employee == null)
                return NotFound("Employee not found");
            
            var profile = employee.Profile;

            return Ok(new
            {   
                employeeId = employee.Id, 
                employeeName = employee.Name,
                primary = profile?.Primary,
                department = profile?.Department?.Name,
                position = profile?.Position?.Name,
                block = profile?.Block?.Name,
                branch = profile?.Branch?.Name
            });
        }
        // Sơ yếu lý lịch
        [HttpGet("resume")]
        [Authorize]
        public async Task<IActionResult> GetResume()
        {
            var employeeIdClaim = User.FindFirst("EmployeeId")?.Value;
            if (string.IsNullOrEmpty(employeeIdClaim))
                return Problem("Missing EmployeeId claim");

            var employeeId = int.Parse(employeeIdClaim);
            
            var employee = await _context.Employees.FirstOrDefaultAsync(e => e.Id == employeeId);
                await _context.Entry(employee).Reference(e => e.Ethnic).LoadAsync();
                await _context.Entry(employee).Reference(e => e.Religion).LoadAsync();
                await _context.Entry(employee).Reference(e => e.Country).LoadAsync();


            if (employee == null)
                return NotFound("Employee not found");

            var profile = employee.Profile;

            var config = await _context.EmployeeConfigs
                .FirstOrDefaultAsync(ec => ec.EmployeeId == employeeId);
            
            return Ok(new
            {
                id = employee.Id,
                code = employee.Code,
                name = employee.Name,
                gender = employee.Gender,
                ethnic = employee.Ethnic?.Name,
                religon = employee.Religion?.Name,
                dateOfBirth = employee.DateOfBirth,
                placeOfBirth = employee.PlaceOfBirthId,
                country = employee.Country?.Name,
                maritalStatus = employee.MaritalStatusId, 
                permanentAddress = employee.PermanentAddress,
                temporaryAddress = employee.TemporaryAddress,
                phoneNumber = employee.PhoneNumber,
                mobileNumber = employee.MobileNumber,
                email = employee.Email,
                companyEmail = employee.CompanyEmail,
                status = employee.Status,
                attendanceCode = employee.AttendanceCode,
                vacationDay = config?.VacationDay ?? 0
            });
        }
    }
}
