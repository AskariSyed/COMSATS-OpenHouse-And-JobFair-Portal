#!/usr/bin/env pwsh

# Build Small HTML Web Bundle - Automation Script
# Usage: .\build_small_web.ps1

param(
    [string]$mode = "html",  # "html" or "canvaskit"
    [switch]$analyzeSize
)

$projectPath = Get-Location
$buildDir = Join-Path $projectPath "build\web"

Write-Host "🚀 Building minimal Flutter Web app..." -ForegroundColor Green
Write-Host "Mode: $mode"
Write-Host "Project: $projectPath`n"

# Step 1: Clean
Write-Host "📦 Step 1: Cleaning previous build..." -ForegroundColor Cyan
flutter clean | Out-Null

# Step 2: Get dependencies
Write-Host "📥 Step 2: Getting dependencies..." -ForegroundColor Cyan
flutter pub get | Out-Null

# Step 3: Build
Write-Host "🔨 Step 3: Building web release..." -ForegroundColor Cyan

if ($mode -eq "html") {
    Write-Host "   Using HTML renderer (smallest size)" -ForegroundColor Yellow
    flutter build web --release --web-renderer html --split-debug-info=symbols 2>&1 | Select-Object -Last 20
} else {
    Write-Host "   Using CanvasKit renderer (better graphics)" -ForegroundColor Yellow
    flutter build web --release --web-renderer canvaskit --split-debug-info=symbols 2>&1 | Select-Object -Last 20
}

# Step 4: Analyze size (optional)
if ($analyzeSize) {
    Write-Host "`n📊 Analyzing bundle size..." -ForegroundColor Cyan
    
    if (Test-Path $buildDir) {
        $files = Get-ChildItem -Path $buildDir -Recurse -File | 
                 Sort-Object Length -Descending | 
                 Select-Object -First 15
        
        Write-Host "`nTop 15 Largest Files:" -ForegroundColor Green
        Write-Host "───────────────────────────────────────" -ForegroundColor Green
        
        foreach ($file in $files) {
            $size = [math]::Round($file.Length / 1MB, 2)
            $name = $file.Name
            Write-Host "$name : $($size) MB" -ForegroundColor Yellow
        }
        
        # Total size
        $totalSize = (Get-ChildItem -Path $buildDir -Recurse | Measure-Object -Property Length -Sum).Sum
        $totalSizeMB = [math]::Round($totalSize / 1MB, 2)
        
        Write-Host "`n───────────────────────────────────────" -ForegroundColor Green
        Write-Host "Total Bundle Size: $($totalSizeMB) MB" -ForegroundColor Green
        Write-Host "Gzipped (estimated): $([math]::Round($totalSizeMB * 0.3, 2)) MB" -ForegroundColor Green
        Write-Host "───────────────────────────────────────" -ForegroundColor Green
    } else {
        Write-Host "Build directory not found!" -ForegroundColor Red
    }
} else {
    Write-Host "`n⚠️  Size analysis skipped. Use -analyzeSize flag to enable." -ForegroundColor Yellow
}

Write-Host "`n✅ Build complete!" -ForegroundColor Green
Write-Host "Output: $buildDir" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Upload to web server" -ForegroundColor Gray
Write-Host "2. Enable gzip compression on server" -ForegroundColor Gray
Write-Host "3. Add HTTP/2 caching headers" -ForegroundColor Gray
Write-Host "4. Monitor Core Web Vitals" -ForegroundColor Gray
