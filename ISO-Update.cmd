@setlocal DisableDelayedExpansion
@set "uivr=v22.6.15"
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

:: 若将更新（如果检测到）集成到 install.wim/winre.wim 中，请将此参数更改为 1
set AddUpdates=1

:: 若要清理映像以增量压缩已取代的组件，请将此参数更改为 1（警告：在 18362 及以上版本中，这将会删除基础 RTM 版本程序包）
set Cleanup=1

:: 若要重置操作系统映像并移除已被更新取代的组件，请将此参数更改为 1（快于默认的增量压缩，需要首先设置参数 Cleanup=1）
set ResetBase=1

:: 若不需要创建 ISO 文件，保留原始文件夹，请将此参数更改为 1
set SkipISO=0

:: 若在即使检测到 SafeOS 更新的情况下，也强制使用累积更新来更新 winre.wim，请将此参数更改为 1
set LCUWinre=1

:: 若不更新 ISO 引导文件 bootmgr/bootmgr.efi/efisys.bin，请将此参数更改为 1
set SkipBootFiles=1

:: 更新OneDrive，请将此参数更改为 1
set UpdateOneDrive=1

:: 启动 Dism++ 手动优化清理镜像，请将此参数更改为 1
set StartDism=1

:: 使用现有镜像升级 Windows 版本并保存，请将此参数更改为 1
set AddEdition=1

:: 生成并使用 .msu 更新包（Windows 11），请将此参数更改为 1
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
set "_err========== 错误 ========="
for /f "tokens=6 delims=[]. " %%# in ('ver') do set winbuild=%%#
set _cwmi=0
for %%# in (wmic.exe) do @if not "%%~$PATH:#"=="" (
    wmic path Win32_ComputerSystem get CreationClassName /value 2>nul | find /i "ComputerSystem" 1>nul && set _cwmi=1
)
set _pwsh=1
for %%# in (powershell.exe) do @if "%%~$PATH:#"=="" set _pwsh=0
if %winbuild% geq 22483 if %_pwsh% equ 0 goto :E_PS

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
title ISO 添加更新 %uivr%
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
set _ncab=0
set _niso=0
set iswre=0
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
    if not exist "bin\%%#" (set _bin=%%#&goto :E_Bin)
)

:checkupd
echo.
for /f "tokens=* delims=" %%# in ('dir /b /ad "!_work!"') do if exist "!_work!\%%~#\*.cab" (set /a _ncab+=1&set "_DIR=!_work!\%%~#"&echo %%~#) else if exist "!_work!\%%~#\*.msu" (set /a _ncab+=1&set "_DIR=!_work!\%%~#"&echo %%~#)
if !_ncab! equ 1 if defined _DIR goto :proceed
if !_ncab! equ 0 if not defined _DIR (
    if exist "!_work!\Appx\appx*.txt" set "_DIR=!_work!"&goto :proceed
)

:selectupd
set _DIR=
echo %line%
echo 使用 Tab 键选择或输入包含更新文件的文件夹
echo %line%
echo.
set /p _DIR=
if not defined _DIR (
    echo.
    echo %_err%
    echo 未指定文件夹
    echo.
    goto :selectupd
)
set "_DIR=!_work!\%_DIR:"=%"
if "%_DIR:~-1%"=="\" set "_DIR=%_DIR:~0,-1%"
if not exist "%_DIR%\*.cab" if not exist "%_DIR%\*.msu" (
    echo.
    echo %_err%
    echo 指定的文件夹内无更新文件
    echo.
    goto :selectupd
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
for /f "tokens=* delims=" %%# in ('dir /b /ad "!_work!"') do (
    if exist "%%~#\sources\install.wim" set _ndir=1&set "ISOdir=%%~#"
)

:findiso
echo.
if defined ISOdir goto :checkiso
if %_ndir% neq 1 if exist "*.iso" for /f "tokens=* delims=" %%# in ('dir /b /a:-d *.iso') do (
    set /a _niso+=1 && set "ISOfile=%%~#"
    echo %%~#
)
if !_niso! equ 1 goto :extraciso

