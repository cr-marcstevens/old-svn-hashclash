@echo off
setlocal
setlocal enableextensions

set boostversion=1.52.0
set boostversion2=1_52_0

set bzipversion=1.0.6
set zlibversion=1.2.7

rem Boost Build options, msvc-10.0 corresponds to VS2010
set toolset=msvc
set toolset=msvc-10.0
set parallelbuildjobs=8

rem This TEMPORARY directory is used to build everything
rem !! It should NOT be an existing directory !!
rem !! Its full path should NOT contain spaces or parentheses !!
rem !! Its full path should NOT be too long !!
set tmpdir=tmpdir
set tmpdir=\tmpboostbuild%boostversion%




rem ******************* sanity check ******************************
IF NOT "%tmpdir%" == "\tmpboostbuild%boostversion%" (
   echo Installation Directory: "%installdir%"
   echo.
   echo TempBuild Directory   : "%tmpdir%"
   echo.
   echo Before continuing ensure that TempBuild Directory:
   echo - does NOT contain spaces
   echo - does NOT contain parenthesis
   echo OTHERWISE ABORT HERE AND MODIFY 'set tmpdir=' AT THE TOP OF THIS SCRIPT 

   pause
   pause
)


:docleanup
rem ************** delete output directories (if any) ************
echo.
echo Cleaning up
rmdir /s /q "boost.%boostversion%"   2>nul >nul
if exist "%tmpdir%" (
	echo TempBuild Directory "%tmpdir%" already exists
	echo THIS DIRECTORY WILL BE DELETED, DO YOU WANT TO CONTINUE? 
	rmdir /s "%tmpdir%"
)


rem ************* creating installation directory
echo.
echo Creating Installation and TempBuild Directory

mkdir boost.%boostversion%
for %%I in (boost.%boostversion%) do set installdir=%%~sfI

mkdir "%tmpdir%"
if not exist "%tmpdir%" goto errortmpdir
for %%I in ("%tmpdir%") do set tmpdir=%%~sfI





:dodownload
rem ************** download archives from the web ********************
echo.
IF NOT EXIST boost_%boostversion2%.tar.bz2 (
   echo Downloading Boost: boost_%boostversion2%.tar.bz2
   powershell -Command "$wc = New-Object System.Net.WebClient ; $wc.DownloadFile('https://hashclash.googlecode.com/files/boost_%boostversion2%.tar.bz2','boost_%boostversion2%.tar.bz2.incomplete');" 2>nul >nul
   IF ERRORLEVEL 1 (
      echo Trying different mirror...
      powershell -Command "$wc = New-Object System.Net.WebClient ; $wc.DownloadFile('http://downloads.sourceforge.net/project/boost/boost/%boostversion%/boost_%boostversion2%.tar.bz2','boost_%boostversion2%.tar.bz2.incomplete');"
      IF ERRORLEVEL 1 GOTO downloaderror
   )
   ren boost_%boostversion2%.tar.bz2.incomplete boost_%boostversion2%.tar.bz2
)
:boostdownloaded

IF NOT EXIST bzip2-%bzipversion%.tar.gz (
   echo Downloading BZIP2: bzip2-%bzipversion%.tar.gz
   powershell -Command "$wc = New-Object System.Net.WebClient ; $wc.DownloadFile('http://www.bzip.org/%bzipversion%/bzip2-%bzipversion%.tar.gz','bzip2-%bzipversion%.tar.gz.incomplete');"
   IF ERRORLEVEL 1 GOTO downloaderror
   ren bzip2-%bzipversion%.tar.gz.incomplete bzip2-%bzipversion%.tar.gz
)

IF NOT EXIST zlib-%zlibversion%.tar.gz (
   echo Downloading ZLIB : zlib-%zlibversion%.tar.gz
   powershell -Command "$wc = New-Object System.Net.WebClient ; $wc.DownloadFile('http://downloads.sourceforge.net/project/libpng/zlib/%zlibversion%/zlib-%zlibversion%.tar.gz','zlib-%zlibversion%.tar.gz.incomplete');"
   IF ERRORLEVEL 1 GOTO downloaderror
   ren zlib-%zlibversion%.tar.gz.incomplete zlib-%zlibversion%.tar.gz
)

IF NOT EXIST 7zip.zip (
   IF EXIST 7za920.zip (
      copy 7za920.zip 7zip.zip
   ) ELSE (
      echo Downloading 7ZIP : 7za920.zip
      powershell -Command "$wc = New-Object System.Net.WebClient ; $wc.DownloadFile('http://downloads.sourceforge.net/project/sevenzip/7-Zip/9.20/7za920.zip','7za920.zip.incomplete');"
      IF ERRORLEVEL 1 GOTO downloaderror
      ren 7za920.zip.incomplete 7zip.zip
   )
)





cd "%tmpdir%"



:doextract
rem ************** extract all archives *****************************
echo.

echo Extracting 7ZIP
copy "%installdir%\..\7zip.zip" .
powershell -Command "$sa = New-Object -com Shell.Application; $sa.Namespace((Get-Location).Path).Copyhere($sa.Namespace((Get-Location).Path+'\7zip.zip').items(),0x14);"
IF NOT EXIST 7za.exe GOTO ziperror

echo Extracting Boost
7za.exe x -y   "%installdir%\..\boost_%boostversion2%.tar.bz2" 2>nul >nul
IF ERRORLEVEL 1 GOTO unziperror
7za.exe x -y   boost_%boostversion2%.tar     2>nul >nul
IF ERRORLEVEL 1 GOTO unziperror
del boost_%boostversion2%.tar

