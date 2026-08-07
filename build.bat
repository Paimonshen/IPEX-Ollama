@echo off
setlocal
rem ============================================================
rem  IPEX-Ollama build script
rem
rem  Ollama with the Intel oneAPI (SYCL) backend for Intel GPUs,
rem  following the approach used by the IPEX-LLM project. The
rem  finished package is assembled into ..\IPEX-Ollama\ and can be
rem  zipped as IPEX-Ollama.zip.
rem
rem  Usage:
rem    build.bat configure   - configure the superbuild
rem    build.bat build       - build everything (default)
rem    build.bat package     - build + assemble the release folder
rem
rem  Prerequisites:
rem    - Visual Studio 2022 Build Tools (VC v143)
rem    - Intel oneAPI Base Toolkit (default install path), >= 2025.1
rem    - cmake / ninja / git / go on PATH, or in ..\..\work\tools
rem    - Network access to fetch llama.cpp, or a local copy of the
rem      pinned llama.cpp source in ..\..\work\tools\llama_cpp-src
rem ============================================================

set "SRC=%~dp0"
if "%SRC:~-1%"=="\" set "SRC=%SRC:~0,-1%"
for %%I in ("%SRC%\..") do set "PROJECT=%%~fI"
set "OUT=%PROJECT%\IPEX-Ollama"
set "BUILD=%SRC%\build"

rem ---- toolchain discovery (shared tools from the workspace layout) ----
if exist "%SRC%\..\..\work\tools" set "TOOLSPATH=%SRC%\..\..\work\tools"
if defined TOOLSPATH set "PATH=%TOOLSPATH%\cmake-4.4.2-windows-x86_64\bin;%TOOLSPATH%;%TOOLSPATH%\go\bin;%TOOLSPATH%\cmd;%PATH%"

rem ---- Visual Studio environment (MSVC cl for C code) ----
if exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" (
  call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul
) else (
  echo Error: Visual Studio 2022 Build Tools not found at the default path.
  echo Set up vcvars64.bat manually, or edit this script.
  exit /b 1
)

rem ---- Intel oneAPI environment (DPC++ icx compiler) ----
if exist "C:\Program Files (x86)\Intel\oneAPI\setvars.bat" (
  call "C:\Program Files (x86)\Intel\oneAPI\setvars.bat" intel64 --force >nul
) else (
  echo Error: Intel oneAPI not installed.
  echo Install the Intel oneAPI Base Toolkit, then rerun this script.
  exit /b 1
)

rem ---- optional local llama.cpp source (offline builds) ----
if exist "%SRC%\..\..\work\tools\llama_cpp-src\CMakeLists.txt" set "OLLAMA_LLAMA_CPP_SOURCE=%SRC%\..\..\work\tools\llama_cpp-src"
if defined OLLAMA_LLAMA_CPP_SOURCE echo Using local llama.cpp source: %OLLAMA_LLAMA_CPP_SOURCE%

rem ---- Go proxy settings (China-friendly) ----
set "GOPROXY=https://goproxy.cn,direct"
set "GOSUMDB=off"
set "GIT_SSL_NO_VERIFY=true"

where cmake >nul 2>nul || (echo Error: cmake not found. Install it or add it to PATH. & exit /b 1)
where ninja >nul 2>nul || (echo Error: ninja not found. Install it or add it to PATH. & exit /b 1)
where go >nul 2>nul || (echo Error: go not found. Install it or add it to PATH. & exit /b 1)
where git >nul 2>nul || (echo Error: git not found. Install it or add it to PATH. & exit /b 1)

if /I "%~1"=="configure" goto configure
if /I "%~1"=="package" goto package
goto build

:configure
rem Ninja is used at every level, like llama.cpp's official Windows SYCL
rem build; cl comes from the vcvars environment above. ccache is disabled
rem for reproducible builds in restricted environments.
cmake -S "%SRC%" -B "%BUILD%" -G Ninja -DCMAKE_C_COMPILER=cl -DCMAKE_CXX_COMPILER=cl -DOLLAMA_LLAMA_BACKENDS=sycl -DOLLAMA_VERSION=v0.32.6 -DCMAKE_BUILD_TYPE=Release -DGGML_CCACHE=OFF
if errorlevel 1 (
  echo configure failed
  exit /b 1
)
echo Configure OK. Run: build.bat build
exit /b 0

:build
if not exist "%BUILD%\CMakeCache.txt" (
  call :configure
  if errorlevel 1 exit /b 1
)
cmake --build "%BUILD%" --config Release --parallel 8
if errorlevel 1 (
  echo build failed
  exit /b 1
)
exit /b 0

:package
call :build
if errorlevel 1 exit /b 1

if exist "%OUT%" rmdir /s /q "%OUT%"
mkdir "%OUT%"

copy /y "%SRC%\ollama.exe" "%OUT%\" >nul
if not exist "%BUILD%\lib\ollama" (
  echo Error: native payload missing under %BUILD%\lib\ollama
  exit /b 1
)
xcopy /e /i /y "%BUILD%\lib\ollama" "%OUT%\lib\ollama\" >nul

rem ---- MinGW runtime helper (kept for layout parity with the release zip) ----
if exist "C:\Users\Han\mingw64\bin\libwinpthread-1.dll" copy /y "C:\Users\Han\mingw64\bin\libwinpthread-1.dll" "%OUT%\" >nul

copy /y "%SRC%\start-ollama.bat" "%OUT%\" >nul

echo.
echo Package ready: %OUT%
echo Zip it with:  tar -a -c -f "%PROJECT%\IPEX-Ollama.zip" -C "%PROJECT%" IPEX-Ollama
exit /b 0
