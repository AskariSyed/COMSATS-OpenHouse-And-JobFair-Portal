param(
    [string]$LocalIp = "192.168.137.1",
    [int]$BackendPort = 5158,
    [switch]$NoBackend,
    [switch]$NoAdmin,
    [switch]$NoCompany,
    [switch]$NoStudent,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Assert-Path {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Required path not found: $Path"
    }
}

function Start-RepoProcess {
    param(
        [string]$Title,
        [string]$WorkingDirectory,
        [string]$Command,
        [switch]$Dry
    )

    $fullCommand = "`$Host.UI.RawUI.WindowTitle = '$Title'; Set-Location -LiteralPath '$WorkingDirectory'; $Command"

    if ($Dry) {
        Write-Host "[DRY-RUN] $Title" -ForegroundColor Yellow
        Write-Host "  Dir: $WorkingDirectory"
        Write-Host "  Cmd: $Command"
        return
    }

    Start-Process -FilePath "powershell" -WorkingDirectory $WorkingDirectory -ArgumentList @(
        "-NoExit",
        "-ExecutionPolicy", "Bypass",
        "-Command", $fullCommand
    ) | Out-Null
}

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendDir = Join-Path $repoRoot "Backend"
$adminDir = Join-Path $repoRoot "admin-portal"
$companyDir = Join-Path $repoRoot "company-portal"
$studentDir = Join-Path $repoRoot "student-portal"

Assert-Path $backendDir
Assert-Path $adminDir
Assert-Path $companyDir
Assert-Path $studentDir

$backendUrl = "http://$LocalIp`:$BackendPort"

Write-Step "Local stack configuration (DEBUG MODE)"
Write-Host "Backend URL: $backendUrl" -ForegroundColor Green
Write-Host "Admin URL:   https://$LocalIp`:5173" -ForegroundColor Green
Write-Host "Company URL: https://$LocalIp`:5174" -ForegroundColor Green
Write-Host "Student URL: http://$LocalIp`:5175" -ForegroundColor Green

if (-not $NoBackend) {
    Write-Step "Starting Backend (Debug)"
    Start-RepoProcess -Title "Backend (.NET Debug)" -WorkingDirectory $backendDir -Command "dotnet run" -Dry:$DryRun
}

if (-not $NoAdmin) {
    Write-Step "Starting Admin Portal (Debug)"
    $adminCommand = @(
        "`$env:VITE_BACKEND_URL = '$backendUrl'",
        "`$env:VITE_API_BASE_URL = '$backendUrl'",
        "npx vite --host=$LocalIp --port=5173 --mode development"
    ) -join "; "
    Start-RepoProcess -Title "Admin Portal (Vite Debug)" -WorkingDirectory $adminDir -Command $adminCommand -Dry:$DryRun
}

if (-not $NoCompany) {
    Write-Step "Starting Company Portal (Debug)"
    $companyCommand = @(
        "`$env:VITE_SERVER_URL = '$backendUrl'",
        "npx vite --host=$LocalIp --port=5174 --mode development"
    ) -join "; "
    Start-RepoProcess -Title "Company Portal (Vite Debug)" -WorkingDirectory $companyDir -Command $companyCommand -Dry:$DryRun
}

if (-not $NoStudent) {
    Write-Step "Starting Student Portal (Debug)"
    $studentCommand = @(
        "flutter pub get",
        "`$env:FLUTTER_WEB_RENDERER = 'canvaskit'",
        "flutter run -d chrome --web-hostname $LocalIp --web-port 5175 --dart-define=BACKEND_BASE_URL=$backendUrl --debug"
    ) -join "; "
    Start-RepoProcess -Title "Student Portal (Flutter Web Debug)" -WorkingDirectory $studentDir -Command $studentCommand -Dry:$DryRun
}

Write-Step "Done (Debug Mode)"
if ($DryRun) {
    Write-Host "Dry run complete. Re-run without -DryRun to launch all apps." -ForegroundColor Yellow
} else {
    Write-Host "All selected services are launching in separate PowerShell windows (Debug Mode)." -ForegroundColor Green
    Write-Host "If HTTPS warns in browser for Vite apps, allow the local certificate once." -ForegroundColor Yellow
}
