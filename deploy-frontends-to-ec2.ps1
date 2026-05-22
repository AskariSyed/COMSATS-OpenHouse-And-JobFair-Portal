param(
    [string]$PemKeyPath = "C:\Users\HP\.ssh\jobfair-key.pem",

    [string]$Ec2Host = "52.221.35.144",
    [string]$Ec2User = "ubuntu",
    [string]$BackendUrl = "http://52.221.35.144:5158",
    [switch]$UseRelativeApi,
    [switch]$ApplyNginxConfig,

    [string]$FirebaseEnvFilePath,
    [string]$FirebaseApiKey,
    [string]$FirebaseAuthDomain,
    [string]$FirebaseProjectId,
    [string]$FirebaseStorageBucket,
    [string]$FirebaseMessagingSenderId,
    [string]$FirebaseAppId,
    [string]$FirebaseVapidKey
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$workDir = Join-Path $repoRoot ".deploy-artifacts"

$adminZip = Join-Path $workDir "admin.zip"
$companyZip = Join-Path $workDir "company.zip"
$studentZip = Join-Path $workDir "student.zip"
$studentApk = Join-Path $workDir "student-portal.apk"
$landingZip = Join-Path $workDir "landing.zip"
$nginxDomainsConfig = Join-Path $workDir "jfair-domains.conf"
$nginxIpConfig = Join-Path $workDir "jobfair-ip.nginx.conf"

function Write-Step {
    param([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Assert-Command {
    param([string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' not found in PATH."
    }
}

function Run-OrThrow {
    param(
        [string]$Command,
        [string]$WorkingDirectory
    )

    Push-Location $WorkingDirectory
    try {
        Invoke-Expression $Command
        if ($LASTEXITCODE -ne 0) {
            throw "Command failed ($LASTEXITCODE): $Command"
        }
    }
    finally {
        Pop-Location
    }
}

function Get-EnvValueFromFile {
    param(
        [string]$Path,
        [string]$Key
    )

    if (-not (Test-Path $Path)) {
        return $null
    }

    $line = Get-Content $Path | Where-Object { $_ -match "^\s*$([regex]::Escape($Key))\s*=" } | Select-Object -First 1
    if (-not $line) {
        return $null
    }

    $value = ($line -split "=", 2)[1].Trim()
    if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
        $value = $value.Substring(1, $value.Length - 2)
    }

    return $value
}

Write-Step "Checking prerequisites"
Assert-Command "node"
Assert-Command "npm"
Assert-Command "scp"
Assert-Command "ssh"
Assert-Command "flutter"

if (-not (Test-Path $PemKeyPath)) {
    throw "PEM key not found at: $PemKeyPath"
}

if (Test-Path $workDir) {
    Remove-Item -Recurse -Force $workDir
}
New-Item -ItemType Directory -Path $workDir | Out-Null

$adminDir = Join-Path $repoRoot "admin-portal"
$companyDir = Join-Path $repoRoot "company-portal"
$studentDir = Join-Path $repoRoot "student-portal"
$landingDir = Join-Path $repoRoot "landing-page"

if ($UseRelativeApi) {
    $BackendUrl = ""
}

if (-not $FirebaseEnvFilePath) {
    $FirebaseEnvFilePath = Join-Path $companyDir ".env"
}

if ($FirebaseEnvFilePath.ToLower().EndsWith('.json')) {
    throw "Service-account JSON is for backend Firebase Admin SDK and cannot be used for frontend web Firebase config. Use company-portal/.env (or .env.production) with VITE_FIREBASE_* values."
}

if (-not $FirebaseApiKey) { $FirebaseApiKey = Get-EnvValueFromFile -Path $FirebaseEnvFilePath -Key "VITE_FIREBASE_API_KEY" }
if (-not $FirebaseAuthDomain) { $FirebaseAuthDomain = Get-EnvValueFromFile -Path $FirebaseEnvFilePath -Key "VITE_FIREBASE_AUTH_DOMAIN" }
if (-not $FirebaseProjectId) { $FirebaseProjectId = Get-EnvValueFromFile -Path $FirebaseEnvFilePath -Key "VITE_FIREBASE_PROJECT_ID" }
if (-not $FirebaseStorageBucket) { $FirebaseStorageBucket = Get-EnvValueFromFile -Path $FirebaseEnvFilePath -Key "VITE_FIREBASE_STORAGE_BUCKET" }
if (-not $FirebaseMessagingSenderId) { $FirebaseMessagingSenderId = Get-EnvValueFromFile -Path $FirebaseEnvFilePath -Key "VITE_FIREBASE_MESSAGING_SENDER_ID" }
if (-not $FirebaseAppId) { $FirebaseAppId = Get-EnvValueFromFile -Path $FirebaseEnvFilePath -Key "VITE_FIREBASE_APP_ID" }
if (-not $FirebaseVapidKey) { $FirebaseVapidKey = Get-EnvValueFromFile -Path $FirebaseEnvFilePath -Key "VITE_FIREBASE_VAPID_KEY" }

$missingFirebaseVars = @()
if (-not $FirebaseApiKey) { $missingFirebaseVars += "VITE_FIREBASE_API_KEY" }
if (-not $FirebaseAuthDomain) { $missingFirebaseVars += "VITE_FIREBASE_AUTH_DOMAIN" }
if (-not $FirebaseProjectId) { $missingFirebaseVars += "VITE_FIREBASE_PROJECT_ID" }
if (-not $FirebaseStorageBucket) { $missingFirebaseVars += "VITE_FIREBASE_STORAGE_BUCKET" }
if (-not $FirebaseMessagingSenderId) { $missingFirebaseVars += "VITE_FIREBASE_MESSAGING_SENDER_ID" }
if (-not $FirebaseAppId) { $missingFirebaseVars += "VITE_FIREBASE_APP_ID" }
if (-not $FirebaseVapidKey) { $missingFirebaseVars += "VITE_FIREBASE_VAPID_KEY" }

if ($missingFirebaseVars.Count -gt 0) {
    throw "Missing Firebase web config values: $($missingFirebaseVars -join ', '). Provide them via parameters or in $FirebaseEnvFilePath"
}

Write-Step "Building Admin portal"
$env:VITE_BACKEND_URL = $BackendUrl
$env:VITE_API_BASE_URL = $BackendUrl
Run-OrThrow "npm install" $adminDir
Run-OrThrow "npm run build" $adminDir
if (-not (Test-Path (Join-Path $adminDir "dist"))) {
    throw "Admin build output missing: admin-portal/dist"
}
Compress-Archive -Path (Join-Path $adminDir "dist\*") -DestinationPath $adminZip -Force

Write-Step "Building Company portal"
$env:VITE_SERVER_URL = $BackendUrl
$env:VITE_FIREBASE_API_KEY = $FirebaseApiKey
$env:VITE_FIREBASE_AUTH_DOMAIN = $FirebaseAuthDomain
$env:VITE_FIREBASE_PROJECT_ID = $FirebaseProjectId
$env:VITE_FIREBASE_STORAGE_BUCKET = $FirebaseStorageBucket
$env:VITE_FIREBASE_MESSAGING_SENDER_ID = $FirebaseMessagingSenderId
$env:VITE_FIREBASE_APP_ID = $FirebaseAppId
$env:VITE_FIREBASE_VAPID_KEY = $FirebaseVapidKey
Run-OrThrow "npm install" $companyDir
Run-OrThrow "npm run build" $companyDir
if (-not (Test-Path (Join-Path $companyDir "dist"))) {
    throw "Company build output missing: company-portal/dist"
}
Compress-Archive -Path (Join-Path $companyDir "dist\*") -DestinationPath $companyZip -Force

Write-Step "Building Student portal (Web & APK)"
Run-OrThrow "flutter pub get" $studentDir
Run-OrThrow "flutter build web --release --dart-define=BACKEND_BASE_URL=$BackendUrl --dart-define=APP_ENV=production" $studentDir
Run-OrThrow "flutter build apk --release --dart-define=BACKEND_BASE_URL=$BackendUrl --dart-define=APP_ENV=production" $studentDir
if (-not (Test-Path (Join-Path $studentDir "build\web"))) {
    throw "Student build output missing: student-portal/build/web"
}
if (-not (Test-Path (Join-Path $studentDir "build\app\outputs\flutter-apk\app-release.apk"))) {
    throw "Student APK output missing: student-portal/build/app/outputs/flutter-apk/app-release.apk"
}
Compress-Archive -Path (Join-Path $studentDir "build\web\*") -DestinationPath $studentZip -Force
Copy-Item (Join-Path $studentDir "build\app\outputs\flutter-apk\app-release.apk") $studentApk -Force

Write-Step "Building jfair.tech landing page"
if (-not (Test-Path $landingDir)) {
    throw "Landing page directory missing: landing-page"
}
Run-OrThrow "npm install" $landingDir
Run-OrThrow "npm run build" $landingDir
if (-not (Test-Path (Join-Path $landingDir "dist"))) {
    throw "Landing build output missing: landing-page/dist"
}
Compress-Archive -Path (Join-Path $landingDir "dist\*") -DestinationPath $landingZip -Force

Write-Step "Uploading artifacts to EC2"
$sshOptions = @("-o", "StrictHostKeyChecking=no")
& scp @sshOptions -i $PemKeyPath $adminZip "${Ec2User}@${Ec2Host}:/tmp/admin.zip"
if ($LASTEXITCODE -ne 0) { throw "Upload failed: admin.zip" }
& scp @sshOptions -i $PemKeyPath $companyZip "${Ec2User}@${Ec2Host}:/tmp/company.zip"
if ($LASTEXITCODE -ne 0) { throw "Upload failed: company.zip" }
& scp @sshOptions -i $PemKeyPath $studentZip "${Ec2User}@${Ec2Host}:/tmp/student.zip"
if ($LASTEXITCODE -ne 0) { throw "Upload failed: student.zip" }
& scp @sshOptions -i $PemKeyPath $studentApk "${Ec2User}@${Ec2Host}:/tmp/student-portal.apk"
if ($LASTEXITCODE -ne 0) { throw "Upload failed: student-portal.apk" }
& scp @sshOptions -i $PemKeyPath $landingZip "${Ec2User}@${Ec2Host}:/tmp/landing.zip"
if ($LASTEXITCODE -ne 0) { throw "Upload failed: landing.zip" }

Copy-Item (Join-Path $repoRoot "jfair-domains.conf") $nginxDomainsConfig -Force
Copy-Item (Join-Path $repoRoot "jobfair-ip.nginx.conf") $nginxIpConfig -Force
& scp @sshOptions -i $PemKeyPath $nginxDomainsConfig "${Ec2User}@${Ec2Host}:/tmp/jfair-domains.conf"
if ($LASTEXITCODE -ne 0) { throw "Upload failed: jfair-domains.conf" }
& scp @sshOptions -i $PemKeyPath $nginxIpConfig "${Ec2User}@${Ec2Host}:/tmp/jobfair-ip.nginx.conf"
if ($LASTEXITCODE -ne 0) { throw "Upload failed: jobfair-ip.nginx.conf" }

Write-Step "Deploying static files on EC2"
$remoteDeployScript = @'
set -e
sudo mkdir -p /var/www/admin /var/www/company /var/www/student /var/www/jfair
sudo apt-get update -y
sudo apt-get install -y unzip
# Install webp tools for icon conversion (safe to re-run, no-op if already installed)
sudo apt-get install -y webp 2>/dev/null || true
sudo rm -rf /var/www/admin/* /var/www/company/* /var/www/student/* /var/www/jfair/*
sudo unzip -o /tmp/admin.zip -d /var/www/admin
sudo unzip -o /tmp/company.zip -d /var/www/company
sudo unzip -o /tmp/student.zip -d /var/www/student
sudo mkdir -p /var/www/student/downloads
sudo cp /tmp/student-portal.apk /var/www/student/downloads/student-portal.apk
sudo unzip -o /tmp/landing.zip -d /var/www/jfair

# --- Performance optimisations for student portal ---

# 1. Convert PNG icons to WebP so the LCP image is ~5x smaller
echo "Converting icons to WebP..."
if command -v cwebp >/dev/null 2>&1; then
  for png in /var/www/student/icons/*.png; do
    webp_path="${png%.png}.webp"
    sudo cwebp -q 85 "$png" -o "$webp_path" 2>/dev/null || true
    echo "  Created $webp_path"
  done
else
  echo "  cwebp not available, skipping WebP conversion (PNG will be served)"
fi

# 2. Pre-compress heavy files with gzip so nginx gzip_static serves .gz directly
#    (no per-request CPU cost, ~3-5x smaller download for WASM/JS)
echo "Pre-compressing static assets..."
find /var/www/student -type f \( -name "*.wasm" -o -name "*.js" -o -name "*.mjs" -o -name "*.css" -o -name "*.json" \) | while read f; do
  sudo gzip -k -9 -f "$f"
done
echo "  Pre-compression complete"

# 3. Delete source maps - they are never needed at runtime and waste bandwidth
echo "Removing source maps from production..."
sudo find /var/www/student -name "*.map" -delete
echo "  Source maps removed"

sudo chown -R www-data:www-data /var/www/admin /var/www/company /var/www/student /var/www/jfair
sudo find /var/www/admin /var/www/company /var/www/student -type d -exec chmod 755 {} \;
sudo find /var/www/admin /var/www/company /var/www/student -type f -exec chmod 644 {} \;
sudo find /var/www/jfair -type d -exec chmod 755 {} \;
sudo find /var/www/jfair -type f -exec chmod 644 {} \;
sudo nginx -t
sudo systemctl reload nginx
'@

& ssh @sshOptions -i $PemKeyPath "${Ec2User}@${Ec2Host}" $remoteDeployScript
if ($LASTEXITCODE -ne 0) {
    throw "Remote deployment failed."
}

if ($ApplyNginxConfig) {
    Write-Step "Applying nginx config on EC2"
    $remoteNginxScript = @'
set -e
if [ -f /etc/letsencrypt/live/comsats.jfair.tech/fullchain.pem ] && [ -f /etc/letsencrypt/live/comsats.jfair.tech/privkey.pem ]; then
  sudo cp /tmp/jfair-domains.conf /etc/nginx/sites-available/jfair-domains.conf
  sudo ln -sfn /etc/nginx/sites-available/jfair-domains.conf /etc/nginx/sites-enabled/jfair-domains.conf
  sudo rm -f /etc/nginx/sites-enabled/jobfair-ip.nginx.conf
else
  sudo cp /tmp/jobfair-ip.nginx.conf /etc/nginx/sites-available/jobfair-ip.nginx.conf
  sudo ln -sfn /etc/nginx/sites-available/jobfair-ip.nginx.conf /etc/nginx/sites-enabled/jobfair-ip.nginx.conf
  sudo rm -f /etc/nginx/sites-enabled/jfair-domains.conf
fi

sudo rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/jfair.conf /etc/nginx/sites-enabled/jfair.conf.disabled
sudo nginx -t
sudo systemctl reload nginx
'@

    & ssh @sshOptions -i $PemKeyPath "${Ec2User}@${Ec2Host}" $remoteNginxScript
    if ($LASTEXITCODE -ne 0) {
        throw "Nginx config update failed."
    }
} else {
    Write-Host "Nginx config was uploaded to /tmp, but not activated. Re-run with -ApplyNginxConfig to switch the live site to jfair-domains.conf." -ForegroundColor Yellow
}

Write-Step "Deployment completed"
Write-Host "Home:    https://jfair.tech" -ForegroundColor Green
Write-Host "Admin:   https://admin.jfair.tech" -ForegroundColor Green
Write-Host "Company: https://company.jfair.tech" -ForegroundColor Green
Write-Host "Student: https://student.jfair.tech" -ForegroundColor Green
Write-Host "API:     $BackendUrl" -ForegroundColor Green
