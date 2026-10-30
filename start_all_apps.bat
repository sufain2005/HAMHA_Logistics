@echo off
TITLE HAMHA Logistics — Multi-App Launcher
COLOR 0C
echo ============================================================
echo   HAMHA LOGISTICS PLATFORM - STARTING ALL APPS
echo ============================================================
echo.
echo [1/4] Launching Node.js + PostGIS + Socket.io Backend (Port 5000)...
start "HAMHA Backend Server (Port 5000)" cmd /k "cd /d %~dp0backend && npm run dev"
timeout /t 3 /nobreak > nul

echo [2/4] Launching Customer App (Chrome Port 3000)...
start "HAMHA Customer App (Port 3000)" cmd /k "cd /d %~dp0flutter\customerapp && flutter run -d chrome --web-port 3000"
timeout /t 2 /nobreak > nul

echo [3/4] Launching Driver App (Chrome Port 3001)...
start "HAMHA Driver App (Port 3001)" cmd /k "cd /d %~dp0flutter\driverapp && flutter run -d chrome --web-port 3001"
timeout /t 2 /nobreak > nul

echo [4/4] Launching Owner / Admin Dashboard (Chrome Port 3002)...
start "HAMHA Admin Control Tower (Port 3002)" cmd /k "cd /d "%~dp0flutter\admin(owner)" && flutter run -d chrome --web-port 3002"

echo.
echo ============================================================
echo  ALL 4 HAMHA SERVICES LAUNCHED IN SEPARATE TERMINALS:
echo   - Backend API & Sockets: http://localhost:5000
echo   - Customer App:          http://localhost:3000
echo   - Driver App:            http://localhost:3001
echo   - Owner/Admin Dashboard: http://localhost:3002
echo ============================================================
pause