:selectiso
set _erriso=0
set ISOfile=
echo %line%
echo 使用 Tab 键选择或输入 ISO 文件
echo %line%
echo.
set /p ISOfile=
if not defined ISOfile (
    echo.
    echo %_err%
    echo 未指定 ISO 文件
    echo.
    goto :selectiso
)
set "ISOfile=%ISOfile:"=%"
if not exist "%ISOfile%" set _erriso=1
if /i not "%ISOfile:~-4%"==".iso" set _erriso=1
if %_erriso% equ 1 (
    echo.
    echo %_err%
    echo 指定的文件不是有效的 ISO 文件
    echo.
    goto :selectiso
)

:extraciso
echo.
echo %line%
echo 正在解压 ISO 文件 !ISOfile! ……
echo %line%
echo.
set "ISOdir=ISOFOLDER"
if exist %ISOdir%\ rmdir /s /q %ISOdir%\
7z.exe x "!ISOfile!" -o%ISOdir% * -r %_Null%

:checkiso
if not defined ISOdir goto :E_ISOF
echo %line%
echo 正在检查 ISO 文件信息……
echo %line%
echo.
for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info "%ISOdir%\sources\install.wim" ^| findstr /c:"Image Count"') do set images=%%#
for /l %%# in (1,1,%images%) do call :iso_check %%#
if defined eWIMLIB goto :QUIT
set "_flg=%edition1%"&set "arch=%arch1%"&set "langid=%langid1%"&set "editionid=%edition1%"&set "_oName=%_oname1%"&set "_Srvr=%_ESDSrv1%"
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
if %_ndir% equ 1 if not "%ISOdir%"=="ISOFOLDER" (
    echo.
    echo %line%
    echo 正在复制 ISO 安装文件……
    echo %line%
    echo.
    if exist ISOFOLDER\ rmdir /s /q ISOFOLDER\
    robocopy "%ISOdir%" "ISOFOLDER" /E /A-:R %_Null%
    set "ISOdir=ISOFOLDER"
)
if %AddUpdates% equ 1 if %_updexist% equ 1 (
    echo.
    echo %line%
    echo 正在检查更新文件……
    echo %line%
    echo.
    if %UseMSU% neq 1 if exist "!_DIR!\*Windows1*-KB*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "!_DIR!\*Windows1*-KB*.msu"') do (set "pkgn=%%~n#"&set "package=%%#"&call :exd_msu)
    if %UseMSU% equ 1 if %_build% lss 21382 if exist "!_DIR!\*Windows1*-KB*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "!_DIR!\*Windows1*-KB*.msu"') do (set "pkgn=%%~n#"&set "package=%%#"&call :exd_msu)
    if %UseMSU% equ 1 if %_build% geq 21382 if exist "!_DIR!\*.AggregatedMetadata*.cab" if exist "!_DIR!\*Windows1*-KB*.cab" if exist "!_DIR!\*Windows1*-KB*.psf" call :upd_msu
    if exist "!_cabdir!\" rmdir /s /q "!_cabdir!\"
    DEL /F /Q %_dLog%\* %_Nul3%
    if not exist "%_dLog%\" mkdir "%_dLog%" %_Nul3%
    call :extract
)
if exist bin\ei.cfg copy /y bin\ei.cfg ISOFOLDER\sources\ei.cfg %_Nul3%
if not defined isoupdate goto :nosetupud
echo.
echo %line%
echo 正在应用 ISO 安装文件更新……
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
if %uwinpe% equ 1 goto :WinreWim
:WinreRet
set _rtrn=BootRet
if %uwinpe% equ 1 goto :BootWim
:BootRet
set _rtrn=InstallRet
goto :InstallWim
:InstallRet
if %SkipISO% neq 0 (
    ren ISOFOLDER %DVDISO%
    echo.
    echo %line%
    echo 完成。
    echo %line%
    echo.
    goto :QUIT
)
echo.
echo %line%
echo 正在创建 ISO ……
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
echo 完成。
echo %line%
echo.
goto :QUIT

