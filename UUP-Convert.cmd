@setlocal DisableDelayedExpansion
@set "uivr=v22.6.25"
@echo off
:Admin
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

:: �������£������⵽�����ɵ� install.wim/winre.wim �У��뽫�˲�������Ϊ 1
set AddUpdates=0

:: ��Ҫ����ӳ��������ѹ����ȡ����������뽫�˲�������Ϊ 1�����棺�� 18362 �����ϰ汾�У��⽫��ɾ������ RTM �汾�������
set Cleanup=1

:: ��Ҫ���ò���ϵͳӳ���Ƴ��ѱ�����ȡ����������뽫�˲�������Ϊ 1������Ĭ�ϵ�����ѹ������Ҫ�������ò��� Cleanup=1��
set ResetBase=1

:: ������Ҫ���� ISO �ļ�������ԭʼ�ļ��У��뽫�˲�������Ϊ 1
set SkipISO=0

:: ���ڼ�ʹ��⵽ SafeOS ���µ�����£�Ҳǿ��ʹ���ۻ����������� winre.wim���뽫�˲�������Ϊ 1
set LCUWinre=0

:: �������� ISO �����ļ� bootmgr/bootmgr.efi/efisys.bin���뽫�˲�������Ϊ 1
set SkipBootFiles=1

:: ����OneDrive���뽫�˲�������Ϊ 1
set UpdateOneDrive=0

:: ʹ�����о������� Windows �汾�����棬�뽫�˲�������Ϊ 1
set AddEdition=0

:: ���ɲ�ʹ�� .msu ���°���Windows 11�����뽫�˲�������Ϊ 1
set UseMSU=0

set "FullExit=exit /b"
set "_Null=1>nul 2>nul"

set _DIR=
set _elev=
set "_args="
set "_args=%~1"
if not defined _args goto :NoProgArgs
if "%~1"=="" set "_args="&goto :NoProgArgs
if "%~1"=="-elevated" set _elev=1&set "_args="&goto :NoProgArgs
if "%~2"=="-elevated" set _elev=1

:NoProgArgs
set "SysPath=%SystemRoot%\System32"
if exist "%SystemRoot%\Sysnative\reg.exe" set "SysPath=%SystemRoot%\Sysnative"
set "_ComSpec=%SystemRoot%\System32\cmd.exe"
set "xOS=%PROCESSOR_ARCHITECTURE%"
if /i %PROCESSOR_ARCHITECTURE%==x86 ( if defined PROCESSOR_ARCHITEW6432 (
        set "_ComSpec=%SystemRoot%\Sysnative\cmd.exe"
        set "xOS=%PROCESSOR_ARCHITEW6432%"
    )
)
set "Path=bin;%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
set "_err========== ���� ========="
for /f "tokens=6 delims=[]. " %%# in ('ver') do set winbuild=%%#
set _cwmi=0
for %%# in (wmic.exe) do @if not "%%~$PATH:#"=="" (
    wmic path Win32_ComputerSystem get CreationClassName /value 2>nul | find /i "ComputerSystem" 1>nul && set _cwmi=1
)
set _pwsh=1
for %%# in (powershell.exe) do @if "%%~$PATH:#"=="" set _pwsh=0
if %winbuild% geq 22483 if %_pwsh% equ 0 goto :E_PowerShell

:Passed
set "_log=%~dpn0"
set "_work=%~dp0"
set "_work=%_work:~0,-1%"
set _drv=%~d0
set "_cabdir=%_drv%\Updates"
if "%_work:~0,2%"=="\\" set "_cabdir=%~dp0temp\Updates"
for /f "skip=2 tokens=2*" %%a in ('reg.exe query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do call set "_dsk=%%b"
if exist "%PUBLIC%\Desktop\desktop.ini" set "_dsk=%PUBLIC%\Desktop"
set psfnet=0
if exist "%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\ngen.exe" set psfnet=1
if exist "%SystemRoot%\Microsoft.NET\Framework\v2.0.50727\ngen.exe" set psfnet=1
for %%# in (E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    set "_adr%%#=%%#"
)
if %_cwmi% equ 1 for /f "tokens=2 delims==:" %%# in ('"wmic path Win32_Volume where (DriveLetter is not NULL) get DriveLetter /value" ^| findstr ^=') do (
    if defined _adr%%# set "_adr%%#="
)
if %_cwmi% equ 1 for /f "tokens=2 delims==:" %%# in ('"wmic path Win32_LogicalDisk where (DeviceID is not NULL) get DeviceID /value" ^| findstr ^=') do (
    if defined _adr%%# set "_adr%%#="
)
if %_cwmi% equ 0 for /f "tokens=1 delims=:" %%# in ('powershell -nop -c "(([WMISEARCHER]'Select * from Win32_Volume where DriveLetter is not NULL').Get()).DriveLetter; (([WMISEARCHER]'Select * from Win32_LogicalDisk where DeviceID is not NULL').Get()).DeviceID"') do (
    if defined _adr%%# set "_adr%%#="
)
for %%# in (E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if not defined _sdr (if defined _adr%%# set "_sdr=%%#:")
)
if not defined _sdr set psfnet=0
set "_Pkt=31bf3856ad364e35"
set "_EsuCmp=microsoft-client-li..pplementalservicing"
set "_EdgCmp=microsoft-windows-e..-firsttimeinstaller"
set "_CedCmp=microsoft-windows-edgechromium"
set "_EsuIdn=Microsoft-Client-Licensing-SupplementalServicing"
set "_EdgIdn=Microsoft-Windows-EdgeChromium-FirstTimeInstaller"
set "_CedIdn=Microsoft-Windows-EdgeChromium"
set "_SxsCfg=Microsoft\Windows\CurrentVersion\SideBySide\Configuration"
setlocal EnableDelayedExpansion

set "_Nul1=1>nul"
set "_Nul2=2>nul"
set "_Nul6=2^>nul"
set "_Nul3=1>nul 2>nul"
goto :Begin

:Begin
@cls
title UUP ���ɾ��� %uivr%
set "_dLog=%SystemRoot%\Logs\DISM"
set _dism1=Dism.exe
set _dism2=Dism.exe /ScratchDir

:precheck
set W10UI=0
if %winbuild% geq 10240 (
    set W10UI=1
)
set ksub=SOFTWIM
set ERRORTEMP=
set PREPARED=0
set EXPRESS=0
set uwinpe=0
set "_fixEP="
set _skpd=0
set _skpp=0
set _eosC=0
set _eosP=0
set _eosT=0
set _SrvESD=0
set _Srvr=0
set _ndir=0
set _nesd=0
set "_mount=%_drv%\Mount"
set "_ntf=NTFS"
if /i not "%_drv%"=="%SystemDrive%" if %_cwmi% equ 1 for /f "tokens=2 delims==" %%# in ('"wmic volume where DriveLetter='%_drv%' get FileSystem /value"') do set "_ntf=%%#"
if /i not "%_drv%"=="%SystemDrive%" if %_cwmi% equ 0 for /f %%# in ('powershell -nop -c "(([WMISEARCHER]'Select * from Win32_Volume where DriveLetter=\"%_drv%\"').Get()).FileSystem"') do set "_ntf=%%#"
if /i not "%_ntf%"=="NTFS" (
    set "_mount=%SystemDrive%\Mount"
)
set "line============================================================="

:check
pushd "!_work!"
set _fils=(7z.dll,7z.exe,bootmui.txt,bootwim.txt,oscdimg.exe,imagex.exe,libwim-15.dll,offlinereg.exe,offreg.dll,wimlib-imagex.exe,PSFExtractor.exe)
for %%# in %_fils% do (
    if not exist "bin\%%#" (set _bin=%%#&goto :E_BinMiss)
)

:checkupd
echo.
for /f "tokens=* delims=" %%# in ('dir /b /ad "!_work!"') do if exist "!_work!\%%~#\*.esd" (set /a _ndir+=1&set "_DIR=!_work!\%%~#"&echo %%~#)
if !_ndir! equ 1 if defined _DIR goto :proceed

:selectuup
set _DIR=
echo.
echo %line%
echo ʹ�� Tab ��ѡ���������� .esd �ļ����ļ���
echo %line%
echo.
set /p _DIR=
if not defined _DIR (
    echo.
    echo %_err%
    echo δָ���ļ���
    echo.
    goto :selectuup
)
set "_DIR=!_work!\%_DIR:"=%"
if "%_DIR:~-1%"=="\" set "_DIR=%_DIR:~0,-1%"
if not exist "%_DIR%\*.esd" (
    echo.
    echo %_err%
    echo ָ�����ļ������� .esd �ļ�
    echo.
    goto :selectuup
)

:proceed
set _updexist=0
if exist bin\temp\ rmdir /s /q bin\temp\
if exist temp\ rmdir /s /q temp\
mkdir bin\temp
mkdir temp
if exist "!_DIR!\*Windows1*-KB*.msu" set _updexist=1
if exist "!_DIR!\*Windows1*-KB*.cab" set _updexist=1
if exist "!_DIR!\SSU-*-*.cab" set _updexist=1
if exist "!_work!\Appx\appxadd.txt" set _updexist=1
if exist "!_work!\Appx\appxdel.txt" set _updexist=1
dir /b /ad "!_DIR!\*Package*" %_Nul3% && set EXPRESS=1
for %%# in (
Core,CoreN,CoreSingleLanguage,CoreCountrySpecific
Professional,ProfessionalN,ProfessionalEducation,ProfessionalEducationN,ProfessionalWorkstation,ProfessionalWorkstationN
Education,EducationN,Enterprise,EnterpriseN,EnterpriseG,EnterpriseGN,EnterpriseS,EnterpriseSN,ServerRdsh
PPIPro,IoTEnterprise,IoTEnterpriseS
Cloud,CloudN,CloudE,CloudEN,CloudEdition,CloudEditionN,CloudEditionL,CloudEditionLN
Starter,StarterN,ProfessionalCountrySpecific,ProfessionalSingleLanguage
ServerStandardCore,ServerStandard,ServerDatacenterCore,ServerDatacenter,ServerAzureStackHCICor,ServerTurbineCor,ServerTurbine,ServerStandardACor,ServerDatacenterACor,ServerStandardWSCor,ServerDatacenterWSCor
) do (
if exist "!_DIR!\%%#_*.esd" (dir /b /a:-d "!_DIR!\%%#_*.esd">>temp\uups_esd.txt %_Nul2%) else if exist "!_DIR!\MetadataESD_%%#_*.esd" (dir /b /a:-d "!_DIR!\MetadataESD_%%#_*.esd">>temp\uups_esd.txt %_Nul2%)
)
for /f "tokens=3 delims=: " %%# in ('find /v /c "" temp\uups_esd.txt %_Nul6%') do set _nesd=%%#
if %_nesd% equ 0 goto :E_NotFind
for /L %%# in (1,1,%_nesd%) do call :uup_check %%#
if defined eWIMLIB goto :QUIT
set "MetadataESD=!_DIR!\%uups_esd1%"&set "_flg=%edition1%"&set "arch=%arch1%"&set "langid=%langid1%"&set "editionid=%edition1%"&set "_oName=%_oname1%"&set "_Srvr=%_ESDSrv1%"
goto :ISO

:ISO
if %_updexist% equ 0 set AddUpdates=0
if %PREPARED% equ 0 call :PREPARE
if /i %arch%==arm64 if %winbuild% lss 9600 if %AddUpdates% equ 1 (
    if %_build% geq 17763 set AddUpdates=0
)
if %AddUpdates% equ 1 if %W10UI% equ 0 (set AddUpdates=0)
if %Cleanup% equ 0 set ResetBase=0
if %_build% lss 17763 if %AddUpdates% equ 1 (set Cleanup=1)
call :uup_ref
echo.
echo %line%
echo ���ڲ��� ISO ��װ�ļ�����
echo %line%
echo.
if exist ISOFOLDER\ rmdir /s /q ISOFOLDER\
mkdir ISOFOLDER
wimlib-imagex.exe apply "!MetadataESD!" 1 ISOFOLDER\ --no-acls --no-attributes %_Null%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Apply
if exist ISOFOLDER\MediaMeta.xml del /f /q ISOFOLDER\MediaMeta.xml %_Nul3%
:: rmdir /s /q ISOFOLDER\sources\uup\ %_Nul3%
if %_build% geq 18890 (
    wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\Boot\Fonts\* --dest-dir=ISOFOLDER\boot\fonts --no-acls --no-attributes %_Nul3%
    xcopy /CRY ISOFOLDER\boot\fonts\* ISOFOLDER\efi\microsoft\boot\fonts\ %_Nul3%
)
if %AddUpdates% equ 1 if %_updexist% equ 1 (
    echo.
    echo %line%
    echo ���ڼ������ļ�����
    echo %line%
    echo.
    if %UseMSU% neq 1 if exist "!_DIR!\*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "!_DIR!\*.msu"') do (set "pkgn=%%~n#"&set "package=%%#"&call :exd_msu)
    if %UseMSU% equ 1 if %_build% lss 21382 if exist "!_DIR!\*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "!_DIR!\*.msu"') do (set "pkgn=%%~n#"&set "package=%%#"&call :exd_msu)
    if %UseMSU% equ 1 if %_build% geq 21382 if exist "!_DIR!\*.AggregatedMetadata*.cab" if exist "!_DIR!\*Windows1*-KB*.cab" if exist "!_DIR!\*Windows1*-KB*.psf" call :upd_msu
    if exist "!_cabdir!\" rmdir /s /q "!_cabdir!\"
    DEL /F /Q %_dLog%\* %_Nul3%
    if not exist "%_dLog%\" mkdir "%_dLog%" %_Nul3%
    call :extract
)
if %AddUpdates% equ 0 if not exist "!_cabdir!\" mkdir "!_cabdir!"
if exist bin\ei.cfg copy /y bin\ei.cfg ISOFOLDER\sources\ei.cfg %_Nul3%
if not defined isoupdate goto :nosetupud
echo.
echo %line%
echo ����Ӧ�� ISO ��װ�ļ����¡���
echo %line%
echo.
mkdir "%_cabdir%\du" %_Nul3%
for %%# in (!isoupdate!) do (
    echo %%~#
    expand.exe -r -f:* "!_DIR!\%%~#" "%_cabdir%\du" %_Nul1%
)
xcopy /CDRUY "%_cabdir%\du" "ISOFOLDER\sources\" %_Nul3%
if exist "%_cabdir%\du\*.ini" xcopy /CDRY "%_cabdir%\du\*.ini" "ISOFOLDER\sources\" %_Nul3%
for /f %%# in ('dir /b /ad "%_cabdir%\du\*-*" %_Nul6%') do if exist "ISOFOLDER\sources\%%#\*.mui" copy /y "%_cabdir%\du\%%#\*" "ISOFOLDER\sources\%%#\" %_Nul3%
if exist "%_cabdir%\du\replacementmanifests\" xcopy /CERY "%_cabdir%\du\replacementmanifests" "ISOFOLDER\sources\replacementmanifests\" %_Nul3%
rmdir /s /q "%_cabdir%\du\" %_Nul3%
:nosetupud
set _rtrn=WinreRet
goto :WinreWim
:WinreRet
set _rtrn=BootRet
goto :BootWim
:BootRet
set _rtrn=InstallRet
goto :InstallWim
:InstallRet
if %SkipISO% neq 0 (
    ren ISOFOLDER %DVDISO%
    echo.
    echo %line%
    echo ��ɡ�
    echo %line%
    echo.
    goto :QUIT
)
echo.
echo %line%
echo ���ڴ��� ISO ����
echo %line%
for /f "tokens=5-10 delims=: " %%G in ('wimlib-imagex.exe info ISOFOLDER\sources\install.wim ^| find /i "Last Modification Time"') do (set mmm=%%G&set "isotime=%%H/%%L,%%I:%%J:%%K")
for %%# in (Jan:01 Feb:02 Mar:03 Apr:04 May:05 Jun:06 Jul:07 Aug:08 Sep:09 Oct:10 Nov:11 Dec:12) do for /f "tokens=1,2 delims=:" %%A in ("%%#") do if /i %mmm%==%%A set "isotime=%%B/%isotime%"
if /i not %arch%==arm64 (
    oscdimg.exe -bootdata:2#p0,e,b"ISOFOLDER\boot\etfsboot.com"#pEF,e,b"ISOFOLDER\efi\Microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -t%isotime% -g -l%DVDLABEL% ISOFOLDER %DVDISO%.iso
) else (
    oscdimg.exe -bootdata:1#pEF,e,b"ISOFOLDER\efi\Microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -t%isotime% -g -l%DVDLABEL% ISOFOLDER %DVDISO%.iso
)
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_ISOC
echo.
echo %line%
echo ��ɡ�
echo %line%
echo.
goto :QUIT

