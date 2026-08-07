@echo off
setlocal
rem Export the SYCL fork changes as a single patch for review or for
rem applying to a fresh upstream checkout.
set "SRC=%~dp0"
set "PATCHDIR=%SRC%patches"
if not exist "%PATCHDIR%" mkdir "%PATCHDIR%"
git -C "%SRC%" diff c82ebbd...HEAD --binary > "%PATCHDIR%\ollama-sycl.patch"
echo Patch exported to %PATCHDIR%\ollama-sycl.patch
endlocal
