@echo off
title Appx ����

set "_work=%~dp0"
set "_work=%_work:~0,-1%"

setlocal EnableDelayedExpansion
set "line===================================================="

echo %line%
echo ���ڼ�� Appx ���������
echo %line%


if not exist !_work!\Appx\OneDriveSetup.exe echo �ļ� OneDriveSetup.exe �����ڡ�
if not exist !_work!\Appx\OneDrive.ico echo �ļ� OneDrive.ico �����ڡ�

set /a a=0
set "license=��֤���ļ���"
for /f "delims=" %%i in (!_work!\Appx\appxadd.txt) do (
    for /f "delims=_" %%# in ("%%i") do if not exist !_work!\Appx\%%#*.xml echo %%# ��֤���ļ������ڡ�
    if not exist !_work!\Appx\%%i echo %%i �����ڡ�
)

echo �밴���� 0 �˳��ű���
choice /c 0 /n
if errorlevel 1 (exit /b) else (rem.)