:InstallWim
echo.
echo %line%
echo ���ڴ��� install.wim �ļ�����
echo %line%
echo.
if exist "temp\*.ESD" (set _rrr=--ref="temp\*.esd") else (set "_rrr=")
set _rrr=%_rrr% --compress=LZX
for /L %%# in (1, 1,%_nesd%) do (
    wimlib-imagex.exe export "!_DIR!\!uups_esd%%#!" 3 "ISOFOLDER\sources\install.wim" --ref="!_DIR!\*.esd" %_rrr%
    call set ERRORTEMP=!ERRORLEVEL!
    if !ERRORTEMP! neq 0 goto :E_Export
)
echo.
echo %line%
echo ���ڽ� Winre.wim ��ӵ� install.wim �С���
echo %line%
echo.
for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info "ISOFOLDER\sources\install.wim" ^| findstr /c:"Image Count"') do set imgcount=%%#
for /L %%# in (1,1,%imgcount%) do (
    wimlib-imagex.exe update "ISOFOLDER\sources\install.wim" %%# --command="add 'temp\Winre.wim' '\Windows\System32\Recovery\Winre.wim'" %_Null%
)
if %AddUpdates% equ 0 goto :noupd
if %_updexist% equ 0 goto :noupd
if %UpdateOneDrive% equ 1 (
    echo.
    echo %line%
    echo ���ڸ��� OneDrive ��װ�ļ�����
    echo %line%
    echo.
    for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info ISOFOLDER\sources\install.wim ^| findstr /c:"Image Count"') do set imgcount=%%#
    if %_build% lss 22563 (
        if exist "!_work!\Appx\OneDriveSetup.exe" (
            for /L %%# in (1,1,!imgcount!) do (
                wimlib-imagex.exe update "ISOFOLDER\sources\install.wim" %%# --command="add '!_work!\Appx\OneDriveSetup.exe' '\Windows\SysWOW64\OneDriveSetup.exe'" %_Null%
            )
        )
        if exist "!_work!\Appx\OneDrive.ico" (
            for /L %%# in (1,1,!imgcount!) do (
                wimlib-imagex.exe update "ISOFOLDER\sources\install.wim" %%# --command="add '!_work!\Appx\OneDrive.ico' '\Windows\SysWOW64\OneDrive.ico'" %_Null%
            )
        )
    ) else (
        if exist "!_work!\Appx\OneDriveSetup.exe" (
            for /L %%# in (1,1,!imgcount!) do (
                wimlib-imagex.exe update "ISOFOLDER\sources\install.wim" %%# --command="add '!_work!\Appx\OneDriveSetup.exe' '\Windows\System32\OneDriveSetup.exe'" %_Null%
            )
        )
        if exist "!_work!\Appx\OneDrive.ico" (
            for /L %%# in (1,1,!imgcount!) do (
                wimlib-imagex.exe update "ISOFOLDER\sources\install.wim" %%# --command="add '!_work!\Appx\OneDrive.ico' '\Windows\System32\OneDrive.ico'" %_Null%
            )
        )
    )
)
set iswre=0
call :update
:noupd
wimlib-imagex.exe optimize "ISOFOLDER\sources\install.wim"
for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info "ISOFOLDER\sources\install.wim" ^| findstr /c:"Image Count"') do set imgcount=%%#
for /L %%# in (1,1,%imgcount%) do (
    for /f "tokens=3 delims=<>" %%A in ('imagex /info "ISOFOLDER\sources\install.wim" %%# ^| find /i "<HIGHPART>"') do call set "HIGHPART=%%A"
    for /f "tokens=3 delims=<>" %%A in ('imagex /info "ISOFOLDER\sources\install.wim" %%# ^| find /i "<LOWPART>"') do call set "LOWPART=%%A"
    wimlib-imagex.exe info "ISOFOLDER\sources\install.wim" %%# --image-property CREATIONTIME/HIGHPART=!HIGHPART! --image-property CREATIONTIME/LOWPART=!LOWPART! %_Nul1%
)
goto :%_rtrn%

:WinreWim
echo.
echo %line%
echo ���ڴ��� Winre.wim �ļ�����
echo %line%
echo.
wimlib-imagex.exe export "!MetadataESD!" 2 temp\Winre.wim --compress=LZX --boot
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Export
if %LCUWinre% equ 0 (set iswre=1) else (set iswre=0)
if %uwinpe% equ 1 if %AddUpdates% equ 1 if %_updexist% equ 1 (
    call :update temp\Winre.wim
)
wimlib-imagex.exe optimize temp\Winre.wim
goto :%_rtrn%

:BootWim
echo.
echo %line%
echo ���ڴ��� boot.wim �ļ�����
echo %line%
echo.
wimlib-imagex.exe export "!MetadataESD!" 2 temp\boot.wim --compress=LZX --boot
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Export
echo.
echo %line%
echo �����Ż� boot.wim �ļ�����
echo %line%
echo.
if exist "%_mount%\" rmdir /s /q "%_mount%\"
if not exist "%_mount%\" mkdir "%_mount%"
type nul>temp\winpe.txt
set "remove="
%_dism1% /Mount-Wim /Wimfile:"temp\boot.wim" /Index:1 /MountDir:"%_mount%"
for /f "tokens=3 delims=: " %%i in ('%_dism1% /English /Image:"%_mount%" /Get-Packages ^| findstr /c:"Package Identity"') do echo %%i>>temp\winpe.txt
for /f "tokens=* delims=" %%# in (bin\winpe.txt) do for /f "tokens=* delims=" %%i in ('type temp\winpe.txt ^| findstr /c:"%%#"') do set "remove=!remove! /PackageName:%%i"
%_dism1% /Image:"%_mount%" /Remove-Package !remove! %_Null%
%_dism1% /Image:"%_mount%" /Cleanup-Image /StartComponentCleanup
%_dism1% /Image:"%_mount%" /Cleanup-Image /StartComponentCleanup /ResetBase %_Null%
%_dism1% /Unmount-Wim /MountDir:"%_mount%" /Commit
set iswre=0
if %uwinpe% equ 1 if %AddUpdates% equ 1 if %_updexist% equ 1 call :update temp\boot.wim
copy /y temp\boot.wim ISOFOLDER\sources\boot.wim %_Nul1%
wimlib-imagex.exe info ISOFOLDER\sources\boot.wim 1 "Microsoft Windows PE (%arch%)" "Microsoft Windows PE (%arch%)" --image-property FLAGS=9 %_Nul3%
wimlib-imagex.exe update ISOFOLDER\sources\boot.wim 1 --command="delete '\Windows\system32\winpeshl.ini'" %_Nul3%
wimlib-imagex.exe extract ISOFOLDER\sources\boot.wim 1 Windows\System32\config\SOFTWARE --dest-dir=bin\temp --no-acls --no-attributes %_Null%
offlinereg.exe bin\temp\SOFTWARE "Microsoft\Windows NT\CurrentVersion\WinPE" setvalue InstRoot X:\$windows.~bt\ %_Nul3%
offlinereg.exe bin\temp\SOFTWARE.new "Microsoft\Windows NT\CurrentVersion" setvalue SystemRoot X:\$windows.~bt\Windows %_Nul3%
del /f /q bin\temp\SOFTWARE
ren bin\temp\SOFTWARE.new SOFTWARE
type nul>bin\boot-wim.txt
>>bin\boot-wim.txt echo add 'bin^\temp^\SOFTWARE' '^\Windows^\System32^\config^\SOFTWARE'
set "_bkimg="
wimlib-imagex.exe extract ISOFOLDER\sources\boot.wim 1 Windows\System32\winpe.jpg --dest-dir=ISOFOLDER\sources --no-acls --no-attributes --nullglob %_Null%
for %%# in (background_cli.bmp, background_svr.bmp, background_cli.png, background_svr.png, winpe.jpg) do if exist "ISOFOLDER\sources\%%#" set "_bkimg=%%#"
if defined _bkimg (
    >>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%_bkimg%' '^\Windows^\system32^\winpe.jpg'
    >>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%_bkimg%' '^\Windows^\system32^\winre.jpg'
)
wimlib-imagex.exe update ISOFOLDER\sources\boot.wim 1 < bin\boot-wim.txt %_Null%
rmdir /s /q bin\temp\
wimlib-imagex.exe extract "ISOFOLDER\sources\install.wim" 1 Windows\system32\xmllite.dll --dest-dir=ISOFOLDER\sources --no-acls --no-attributes %_Nul3%
type nul>bin\boot-wim.txt
>>bin\boot-wim.txt echo delete '^\Windows^\system32^\winpeshl.ini'
>>bin\boot-wim.txt echo add 'ISOFOLDER^\setup.exe' '^\setup.exe'
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\inf^\setup.cfg' '^\sources^\inf^\setup.cfg'
if not defined _bkimg (
    wimlib-imagex.exe extract ISOFOLDER\sources\boot.wim 1 Windows\System32\winpe.jpg --dest-dir=ISOFOLDER\sources --no-acls --no-attributes --nullglob %_Null%
    for %%# in (background_cli.bmp, background_svr.bmp, background_cli.png, background_svr.png, winpe.jpg) do if exist "ISOFOLDER\sources\%%#" set "_bkimg=%%#"
)
if defined _bkimg (
    >>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%_bkimg%' '^\sources^\background.bmp'
    >>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%_bkimg%' '^\Windows^\system32^\setup.bmp'
    >>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%_bkimg%' '^\Windows^\system32^\winpe.jpg'
    >>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%_bkimg%' '^\Windows^\system32^\winre.jpg'
)
for /f %%# in (bin\bootwim.txt) do if exist "ISOFOLDER\sources\%%#" (
    >>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%%#' '^\sources^\%%#'
)
for /f %%# in (bin\bootmui.txt) do if exist "ISOFOLDER\sources\%langid%\%%#" (
    >>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%langid%^\%%#' '^\sources^\%langid%^\%%#'
)
wimlib-imagex.exe export temp\boot.wim 1 ISOFOLDER\sources\boot.wim "Microsoft Windows Setup (%arch%)" "Microsoft Windows Setup (%arch%)" --boot
wimlib-imagex.exe update ISOFOLDER\sources\boot.wim 2 < bin\boot-wim.txt %_Null%
wimlib-imagex.exe info ISOFOLDER\sources\boot.wim 2 --image-property FLAGS=2 %_Nul3%
wimlib-imagex.exe optimize ISOFOLDER\sources\boot.wim
del /f /q bin\boot-wim.txt %_Nul3%
del /f /q ISOFOLDER\sources\xmllite.dll %_Nul3%
del /f /q ISOFOLDER\sources\winpe.jpg %_Nul3%
goto :%_rtrn%

:PREPARE
echo.
echo %line%
echo ���ڼ�龵����Ϣ����
echo %line%
set PREPARED=1
imagex /info "!MetadataESD!" 3 >bin\info.txt 2>&1
for /f "tokens=3 delims=<>" %%# in ('find /i "<MAJOR>" bin\info.txt') do set ver1=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<MINOR>" bin\info.txt') do set ver2=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<BUILD>" bin\info.txt') do set _build=%%#
wimlib-imagex.exe extract "!MetadataESD!" 1 sources\setuphost.exe --dest-dir=bin\temp --no-acls --no-attributes %_Nul3%
7z.exe l bin\temp\setuphost.exe >bin\temp\version.txt 2>&1
if %_build% geq 22478 (
    wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\System32\UpdateAgent.dll --dest-dir=bin\temp --no-acls --no-attributes --ref="!_DIR!\*.esd" %_Nul3%
    if exist "bin\temp\UpdateAgent.dll" 7z.exe l bin\temp\UpdateAgent.dll >bin\temp\version.txt 2>&1
)
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" bin\temp\version.txt" %_Nul6%') do (set uupver=%%i.%%j&set uupmaj=%%i&set uupmin=%%j)
set revver=%uupver%&set revmaj=%uupmaj%&set revmin=%uupmin%
set "tok=6,7"&set "toe=5,6,7"
if /i %arch%==x86 (set _ss=x86) else if /i %arch%==x64 (set _ss=amd64) else (set _ss=arm64)
wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\WinSxS\Manifests\%_ss%_microsoft-windows-coreos-revision*.manifest --dest-dir=bin\temp --no-acls --no-attributes --ref="!_DIR!\*.esd" %_Nul3%
if exist "bin\temp\*_microsoft-windows-coreos-revision*.manifest" for /f "tokens=%tok% delims=_." %%i in ('dir /b /a:-d /od bin\temp\*_microsoft-windows-coreos-revision*.manifest') do (set revver=%%i.%%j&set revmaj=%%i&set revmin=%%j)
if %_build% geq 15063 (
    wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\System32\config\SOFTWARE --dest-dir=bin\temp --no-acls --no-attributes %_Null%
    set "isokey=Microsoft\Windows NT\CurrentVersion\Update\TargetingInfo\Installed"
    for /f %%i in ('"offlinereg.exe bin\temp\SOFTWARE "!isokey!" enumkeys %_Nul6% ^| findstr /i /r ".*\.OS""') do if not errorlevel 1 (
        for /f "tokens=5,6 delims==:." %%A in ('"offlinereg.exe bin\temp\SOFTWARE "!isokey!\%%i" getvalue Version %_Nul6%"') do if %%A gtr !revmaj! (
            set "revver=%%~A.%%B
            set revmaj=%%~A
            set "revmin=%%B
        )
    )
)
if %uupmin% lss %revmin% set uupver=%revver%
if %uupmaj% lss %revmaj% set uupver=%revver%
set _label=%uupver%
call :setlabel
rmdir /s /q bin\temp\