:InstallWim
if %UpdateOneDrive% equ 1 (
    echo.
    echo %line%
    echo 正在更新 OneDrive 安装文件……
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
goto :%_rtrn%

:WinreWim
echo.
echo %line%
echo 正在从 install.wim 提取 Winre.wim 文件……
echo %line%
echo.
wimlib-imagex.exe extract "ISOFOLDER\sources\install.wim" 1 Windows\System32\Recovery\Winre.wim --dest-dir=temp --no-acls --no-attributes %_Nul3%
if %ERRORTEMP% neq 0 (
    echo %_err%
    echo 无法从 install.wim 提取 Winre.wim 
    echo.
    goto :QUIT
)
if %LCUWinre% equ 0 (set iswre=1) else (set iswre=0)
call :update temp\Winre.wim
wimlib-imagex.exe optimize temp\Winre.wim
echo.
echo %line%
echo 正在将 Winre.wim 添加到 install.wim 中……
echo %line%
echo.
for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info "ISOFOLDER\sources\install.wim" ^| findstr /c:"Image Count"') do set imgcount=%%#
for /L %%# in (1,1,%imgcount%) do (
    wimlib-imagex.exe update "ISOFOLDER\sources\install.wim" %%# --command="add 'temp\Winre.wim' '\Windows\System32\Recovery\Winre.wim'" %_Null%
)
goto :%_rtrn%

:BootWim
set iswre=0
call :update ISOFOLDER\sources\boot.wim
if not defined isoupdate goto :nosetup
wimlib-imagex.exe extract "ISOFOLDER\sources\install.wim" 1 Windows\system32\xmllite.dll --dest-dir=ISOFOLDER\sources --no-acls --no-attributes %_Nul3%
type nul>bin\boot-wim.txt
>>bin\boot-wim.txt echo add 'ISOFOLDER^\setup.exe' '^\setup.exe'
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\inf^\setup.cfg' '^\sources^\inf^\setup.cfg'
for /f %%# in (bin\bootwim.txt) do if exist "ISOFOLDER\sources\%%#" (
    >>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%%#' '^\sources^\%%#'
)
for /f %%# in (bin\bootmui.txt) do if exist "ISOFOLDER\sources\%langid%\%%#" (
    >>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%langid%^\%%#' '^\sources^\%langid%^\%%#'
)
wimlib-imagex.exe update ISOFOLDER\sources\boot.wim 2 < bin\boot-wim.txt %_Null%
:nosetup
wimlib-imagex.exe optimize ISOFOLDER\sources\boot.wim
del /f /q bin\boot-wim.txt %_Nul3%
del /f /q ISOFOLDER\sources\xmllite.dll %_Nul3%
goto :%_rtrn%

:PREPARE
echo %line%
echo 正在检查镜像信息……
echo %line%
set PREPARED=1
imagex /info "!ISOdir!\sources\install.wim" 1 >bin\info.txt 2>&1
for /f "tokens=3 delims=<>" %%# in ('find /i "<MAJOR>" bin\info.txt') do set ver1=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<MINOR>" bin\info.txt') do set ver2=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<BUILD>" bin\info.txt') do set _build=%%#
if exist "!ISOdir!\sources\setuphost.exe" 7z.exe l !ISOdir!\sources\setuphost.exe >bin\temp\version.txt 2>&1
if %_build% geq 22478 (
    wimlib-imagex.exe extract "!ISOdir!\sources\install.wim" 1 Windows\System32\UpdateAgent.dll --dest-dir=bin\temp --no-acls --no-attributes %_Nul3%
    if exist "bin\temp\UpdateAgent.dll" 7z.exe l bin\temp\UpdateAgent.dll >bin\temp\version.txt 2>&1
)
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" bin\temp\version.txt" %_Nul6%') do (set isover=%%i.%%j&set isomaj=%%i&set isomin=%%j)
set revver=%isover%&set revmaj=%isomaj%&set revmin=%isomin%
set "tok=6,7"&set "toe=5,6,7"
if /i %arch%==x86 (set _ss=x86) else if /i %arch%==x64 (set _ss=amd64) else (set _ss=arm64)
wimlib-imagex.exe extract "!ISOdir!\sources\install.wim" 1 Windows\WinSxS\Manifests\%_ss%_microsoft-windows-coreos-revision*.manifest --dest-dir=bin\temp --no-acls --no-attributes %_Nul3%
if exist "bin\temp\*_microsoft-windows-coreos-revision*.manifest" for /f "tokens=%tok% delims=_." %%i in ('dir /b /a:-d /od bin\temp\*_microsoft-windows-coreos-revision*.manifest') do (set revver=%%i.%%j&set revmaj=%%i&set revmin=%%j)
if %_build% geq 15063 (
    wimlib-imagex.exe extract "!ISOdir!\sources\install.wim" 1 Windows\System32\config\SOFTWARE --dest-dir=bin\temp --no-acls --no-attributes %_Null%
    set "isokey=Microsoft\Windows NT\CurrentVersion\Update\TargetingInfo\Installed"
    for /f %%i in ('"offlinereg.exe bin\temp\SOFTWARE "!isokey!" enumkeys %_Nul6% ^| findstr /i /r ".*\.OS""') do if not errorlevel 1 (
        for /f "tokens=5,6 delims==:." %%A in ('"offlinereg.exe bin\temp\SOFTWARE "!isokey!\%%i" getvalue Version %_Nul6%"') do if %%A gtr !revmaj! (
            set "revver=%%~A.%%B
            set revmaj=%%~A
            set "revmin=%%B
        )
    )
)
if %isomin% lss %revmin% set isover=%revver%
if %isomaj% lss %revmaj% set isover=%revver%
set _label=%isover%
call :setlabel
rmdir /s /q bin\temp\

