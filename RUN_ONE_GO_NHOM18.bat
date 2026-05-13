@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
cls

echo =============================================================================
echo ONE-GO EXECUTION: INSTALL ^> BUILD ^> TEST
echo =============================================================================
echo.

echo [1/3] Dependency check/install script...
powershell -ExecutionPolicy Bypass -File "%~dp0Install_Dependencies_Nhom18.ps1"
if errorlevel 1 (
    echo [ERROR] Dependency step failed.
    pause
    exit /b 1
)

echo [2/3] Full build...
call "%~dp0Run_Setup_Nhom18.bat"
if errorlevel 1 (
    echo [ERROR] Build failed.
    pause
    exit /b 1
)

echo [3/3] Full test...
call "%~dp0Run_Test_Nhom18.bat"
if errorlevel 1 (
    echo [ERROR] Test failed.
    pause
    exit /b 1
)

echo.
echo =============================================================================
echo DONE - ONE GO COMPLETED
echo =============================================================================
echo.
pause
