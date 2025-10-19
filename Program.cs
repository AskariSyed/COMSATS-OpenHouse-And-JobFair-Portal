using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using JobFairPortal.Data;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.FileProviders;
using Microsoft.IdentityModel.Tokens;
using Npgsql;
using Npgsql.EntityFrameworkCore.PostgreSQL.Infrastructure;
using System.IdentityModel.Tokens.Jwt;
using System.Text;

// Disable default inbound claim mapping
JwtSecurityTokenHandler.DefaultInboundClaimTypeMap.Clear();

var builder = WebApplication.CreateBuilder(args);

// ---------------------------
// 1. Services
// ---------------------------
var dataSourceBuilder = new NpgsqlDataSourceBuilder(builder.Configuration.GetConnectionString("DefaultConnection"));
dataSourceBuilder.EnableDynamicJson(); // 👈 this line enables List<> / object JSON writing
var dataSource = dataSourceBuilder.Build();

builder.Services.AddDbContext<JobFairRecruitmentDbContext>(options =>
    options.UseNpgsql(dataSource));

builder.Services.AddControllers();

var jwtKey = builder.Configuration["Jwt:Key"];
var key = Encoding.UTF8.GetBytes(jwtKey);

FirebaseApp.Create(new AppOptions()
{
    Credential = GoogleCredential.FromFile("C:\\Users\\HP\\source\\repos\\Job Fair\\JobFairPortal\\config\\hirebridge-c28e9-firebase-adminsdk-fbsvc-22c59be5ca.json")
});

builder.WebHost.ConfigureKestrel(serverOptions =>
{
    serverOptions.ListenAnyIP(5158); // HTTP
    serverOptions.ListenAnyIP(7050, listenOptions =>
    {
        listenOptions.UseHttps();    // HTTPS
    });
});

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],

        ValidateAudience = true,
        ValidAudience = builder.Configuration["Jwt:Audience"],

        ValidateLifetime = true,
        ClockSkew = TimeSpan.FromMinutes(5),

        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]))
    };

    options.Events = new JwtBearerEvents
    {
        OnAuthenticationFailed = ctx =>
        {
            Console.WriteLine("❌ JWT failed: " + ctx.Exception.Message);
            return Task.CompletedTask;
        }
    };
});

builder.Services.AddSwaggerGen(c =>
{
    c.AddSecurityDefinition("Bearer", new Microsoft.OpenApi.Models.OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.Http,
        Scheme = "bearer",  // 👈 this tells Swagger it’s the bearer HTTP scheme
        BearerFormat = "JWT",
        In = Microsoft.OpenApi.Models.ParameterLocation.Header,
        Description = "Paste only your JWT token below (no need to type 'Bearer ')."
    });

    c.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
    {
        {
            new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Reference = new Microsoft.OpenApi.Models.OpenApiReference
                {
                    Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                    Id = "Bearer"
                },
                Scheme = "bearer",
                Name = "Bearer",
                In = Microsoft.OpenApi.Models.ParameterLocation.Header
            },
            new string[] {}
        }
    });
});


builder.Services.AddEndpointsApiExplorer();
builder.Services.AddMemoryCache();
builder.Services.AddLogging();
builder.Services.AddScoped<JobFairPortal.Services.MailKitMailService>();


var app = builder.Build();

// ---------------------------
// 3. Configure Middleware
// ---------------------------

// Enable Swagger in development
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
app.Use(async (context, next) =>
{
    if (context.Request.Headers.ContainsKey("Authorization"))
    {
        Console.WriteLine("🔑 Raw Authorization Header: " + context.Request.Headers["Authorization"]);
    }
    await next();
});

// Enable serving files from wwwroot
app.UseStaticFiles();

// Enable serving files from "uploads" folder
var uploadsPath = Path.Combine(Directory.GetCurrentDirectory(), "uploads");
if (!Directory.Exists(uploadsPath))
    Directory.CreateDirectory(uploadsPath);

app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(uploadsPath),
    RequestPath = "/uploads"
});

// Enable Authentication & Authorization
app.UseAuthentication();
app.UseAuthorization();

// Map Controllers
app.MapControllers();

// ---------------------------
// 4. Run App
// ---------------------------
app.Run();
