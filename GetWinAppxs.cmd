@echo off
title 获取 Appxs 列表

>NUL 2>&1 REG.exe query "HKU\S-1-5-19" || (
    echo Set UAC = CreateObject^("Shell.Application"^) > "%TEMP%\Getadmin.vbs"
    if exist %LocalAppdata%\Microsoft\WindowsApps\wt.exe (
        echo UAC.ShellExecute "wt.exe","%~f0","%~dp0","runas",1 >> "%TEMP%\Getadmin.vbs"
    ) else (
        echo UAC.ShellExecute "cmd.exe","%~f0","%~dp0","runas",1 >> "%TEMP%\Getadmin.vbs"
    )
    "%TEMP%\Getadmin.vbs"
    del /f /q "%TEMP%\Getadmin.vbs" 2>NUL
    exit /b
)

@cls
set "line============================================================="
set "_err========== 错误 ========="

:: 读取当前系统 Appxs 列表，请修改Online为1
set Online=0

if %Online% equ 1 goto :Online

:select
set _DIR=
echo %line%
echo 使用 Tab 键选择或输入包含更新文件的文件夹
echo %line%
echo.
set /p _DIR=
if not defined _DIR (
    echo %_err%
    echo 未指定文件夹
    echo.
    goto :select
)

echo %line%
echo 挂载的镜像 %_DIR% 的 Appx 列表
echo %line%
echo.
for /f "tokens=2 delims=: " %%# in ('Dism /English /Image:%_DIR% /Get-ProvisionedAppxPackages ^| findstr /c:"PackageName"') do echo %%#
echo.
goto :Done

:Online
echo %line%
echo 当前系统 Appx 列表
echo %line%
echo.
for /f "tokens=2 delims=: " %%# in ('Dism /English /Online /Get-ProvisionedAppxPackages ^| findstr /c:"PackageName"') do echo %%#
echo.
goto :Done

:Done
echo 请按数字 0 键退出脚本。
choice /c 0 /n
if errorlevel 1 (exit /b) else (rem.)