:setlabel
set DVDISO=%_label%.%arch%
for %%# in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do set langid=!langid:%%#=%%#!
if /i %arch%==x86 set archl=X86
if /i %arch%==x64 set archl=X64
if /i %arch%==arm64 set archl=A64
set images=0
set DVDLABEL=CCSA_%archl%FRE_%langid%_DV9
if not exist "ISOFOLDER\sources\install.wim" goto :Skiplabel
for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info "ISOFOLDER\sources\install.wim" ^| findstr /c:"Image Count"') do set images=%%#
if %images% geq 4 set DVDLABEL=CCCOMA_%archl%FRE_%langid%_DV9
:Skiplabel
if %_SrvESD% equ 1 (
    set DVDLABEL=SSS_%archl%FRE_%langid%_DV9
)
exit /b

:uup_ref
echo.
echo %line%
echo ����׼������ Cab �Ĺ��� ESD �ļ�����
echo %line%
echo.
set _level=XPRESS
if exist "!_DIR!\*.xml.cab" if exist "!_DIR!\Metadata\*" move /y "!_DIR!\*.xml.cab" "!_DIR!\Metadata\" %_Nul3%
if exist "!_DIR!\*.cab" (
    for /f "tokens=* delims=" %%# in ('dir /b /a:-d "!_DIR!\*.cab"') do (
        del /f /q temp\update.mum %_Null%
        expand.exe -f:update.mum "!_DIR!\%%#" temp %_Null%
        if exist "temp\update.mum" call :uup_cab "%%#"
    )
)
if %EXPRESS% equ 1 (
    for /f "tokens=* delims=" %%# in ('dir /b /a:d /o:-n "!_DIR!\"') do call :uup_dir "%%#"
)
if exist "!_DIR!\Metadata\*.xml.cab" copy /y "!_DIR!\Metadata\*.xml.cab" "!_DIR!\" %_Nul3%
exit /b

:uup_dir
if /i "%~1"=="Metadata" exit /b
echo %~1| find /i "RetailDemo" %_Nul1% && exit /b
echo %~1| find /i "Holographic-Desktop-FOD" %_Nul1% && exit /b
echo %~1| find /i "Windows10.0-KB" %_Nul1% && exit /b
echo %~1| find /i "Windows11.0-KB" %_Nul1% && exit /b
echo %~1| find /i "SSU-" %_Nul1% && exit /b
set cbsp=%~1
if exist "!_work!\temp\%cbsp%.ESD" exit /b
echo ת��Ϊ ESD �ļ���%cbsp%
rmdir /s /q "!_DIR!\%~1\$dpx$.tmp\" %_Nul3%
wimlib-imagex.exe capture "!_DIR!\%~1" "temp\%cbsp%.ESD" --compress=%_level% --check --no-acls --norpfix "Edition Package" "Edition Package" %_Null%
exit /b

:uup_cab
echo %~1| find /i "RetailDemo" %_Nul1% && exit /b
echo %~1| find /i "Holographic-Desktop-FOD" %_Nul1% && exit /b
echo %~1| find /i "Windows10.0-KB" %_Nul1% && exit /b
echo %~1| find /i "Windows11.0-KB" %_Nul1% && exit /b
echo %~1| find /i "SSU-" %_Nul1% && exit /b
set cbsp=%~n1
if exist "!_work!\temp\%cbsp%.ESD" exit /b
echo %cbsp%
set /a _ref+=1
set /a _rnd=%random%
set _dst=%_drv%\_tmp%_ref%
if exist "%_dst%" (set _dst=%_drv%\_tmp%_rnd%)
mkdir %_dst% %_Nul3%
expand.exe -f:* "!_DIR!\%cbsp%.cab" %_dst%\ %_Null%
wimlib-imagex.exe capture "%_dst%" "temp\%cbsp%.ESD" --compress=%_level% --check --no-acls --norpfix "Edition Package" "Edition Package" %_Null%
rmdir /s /q %_dst%\ %_Nul3%
if exist "%_dst%\" (
    mkdir %_drv%\_del %_Null%
    robocopy %_drv%\_del %_dst% /MIR /R:1 /W:1 /NFL /NDL /NP /NJH /NJS %_Null%
    rmdir /s /q %_drv%\_del\ %_Null%
    rmdir /s /q %_dst%\ %_Null%
)
exit /b

:uup_check
set _ESDSrv%1=0
for /f "tokens=2 delims=]" %%# in ('find /v /n "" temp\uups_esd.txt ^| find "[%1]"') do set uups_esd=%%#
set "uups_esd%1=%uups_esd%"
wimlib-imagex.exe info "!_DIR!\%uups_esd%" 3 %_Nul3%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% equ 73 (
    echo %_err%
    echo %uups_esd% �ļ�����
    echo.
    set eWIMLIB=1
    exit /b
)
if %ERRORTEMP% neq 0 (
    echo %_err%
    echo �޷����������ļ� %uups_esd% ����Ϣ
    echo.
    set eWIMLIB=1
    exit /b
)
imagex /info "!_DIR!\%uups_esd%" 3 >bin\info.txt 2>&1
for /f "tokens=3 delims=<>" %%# in ('find /i "<DEFAULT>" bin\info.txt') do set "langid%1=%%#"
for /f "tokens=3 delims=<>" %%# in ('find /i "<EDITIONID>" bin\info.txt') do set "edition%1=%%#"
for /f "tokens=3 delims=<>" %%# in ('find /i "<ARCH>" bin\info.txt') do (if %%# equ 0 (set "arch%1=x86") else if %%# equ 9 (set "arch%1=x64") else (set "arch%1=arm64"))
set "_wtx=Windows 10"
find /i "<NAME>" bin\info.txt %_Nul2% | find /i "Windows 11" %_Nul1% && (set "_wtx=Windows 11")
echo !edition%1! | findstr /i /b "Server" %_Nul3% && (set _SrvESD=1&set _ESDSrv%1=1)
if !_ESDSrv%1! equ 1 findstr /i /c:"Server Core" bin\info.txt %_Nul3% && (
    if /i "!edition%1!"=="ServerStandard" set "edition%1=ServerStandardCore"
    if /i "!edition%1!"=="ServerDatacenter" set "edition%1=ServerDatacenterCore"
)
del /f /q bin\info*.txt
exit /b

:exd_msu
echo %line%
echo ����ۻ����� %package% �ļ�
echo %line%
echo.
mkdir "!_DIR!\%pkgn%" %_Nul3%
expand.exe -f:*Windows1*.cab "!_DIR!\%package%" "!_DIR!\%pkgn%" %_Null%
if exist "!_DIR!\%pkgn%\*Windows*.cab" for /f "tokens=* delims=" %%i in ('dir /b /on "!_DIR!\%pkgn%\*Windows*.cab"') do if not exist "!_DIR!\%%i" copy /y "!_DIR!\%pkgn%\%%i" "!_DIR!\%%i" %_Nul3%
expand.exe -f:*Windows1*.psf "!_DIR!\%package%" "!_DIR!\%pkgn%" %_Null%
if exist "!_DIR!\%pkgn%\*Windows*.psf" for /f "tokens=* delims=" %%i in ('dir /b /on "!_DIR!\%pkgn%\*Windows*.psf"') do if not exist "!_DIR!\%%i" copy /y "!_DIR!\%pkgn%\%%i" "!_DIR!\%%i" %_Nul3%
expand.exe -f:*SSU-*.cab "!_DIR!\%package%" "!_DIR!\%pkgn%" %_Null%
if exist "!_DIR!\%pkgn%\*SSU-*.cab" for /f "tokens=* delims=" %%i in ('dir /b /on "!_DIR!\%pkgn%\*SSU-*.cab"') do if not exist "!_DIR!\%%i" copy /y "!_DIR!\%pkgn%\%%i" "!_DIR!\%%i" %_Nul3%
rmdir /s /q "!_DIR!\%pkgn%\" %_Nul3%
exit /b

:upd_msu
echo %line%
echo �����ۻ����µ� MSU �ļ�
echo %line%
pushd "!_DIR!"
set "_MSUdll=dpx.dll ReserveManager.dll TurboStack.dll UpdateAgent.dll wcp.dll"
set "_MSUonf=onepackage.AggregatedMetadata.cab"
set "_MSUssu="
set IncludeSSU=1
set _mcfail=0
for /f "delims=" %%# in ('dir /b /a:-d "*.AggregatedMetadata*.cab"') do set "_MSUmeta=%%#"
if exist "_tMSU\" rmdir /s /q "_tMSU\" %_Nul3%
mkdir "_tMSU"
expand.exe -f:LCUCompDB*.xml.cab "%_MSUmeta%" "_tMSU" %_Null%
if not exist "_tMSU\LCUCompDB*.xml.cab" (
echo.
echo AggregatedMetadata �ļ��� LCUCompDB �ļ���ʧ������������
goto :msu_uups
)
for /f %%# in ('dir /b /a:-d "_tMSU\LCUCompDB*.xml.cab"') do set "_MSUcdb=%%#"
for /f "tokens=2 delims=_." %%# in ('echo %_MSUcdb%') do set "_MSUkbn=%%#"
if not exist "*Windows1*%_MSUkbn%*%arch%*.cab" (
echo.
echo �����ۻ����� %_MSUkbn% �� cab �ļ���ʧ������������
goto :msu_uups
)
if not exist "*Windows1*%_MSUkbn%*%arch%*.psf" (
echo.
echo �����ۻ����� %_MSUkbn% �� psf �ļ���ʧ������������
goto :msu_uups
)
if exist "*Windows1*%_MSUkbn%*%arch%*.msu" (
echo.
echo �����ۻ����� %_MSUkbn% �� msu �ļ��Ѿ����ڣ�����������
goto :msu_uups
)
for /f "delims=" %%# in ('dir /b /a:-d "*Windows1*%_MSUkbn%*%arch%*.cab"') do set "_MSUcab=%%#"
for /f "delims=" %%# in ('dir /b /a:-d "*Windows1*%_MSUkbn%*%arch%*.psf"') do set "_MSUpsf=%%#"
set "_MSUkbf=Windows10.0-%_MSUkbn%-%arch%"
echo %_MSUcab%| findstr /i "Windows11\." %_Nul1% && set "_MSUkbf=Windows11.0-%_MSUkbn%-%arch%"
if exist "SSU-*%arch%*.cab" (
for /f "tokens=2 delims=-" %%# in ('dir /b /a:-d "SSU-*%arch%*.cab"') do set "_MSUtsu=SSU-%%#-%arch%.cab"
for /f "delims=" %%# in ('dir /b /a:-d "SSU-*%arch%*.cab"') do set "_MSUssu=%%#"
expand.exe -f:SSUCompDB*.xml.cab "%_MSUmeta%" "_tMSU" %_Null%
if exist "_tMSU\SSU*-express.xml.cab" del /f /q "_tMSU\SSU*-express.xml.cab"
if not exist "_tMSU\SSUCompDB*.xml.cab" set IncludeSSU=0
) else (
set IncludeSSU=0
)
if %IncludeSSU% equ 1 for /f %%# in ('dir /b /a:-d "_tMSU\SSUCompDB*.xml.cab"') do set "_MSUsdb=%%#"
set "_MSUddd=DesktopDeployment_x86.cab"
if exist "*DesktopDeployment*.cab" (
for /f "delims=" %%# in ('dir /b /a:-d "*DesktopDeployment*.cab" ^|find /i /v "%_MSUddd%"') do set "_MSUddc=%%#"
) else (
call set "_MSUddc=_tMSU\DesktopDeployment.cab"
call set "_MSUddd=_tMSU\DesktopDeployment_x86.cab"
call :DDCAB
)
if %_mcfail% equ 1 goto :msu_uups
if /i not %arch%==x86 if not exist "DesktopDeployment_x86.cab" if not exist "_tMSU\DesktopDeployment_x86.cab" (
call set "_MSUddd=_tMSU\DesktopDeployment_x86.cab"
call :DDC86
)
if %_mcfail% equ 1 goto :msu_uups
call :crDDF _tMSU\%_MSUonf%
(echo "_tMSU\%_MSUcdb%" "%_MSUcdb%"
if %IncludeSSU% equ 1 echo "_tMSU\%_MSUsdb%" "%_MSUsdb%"
)>>zzz.ddf
%_Null% makecab.exe /F zzz.ddf /D Compress=ON /D CompressionType=MSZIP
if %ERRORLEVEL% neq 0 (echo ʧ�ܣ������ò�����&goto :msu_uups)
call :crDDF %_MSUkbf%.msu
(echo "%_MSUddc%" "DesktopDeployment.cab"
if /i not %arch%==x86 echo "%_MSUddd%" "DesktopDeployment_x86.cab"
echo "_tMSU\%_MSUonf%" "%_MSUonf%"
if %IncludeSSU% equ 1 echo "%_MSUssu%" "%_MSUtsu%"
echo "%_MSUcab%" "%_MSUkbf%.cab"
echo "%_MSUpsf%" "%_MSUkbf%.psf"
)>>zzz.ddf
%_Null% makecab.exe /F zzz.ddf /D Compress=OFF
if %ERRORLEVEL% neq 0 (echo ʧ�ܣ������ò�����&goto :msu_uups)

:msu_uups
if exist "zzz.ddf" del /f /q "zzz.ddf"
if exist "_tSSU\" rmdir /s /q "_tSSU\" %_Nul3%
rmdir /s /q "_tMSU\" %_Nul3%
popd
exit /b