:setlabel
set DVDISO=%_label%.%arch%
for %%# in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do set langid=!langid:%%#=%%#!
if /i %arch%==x86 set archl=X86
if /i %arch%==x64 set archl=X64
if /i %arch%==arm64 set archl=A64
for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info "!ISOdir!\sources\install.wim" ^| findstr /c:"Image Count"') do set images=%%#
set DVDLABEL=CCSA_%archl%FRE_%langid%_DV9
if %images% geq 4 set DVDLABEL=CCCOMA_%archl%FRE_%langid%_DV9
if %_SrvESD% equ 1 (
    set DVDLABEL=SSS_%archl%FRE_%langid%_DV9
)
exit /b

:iso_check
set _ESDSrv%1=0
wimlib-imagex.exe info "%ISOdir%\sources\install.wim" %1 %_Nul3%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% equ 73 (
    echo %_err%
    echo install.wim 文件已损坏
    echo.
    set eWIMLIB=1
    exit /b
)
if %ERRORTEMP% neq 0 (
    echo %_err%
    echo 无法解析来自文件 install.wim 的信息
    echo.
    set eWIMLIB=1
    exit /b
)
imagex /info "%ISOdir%\sources\install.wim" %1 >bin\info.txt 2>&1
for /f "tokens=3 delims=<>" %%# in ('find /i "<DEFAULT>" bin\info.txt') do set "langid%1=%%#"
for /f "tokens=3 delims=<>" %%# in ('find /i "<EDITIONID>" bin\info.txt') do set "edition%1=%%#"
for /f "tokens=3 delims=<>" %%# in ('find /i "<ARCH>" bin\info.txt') do (if %%# equ 0 (set "arch%1=x86") else if %%# equ 9 (set "arch%1=x64") else (set "arch%1=arm64"))
set "_wtx=Windows 10"
find /i "<NAME>" bin\info.txt %_Nul2% | find /i "Windows 11" %_Nul1% && (set "_wtx=Windows 11")
echo !edition%1!|findstr /i /b "Server" %_Nul3% && (set _SrvESD=1&set _ESDSrv%1=1)
if !_ESDSrv%1! equ 1 findstr /i /c:"Server Core" bin\info.txt %_Nul3% && (
    if /i "!edition%1!"=="ServerStandard" set "edition%1=ServerStandardCore"
    if /i "!edition%1!"=="ServerDatacenter" set "edition%1=ServerDatacenterCore"
)
del /f /q bin\info*.txt
exit /b

