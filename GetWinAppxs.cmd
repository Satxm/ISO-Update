@echo off
title ��ȡ Appxs �б�

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
set "_err========== ���� ========="

:: ��ȡ��ǰϵͳ Appxs �б����޸�OnlineΪ1
set Online=0

if %Online% equ 1 goto :Online

:select
set _DIR=
echo %line%
echo ʹ�� Tab ��ѡ���������������ļ����ļ���
echo %line%
echo.
set /p _DIR=
if not defined _DIR (
    echo %_err%
    echo δָ���ļ���
    echo.
    goto :select
)

echo %line%
echo ���صľ��� %_DIR% �� Appx �б�
echo %line%
echo.
for /f "tokens=2 delims=: " %%# in ('Dism /English /Image:%_DIR% /Get-ProvisionedAppxPackages ^| findstr /c:"PackageName"') do echo %%#
echo.
goto :Done

:Online
echo %line%
echo ��ǰϵͳ Appx �б�
echo %line%
echo.
for /f "tokens=2 delims=: " %%# in ('Dism /English /Online /Get-ProvisionedAppxPackages ^| findstr /c:"PackageName"') do echo %%#
echo.
goto :Done

:Done
echo �밴���� 0 ���˳��ű���
choice /c 0 /n
if errorlevel 1 (exit /b) else (rem.)