:DDCAB
echo.
echo ���ڽ�ѹ�����ļ�����
if exist "_tSSU\" rmdir /s /q "_tSSU\" %_Nul3%
mkdir "_tSSU\000"
if not defined _MSUssu goto :ssuinner64
expand.exe -f:* "%_MSUssu%" "_tSSU" %_Null% || goto :ssuinner64
goto :ssuouter64
:ssuinner64
popd
for /f %%# in ('wimlib-imagex.exe dir %_file% 1 --path=Windows\WinSxS\Manifests ^| find /i "_microsoft-windows-servicingstack_"') do (
wimlib-imagex.exe extract %_file% 1 Windows\WinSxS\%%~n# --dest-dir="!_DIR!\_tSSU" --no-acls --no-attributes %_Nul3%
)
pushd "!_DIR!"
:ssuouter64
set xbt=%arch%
if /i %arch%==x64 set xbt=amd64
for /f %%# in ('dir /b /ad "_tSSU\%xbt%_microsoft-windows-servicingstack_*"') do set "src=%%#"
for %%# in (%_MSUdll%) do move /y "_tSSU\%src%\%%#" "_tSSU\000\%%#" %_Nul1%
call :crDDF %_MSUddc%
call :apDDF _tSSU\000
%_Null% makecab.exe /F zzz.ddf /D Compress=ON /D CompressionType=MSZIP
if %ERRORLEVEL% neq 0 (set _mcfail=1&echo ʧ�ܣ������ò�����&exit /b)
mkdir "_tSSU\111"
if /i not %arch%==x86 if not exist "DesktopDeployment_x86.cab" goto :DDCdual
rmdir /s /q "_tSSU\" %_Nul3%
exit /b

:DDC86
echo.
echo ���ڽ�ѹ�����ļ�����
if exist "_tSSU\" rmdir /s /q "_tSSU\" %_Nul3%
mkdir "_tSSU\111"
if not defined _MSUssu goto :ssuinner86
expand.exe -f:* "%_MSUssu%" "_tSSU" %_Null% || goto :ssuinner86
goto :ssuouter86
:ssuinner86
popd
for /f %%# in ('wimlib-imagex.exe dir %_file% 1 --path=Windows\WinSxS\Manifests ^| find /i "x86_microsoft-windows-servicingstack_"') do (
wimlib-imagex.exe extract %_file% 1 Windows\WinSxS\%%~n# --dest-dir="!_DIR!\_tSSU" --no-acls --no-attributes %_Nul3%
)
pushd "!_DIR!"
:ssuouter86
:DDCdual
for /f %%# in ('dir /b /ad "_tSSU\x86_microsoft-windows-servicingstack_*"') do set "src=%%#"
for %%# in (%_MSUdll%) do move /y "_tSSU\%src%\%%#" "_tSSU\111\%%#" %_Nul1%
call :crDDF %_MSUddd%
call :apDDF _tSSU\111
%_Null% makecab.exe /F zzz.ddf /D Compress=ON /D CompressionType=MSZIP
if %ERRORLEVEL% neq 0 (set _mcfail=1&echo ʧ�ܣ������ò�����&exit /b)
rmdir /s /q "_tSSU\" %_Nul3%
exit /b

:crDDF
echo.
echo �������ɣ�%~nx1
(echo .Set DiskDirectoryTemplate="."
echo .Set CabinetNameTemplate="%1"
echo .Set MaxCabinetSize=0
echo .Set MaxDiskSize=0
echo .Set FolderSizeThreshold=0
echo .Set RptFileName=nul
echo .Set InfFileName=nul
echo .Set Cabinet=ON
)>zzz.ddf
exit /b

:apDDF
(echo .Set SourceDir="%1"
echo "dpx.dll"
echo "ReserveManager.dll"
echo "TurboStack.dll"
echo "UpdateAgent.dll"
echo "wcp.dll"
)>>zzz.ddf
exit /b

:update
if %W10UI% equ 0 exit /b
set directcab=0
set wim=0
set dvd=0
set _tgt=
set _tgt=%1
if defined _tgt (
    set wim=1
    set _target=%1
) else (
    set dvd=1
    set _target=ISOFOLDER
)
if %dvd% equ 1 (
    for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info "%_target%\sources\install.wim" ^| findstr /c:"Image Count"') do set imgcount=%%#
)
if %wim% equ 1 (
    for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info "%_tgt%" ^| findstr /c:"Image Count"') do set imgcount=%%#
)
if %wim% equ 0 goto :dvdup
call :mount "%_target%"

:dvdup
if %dvd% equ 0 goto :nodvd
if not exist "%SystemRoot%\temp\" mkdir "%SystemRoot%\temp" %_Nul3%
if exist "%SystemRoot%\temp\UpdateAgent.dll" del /f /q "%SystemRoot%\temp\UpdateAgent.dll" %_Nul3%
if exist "%SystemRoot%\temp\Facilitator.dll" del /f /q "%SystemRoot%\temp\Facilitator.dll" %_Nul3%
call :mount "%_target%\sources\install.wim"
if %AddEdition% equ 1 for /l %%# in (%imgcount%,-1,1) do %_dism1% /Delete-Image /ImageFile:"%_target%\sources\install.wim" /Index:%%# %_Nul3%

:nodvd
if exist "%_mount%\" rmdir /s /q "%_mount%\"
if %_build% geq 19041 if %winbuild% lss 17133 if exist "%SysPath%\ext-ms-win-security-slc-l1-1-0.dll" (
    del /f /q %SysPath%\ext-ms-win-security-slc-l1-1-0.dll %_Nul3%
    if /i not %xOS%==x86 del /f /q %SystemRoot%\SysWOW64\ext-ms-win-security-slc-l1-1-0.dll %_Nul3%
)
echo.
if %wim% equ 1 exit /b
if %isomin% lss %revmin% set isover=%revver%
if %isomaj% lss %revmaj% set isover=%revver%
set _label=%isover%
call :setlabel
exit /b

:extract
if not exist "!_cabdir!\" mkdir "!_cabdir!"
set _cab=0
if %UseMSU% equ 1 if %_build% geq 21382 if exist "!_DIR!\*Windows1*-KB*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "!_DIR!\*Windows1*-KB*.msu"') do (set "package=%%#"&call :sum2msu)
if exist "!_DIR!\SSU-*-*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_DIR!\SSU-*-*.cab"') do (call set /a _cab+=1)
if exist "!_DIR!\*Windows1*-KB*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_DIR!\*Windows1*-KB*.cab"') do (set "pkgn=%%~n#"&call :sum2cab)
set count=0&set isoupdate=&set tmpcmp=
if %UseMSU% equ 1 if %_build% geq 21382 if exist "!_DIR!\*Windows1*-KB*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "!_DIR!\*Windows1*-KB*.msu"') do (set "pkgn=%%~n#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :msu2)
if exist "!_DIR!\SSU-*-*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_DIR!\SSU-*-*.cab"') do (set "pkgn=%%~n#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :cab2)
if exist "!_DIR!\*Windows1*-KB*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_DIR!\*Windows1*-KB*.cab"') do (set "pkgn=%%~n#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :cab2)
if defined tmpcmp if exist "!_DIR!\Windows10.0-*%arch%_inout.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_DIR!\Windows10.0-*%arch%_inout.cab"') do (set "pkgn=%%~n#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :cab2)
if defined tmpcmp if exist "!_DIR!\Windows11.0-*%arch%_inout.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_DIR!\Windows11.0-*%arch%_inout.cab"') do (set "pkgn=%%~n#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :cab2)
goto :eof

:sum2msu
expand.exe -d -f:*Windows*.psf "!_DIR!\%package%" | findstr /i %arch%\.psf %_Nul3% || goto :eof
call set /a _cab+=1
goto :eof

:sum2cab
for /f "tokens=2 delims=-" %%V in ('echo %pkgn%') do set pkgid=%%V
if %UseMSU% equ 1 if %_build% geq 21382 if exist "!_DIR!\*Windows1*%pkgid%*%arch%*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "!_DIR!\*Windows1*%pkgid%*%arch%*.msu"') do (
expand.exe -d -f:*Windows*.psf "!_DIR!\%%#" | findstr /i %arch%\.psf %_Nul3% && goto :eof
)
call set /a _cab+=1
goto :eof

:cab2
for /f "tokens=2 delims=-" %%V in ('echo %pkgn%') do set pkgid=%%V
if %UseMSU% equ 1 if %_build% geq 21382 if exist "!_DIR!\*Windows1*%pkgid%*%arch%*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "!_DIR!\*Windows1*%pkgid%*%arch%*.msu"') do (
    expand.exe -d -f:*Windows*.psf "!_DIR!\%%#" | findstr /i %arch%\.psf %_Nul3% && goto :eof
)
if defined cab_%pkgn% goto :eof
if exist "!dest!\" rmdir /s /q "!dest!\"
mkdir "!dest!"
set /a count+=1
7z.exe e "!_DIR!\%package%" -o"!dest!" update.mum %_Null%
if not exist "!dest!\update.mum" (
    expand.exe -f:*defender*.xml "!_DIR!\%package%" "!dest!" %_Null%
    if exist "!dest!\*defender*.xml" (
        echo [%count%/%_cab%] %package%
        expand.exe -f:* "!_DIR!\%package%" "!dest!" %_Null%
    ) else (
        if not defined cab_%pkgn% echo [%count%/%_cab%] %package% [��װ�ļ�����]
        set isoupdate=!isoupdate! "%package%"
        set cab_%pkgn%=1
        rmdir /s /q "!dest!\" %_Nul3%
    )
    goto :eof
)
expand.exe -f:*.psf.cix.xml "!_DIR!\%package%" "!dest!" %_Null%
if exist "!dest!\*.psf.cix.xml" (
    if not exist "!_DIR!\%pkgn%.psf" if not exist "!_DIR!\*%pkgid%*%arch%*.psf" (
        echo [%count%/%_cab%] %package% / PSF �ļ���ʧ
        goto :eof
    )
    if %psfnet% equ 0 (
        echo [%count%/%_cab%] %package% / PSFExtractor ������
        goto :eof
    )
    set psf_%pkgn%=1
)
expand.exe -f:toc.xml "!_DIR!\%package%" "!dest!" %_Null%
if exist "!dest!\toc.xml" (
    echo [%count%/%_cab%] %package% [��ϸ��°�]
    mkdir "!_cabdir!\lcu" %_Nul3%
    expand.exe -f:* "!_DIR!\%package%" "!_cabdir!\lcu" %_Null%
    if exist "!_cabdir!\lcu\SSU-*%arch%*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\SSU-*%arch%*.cab"') do (set "compkg=%%#"&call :inrenssu)
    if exist "!_cabdir!\lcu\*Windows1*-KB*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\*Windows1*-KB*.cab"') do (set "compkg=%%#"&call :inrenupd)
    rmdir /s /q "!_cabdir!\lcu\" %_Nul3%
    rmdir /s /q "!dest!\" %_Nul3%
    goto :eof
)
set "_type="
if %_build% geq 17763 findstr /i /m "WinPE" "!dest!\update.mum" %_Nul3% && (
    %_Nul3% findstr /i /m "Edition\"" "!dest!\update.mum"
    if errorlevel 1 (set "_type=[Safe OS]"&set uwinpe=1)
)
if not defined _type (
    expand.exe -f:*_microsoft-windows-sysreset_*.manifest "!_DIR!\%package%" "!dest!" %_Null%
    if exist "!dest!\*_microsoft-windows-sysreset_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (set "_type=[Safe OS]"&set uwinpe=1)
)
if not defined _type (
    expand.exe -f:*_microsoft-windows-i..dsetup-rejuvenation_*.manifest "!_DIR!\%package%" "!dest!" %_Null%
    if exist "!dest!\*_microsoft-windows-i..dsetup-rejuvenation_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (set "_type=[Safe OS]"&set uwinpe=1)
)
if not defined _type (
    findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% && (set "_type=[�����ۻ�����]"&set uwinpe=1)
)
if not defined _type (
    findstr /i /m "Package_for_WindowsExperienceFeaturePack" "!dest!\update.mum" %_Nul3% && set "_type=[UX ���������]"
)
if not defined _type (
    expand.exe -f:*_microsoft-windows-servicingstack_*.manifest "!_DIR!\%package%" "!dest!" %_Null%
    if exist "!dest!\*_microsoft-windows-servicingstack_*.manifest" (
        set "_type=[�����ջ����]"&set uwinpe=1
        findstr /i /m /c:"Microsoft-Windows-CoreEdition" "!dest!\update.mum" %_Nul3% || set _eosC=1
        findstr /i /m /c:"Microsoft-Windows-ProfessionalEdition" "!dest!\update.mum" %_Nul3% || set _eosP=1
        findstr /i /m /c:"Microsoft-Windows-PPIProEdition" "!dest!\update.mum" %_Nul3% || set _eosT=1
    )
)
if not defined _type (
    expand.exe -f:*_netfx4*.manifest "!_DIR!\%package%" "!dest!" %_Null%
    if exist "!dest!\*_netfx4*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || set "_type=[NetFx]"
)
if not defined _type (
    expand.exe -f:*_microsoft-windows-s..boot-firmwareupdate_*.manifest "!_DIR!\%package%" "!dest!" %_Null%
    if exist "!dest!\*_microsoft-windows-s..boot-firmwareupdate_*.manifest" set "_type=[��ȫ����]"
)
if not defined _type if %_build% geq 18362 (
    expand.exe -f:microsoft-windows-*enablement-package~*.mum "!_DIR!\%package%" "!dest!" %_Null%
    if exist "!dest!\microsoft-windows-*enablement-package~*.mum" set "_type=[��������]"
    if exist "!dest!\Microsoft-Windows-1909Enablement-Package~*.mum" set "_fixEP=18363"
    if exist "!dest!\Microsoft-Windows-20H2Enablement-Package~*.mum" set "_fixEP=19042"
    if exist "!dest!\Microsoft-Windows-21H1Enablement-Package~*.mum" set "_fixEP=19043"
    if exist "!dest!\Microsoft-Windows-21H2Enablement-Package~*.mum" set "_fixEP=19044"
    if exist "!dest!\Microsoft-Windows-22H2Enablement-Package~*.mum" if %_build% lss 22000 set "_fixEP=19045"
)
if %_build% geq 18362 if exist "!dest!\*enablement-package*.mum" (
    expand.exe -f:*_microsoft-windows-e..-firsttimeinstaller_*.manifest "!_DIR!\%package%" "!dest!" %_Null%
    if exist "!dest!\*_microsoft-windows-e..-firsttimeinstaller_*.manifest" set "_type=[�������� / EdgeChromium]"
)
if not defined _type (
    expand.exe -f:*_microsoft-windows-e..-firsttimeinstaller_*.manifest "!_DIR!\%package%" "!dest!" %_Null%
    if exist "!dest!\*_microsoft-windows-e..-firsttimeinstaller_*.manifest" set "_type=[EdgeChromium]"
)
if not defined _type (
    expand.exe -f:*_adobe-flash-for-windows_*.manifest "!_DIR!\%package%" "!dest!" %_Null%
    if exist "!dest!\*_adobe-flash-for-windows_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || set "_type=[Flash]"
)
echo [%count%/%_cab%] %package% %_type%
set cab_%pkgn%=1
expand.exe -f:* "!_DIR!\%package%" "!dest!" %_Null% || (
    rmdir /s /q "!dest!\" %_Nul3%
    set directcab=!directcab! %package%
    goto :eof
)
7z.exe e "!_DIR!\%package%" -o"!dest!" update.mum -aoa %_Null%
if exist "!dest!\*cablist.ini" expand.exe -f:* "!dest!\*.cab" "!dest!" %_Null% || (
    rmdir /s /q "!dest!\" %_Nul3%
    set directcab=!directcab! %package%
    goto :eof
)
if exist "!dest!\*cablist.ini" (
    del /f /q "!dest!\*cablist.ini" %_Nul3%
    del /f /q "!dest!\*.cab" %_Nul3%
)
set _sbst=0
if defined psf_%pkgn% (
    if not exist "!dest!\express.psf.cix.xml" for /f %%# in ('dir /b /a:-d "!dest!\*.psf.cix.xml"') do rename "!dest!\%%#" express.psf.cix.xml %_Nul3%
    subst %_sdr% "!_cabdir!" %_Nul3% && set _sbst=1
    if !_sbst! equ 1 pushd %_sdr%
    if not exist "%package%" (
        copy /y "!_DIR!\%pkgn%.*" . %_Nul3%
        if not exist "%pkgn%.psf" for /f %%# in ('dir /b /a:-d "!_DIR!\*%pkgid%*%arch%*.psf"') do copy /y "!_DIR!\%%#" %pkgn%.psf %_Nul3%
    )
    if not exist "PSFExtractor.exe" copy /y "!_work!\bin\PSFExtractor.*" . %_Nul3%
    PSFExtractor.exe %package% %_Null%
    if !errorlevel! neq 0 (
        echo ���ִ��󣺽�ѹ PSF ����ʧ��
        rmdir /s /q "%pkgn%\" %_Nul3%
        set psf_%pkgn%=
    )
    if !_sbst! equ 1 popd
    if !_sbst! equ 1 subst %_sdr% /d %_Nul3%
)
goto :eof

