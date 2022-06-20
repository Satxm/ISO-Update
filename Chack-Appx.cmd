@echo off
title Appx 管理

set "_work=%~dp0"
set "_work=%_work:~0,-1%"

setlocal EnableDelayedExpansion
set "line===================================================="

echo %line%
echo 正在检查 Appx 软件包……
echo %line%


if not exist !_work!\Appx\OneDriveSetup.exe echo 文件 OneDriveSetup.exe 不存在。
if not exist !_work!\Appx\OneDrive.ico echo 文件 OneDrive.ico 不存在。

set /a a=0
set "license=无证书文件。"
for /f "delims=" %%i in (!_work!\Appx\appxadd.txt) do (
    for /f "delims=_" %%# in ("%%i") do if not exist !_work!\Appx\%%#*.xml echo %%# 的证书文件不存在。
    if not exist !_work!\Appx\%%i echo %%i 不存在。
)

echo 请按数字 0 退出脚本。
choice /c 0 /n
if errorlevel 1 (exit /b) else (rem.)