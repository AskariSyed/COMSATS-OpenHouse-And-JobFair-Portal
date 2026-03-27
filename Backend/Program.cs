using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using JobFairPortal.Data;
using JobFairPortal.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.FileProviders;
using Microsoft.IdentityModel.Tokens;
using Npgsql;
using Npgsql.EntityFrameworkCore.PostgreSQL.Infrastructure;
using System.IdentityModel.Tokens.Jwt;
using System.Text;
using Microsoft.AspNetCore.SignalR;
using JobFairPortal.Hubs;

// Disable default inbound claim mapping
JwtSecurityTokenHandler.DefaultInboundClaimTypeMap.Clear();

var builder = WebApplication.CreateBuilder(args);


var dataSourceBuilder = new NpgsqlDataSourceBuilder(builder.Configuration.GetConnectionString("DefaultConnection"));
dataSourceBuilder.EnableDynamicJson(); 
var dataSource = dataSourceBuilder.Build();

builder.Services.AddDbContext<JobFairRecruitmentDbContext>(options =>
    options.UseNpgsql(dataSource));

builder.Services.AddControllers();

// SignalR for real-time notifications
builder.Services.AddSignalR();

var jwtKey = builder.Configuration["Jwt:Key"];
if (string.IsNullOrWhiteSpace(jwtKey))
{
    throw new InvalidOperationException("Configuration key 'Jwt:Key' is missing or empty.");
}

var firebaseServiceAccountJson = builder.Configuration["Firebase:ServiceAccountJson"];
var firebasePath = builder.Configuration["Firebase:ServiceAccountPath"];
if (string.IsNullOrWhiteSpace(firebaseServiceAccountJson) && string.IsNullOrWhiteSpace(firebasePath))
    throw new InvalidOperationException("Firebase credentials are missing. Configure either 'Firebase:ServiceAccountJson' or 'Firebase:ServiceAccountPath'.");

GoogleCredential firebaseCredential;
if (!string.IsNullOrWhiteSpace(firebaseServiceAccountJson))
{
    firebaseCredential = GoogleCredential.FromJson(firebaseServiceAccountJson);
}
else
{
    firebaseCredential = GoogleCredential.FromFile(firebasePath!);
}

FirebaseApp.Create(new AppOptions()
{
    Credential = firebaseCredential
});

builder.WebHost.ConfigureKestrel(serverOptions =>
{
    var portValue = Environment.GetEnvironmentVariable("PORT");
    if (int.TryParse(portValue, out var port) && port > 0)
    {
        // Cloud platforms (e.g., Render) provide a dynamic HTTP port via PORT.
        serverOptions.ListenAnyIP(port);
        return;
    }

    // Local development defaults
    serverOptions.ListenAnyIP(5158); // HTTP
    serverOptions.ListenAnyIP(7050, listenOptions =>
    {
        listenOptions.UseHttps();    // HTTPS
    });
});
builder.Services.AddCors(options =>
{
    options.AddPolicy("FrontendCors", policy =>
    {
        var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>();
        policy.SetIsOriginAllowed(origin =>
              {
                  if (!Uri.TryCreate(origin, UriKind.Absolute, out var uri)) return false;
                  // Use configured origins in production; fall back to local hosts for development
                  if (allowedOrigins is { Length: > 0 })
                      return allowedOrigins.Contains(origin, StringComparer.OrdinalIgnoreCase);
                  return uri.Host is "localhost" or "127.0.0.1" or "192.168.137.1" or "54.254.84.101";
              })
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
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
            Encoding.UTF8.GetBytes(jwtKey))
    };

    options.Events = new JwtBearerEvents
    {
        OnAuthenticationFailed = ctx =>
        {
            Console.WriteLine("❌ JWT failed: " + ctx.Exception.Message);
            return Task.CompletedTask;
        }
        ,OnMessageReceived = ctx =>
        {
            // Allow JWT to be passed to SignalR hubs via query string (access_token)
            var accessToken = ctx.Request.Query["access_token"].FirstOrDefault();
            var path = ctx.HttpContext.Request.Path;
            if (!string.IsNullOrEmpty(accessToken) && (path.StartsWithSegments("/hubs/companyRequests")))
            {
                ctx.Token = accessToken;
            }
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
        Scheme = "bearer",  
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


builder.Services.AddScoped<AuthValidationService>();
builder.Services.AddScoped<AuthTokenService>();
builder.Services.AddScoped<ICompanyConfirmationService, CompanyConfirmationService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IParticipationService, ParticipationService>();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddMemoryCache();
builder.Services.AddLogging();
builder.Services.AddScoped<JobFairPortal.Services.MailKitMailService>();
builder.Services.AddMemoryCache();
builder.Services.AddApplicationInsightsTelemetry();


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
app.UseCors("FrontendCors");

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

// Map SignalR hubs
app.MapHub<CompanyRequestsHub>("/hubs/companyRequests");

// ---------------------------
// 4. Run App
// ---------------------------
app.Run();