:msu2
if defined msu_%pkgn% goto :eof
if exist "!dest!\" rmdir /s /q "!dest!\"
mkdir "!dest!"
expand.exe -d -f:*Windows*.psf "!_DIR!\%package%" | findstr /i %arch%\.psf %_Nul3% || goto :eof
set /a count+=1
echo [%count%/%_cab%] %package% [�ۻ�����(MSU)]
mkdir "!_cabdir!\lcu" %_Nul3%
expand.exe -f:*Windows*.cab "!_DIR!\%package%" "!_cabdir!\lcu" %_Null%
for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\*Windows1*-KB*.cab"') do set "compkg=%%#"
7z.exe e "!_cabdir!\lcu\%compkg%" -o"!dest!" update.mum %_Null%
expand.exe -f:SSU-*%arch%*.cab "!_DIR!\%package%" "!_cabdir!\lcu" %_Null%
if exist "!_cabdir!\lcu\SSU-*%arch%*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\SSU-*%arch%*.cab"') do (set "compkg=%%#"&call :inrenssu)
rmdir /s /q "!_cabdir!\lcu\" %_Nul3%
set msu_%pkgn%=1
goto :eof

:inrenupd
for /f "tokens=2 delims=-" %%V in ('echo %compkg%') do set kbupd=%%V
set _ufn=Windows10.0-%kbupd%-%arch%_inout.cab
echo %compkg%| findstr /i "Windows11\." %_Nul1% && set _ufn=Windows11.0-%kbupd%-%arch%_inout.cab
if exist "!_DIR!\%_ufn%" goto :eof
call set /a _cab+=1
set "tmpcmp=!tmpcmp! %_ufn%"
move /y "!_cabdir!\lcu\%compkg%" "!_DIR!\%_ufn%" %_Nul3%
goto :eof

:inrenssu
if exist "!_DIR!\%compkg:~0,-4%*.cab" goto :eof
set kbupd=
expand.exe -f:update.mum "!_cabdir!\lcu\%compkg%" "!_cabdir!\lcu" %_Null%
if not exist "!_cabdir!\lcu\update.mum" goto :eof
for /f "tokens=3 delims== " %%# in ('findstr /i releaseType "!_cabdir!\lcu\update.mum"') do set kbupd=%%~#
if "%kbupd%"=="" goto :eof
set _ufn=Windows10.0-%kbupd%-%arch%_inout.cab
dir /b /on "!_cabdir!\lcu\*Windows1*-KB*.cab" %_Nul2% | findstr /i "Windows11\." %_Nul1% && set _ufn=Windows11.0-%kbupd%-%arch%_inout.cab
if exist "!_DIR!\%_ufn%" goto :eof
call set /a _cab+=1
set "tmpcmp=!tmpcmp! %_ufn%"
move /y "!_cabdir!\lcu\%compkg%" "!_DIR!\%_ufn%" %_Nul3%
goto :eof

:updatewim
set mumtarget=%_mount%
set dismtarget=/Image:"%_mount%"
set SOFTWARE=uiSOFTWARE
set COMPONENTS=uiCOMPONENTS
set "_Wnn=HKLM\%SOFTWARE%\Microsoft\Windows\CurrentVersion\SideBySide\Winners"
set "_Cmp=HKLM\%COMPONENTS%\DerivedData\Components"
if exist "%mumtarget%\Windows\Servicing\Packages\*arm64*.mum" (
    set "xBT=arm64"
    set "_EsuKey=%_Wnn%\arm64_%_EsuCmp%_%_Pkt%_none_0a0357560ca88a4d"
    set "_EdgKey=%_Wnn%\arm64_%_EdgCmp%_%_Pkt%_none_1e5e2b2c8adcf701"
    set "_CedKey=%_Wnn%\arm64_%_CedCmp%_%_Pkt%_none_df3eefecc502346d"
) else if exist "%mumtarget%\Windows\Servicing\Packages\*amd64*.mum" (
    set "xBT=amd64"
    set "_EsuKey=%_Wnn%\amd64_%_EsuCmp%_%_Pkt%_none_0a0357560ca88a4d"
    set "_EdgKey=%_Wnn%\amd64_%_EdgCmp%_%_Pkt%_none_1e5e22f28add0265"
    set "_CedKey=%_Wnn%\amd64_%_CedCmp%_%_Pkt%_none_df3ee7b2c5023fd1"
) else (
    set "xBT=x86"
    set "_EsuKey=%_Wnn%\x86_%_EsuCmp%_%_Pkt%_none_ade4bbd2544b1917"
    set "_EdgKey=%_Wnn%\x86_%_EdgCmp%_%_Pkt%_none_c23f876ed27f912f"
    set "_CedKey=%_Wnn%\x86_%_CedCmp%_%_Pkt%_none_83204c2f0ca4ce9b"
)
for /f "tokens=4,5,6 delims=_" %%H in ('dir /b "%mumtarget%\Windows\WinSxS\Manifests\%xBT%_microsoft-windows-foundation_*.manifest"') do set "_Fnd=microsoft-w..-foundation_%_Pkt%_%%H_%%~nJ"
set mpamfe=
set lcumsu=
set servicingstack=
set cumulative=
set netpack=
set netroll=
set netlcu=
set netmsu=
set secureboot=
set edge=
set safeos=
set callclean=
set supdt=
set overall=
set lcupkg=
set ldr=
set mounterr=
set LTSC=0
if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
    if %_build% neq 14393 if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-PPIProEdition~*.mum" set LTSC=1
    if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-EnterpriseS*Edition~*.mum" set LTSC=1
    if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-IoTEnterpriseS*Edition~*.mum" set LTSC=1
    if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-Server*Edition~*.mum" set LTSC=1
    if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-Server*ACorEdition~*.mum" set LTSC=0
)
if exist "!_DIR!\SSU-*-*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_DIR!\SSU-*-*.cab"') do (set "pckn=%%~n#"&set "packx=%%~x#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :procmum)
if exist "!_DIR!\*Windows1*-KB*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_DIR!\*Windows1*-KB*.cab"') do (set "pckn=%%~n#"&set "packx=%%~x#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :procmum)
if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" if %UseMSU% equ 1 if %_build% geq 21382 if exist "!_DIR!\*Windows1*-KB*.msu" (for /f "tokens=* delims=" %%# in ('dir /b /on "!_DIR!\*Windows1*-KB*.msu"') do if defined msu_%%~n# (set "pckn=%%~n#"&set "packx=%%~x#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :procmum))
if %_build% geq 19041 if %winbuild% lss 17133 if not exist "%SysPath%\ext-ms-win-security-slc-l1-1-0.dll" (
    copy /y %SysPath%\slc.dll %SysPath%\ext-ms-win-security-slc-l1-1-0.dll %_Nul1%
    if /i not %xOS%==x86 copy /y %SystemRoot%\SysWOW64\slc.dll %SystemRoot%\SysWOW64\ext-ms-win-security-slc-l1-1-0.dll %_Nul1%
)
if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
    reg.exe load HKLM\%SOFTWARE% "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
    if %winbuild% lss 15063 if /i %arch%==arm64 reg.exe add HKLM\%SOFTWARE%\Microsoft\Windows\CurrentVersion\SideBySide /v AllowImproperDeploymentProcessorArchitecture /t REG_DWORD /d 1 /f %_Nul1%
    if %winbuild% lss 9600 reg.exe add HKLM\%SOFTWARE%\Microsoft\Windows\CurrentVersion\SideBySide /v AllowImproperDeploymentProcessorArchitecture /t REG_DWORD /d 1 /f %_Nul
    reg.exe save HKLM\%SOFTWARE% "%mumtarget%\Windows\System32\Config\SOFTWARE2" %_Nul1%
    reg.exe unload HKLM\%SOFTWARE% %_Nul1%
    move /y "%mumtarget%\Windows\System32\Config\SOFTWARE2" "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
)
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
    reg.exe load HKLM\%SOFTWARE% "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
    reg.exe add HKLM\%SOFTWARE%\%_SxsCfg% /v DisableComponentBackups /t REG_DWORD /d 1 /f %_Nul1%
    reg.exe unload HKLM\%SOFTWARE% %_Nul1%
)
if defined netpack set "ldr=!netpack! !ldr!"
for %%# in (supdt,safeos,secureboot,edge,ldr,cumulative,lcumsu) do if defined %%# set overall=1
if not defined overall if not defined mpamfe if not defined servicingstack goto :eof
if defined servicingstack (
    if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" if !iswre! equ 1 if not defined safeos (
        %_dism1% /Unmount-Wim /MountDir:"%_mount%" /Discard
        goto :WinreRet
    )
    set callclean=1
    %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismSSU.log" /Add-Package %servicingstack%
    cmd /c exit /b !errorlevel!
    if /i not "!=ExitCode!"=="00000000" if /i not "!=ExitCode!"=="800f081e" goto :errmount
    if not defined overall call :cleanup
)
if not defined overall if not defined mpamfe goto :eof
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" if !iswre! equ 1 if defined safeos (
    set callclean=1
    %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismWinPE.log" /Add-Package %safeos%
    cmd /c exit /b !errorlevel!
    if /i not "!=ExitCode!"=="00000000" if /i not "!=ExitCode!"=="800f081e" goto :errmount
    call :cleanup
    if %ResetBase% neq 0 %_dism2%:"!_cabdir!" %dismtarget% /Cleanup-Image /StartComponentCleanup /ResetBase %_Null%
    goto :eof
)
if defined secureboot (
    set callclean=1
    %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismSecureBoot.log" /Add-Package %secureboot%
    cmd /c exit /b !errorlevel!
    if /i not "!=ExitCode!"=="00000000" if /i not "!=ExitCode!"=="800f081e" goto :errmount
)
if defined ldr (
    set callclean=1
    %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismUpdt.log" /Add-Package %ldr%
    cmd /c exit /b !errorlevel!
    if /i not "!=ExitCode!"=="00000000" if /i not "!=ExitCode!"=="800f081e" if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :errmount
)
if defined supdt (
    set "_SxsKey=%_EsuKey%"
    set "_SxsCmp=%_EsuCmp%"
    set "_SxsIdn=%_EsuIdn%"
    set "_SxsCF=64"
    set "_DsmLog=DismLCUs.log"
    for %%# in (%supdt%) do (set "cbsn=%%~n#"&set "dest=!_cabdir!\%%~n#"&call :pXML)
)
set "_DsmLog=DismLCU.log"
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" set "_DsmLog=DismLCU_winpe.log"
if not defined cumulative if not defined lcumsu goto :cumwd
set callclean=1
if defined cumulative %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\%_DsmLog%" /Add-Package %cumulative%
if defined lcumsu for %%# in (%lcumsu%) do (
echo.&echo %%#
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\%_DsmLog%" /Add-Package /PackagePath:"!_DIR!\%%#"
)
cmd /c exit /b !errorlevel!
if /i not "!=ExitCode!"=="00000000" if /i not "!=ExitCode!"=="800f081e" if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :errmount
:cumwd
if defined lcupkg call :ReLCU
if defined callclean call :cleanup
if defined mpamfe (
    echo.
    echo ������� Defender ���¡���
    call :defender_update
)
if not defined edge goto :eof
if defined edge (
    %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismEdge.log" /Add-Package %edge%
    cmd /c exit /b !errorlevel!
    if /i not "!=ExitCode!"=="00000000" if /i not "!=ExitCode!"=="800f081e" goto :errmount
)
goto :eof

:errmount
set mounterr=1
%_dism1% %dismtarget% /Get-Packages %_Null%
%_dism1% /Unmount-Wim /MountDir:"%_mount%" /Discard
%_dism1% /Cleanup-Wim %_Nul3%
goto :eof
rmdir /s /q "%_mount%\" %_Nul3%
set AddUpdates=0
set FullExit=exit
goto :%_rtrn%

