using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using SiamInternalApi.Data;
using SiamInternalApi.Models;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace SiamInternalApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _config;

        public AuthController(AppDbContext context, IConfiguration config)
        {
            _context = context;
            _config = config;
        }

        [HttpPost("login")]
        public IActionResult Login([FromBody] LoginRequest request)
        {
            var user = _context.Users.FirstOrDefault(u => u.Username == request.Username && u.Active);

            if (user == null)
                return Unauthorized("User not found or inactive");

            if (user.Password != request.Password)
                return Unauthorized("Invalid password");

            var claims = new[]
            {
                new Claim(ClaimTypes.Name, user.Username),
                new Claim("UserId", user.Id.ToString()),
                new Claim("EmployeeId", user.EmployeeId.ToString()),
                new Claim(ClaimTypes.Role, user.GroupId.ToString())
            };

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var token = new JwtSecurityToken(
                claims: claims,
                expires: DateTime.Now.AddHours(2),
                signingCredentials: creds);

            return Ok(new LoginResponse
            {
                Token = new JwtSecurityTokenHandler().WriteToken(token),
                DisplayName = user.Name,
                Role = user.GroupId.ToString(),
                EmployeeId = user.EmployeeId
            });
        }
    }

    public class LoginRequest
    {
        public string Username { get; set; } = "";
        public string Password { get; set; } = "";
    }

    public class LoginResponse
    {
        public string Token { get; set; } = "";
        public string DisplayName { get; set; } = "";
        public string Role { get; set; } = "";
        public int EmployeeId { get; set; }
    }
}