:exd_msu
echo %line%
echo 解包累积更新 %package% 文件
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
echo 创建累积更新的 MSU 文件
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
echo AggregatedMetadata 文件中 LCUCompDB 文件丢失，跳过操作。
goto :msu_uups
)
for /f %%# in ('dir /b /a:-d "_tMSU\LCUCompDB*.xml.cab"') do set "_MSUcdb=%%#"
for /f "tokens=2 delims=_." %%# in ('echo %_MSUcdb%') do set "_MSUkbn=%%#"
if not exist "*Windows1*%_MSUkbn%*%arch%*.cab" (
echo.
echo 最新累积更新 %_MSUkbn% 的 cab 文件丢失，跳过操作。
goto :msu_uups
)
if not exist "*Windows1*%_MSUkbn%*%arch%*.psf" (
echo.
echo 最新累积更新 %_MSUkbn% 的 psf 文件丢失，跳过操作。
goto :msu_uups
)
if exist "*Windows1*%_MSUkbn%*%arch%*.msu" (
echo.
echo 最新累积更新 %_MSUkbn% 的 msu 文件已经存在，跳过操作。
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
if %ERRORLEVEL% neq 0 (echo 失败，跳过该操作。&goto :msu_uups)
call :crDDF %_MSUkbf%.msu
(echo "%_MSUddc%" "DesktopDeployment.cab"
if /i not %arch%==x86 echo "%_MSUddd%" "DesktopDeployment_x86.cab"
echo "_tMSU\%_MSUonf%" "%_MSUonf%"
if %IncludeSSU% equ 1 echo "%_MSUssu%" "%_MSUtsu%"
echo "%_MSUcab%" "%_MSUkbf%.cab"
echo "%_MSUpsf%" "%_MSUkbf%.psf"
)>>zzz.ddf
%_Null% makecab.exe /F zzz.ddf /D Compress=OFF
if %ERRORLEVEL% neq 0 (echo 失败，跳过该操作。&goto :msu_uups)

:msu_uups
if exist "zzz.ddf" del /f /q "zzz.ddf"
if exist "_tSSU\" rmdir /s /q "_tSSU\" %_Nul3%
rmdir /s /q "_tMSU\" %_Nul3%
popd
exit /b

:DDCAB
echo.
echo 正在解压所需文件……
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
if %ERRORLEVEL% neq 0 (set _mcfail=1&echo 失败，跳过该操作。&exit /b)
mkdir "_tSSU\111"
if /i not %arch%==x86 if not exist "DesktopDeployment_x86.cab" goto :DDCdual
rmdir /s /q "_tSSU\" %_Nul3%
exit /b

:DDC86
echo.
echo 正在解压所需文件……
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
if %ERRORLEVEL% neq 0 (set _mcfail=1&echo 失败，跳过该操作。&exit /b)
rmdir /s /q "_tSSU\" %_Nul3%
exit /b

:crDDF
echo.
echo 正在生成：%~nx1
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
if %AddEdition% equ 1 for /l %%# in (1,1,%imgcount%) do %_dism1% /Delete-Image /ImageFile:"%_www%" /Index:1 %_Nul3%

:nodvd
if exist "%_mount%\" rmdir /s /q "%_mount%\"
if %_build% geq 19041 if %winbuild% lss 17133 if exist "%SysPath%\ext-ms-win-security-slc-l1-1-0.dll" (
    del /f /q %SysPath%\ext-ms-win-security-slc-l1-1-0.dll %_Nul3%
    if /i not %xOS%==x86 del /f /q %SystemRoot%\SysWOW64\ext-ms-win-security-slc-l1-1-0.dll %_Nul3%
)
echo.
if %wim% equ 1 exit /b
wimlib-imagex.exe optimize "%_target%\sources\install.wim"
for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info "%_target%\sources\install.wim" ^| findstr /c:"Image Count"') do set imgcount=%%#
for /L %%# in (1,1,%imgcount%) do (
    for /f "tokens=3 delims=<>" %%A in ('imagex /info "%_target%\sources\install.wim" %%# ^| find /i "<HIGHPART>"') do call set "HIGHPART=%%A"
    for /f "tokens=3 delims=<>" %%A in ('imagex /info "%_target%\sources\install.wim" %%# ^| find /i "<LOWPART>"') do call set "LOWPART=%%A"
    wimlib-imagex.exe info "%_target%\sources\install.wim" %%# --image-property CREATIONTIME/HIGHPART=!HIGHPART! --image-property CREATIONTIME/LOWPART=!LOWPART! %_Nul1%
)
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
    if not defined cab_%pkgn% echo [%count%/%_cab%] %package% [安装文件更新]
    set isoupdate=!isoupdate! "%package%"
    set cab_%pkgn%=1
    rmdir /s /q "!dest!\" %_Nul3%
    goto :eof
)
expand.exe -f:*.psf.cix.xml "!_DIR!\%package%" "!dest!" %_Null%
if exist "!dest!\*.psf.cix.xml" (
    if not exist "!_DIR!\%pkgn%.psf" if not exist "!_DIR!\*%pkgid%*%arch%*.psf" (
        echo [%count%/%_cab%] %package% / PSF 文件丢失
        goto :eof
    )
    if %psfnet% equ 0 (
        echo [%count%/%_cab%] %package% / PSFExtractor 不可用
        goto :eof
    )
    set psf_%pkgn%=1
)
expand.exe -f:toc.xml "!_DIR!\%package%" "!dest!" %_Null%
if exist "!dest!\toc.xml" (
    echo [%count%/%_cab%] %package% [组合更新包]
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
    findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% && (set "_type=[最新累积更新]"&set uwinpe=1)
)
if not defined _type (
    findstr /i /m "Package_for_WindowsExperienceFeaturePack" "!dest!\update.mum" %_Nul3% && set "_type=[UX 功能体验包]"
)
if not defined _type (
    expand.exe -f:*_microsoft-windows-servicingstack_*.manifest "!_DIR!\%package%" "!dest!" %_Null%
    if exist "!dest!\*_microsoft-windows-servicingstack_*.manifest" (
        set "_type=[服务堆栈更新]"&set uwinpe=1
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
    if exist "!dest!\*_microsoft-windows-s..boot-firmwareupdate_*.manifest" set "_type=[安全启动]"
)
if not defined _type if %_build% geq 18362 (
    expand.exe -f:microsoft-windows-*enablement-package~*.mum "!_DIR!\%package%" "!dest!" %_Null%
    if exist "!dest!\microsoft-windows-*enablement-package~*.mum" set "_type=[功能启用]"
    if exist "!dest!\Microsoft-Windows-1909Enablement-Package~*.mum" set "_fixEP=18363"
    if exist "!dest!\Microsoft-Windows-20H2Enablement-Package~*.mum" set "_fixEP=19042"
    if exist "!dest!\Microsoft-Windows-21H1Enablement-Package~*.mum" set "_fixEP=19043"
    if exist "!dest!\Microsoft-Windows-21H2Enablement-Package~*.mum" set "_fixEP=19044"
    if exist "!dest!\Microsoft-Windows-22H2Enablement-Package~*.mum" if %_build% lss 22000 set "_fixEP=19045"
)
if %_build% geq 18362 if exist "!dest!\*enablement-package*.mum" (
    expand.exe -f:*_microsoft-windows-e..-firsttimeinstaller_*.manifest "!_DIR!\%package%" "!dest!" %_Null%
    if exist "!dest!\*_microsoft-windows-e..-firsttimeinstaller_*.manifest" set "_type=[功能启用 / EdgeChromium]"
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
        echo 出现错误：解压 PSF 更新失败
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
echo [%count%/%_cab%] %package% [累积更新(MSU)]
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
if %UseMSU% equ 1 if %_build% geq 21382 if exist "!_DIR!\*Windows1*-KB*.msu" (for /f "tokens=* delims=" %%# in ('dir /b /on "!_DIR!\*Windows1*-KB*.msu"') do if defined msu_%%~n# (set "pckn=%%~n#"&set "packx=%%~x#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :procmum))
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
if not defined overall if not defined servicingstack goto :eof
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
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" if !iswre! equ 1 if defined safeos (
    set callclean=1
    %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismWinPE.log" /Add-Package %safeos%
    cmd /c exit /b !errorlevel!
    if /i not "!=ExitCode!"=="00000000" if /i not "!=ExitCode!"=="800f081e" goto :errmount
    call :cleanup
    if %ResetBase% equ 0 %_dism2%:"!_cabdir!" %dismtarget% /Cleanup-Image /StartComponentCleanup /ResetBase %_Null%
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
set _dualSxS=
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

:pXML
if %_build% neq 18362 (
    call :cXML stage
    echo.
    echo 正在处理 [1/1] - 正在暂存 %cbsn%
    %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\%_DsmLog%" /Apply-Unattend:"!_cabdir!\stage.xml"
    if !errorlevel! neq 0 if !errorlevel! neq 3010 goto :eof
)
if %_build% neq 18362 (call :Winner) else (call :Suppress)
if defined _dualSxS (
    set "_SxsKey=%_CedKey%"
    set "_SxsCmp=%_CedCmp%"
    set "_SxsIdn=%_CedIdn%"
    set "_SxsCF=256"
    if %_build% neq 18362 (call :Winner) else (call :Suppress)
)
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
    echo 正在更新 %_nnn% [%%#/%imgcount%]
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
if %StartDism% equ 1 start /WAIT "" "bin\Dism++x64.exe"
if %AddEdition% neq 1 goto :SkipEdition
echo.
echo %line%
echo 正在转换 Windows 版本……
echo %line%
echo.
for /f "tokens=3 delims=: " %%# in ('%_dism1% /English %dismtarget% /Get-CurrentEdition ^| findstr /c:"Current Edition"') do set editionid=%%#
if /i %editionid%==Core for %%i in (Core, CoreSingleLanguage) do (set nedition=%%i&call :newinstall)
if /i %editionid%==Professional for %%i in (Education, Professional, ProfessionalEducation, ProfessionalWorkstation) do (set nedition=%%i&call :newinstall %%i)
%_dism1% /Unmount-Wim /MountDir:"%_mount%" /Discard
goto :eof
:SkipEdition
%_dism1% /Unmount-Wim /MountDir:"%_mount%" /Commit
if !errorlevel! neq 0 (
    %_dism1% /Unmount-Wim /MountDir:"%_mount%" /Discard
    %_dism1% /Cleanup-Wim %_Nul3%
    goto :eof
)
goto :eof

:doappx
if exist !_work!\Appx\appxdel.txt (
    if %_build% geq 22563 (
        echo.
        echo %line%
        echo 正在优化 Appx 注册表……
        echo %line%
        echo.
        %_Nul3% offlinereg.exe "%_mount%\Windows\system32\config\SOFTWARE" "Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore" createkey Deprovisioned
        for /f "delims=" %%i in (!_work!\Appx\appxdel.txt) do (
            %_Nul3% offlinereg.exe "%_mount%\Windows\system32\config\SOFTWARE.new" "Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned" createkey %%i
        )
        if exist "%_mount%\Windows\system32\config\SOFTWARE.new" del /f /q "%_mount%\Windows\system32\config\SOFTWARE"&ren "%_mount%\Windows\System32\Config\SOFTWARE.new" SOFTWARE
    )
    if %_build% lss 22563 (
        echo.
        echo %line%
        echo 正在卸载 Appx 软件包……
        echo %line%
        echo.
        for /f "delims=" %%# in ('type !_work!\Appx\appxdel.txt ^| find /c /v ""') do set "all=%%#"
        set /a a=0
        for /f "delims=" %%i in (!_work!\Appx\appxdel.txt) do (
            set /a a+=1
            echo [!a!/!all!] 正在移除 %%i
            %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismAppx.log" /Remove-ProvisionedAppxPackage /PackageName:%%i %_Null%
        )
    )
)
if %_build% geq 22000 if %_build% lss 22563 (
    echo.
    echo %line%
    echo 正在优化 Appx 注册表……
    echo %line%
    echo.
    %_Nul3% offlinereg.exe "%_mount%\Windows\system32\config\SOFTWARE" "Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned" deletekey Microsoft.ZuneMusic_8wekyb3d8bbwe
    for /f "delims=" %%i in ('offlinereg.exe "%_mount%\Windows\system32\config\SOFTWARE.new" "Microsoft\Windows\CurrentVersion\AppModel\StubPreference" enumkeys') do (
        %_Nul3% offlinereg.exe "%_mount%\Windows\system32\config\SOFTWARE.new" "Microsoft\Windows\CurrentVersion\AppModel\StubPreference" deletekey %%i
    )
    if exist "%_mount%\Windows\system32\config\SOFTWARE.new" del /f /q "%_mount%\Windows\system32\config\SOFTWARE"&ren "%_mount%\Windows\System32\Config\SOFTWARE.new" SOFTWARE
)
if exist !_work!\Appx\appxadd.txt (
    echo.
    echo %line%
    echo 正在安装 Appx 软件包……
    echo %line%
    echo.
    for /f "delims=" %%# in ('type !_work!\Appx\appxadd.txt ^| find /c /v ""') do set "all=%%#"
    set /a a=0
    set "license="
    for /f "delims=" %%i in (!_work!\Appx\appxadd.txt) do (
        for /f "delims=_" %%# in ("%%i") do (
            if exist !_work!\Appx\%%#*.xml (
                for /f "delims=" %%i in ('dir /a /b !_work!\Appx\%%#*.xml') do set "license=/LicensePath:!_work!\Appx\%%i"
            ) else (
                set "license=/SkipLicense"
            )
        )
        set /a a+=1
        echo [!a!/!all!] 正在安装 %%i
        %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismAppx.log" /Add-ProvisionedAppxPackage /PackagePath:"!_work!\Appx\%%i" /Region=all !license! %_Null%
    )
)
goto :eof

:newinstall
for %%# in (
    "Core:%_wtx% Home:%_wtx% 家庭版"
    "CoreSingleLanguage:%_wtx% Home Single Language:%_wtx% 家庭单语言版"
    "Education:%_wtx% Education:%_wtx% 教育版"
    "Professional:%_wtx% Pro:%_wtx% 专业版"
    "ProfessionalEducation:%_wtx% Pro Education:%_wtx% 专业教育版"
    "ProfessionalWorkstation:%_wtx% Pro for Workstations:%_wtx% 专业工作站版"
    "Enterprise:%_wtx% Enterprise:%_wtx% 企业版 "
    "EnterpriseG:%_wtx% Enterprise G:%_wtx% 政府企业版 "
    "EnterpriseS:%_wtx% Enterprise LTSC:%_wtx% 企业版 LTSC"
    "IoTEnterprise:%_wtx% IoT Enterprise:%_wtx% IoT 企业版"
    "IoTEnterpriseS:%_wtx% IoT Enterprise LTSC:%_wtx% IoT 企业版 LTSC"
) do for /f "tokens=1,2,3 delims=:" %%A in ("%%~#") do (
    if %nedition%==%%A set "_namea=%%B"&set "_nameb=%%C"
)
echo 正在处理 !_nameb!
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
if exist "%mumtarget%\Windows\WinSxS\Temp\PendingDeletes\*" (
    takeown /f "%mumtarget%\Windows\WinSxS\Temp\PendingDeletes\*" /A %_Nul3%
    icacls "%mumtarget%\Windows\WinSxS\Temp\PendingDeletes\*" /grant *S-1-5-32-544:F %_Nul3%
    del /f /q "%mumtarget%\Windows\WinSxS\Temp\PendingDeletes\*" %_Nul3%
)
if exist "%mumtarget%\Windows\WinSxS\Temp\TransformerRollbackData\*" (
    takeown /f "%mumtarget%\Windows\WinSxS\Temp\TransformerRollbackData\*" /R /A %_Nul3%
    icacls "%mumtarget%\Windows\WinSxS\Temp\TransformerRollbackData\*" /grant *S-1-5-32-544:F /T %_Nul3%
    del /s /f /q "%mumtarget%\Windows\WinSxS\Temp\TransformerRollbackData\*" %_Nul3%
)
if exist "%mumtarget%\Windows\inf\*.log" (
    del /f /q "%mumtarget%\Windows\inf\*.log" %_Nul3%
)
for /f "tokens=* delims=" %%# in ('dir /b /ad "%mumtarget%\Windows\CbsTemp\" %_Nul6%') do rmdir /s /q "%mumtarget%\Windows\CbsTemp\%%#\" %_Nul3%
del /s /f /q "%mumtarget%\Windows\CbsTemp\*" %_Nul3%
goto :eof

:E_ISOF
echo %_err%
echo 在指定的路径中没有未找到 ISO 文件（夹）。
echo.
goto :QUIT

:E_Admin
echo %_err%
echo 此脚本需要以管理员权限运行。
echo 若要继续执行，请在脚本上右键单击并选择“以管理员权限运行”。
echo.
echo 请按任意键退出脚本。
pause >nul
exit /b

:E_PS
echo %_err%
echo 此脚本的工作需要 Windows PowerShell。
echo.
echo 请按任意键退出脚本。
pause >nul
exit /b

:E_Bin
echo %_err%
echo 所需的文件 %_bin% 丢失。
echo.
goto :QUIT

:E_Apply
echo.
echo 在应用映像的时候出现错误。
echo.
goto :QUIT

:E_Winre
echo.
echo 未找到 Winre.wim 文件
echo.
goto :QUIT

:E_ISOC
ren ISOFOLDER %DVDISO%
echo.
echo 在创建ISO映像的时候出现错误。
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
        echo 正在移除临时文件……
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
echo 请按数字 0 键退出脚本。
choice /c 0 /n
if errorlevel 1 (%FullExit%) else (rem.)
