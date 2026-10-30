Write-Host "============================================================" -ForegroundColor Red
Write-Host "  HAMHA LOGISTICS PLATFORM — ALL-IN-ONE MULTI-APP LAUNCHER  " -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Red

$rootDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Start Backend
Write-Host "[1/4] Starting Node.js + PostGIS + Socket.io Server on port 5000..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$rootDir\backend'; npm run dev"

Start-Sleep -Seconds 2

# 2. Start Customer App
Write-Host "[2/4] Starting Customer App on http://localhost:3000..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$rootDir\flutter\customerapp'; flutter run -d chrome --web-port 3000"

Start-Sleep -Seconds 2

# 3. Start Driver App
Write-Host "[3/4] Starting Driver App on http://localhost:3001..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$rootDir\flutter\driverapp'; flutter run -d chrome --web-port 3001"

Start-Sleep -Seconds 2

# 4. Start Owner/Admin Dashboard
Write-Host "[4/4] Starting Admin/Owner Command Tower on http://localhost:3002..." -ForegroundColor Magenta
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$rootDir\flutter\admin(owner)'; flutter run -d chrome --web-port 3002"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Red
Write-Host "All apps launched in dedicated browser windows / tabs:" -ForegroundColor White
Write-Host " • Backend API & Sockets: http://localhost:5000" -ForegroundColor Yellow
Write-Host " • Customer App:          http://localhost:3000" -ForegroundColor Green
Write-Host " • Driver App:            http://localhost:3001" -ForegroundColor Cyan
Write-Host " • Owner/Admin Dashboard: http://localhost:3002" -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Red