:ReLCU
if exist "!lcudir!\update.mum" if exist "!lcudir!\*.manifest" goto :eof
if not exist "!lcudir!\" mkdir "!lcudir!"
expand.exe -f:* "!_DIR!\%lcupkg%" "!lcudir!" %_Null%
7z.exe e "!_DIR!\%lcupkg%" -o"!lcudir!" update.mum -aoa %_Null%
if exist "!lcudir!\*cablist.ini" (
    expand.exe -f:* "!lcudir!\*.cab" "!lcudir!" %_Null%
    del /f /q "!lcudir!\*cablist.ini" %_Nul3%
    del /f /q "!lcudir!\*.cab" %_Nul3%
)
set _sbst=0
for /f "tokens=2 delims=-" %%V in ('echo %lcupkg%') do set lcuid=%%V
if exist "!lcudir!\*.psf.cix.xml" (
    if not exist "!lcudir!\express.psf.cix.xml" for /f %%# in ('dir /b /a:-d "!lcudir!\*.psf.cix.xml"') do rename "!lcudir!\%%#" express.psf.cix.xml %_Nul3%
    subst %_sdr% "!_cabdir!" %_Nul3% && set _sbst=1
    if !_sbst! equ 1 pushd %_sdr%
    if not exist "%lcupkg%" (
        copy /y "!_DIR!\%lcupkg:~0,-4%.*" . %_Nul3%
        if not exist "%lcupkg:~0,-4%.psf" for /f %%# in ('dir /b /a:-d "!_DIR!\*%lcuid%*%arch%*.psf"') do copy /y "!_DIR!\%%#" %lcupkg:~0,-4%.psf %_Nul3%
    )
    if not exist "PSFExtractor.exe" copy /y "!_work!\bin\PSFExtractor.*" . %_Nul3%
    PSFExtractor.exe %lcupkg% %_Null%
    if !_sbst! equ 1 popd
    if !_sbst! equ 1 subst %_sdr% /d %_Nul3%
)
goto :eof

:procmum
if exist "!dest!\*.psf.cix.xml" if not defined psf_%pckn% goto :eof
if exist "!dest!\*defender*.xml" (
    if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :eof
    call :defender_check
    goto :eof
)
if not exist "!dest!\update.mum" (
    if /i "!lcupkg!"=="%package%" call :ReLCU
)
set _dcu=0
if not exist "!dest!\update.mum" (
    for %%# in (%directcab%) do if /i "%package%"=="%%~#" set _dcu=1
    if "!_dcu!"=="0" goto :eof
)
set xmsu=0
if /i "%packx%"==".msu" set xmsu=1
for /f "tokens=2 delims=-" %%V in ('echo %pckn%') do set pckid=%%V
if %xmsu% equ 1 if %UseMSU% equ 1 if %_build% geq 21382 if exist "!_DIR!\*Windows1*%pckid%*%arch%*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "!_DIR!\*Windows1*%pckid%*%arch%*.msu"') do (
expand.exe -d -f:*Windows*.psf "!_DIR!\%%#" | findstr /i %arch%\.psf %_Nul3% && goto :eof
)
if %_build% geq 17763 if exist "!dest!\update.mum" if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
    findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (findstr /i /m "Microsoft-Windows-NetFx" "!dest!\*.mum" %_Nul3% && if not exist "!dest!\*_netfx4clientcorecomp.resources*.manifest" (
            if exist "!dest!\*_*10.0.*.manifest" (set "netroll=!netroll! /PackagePath:!dest!\update.mum") else (if exist "!dest!\*_*11.0.*.manifest" set "netroll=!netroll! /PackagePath:!dest!\update.mum")
        ))
    findstr /i /m "Package_for_OasisAsset" "!dest!\update.mum" %_Nul3% && (if not exist "%mumtarget%\Windows\Servicing\packages\*OasisAssets-Package*.mum" goto :eof)
    findstr /i /m "WinPE" "!dest!\update.mum" %_Nul3% && (
        %_Nul3% findstr /i /m "Edition\"" "!dest!\update.mum"
    if errorlevel 1 goto :eof
    )
)
if %_build% geq 19041 if exist "!dest!\update.mum" if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
    findstr /i /m "Package_for_WindowsExperienceFeaturePack" "!dest!\update.mum" %_Nul3% && (
        if not exist "%mumtarget%\Windows\Servicing\packages\Microsoft-Windows-UserExperience-Desktop*.mum" goto :eof
        set fxupd=0
        for /f "tokens=3 delims== " %%# in ('findstr /i "Edition" "!dest!\update.mum" %_Nul6%') do if exist "%mumtarget%\Windows\Servicing\packages\%%~#*.mum" set fxupd=1
        if "!fxupd!"=="0" goto :eof
    )
)
if exist "!dest!\*_microsoft-windows-servicingstack_*.manifest" (
    set "servicingstack=!servicingstack! /PackagePath:!dest!\update.mum"
    goto :eof
)
if exist "!dest!\*_netfx4-netfx_detectionkeys_extended*.manifest" if exist "!dest!\*_netfx4clientcorecomp.resources*_en-us_*.manifest" (
    if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :eof
    set "netpack=!netpack! /PackagePath:!dest!\update.mum"
    goto :eof
)
if exist "!dest!\*_%_EdgCmp%_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (
    if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :eof
    if exist "!dest!\*enablement-package*.mum" (
        for /f %%# in ('dir /b /a:-d "!dest!\*enablement-package~*.mum"') do set "ldr=!ldr! /PackagePath:!dest!\%%#"
        set "edge=!edge! /PackagePath:!dest!\update.mum"
    )
    if not exist "!dest!\*enablement-package*.mum" set "edge=!edge! /PackagePath:!dest!\update.mum"
    goto :eof
)
if exist "!dest!\*_microsoft-windows-sysreset_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (
    if not exist "%mumtarget%\Windows\Servicing\Packages\WinPE-SRT-Package~*.mum" goto :eof
    set "safeos=!safeos! /PackagePath:!dest!\update.mum"
    goto :eof
)
if exist "!dest!\*_microsoft-windows-i..dsetup-rejuvenation_*.manifest" if not exist "!dest!\*_microsoft-windows-sysreset_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (
    if not exist "%mumtarget%\Windows\Servicing\Packages\WinPE-Rejuv-Package~*.mum" goto :eof
    set "safeos=!safeos! /PackagePath:!dest!\update.mum"
    goto :eof
)
if exist "!dest!\*_microsoft-windows-s..boot-firmwareupdate_*.manifest" (
    if %winbuild% lss 9600 goto :eof
    if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :eof
    set secureboot=!secureboot! /PackagePath:"!_DIR!\%package%"
    goto :eof
)
if exist "!dest!\update.mum" if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
    findstr /i /m "WinPE" "!dest!\update.mum" %_Nul3% || (findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (goto :eof))
    findstr /i /m "WinPE-NetFx-Package" "!dest!\update.mum" %_Nul3% && (findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (goto :eof))
)
if exist "!dest!\*_adobe-flash-for-windows_*.manifest" if not exist "!dest!\*enablement-package*.mum" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (
    if not exist "%mumtarget%\Windows\Servicing\packages\Adobe-Flash-For-Windows-Package*.mum" if not exist "%mumtarget%\Windows\Servicing\packages\Microsoft-Windows-Client-Desktop-Required-Package*.mum" goto :eof
    if %_build% geq 16299 (
        set flash=0
        for /f "tokens=3 delims== " %%# in ('findstr /i "Edition" "!dest!\update.mum" %_Nul6%') do if exist "%mumtarget%\Windows\Servicing\packages\%%~#*.mum" set flash=1
        if "!flash!"=="0" goto :eof
    )
)
for %%# in (%directcab%) do (
    if /i "%package%"=="%%~#" (
        set "cumulative=!cumulative! /PackagePath:"!_DIR!\%package%""
        goto :eof
    )
)
if exist "!dest!\update.mum" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% && (
    if %_build% geq 20231 (
        set "lcudir=!dest!"
        set "lcupkg=%package%"
    )
    if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
        if %xmsu% equ 1 (set "lcumsu=!lcumsu! %package%") else (set "cumulative=!cumulative! /PackagePath:!dest!\update.mum")
        goto :eof
    )
    if %xmsu% equ 1 (
        set "lcumsu=!lcumsu! %package%"
        set "netmsu=!netmsu! %package%"
        goto :eof
    ) else (
        set "netlcu=!netlcu! /PackagePath:!dest!\update.mum"
    )
    if exist "!dest!\*_%_EsuCmp%_*.manifest" if not exist "!dest!\*_%_CedCmp%_*.manifest" if %LTSC% equ 0 (set "supdt=!supdt! %package%"&goto :eof)
    if exist "!dest!\*_%_EsuCmp%_*.manifest" if exist "!dest!\*_%_CedCmp%_*.manifest" if %LTSC% equ 0 (set "supdt=!supdt! %package%"&goto :eof)
    set "cumulative=!cumulative! /PackagePath:!dest!\update.mum"
    goto :eof
)
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (set "ldr=!ldr! /PackagePath:!dest!\update.mum"&goto :eof)
if exist "!dest!\*_%_EsuCmp%_*.manifest" if %LTSC% equ 0 (set "supdt=!supdt! %package%"&goto :eof)
set "ldr=!ldr! /PackagePath:!dest!\update.mum"
goto :eof

