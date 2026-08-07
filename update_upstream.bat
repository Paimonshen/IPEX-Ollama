@echo off
setlocal
rem ============================================================
rem  Refresh the SYCL fork against the latest upstream Ollama.
rem  Fetches upstream master, rebases the local SYCL commits on
rem  top, and regenerates patches\ollama-sycl.patch.
rem ============================================================

set "SRC=%~dp0"
set "PATCHDIR=%SRC%patches"

where git >nul 2>nul || (echo Error: git not found. Install it or add it to PATH. & exit /b 1)

git -C "%SRC%" fetch origin master
if errorlevel 1 (
  echo Fetch failed. Check network access to https://github.com/ollama/ollama.git
  exit /b 1
)

git -C "%SRC%" rebase origin/master
if errorlevel 1 (
  echo.
  echo Rebase conflicts. Resolve them, then run: git -C "%SRC%" rebase --continue
  echo and rerun this script to regenerate the patch.
  exit /b 1
)

if not exist "%PATCHDIR%" mkdir "%PATCHDIR%"
git -C "%SRC%" diff origin/master...HEAD --binary > "%PATCHDIR%\ollama-sycl.patch"
echo.
echo Upstream rebase complete.
echo Patch exported to %PATCHDIR%\ollama-sycl.patch
echo Rebuild with: build.bat package
endlocal