echo Extracting BZIP2
7za.exe x -y   "%installdir%\..\bzip2-%bzipversion%.tar.gz"    2>nul >nul
IF ERRORLEVEL 1 GOTO unziperror
7za.exe x -y   bzip2-%bzipversion%.tar       2>nul >nul
IF ERRORLEVEL 1 GOTO unziperror
del bzip2-%bzipversion%.tar

echo Extracting ZLIB
7za.exe x -y   "%installdir%\..\zlib-%zlibversion%.tar.gz"     2>nul >nul
IF ERRORLEVEL 1 GOTO unziperror
7za.exe x -y   zlib-%zlibversion%.tar        2>nul >nul
IF ERRORLEVEL 1 GOTO unziperror
del zlib-%zlibversion%.tar








:dobuild
rem ******************* compile boost ****************************
echo.

for %%I in (bzip2-%bzipversion%) do set bzip2dir=%%~fsI
for %%I in (zlib-%zlibversion%) do set zlibdir=%%~fsI

cd boost_%boostversion2%

if not exist b2.exe call bootstrap.bat

echo.
echo Compiling BOOST (incl. BZIP2 and ZLIB) 32-bit libraries

b2.exe -q -j %parallelbuildjobs% address-model=32 --toolset=%toolset% --build-type=complete %libs% -sBZIP2_SOURCE="%bzip2dir%" -sZLIB_SOURCE="%zlibdir%" stage > build_boost_32.log 2>&1
timeout 5 /nobreak >nul
ren stage lib32
ren bin.v2 bin.v2.32

echo.
echo Compiling BOOST (incl. BZIP2 and ZLIB) 64-bit libraries

b2.exe -q -j %parallelbuildjobs% address-model=64 --toolset=%toolset% --build-type=complete %libs% -sBZIP2_SOURCE="%bzip2dir%" -sZLIB_SOURCE="%zlibdir%" stage > build_boost_64.log 2>&1
timeout 5 /nobreak >nul
ren stage lib64
ren bin.v2 bin.v2.64

cd ..






:doinstall
rem ******************* install boost ****************************
echo.
echo Installing BOOST (incl. BZIP2 and ZLIB)

move "boost_%boostversion2%\boost" "%installdir%\boost"
move "boost_%boostversion2%\lib32\lib" "%installdir%\lib32"
move "boost_%boostversion2%\lib64\lib" "%installdir%\lib64"
copy "boost_%boostversion2%\*.log" "%installdir%\"
copy "%bzip2dir%\*.h" "%installdir%\"
copy "%zlibdir%\*.h" "%installdir%\"

echo ^<?xml version=^'1.0^' encoding=^'utf-8^'?^>                                                        >  "%installdir%\..\boost32.props"
echo ^<Project ToolsVersion=^'4.0^' xmlns=^'http://schemas.microsoft.com/developer/msbuild/2003^'^>      >> "%installdir%\..\boost32.props"
echo   ^<ImportGroup Label=^'PropertySheets^' /^>                                                        >> "%installdir%\..\boost32.props"
echo   ^<PropertyGroup Label=^'UserMacros^' /^>                                                          >> "%installdir%\..\boost32.props"
echo   ^<PropertyGroup^>                                                                                 >> "%installdir%\..\boost32.props"
echo     ^<IncludePath^>$(IncludePath);%installdir%;..\src\libhashutil5^</IncludePath^>                  >> "%installdir%\..\boost32.props"
echo     ^<LibraryPath^>$(LibraryPath);%installdir%\lib32;$(Configuration)\^</LibraryPath^>              >> "%installdir%\..\boost32.props"
echo   ^</PropertyGroup^>                                                                                >> "%installdir%\..\boost32.props"
echo   ^<ItemDefinitionGroup /^>                                                                         >> "%installdir%\..\boost32.props"
echo   ^<ItemGroup /^>                                                                                   >> "%installdir%\..\boost32.props"
echo ^</Project^>                                                                                        >> "%installdir%\..\boost32.props"

echo ^<?xml version=^'1.0^' encoding=^'utf-8^'?^>                                                        >  "%installdir%\..\boost64.props"
echo ^<Project ToolsVersion=^'4.0^' xmlns=^'http://schemas.microsoft.com/developer/msbuild/2003^'^>      >> "%installdir%\..\boost64.props"
echo   ^<ImportGroup Label=^'PropertySheets^' /^>                                                        >> "%installdir%\..\boost64.props"
echo   ^<PropertyGroup Label=^'UserMacros^' /^>                                                          >> "%installdir%\..\boost64.props"
echo   ^<PropertyGroup^>                                                                                 >> "%installdir%\..\boost64.props"
echo     ^<IncludePath^>$(IncludePath);%installdir%;..\src\libhashutil5^</IncludePath^>                  >> "%installdir%\..\boost64.props"
echo     ^<LibraryPath^>$(LibraryPath);%installdir%\lib64;$(Configuration)$(Platform)\^</LibraryPath^>   >> "%installdir%\..\boost64.props"
echo   ^</PropertyGroup^>                                                                                >> "%installdir%\..\boost64.props"
echo   ^<ItemDefinitionGroup /^>                                                                         >> "%installdir%\..\boost64.props"
echo   ^<ItemGroup /^>                                                                                   >> "%installdir%\..\boost64.props"
echo ^</Project^>                                                                                        >> "%installdir%\..\boost64.props"




rem ****************** finished ****************************
echo Cleaning up
cd ..
rmdir /s "%tmpdir%"
cd "%installdir%\.."

goto end







:errortmpdir
echo Failed to create temporary build directory:
echo %tmpdir%
echo.
echo MODIFY 'set tmpdir=' AT THE TOP OF THIS SCRIPT

goto end

:downloaderror
echo Download failed, try to manually download file into directory:
echo %CD%
goto end

:ziperror
echo Cannot find 7za.exe, try to manually extract file
goto end

:unziperror
echo Error while extracting archive
goto end

:end

pause
