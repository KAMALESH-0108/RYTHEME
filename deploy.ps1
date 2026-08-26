Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "🚀 RYTHEME Production Build & Deployment Pipeline (PowerShell)" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

# Step 1: Build Flutter Web
Write-Host "`n📱 [1/3] Building Flutter Web Client..." -ForegroundColor Yellow
flutter pub get
flutter build web --release

# Step 2: Build JioSaavn API Engine
Write-Host "`n🎵 [2/3] Building JioSaavn Open-Source API Engine..." -ForegroundColor Yellow
Set-Location jiosaavn-api
npm install
npm run build
Set-Location ..

# Step 3: Install Backend Dependencies
Write-Host "`n🌐 [3/3] Preparing Express Production Server..." -ForegroundColor Yellow
Set-Location backend
npm install --production
Set-Location ..

Write-Host "`n====================================================" -ForegroundColor Green
Write-Host "✅ Build Succeeded! Launching Production Stack..." -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green
Set-Location backend
node start-production.js
