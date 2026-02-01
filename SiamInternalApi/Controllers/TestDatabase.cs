using Microsoft.AspNetCore.Mvc;
using SiamInternalApi.Data;
using Microsoft.AspNetCore.Authorization;
namespace SiamInternalApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TestController : ControllerBase
    {
        private readonly AppDbContext _context;

        public TestController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/test/users
        [HttpGet("users")]
        public IActionResult GetUsers()
        {
            var users = _context.Users.Take(10).ToList(); // lấy 5 user đầu tiên
            return Ok(users);
        }

        [HttpGet("usersauth")]
        [Authorize(Roles = "1")]
        public IActionResult GetUsersAuth()
        {
            var users = _context.Users.Take(10).ToList();
            return Ok(users);
        }
        // GET: api/test/employees
        [HttpGet("employees")]
        public IActionResult GetEmployees()
        {
            var employees = _context.Employees.Take(7).ToList();
            return Ok(employees);
        }

        [HttpGet("day_off_types")]
        public IActionResult GetDayOffTypes()
        {
            var dayofftype = _context.DayOffTypes.Take(5).ToList();
            return Ok(dayofftype);
        }

        [HttpGet("letters")]
        public IActionResult GetLetter()
        {
            var letters = _context.Letters.Take(5).ToList();
            return Ok(letters);
        }
    }
}