:defender_check
if %_skpp% equ 1 if %_skpd% equ 1 (set /a _sum-=1&goto :eof)
set "_MWD=ProgramData\Microsoft\Windows Defender"
if not exist "%mumtarget%\%_MWD%\Definition Updates\Updates\*.vdm" (set "mpamfe=!dest!"&goto :eof)
if %_skpp% equ 0 dir /b /ad "%mumtarget%\%_MWD%\Platform\*.*.*.*" %_Nul3% && (
    if not exist "!_cabdir!\*defender*.xml" expand.exe -f:*defender*.xml "!_DIR!\%package%" "!_cabdir!" %_Null%
    for /f %%i in ('dir /b /a:-d "!_cabdir!\*defender*.xml"') do for /f "tokens=3 delims=<> " %%# in ('type "!_cabdir!\%%i" ^| find /i "platform"') do (
        dir /b /ad "%mumtarget%\%_MWD%\Platform\%%#*" %_Nul3% && set _skpp=1
    )
)
set "_ver1j=0"&set "_ver1n=0"
set "_ver2j=0"&set "_ver2n=0"
set "_fil1=%mumtarget%\%_MWD%\Definition Updates\Updates\mpavdlta.vdm"
set "_fil2=!_cabdir!\mpavdlta.vdm"
set "cfil1=!_fil1:\=\\!"
set "cfil2=!_fil2:\=\\!"
if %_skpd% equ 0 if exist "!_fil1!" (
    if %winbuild% lss 22483 for /f "tokens=3,4 delims==." %%a in ('wmic datafile where "name='!cfil1!'" get Version /value ^| find "="') do set "_ver1j=%%a"&set "_ver1n=%%b"
    if %winbuild% geq 22483 for /f "tokens=2,3 delims=." %%a in ('powershell -nop -c "([WMI]'CIM_DataFile.Name=\"!cfil1!\"').Version"') do set "_ver1j=%%a"&set "_ver1n=%%b"
    expand.exe -i -f:mpavdlta.vdm "!_DIR!\%package%" "!_cabdir!" %_Null%
)
if exist "!_fil2!" (
    if %winbuild% lss 22483 for /f "tokens=3,4 delims==." %%a in ('wmic datafile where "name='!cfil2!'" get Version /value ^| find "="') do set "_ver2j=%%a"&set "_ver2n=%%b"
    if %winbuild% geq 22483 for /f "tokens=2,3 delims=." %%a in ('powershell -nop -c "([WMI]'CIM_DataFile.Name=\"!cfil2!\"').Version"') do set "_ver2j=%%a"&set "_ver2n=%%b"
)
if %_ver1j% gtr %_ver2j% set _skpd=1
if %_ver1j% equ %_ver2j% if %_ver1n% geq %_ver2n% set _skpd=1
if %_skpp% equ 1 if %_skpd% equ 1 (set /a _sum-=1&goto :eof)
set "mpamfe=!dest!"
goto :eof

:defender_update
xcopy /CIRY "!mpamfe!\Definition Updates\Updates" "%mumtarget%\%_MWD%\Definition Updates\Updates\" %_Nul3%
if exist "%mumtarget%\%_MWD%\Definition Updates\Updates\MpSigStub.exe" del /f /q "%mumtarget%\%_MWD%\Definition Updates\Updates\MpSigStub.exe" %_Nul3%
xcopy /ECIRY "!mpamfe!\Platform" "%mumtarget%\%_MWD%\Platform\" %_Nul3%
for /f %%# in ('dir /b /ad "!mpamfe!\Platform\*.*.*.*"') do set "_wdplat=%%#"
if exist "%mumtarget%\%_MWD%\Platform\%_wdplat%\MpSigStub.exe" del /f /q "%mumtarget%\%_MWD%\Platform\%_wdplat%\MpSigStub.exe" %_Nul3%
if not exist "!mpamfe!\Platform\%_wdplat%\ConfigSecurityPolicy.exe" copy /y "%mumtarget%\Program Files\Windows Defender\ConfigSecurityPolicy.exe" "%mumtarget%\%_MWD%\Platform\%_wdplat%\" %_Nul3%
if not exist "!mpamfe!\Platform\%_wdplat%\MpAsDesc.dll" copy /y "%mumtarget%\Program Files\Windows Defender\MpAsDesc.dll" "%mumtarget%\%_MWD%\Platform\%_wdplat%\" %_Nul3%
if not exist "!mpamfe!\Platform\%_wdplat%\MpEvMsg.dll" copy /y "%mumtarget%\Program Files\Windows Defender\MpEvMsg.dll" "%mumtarget%\%_MWD%\Platform\%_wdplat%\" %_Nul3%
if not exist "!mpamfe!\Platform\%_wdplat%\ProtectionManagement.dll" copy /y "%mumtarget%\Program Files\Windows Defender\ProtectionManagement.dll" "%mumtarget%\%_MWD%\Platform\%_wdplat%\" %_Nul3%
for /f %%A in ('dir /b /ad "%mumtarget%\Program Files\Windows Defender\*-*"') do (
    if not exist "%mumtarget%\%_MWD%\Platform\%_wdplat%\%%A\" mkdir "%mumtarget%\%_MWD%\Platform\%_wdplat%\%%A" %_Nul3%
    if not exist "!mpamfe!\Platform\%_wdplat%\%%A\MpAsDesc.dll.mui" copy /y "%mumtarget%\Program Files\Windows Defender\%%A\MpAsDesc.dll.mui" "%mumtarget%\%_MWD%\Platform\%_wdplat%\%%A\" %_Nul3%
    if not exist "!mpamfe!\Platform\%_wdplat%\%%A\MpEvMsg.dll.mui" copy /y "%mumtarget%\Program Files\Windows Defender\%%A\MpEvMsg.dll.mui" "%mumtarget%\%_MWD%\Platform\%_wdplat%\%%A\" %_Nul3%
    if not exist "!mpamfe!\Platform\%_wdplat%\%%A\ProtectionManagement.dll.mui" copy /y "%mumtarget%\Program Files\Windows Defender\%%A\ProtectionManagement.dll.mui" "%mumtarget%\%_MWD%\Platform\%_wdplat%\%%A\" %_Nul3%
)
if /i %arch%==x86 goto :eof
if not exist "!mpamfe!\Platform\%_wdplat%\x86\MpAsDesc.dll" copy /y "%mumtarget%\Program Files (x86)\Windows Defender\MpAsDesc.dll" "%mumtarget%\%_MWD%\Platform\%_wdplat%\x86\" %_Nul3%
for /f %%A in ('dir /b /ad "%mumtarget%\Program Files (x86)\Windows Defender\*-*"') do (
    if not exist "%mumtarget%\%_MWD%\Platform\%_wdplat%\x86\%%A\" mkdir "%mumtarget%\%_MWD%\Platform\%_wdplat%\x86\%%A" %_Nul3%
    if not exist "!mpamfe!\Platform\%_wdplat%\x86\%%A\MpAsDesc.dll.mui" copy /y "%mumtarget%\Program Files (x86)\Windows Defender\%%A\MpAsDesc.dll.mui" "%mumtarget%\%_MWD%\Platform\%_wdplat%\x86\%%A\" %_Nul3%
)
goto :eof

:pXML
if %_build% neq 18362 (
    call :cXML stage
    echo.
    echo ���ڴ��� [1/1] - �����ݴ� %cbsn%
    %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\%_DsmLog%" /Apply-Unattend:"!_cabdir!\stage.xml"
    if !errorlevel! neq 0 if !errorlevel! neq 3010 goto :eof
)
if %_build% neq 18362 (call :Winner) else (call :Suppress)
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\%_DsmLog%" /Add-Package /PackagePath:"!dest!\update.mum"
if %_build% neq 18362 (del /f /q "!_cabdir!\stage.xml" %_Nul3%)
goto :eof

:cXML
(
echo.^<?xml version="1.0" encoding="utf-8"?^>
echo.^<unattend xmlns="urn:schemas-microsoft-com:unattend"^>
echo.    ^<servicing^>
echo.        ^<package action="%1"^>
)>"!_cabdir!\%1.xml"
findstr /i Package_for_RollupFix "!dest!\update.mum" %_Nul3% && (
findstr /i Package_for_RollupFix "!dest!\update.mum" >>"!_cabdir!\%1.xml"
)
findstr /i Package_for_RollupFix "!dest!\update.mum" %_Nul3% || (
findstr /i Package_for_KB "!dest!\update.mum" | findstr /i /v _RTM >>"!_cabdir!\%1.xml"
)
(
echo.            ^<source location="!dest!\update.mum" /^>
echo.        ^</package^>
echo.     ^</servicing^>
echo.^</unattend^>
)>>"!_cabdir!\%1.xml"
goto :eof

:Suppress
for /f %%# in ('dir /b /a:-d "!dest!\%xBT%_%_SxsCmp%_*.manifest"') do set "_SxsCom=%%~n#"
for /f "tokens=4 delims=_" %%# in ('echo %_SxsCom%') do set "_SxsVer=%%#"
if not exist "%mumtarget%\Windows\WinSxS\Manifests\%_SxsCom%.manifest" (
    %_Nul3% icacls "%mumtarget%\Windows\WinSxS\Manifests" /save "!_cabdir!\acl.txt"
    %_Nul3% takeown /f "%mumtarget%\Windows\WinSxS\Manifests" /A
    %_Nul3% icacls "%mumtarget%\Windows\WinSxS\Manifests" /grant:r "*S-1-5-32-544:(OI)(CI)(F)"
    %_Nul3% copy /y "!dest!\%_SxsCom%.manifest" "%mumtarget%\Windows\WinSxS\Manifests\"
    %_Nul3% icacls "%mumtarget%\Windows\WinSxS\Manifests" /setowner "NT SERVICE\TrustedInstaller"
    %_Nul3% icacls "%mumtarget%\Windows\WinSxS" /restore "!_cabdir!\acl.txt"
    %_Nul3% del /f /q "!_cabdir!\acl.txt"
)
reg.exe query HKLM\%COMPONENTS% %_Nul3% || reg.exe load HKLM\%COMPONENTS% "%mumtarget%\Windows\System32\Config\COMPONENTS" %_Nul3%
reg.exe query "%_Cmp%\%_SxsCom%" %_Nul3% && goto :Winner
for /f "skip=1 tokens=* delims=" %%# in ('certutil -hashfile "!dest!\%_SxsCom%.manifest" SHA256^|findstr /i /v CertUtil') do set "_SxsSha=%%#"
set "_SxsSha=%_SxsSha: =%"
set "_psin=%_SxsIdn%, Culture=neutral, Version=%_SxsVer%, PublicKeyToken=%_Pkt%, ProcessorArchitecture=%xBT%, versionScope=NonSxS"
for /f "tokens=* delims=" %%# in ('powershell -nop -c "$str = '%_psin%'; [BitConverter]::ToString([Text.Encoding]::ASCII.GetBytes($str))-replace'-'" %_Nul6%') do set "_SxsHsh=%%#"
%_Nul3% reg.exe add "%_Cmp%\%_SxsCom%" /f /v "c^!%_Fnd%" /t REG_BINARY /d ""
%_Nul3% reg.exe add "%_Cmp%\%_SxsCom%" /f /v identity /t REG_BINARY /d "%_SxsHsh%"
%_Nul3% reg.exe add "%_Cmp%\%_SxsCom%" /f /v S256H /t REG_BINARY /d "%_SxsSha%"
%_Nul3% reg.exe add "%_Cmp%\%_SxsCom%" /f /v CF /t REG_DWORD /d "%_SxsCF%"
for /f "tokens=* delims=" %%# in ('reg.exe query HKLM\%COMPONENTS%\DerivedData\VersionedIndex %_Nul6% ^| findstr /i VersionedIndex') do reg.exe delete "%%#" /f %_Nul3%

:Winner
for /f "tokens=4 delims=_" %%# in ('dir /b /a:-d "!dest!\%xBT%_%_SxsCmp%_*.manifest"') do (
    set "pv_al=%%#"
)
for /f "tokens=1-4 delims=." %%G in ('echo %pv_al%') do (
    set "pv_os=%%G.%%H"
    set "pv_mj=%%G"&set "pv_mn=%%H"&set "pv_bl=%%I"&set "pv_dl=%%J"
)
set kv_al=
reg.exe load HKLM\%SOFTWARE% "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul3%
if not exist "%mumtarget%\Windows\WinSxS\Manifests\%xBT%_%_SxsCmp%_*.manifest" goto :SkipChk
reg.exe query "%_SxsKey%" %_Nul3% || goto :SkipChk
reg.exe query HKLM\%COMPONENTS% %_Nul3% || reg.exe load HKLM\%COMPONENTS% "%mumtarget%\Windows\System32\Config\COMPONENTS" %_Nul3%
reg.exe query "%_Cmp%" /f "%xBT%_%_SxsCmp%_*" /k %_Nul2% | find /i "HKEY_LOCAL_MACHINE" %_Nul1% || goto :SkipChk
call :ChkESUver %_Nul3%
set "wv_bl=0"&set "wv_dl=0"
reg.exe query "%_SxsKey%\%pv_os%" /ve %_Nul2% | findstr \( | findstr \. %_Nul1% || goto :SkipChk
for /f "tokens=2*" %%a in ('reg.exe query "%_SxsKey%\%pv_os%" /ve ^| findstr \(') do set "wv_al=%%b"
for /f "tokens=1-4 delims=." %%G in ('echo %wv_al%') do (
    set "wv_mj=%%G"&set "wv_mn=%%H"&set "wv_bl=%%I"&set "wv_dl=%%J"
)

:SkipChk
reg.exe add "%_SxsKey%\%pv_os%" /f /v %pv_al% /t REG_BINARY /d 01 %_Nul3%
set skip_pv=0
if "%kv_al%"=="" (
    reg.exe add "%_SxsKey%\%pv_os%" /f /ve /d %pv_al% %_Nul3%
    reg.exe add "%_SxsKey%" /f /ve /d %pv_os% %_Nul3%
    goto :EndChk
)
if %pv_mj% lss %kv_mj% (
    set skip_pv=1
    if %pv_bl% geq %wv_bl% if %pv_dl% geq %wv_dl% reg.exe add "%_SxsKey%\%pv_os%" /f /ve /d %pv_al% %_Nul3%
)
if %pv_mj% equ %kv_mj% if %pv_mn% lss %kv_mn% (
    set skip_pv=1
    if %pv_bl% geq %wv_bl% if %pv_dl% geq %wv_dl% reg.exe add "%_SxsKey%\%pv_os%" /f /ve /d %pv_al% %_Nul3%
)
if %pv_mj% equ %kv_mj% if %pv_mn% equ %kv_mn% if %pv_bl% lss %kv_bl% (
    set skip_pv=1
)
if %pv_mj% equ %kv_mj% if %pv_mn% equ %kv_mn% if %pv_bl% equ %kv_bl% if %pv_dl% lss %kv_dl% (
    set skip_pv=1
)
if %skip_pv% equ 0 (
    reg.exe add "%_SxsKey%\%pv_os%" /f /ve /d %pv_al% %_Nul3%
    reg.exe add "%_SxsKey%" /f /ve /d %pv_os% %_Nul3%
)

:EndChk
if /i %xOS%==x86 if /i not %arch%==x86 (
    reg.exe save HKLM\%SOFTWARE% "%mumtarget%\Windows\System32\Config\SOFTWARE2" %_Nul1%
    reg.exe query HKLM\%COMPONENTS% %_Nul3% && reg.exe save HKLM\%COMPONENTS% "%mumtarget%\Windows\System32\Config\COMPONENTS2" %_Nul1%
)
reg.exe unload HKLM\%SOFTWARE% %_Nul3%
reg.exe unload HKLM\%COMPONENTS% %_Nul3%
if /i %xOS%==x86 if /i not %arch%==x86 (
    move /y "%mumtarget%\Windows\System32\Config\SOFTWARE2" "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
    if exist "%mumtarget%\Windows\System32\Config\COMPONENTS2" move /y "%mumtarget%\Windows\System32\Config\COMPONENTS2" "%mumtarget%\Windows\System32\Config\COMPONENTS" %_Nul1%
)
goto :eof

:ChkESUver
set kv_os=
reg.exe query "%_SxsKey%" /ve | findstr \( | findstr \. || goto :eof
for /f "tokens=2*" %%a in ('reg.exe query "%_SxsKey%" /ve ^| findstr \(') do set "kv_os=%%b"
if "%kv_os%"=="" goto :eof
set kv_al=
reg.exe query "%_SxsKey%\%kv_os%" /ve | findstr \( | findstr \. || goto :eof
for /f "tokens=2*" %%a in ('reg.exe query "%_SxsKey%\%kv_os%" /ve ^| findstr \(') do set "kv_al=%%b"
if "%kv_al%"=="" goto :eof
reg.exe query "%_Cmp%" /f "%xBT%_%_SxsCmp%_%_Pkt%_%kv_al%_*" /k %_Nul2% | find /i "%kv_al%" %_Nul1% || (
    set kv_al=
    goto :eof
)
for /f "tokens=1-4 delims=." %%G in ('echo %kv_al%') do (
    set "kv_mj=%%G"&set "kv_mn=%%H"&set "kv_bl=%%I"&set "kv_dl=%%J"
)
goto :eof

:mount
if exist "%_mount%\" rmdir /s /q "%_mount%\"
if not exist "%_mount%\" mkdir "%_mount%"
for %%# in (handle1,handle2) do set %%#=0
set _www=%~1
set _nnn=%~nx1
set /a a=0
for /L %%# in (1,1,%imgcount%) do (
    echo.
    echo %line%
    echo ���ڸ��� %_nnn% [%%#/%imgcount%]
    echo %line%
    set "_inx=%%#"&call :dowork
)
goto :eof

:dowork
%_dism2%:"!_cabdir!" /Mount-Wim /Wimfile:"%_www%" /Index:%_inx% /MountDir:"%_mount%"
if !errorlevel! neq 0 (
    %_dism1% /Unmount-Wim /MountDir:"%_mount%" /Discard
    %_dism1% /Cleanup-Wim %_Nul3%
    goto :eof
)
call :updatewim
if defined mounterr goto :eof
if not exist "%_mount%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" call :doappx
if !handle1! equ 0 if %dvd% equ 1 if %SkipBootFiles% equ 0 (
    set handle1=1
    if /i %arch%==x86 (set efifile=bootia32.efi) else if /i %arch%==x64 (set efifile=bootx64.efi) else ( set efifile=bootaa64.efi)
    for %%i in (efisys.bin,efisys_noprompt.bin) do if exist "%_mount%\Windows\Boot\DVD\EFI\en-US\%%i" ( xcopy /CIDRY "%_mount%\Windows\Boot\DVD\EFI\en-US\%%i" "%_target%\efi\microsoft\boot\" %_Nul3%)
    if /i not %arch%==arm64 (
        xcopy /CIDRY "%_mount%\Windows\Boot\PCAT\bootmgr" "%_target%\" %_Nul3%
        xcopy /CIDRY "%_mount%\Windows\Boot\PCAT\memtest.exe" "%_target%\boot\" %_Nul3%
        xcopy /CIDRY "%_mount%\Windows\Boot\EFI\memtest.efi" "%_target%\efi\microsoft\boot\" %_Nul3%
    )
    xcopy /CIDRY "%_mount%\Windows\Boot\EFI\bootmgfw.efi" "%_target%\efi\boot\!efifile!" %_Nul3%
    xcopy /CIDRY "%_mount%\Windows\Boot\EFI\bootmgr.efi" "%_target%\" %_Nul3%
    if exist "%_mount%\Windows\Boot\EFI\winsipolicy.p7b" if exist "%_target%\efi\microsoft\boot\winsipolicy.p7b" xcopy /CEDRY "%_mount%\Windows\Boot\EFI\winsipolicy.p7b" "%_target%\efi\microsoft\boot\winsipolicy.p7b" %_Nul3%
    if exist "%_mount%\Windows\Boot\EFI\CIPolicies\" if exist "%_target%\efi\microsoft\boot\cipolicies\" xcopy /CEDRY "%_mount%\Windows\Boot\EFI\CIPolicies\*" "%_target%\efi\microsoft\boot\cipolicies\" %_Nul3%
)
if !handle2! equ 0 if %dvd% equ 1 if not exist "%_mount%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" if exist "%_mount%\Windows\Servicing\Packages\Package_for_RollupFix*.mum" (
    set handle2=1
    set isomin=0
    for /f "tokens=%tok% delims=_." %%i in ('dir /b /a:-d /od "%_mount%\Windows\WinSxS\Manifests\%_ss%_microsoft-windows-coreos-revision*.manifest"') do (set isover=%%i.%%j&set isomaj=%%i&set isomin=%%j)
    set "isokey=Microsoft\Windows NT\CurrentVersion\Update\TargetingInfo\Installed"
    for /f %%i in ('"offlinereg.exe "%_mount%\Windows\system32\config\SOFTWARE" "!isokey!" enumkeys %_Nul6% ^| findstr /i /r ".*\.OS""') do if not errorlevel 1 (
        for /f "tokens=5,6 delims==:." %%A in ('"offlinereg.exe "%_mount%\Windows\system32\config\SOFTWARE" "!isokey!\%%i" getvalue Version %_Nul6%"') do if %%A gtr !isomaj! (
            set "revver=%%~A.%%B
            set revmaj=%%~A
            set "revmin=%%B
        )
    )
)
if exist "%_mount%\Windows\system32\UpdateAgent.dll" if not exist "%SystemRoot%\temp\UpdateAgent.dll" copy /y "%_mount%\Windows\system32\UpdateAgent.dll" %SystemRoot%\temp\ %_Nul1%
if exist "%_mount%\Windows\system32\Facilitator.dll" if not exist "%SystemRoot%\temp\Facilitator.dll" copy /y "%_mount%\Windows\system32\Facilitator.dll" %SystemRoot%\temp\ %_Nul1%
if exist "%_mount%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :SkipEdition
if %AddEdition% neq 1 goto :SkipEdition
echo.
echo %line%
echo ����ת�� Windows �汾����
echo %line%
echo.
for /f "tokens=3 delims=: " %%# in ('%_dism1% /English %dismtarget% /Get-CurrentEdition ^| findstr /c:"Current Edition"') do set editionid=%%#
if /i %editionid%==Core for %%i in (Core, CoreSingleLanguage) do ( set nedition=%%i && call :newinstall)
if /i %editionid%==Professional for %%i in (Education, Professional, ProfessionalEducation, ProfessionalWorkstation) do ( set nedition=%%i && call :newinstall)
%_dism1% /Unmount-Wim /MountDir:"%_mount%" /Discard
goto :eof
:SkipEdition
%_dism1% /Unmount-Wim /MountDir:"%_mount%" /Commit
goto :eof

:doappx
if %_build% geq 19041 set "appxtxt=.19041"
if %_build% geq 22000 set "appxtxt=.22000"
if %_build% geq 22563 set "appxtxt=.22621"
if %_build% geq 22563 if exist !_work!\Appx\appxdel!appxtxt!.txt (
    echo.
    echo %line%
    echo �����Ż� Appx ע�����
    echo %line%
    echo.
    %_Nul3% offlinereg.exe "%_mount%\Windows\system32\config\SOFTWARE" "Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore" createkey Deprovisioned
    for /f "delims=" %%i in (!_work!\Appx\appxdel!appxtxt!.txt) do (
        %_Nul3% offlinereg.exe "%_mount%\Windows\system32\config\SOFTWARE.new" "Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned" createkey %%i
    )
    if exist "%_mount%\Windows\system32\config\SOFTWARE.new" del /f /q "%_mount%\Windows\system32\config\SOFTWARE"&ren "%_mount%\Windows\System32\Config\SOFTWARE.new" SOFTWARE
)
if %_build% lss 22563 if exist !_work!\Appx\appxdel!appxtxt!.txt (
    echo.
    echo %line%
    echo ����ж�� Appx ���������
    echo %line%
    echo.
    for /f "delims=" %%i in (!_work!\Appx\appxdel!appxtxt!.txt) do (
        echo �����Ƴ� %%i
        %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismAppx.log" /Remove-ProvisionedAppxPackage /PackageName:%%i %_Null%
    )
    if %_build% geq 22000 (
        echo.
        echo %line%
        echo �����Ż� Appx ע�����
        echo %line%
        echo.
        %_Nul3% offlinereg.exe "%_mount%\Windows\system32\config\SOFTWARE" "Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned" deletekey Microsoft.ZuneMusic_8wekyb3d8bbwe
        for /f "delims=" %%i in ('offlinereg.exe "%_mount%\Windows\system32\config\SOFTWARE.new" "Microsoft\Windows\CurrentVersion\AppModel\StubPreference" enumkeys') do (
            %_Nul3% offlinereg.exe "%_mount%\Windows\system32\config\SOFTWARE.new" "Microsoft\Windows\CurrentVersion\AppModel\StubPreference" deletekey %%i
        )
        if exist "%_mount%\Windows\system32\config\SOFTWARE.new" del /f /q "%_mount%\Windows\system32\config\SOFTWARE"&ren "%_mount%\Windows\System32\Config\SOFTWARE.new" SOFTWARE
    )
)
if exist !_work!\Appx\appxadd!appxtxt!.txt (
    echo.
    echo %line%
    echo ���ڰ�װ Appx ���������
    echo %line%
    echo.
    set "license="
    for /f "delims=" %%i in (!_work!\Appx\appxadd!appxtxt!.txt) do (
        for /f "delims=_" %%# in ("%%i") do (
            if exist !_work!\Appx\%%#*.xml (
                for /f "delims=" %%i in ('dir /a /b !_work!\Appx\%%#*.xml') do set "license=/LicensePath:!_work!\Appx\%%i"
            ) else (
                set "license=/SkipLicense"
            )
        )
        echo ���ڰ�װ %%i
        %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismAppx.log" /Add-ProvisionedAppxPackage /PackagePath:"!_work!\Appx\%%i" /Region=all !license! %_Null%
    )
)
goto :eof

:newinstall
for %%# in (
    "Core:%_wtx% Home:%_wtx% ��ͥ��"
    "CoreSingleLanguage:%_wtx% Home Single Language:%_wtx% ��ͥ�����԰�"
    "Education:%_wtx% Education:%_wtx% ������"
    "Professional:%_wtx% Pro:%_wtx% רҵ��"
    "ProfessionalEducation:%_wtx% Pro Education:%_wtx% רҵ������"
    "ProfessionalWorkstation:%_wtx% Pro for Workstations:%_wtx% רҵ����վ��"
) do for /f "tokens=1,2,3 delims=:" %%A in ("%%~#") do (
    if %nedition%==%%A set "_namea=%%B"&set "_nameb=%%C"
)
echo ���ڴ��� !_nameb!
if exist "%_mount%\Windows\Core.xml" del /f /q "%_mount%\Windows\Core.xml" %_Nul3%
if exist "%_mount%\Windows\CoreSingleLanguage.xml" del /f /q "%_mount%\Windows\CoreSingleLanguage.xml" %_Nul3%
if exist "%_mount%\Windows\Education.xml" del /f /q "%_mount%\Windows\Education.xml" %_Nul3%
if exist "%_mount%\Windows\Professional.xml" del /f /q "%_mount%\Windows\Professional.xml" %_Nul3%
if exist "%_mount%\Windows\ProfessionalEducation.xml" del /f /q "%_mount%\Windows\ProfessionalEducation.xml" %_Nul3%
if exist "%_mount%\Windows\ProfessionalWorkstation.xml" del /f /q "%_mount%\Windows\ProfessionalWorkstation.xml" %_Nul3%
%_dism1% %dismtarget% /Set-Edition:%nedition% %_Null%
%_dism1% /Commit-Image /MountDir:"%_mount%" /Append
for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info "%_www%" ^| findstr /c:"Image Count"') do set nimg=%%#
wimlib-imagex.exe info "%_www%" !nimg! "!_namea!" "!_namea!" --image-property DISPLAYNAME="!_nameb!" --image-property DISPLAYDESCRIPTION="!_nameb!" --image-property FLAGS=%nedition% %_Nul3%
echo.
goto :eof

:cleanup
set savc=0&set savr=1
if %_build% geq 18362 (set savc=3&set savr=3)
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
    if /i not %arch%==arm64 (
        reg.exe load HKLM\%ksub% "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
        reg.exe add HKLM\%ksub%\%_SxsCfg% /v SupersededActions /t REG_DWORD /d %savr% /f %_Nul1%
        reg.exe add HKLM\%ksub%\%_SxsCfg% /v DisableComponentBackups /t REG_DWORD /d 1 /f %_Nul1%
        reg.exe unload HKLM\%ksub% %_Nul1%
    )
    %_dism2%:"!_cabdir!" %dismtarget% /Cleanup-Image /StartComponentCleanup
    if %Cleanup% neq 0 (
        if %ResetBase% neq 0 %_dism2%:"!_cabdir!" %dismtarget% /Cleanup-Image /StartComponentCleanup /ResetBase %_Null%
    )
    call :cleanmanual&goto :eof
)
if %Cleanup% equ 0 call :cleanmanual&goto :eof
if exist "%mumtarget%\Windows\WinSxS\pending.xml" call :cleanmanual&goto :eof
if /i not %arch%==arm64 (
    reg.exe load HKLM\%ksub% "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
    if %ResetBase% equ 1 (
        reg.exe add HKLM\%ksub%\%_SxsCfg% /v DisableResetbase /t REG_DWORD /d 0 /f %_Nul1%
        reg.exe add HKLM\%ksub%\%_SxsCfg% /v SupersededActions /t REG_DWORD /d %savr% /f %_Nul1%
    ) else (
        reg.exe add HKLM\%ksub%\%_SxsCfg% /v DisableResetbase /t REG_DWORD /d 1 /f %_Nul1%
        reg.exe add HKLM\%ksub%\%_SxsCfg% /v SupersededActions /t REG_DWORD /d %savc% /f %_Nul1%
    )
    if /i %xOS%==x86 if /i not %arch%==x86 reg.exe save HKLM\%ksub% "%mumtarget%\Windows\System32\Config\SOFTWARE2" %_Nul1%
    reg.exe unload HKLM\%ksub% %_Nul1%
    if /i %xOS%==x86 if /i not %arch%==x86 move /y "%mumtarget%\Windows\System32\Config\SOFTWARE2" "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
) else (
    %_Nul3% offlinereg.exe "%mumtarget%\Windows\System32\Config\SOFTWARE" %_SxsCfg% setvalue SupersededActions 3 4
    if exist "%mumtarget%\Windows\System32\Config\SOFTWARE.new" del /f /q "%mumtarget%\Windows\System32\Config\SOFTWARE"&ren "%mumtarget%\Windows\System32\Config\SOFTWARE.new" SOFTWARE
)
%_dism2%:"!_cabdir!" %dismtarget% /Cleanup-Image /StartComponentCleanup
if %ResetBase% neq 0 %_dism2%:"!_cabdir!" %dismtarget% /Cleanup-Image /StartComponentCleanup /ResetBase %_Null%
call :cleanmanual&goto :eof

:cleanmanual
if exist "%mumtarget%\Windows\WinSxS\ManifestCache\*.bin" (
    takeown /f "%mumtarget%\Windows\WinSxS\ManifestCache\*.bin" /A %_Nul3%
    icacls "%mumtarget%\Windows\WinSxS\ManifestCache\*.bin" /grant *S-1-5-32-544:F %_Nul3%
    del /f /q "%mumtarget%\Windows\WinSxS\ManifestCache\*.bin" %_Nul3%
)
if exist "%mumtarget%\Windows\WinSxS\Temp\*" (
    takeown /f "%mumtarget%\Windows\WinSxS\Temp\*" /A %_Nul3%
    icacls "%mumtarget%\Windows\WinSxS\Temp\*" /grant *S-1-5-32-544:F %_Nul3%
    del /f /q "%mumtarget%\Windows\WinSxS\Temp\*" %_Nul3%
)
if exist "%mumtarget%\Windows\WinSxS\Backup\*" (
    takeown /f "%mumtarget%\Windows\WinSxS\Backup\*" /R /A %_Nul3%
    icacls "%mumtarget%\Windows\WinSxS\Backup\*" /grant *S-1-5-32-544:F /T %_Nul3%
    del /s /f /q "%mumtarget%\Windows\WinSxS\Backup\*" %_Nul3%
)
if exist "%mumtarget%\Windows\inf\*.log" (
    del /f /q "%mumtarget%\Windows\inf\*.log" %_Nul3%
)
for /f "tokens=* delims=" %%# in ('dir /b /ad "%mumtarget%\Windows\assembly\*NativeImages*" %_Nul6%') do rmdir /s /q "%mumtarget%\Windows\assembly\%%#\" %_Nul3%
for /f "tokens=* delims=" %%# in ('dir /b /ad "%mumtarget%\Windows\CbsTemp\" %_Nul6%') do rmdir /s /q "%mumtarget%\Windows\CbsTemp\%%#\" %_Nul3%
del /s /f /q "%mumtarget%\Windows\CbsTemp\*" %_Nul3%
goto :eof

:E_NotFind
echo %_err%
echo ��ָ����·����δ�ҵ� UUP �ļ�
echo.
goto :QUIT

:E_Admin
echo %_err%
echo �˽ű���Ҫ�Թ���ԱȨ�����С�
echo ��Ҫ����ִ�У����ڽű����Ҽ�������ѡ���Թ���ԱȨ�����С���
echo.
echo �밴������˳��ű���
pause >nul
exit /b

:E_PowerShell
echo %_err%
echo �˽ű��Ĺ�����Ҫ Windows PowerShell��
echo.
echo �밴������˳��ű���
pause >nul
exit /b

:E_BinMiss
echo %_err%
echo ������ļ� %_bin% ��ʧ��
echo.
goto :QUIT

:E_Apply
echo.
echo ��Ӧ��ӳ���ʱ����ִ���
echo.
goto :QUIT

:E_Export
echo.
echo �ڵ���ӳ���ʱ����ִ���
echo.
goto :QUIT

:E_ISOC
ren ISOFOLDER %DVDISO%
echo.
echo �ڴ���ISOӳ���ʱ����ִ���
echo.
goto :QUIT

:QUIT
if exist ISOFOLDER\ rmdir /s /q ISOFOLDER\
if exist bin\temp\ rmdir /s /q bin\temp\
if exist temp\ rmdir /s /q temp\
popd
if defined tmpcmp (
    for %%# in (%tmpcmp%) do del /f /q "!_DIR!\%%~#" %_Nul3%
    set tmpcmp=
)
if exist "!_cabdir!\" (
    if %AddUpdates% equ 1 (
        echo.
        echo %line%
        echo �����Ƴ���ʱ�ļ�����
        echo %line%
        echo.
    )
    rmdir /s /q "!_cabdir!\" %_Nul3%
)
if exist "!_cabdir!\" (
    mkdir %_drv%\_del286 %_Null%
    robocopy %_drv%\_del286 "!_cabdir!" /MIR /R:1 /W:1 /NFL /NDL /NP /NJH /NJS %_Null%
    rmdir /s /q %_drv%\_del286\ %_Null%
    rmdir /s /q "!_cabdir!\" %_Nul3%
)
echo �밴���� 0 ���˳��ű���
choice /c 0 /n
if errorlevel 1 (%FullExit%) else (rem.)
