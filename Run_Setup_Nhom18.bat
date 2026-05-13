@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
cls

echo =============================================================================
echo OUTPATIENT HOSPITAL DB - FULL BUILD
echo PROJECT: QUAN LY KHAM NGOAI TRU + SMART QUEUE
echo =============================================================================
echo.

set "SCRIPT_DIR=%~dp0"

if "%MYSQL_USER%"=="" set "MYSQL_USER=root"
if "%MYSQL_PASSWORD%"=="" set "MYSQL_PASSWORD=root"
if "%MYSQL_HOST%"=="" set "MYSQL_HOST=localhost"
if "%MYSQL_PORT%"=="" set "MYSQL_PORT=3306"
if "%MYSQL_DATABASE%"=="" set "MYSQL_DATABASE=dl_benhvien"

set "MYSQL_CMD=mysql -u%MYSQL_USER% -p%MYSQL_PASSWORD% -h%MYSQL_HOST% -P%MYSQL_PORT%"

echo [1/5] Checking MySQL client...
mysql --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] mysql client not found in PATH.
    echo Run Install_Dependencies_Nhom18.ps1 first.
    pause
    exit /b 1
)

echo [2/5] Checking MySQL connection...
%MYSQL_CMD% -e "SELECT 'connected' AS status;" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Cannot connect to MySQL with current credentials.
    echo Current: %MYSQL_USER%@%MYSQL_HOST%:%MYSQL_PORT%
    pause
    exit /b 1
)

echo [3/5] Ensuring database exists...
%MYSQL_CMD% -e "CREATE DATABASE IF NOT EXISTS %MYSQL_DATABASE% CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
if errorlevel 1 (
    echo [ERROR] Cannot create database %MYSQL_DATABASE%.
    pause
    exit /b 1
)

echo [4/5] Running full one-file SQL build...
%MYSQL_CMD% %MYSQL_DATABASE% < "%SCRIPT_DIR%BaiTapLon_Nhom18_Complete.sql"
if errorlevel 1 (
    echo [ERROR] Import BaiTapLon_Nhom18_Complete.sql failed.
    pause
    exit /b 1
)

echo [5/5] Build done.

echo.
echo =============================================================================
echo BUILD COMPLETED
echo =============================================================================
echo DB: %MYSQL_DATABASE%
echo Host: %MYSQL_HOST%:%MYSQL_PORT%
echo User: %MYSQL_USER%
echo.
echo Next step: Run_Test_Nhom18.bat
echo.
pause
