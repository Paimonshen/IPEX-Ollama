@echo off
setlocal
cd /d "%~dp0"

rem ---- Intel GPU / SYCL memory tuning ----
rem Confirm the Level Zero allocation path (zeMemAllocDevice) is used. This is
rem already llama.cpp's default on Level Zero devices, but we set it explicitly
rem so the behaviour is stable across driver/llama.cpp changes.
rem NOTE: the variable name is GGML_SYCL_USE_LEVEL_ZERO_API (there is no
rem GGML_SYCL_ENABLE_LEVEL_ZERO).
if "%GGML_SYCL_USE_LEVEL_ZERO_API%"=="" set "GGML_SYCL_USE_LEVEL_ZERO_API=1"
set "ONEAPI_DEVICE_SELECTOR=%ONEAPI_DEVICE_SELECTOR%"
if "%ONEAPI_DEVICE_SELECTOR%"=="" set "ONEAPI_DEVICE_SELECTOR=level_zero:0"

echo Starting Ollama (SYCL / Intel GPU)...
echo   GGML_SYCL_USE_LEVEL_ZERO_API=%GGML_SYCL_USE_LEVEL_ZERO_API%
echo   ONEAPI_DEVICE_SELECTOR=%ONEAPI_DEVICE_SELECTOR%
echo.
echo IMPORTANT for Intel iGPUs (user-verified on i5-1135G7):
echo   Weights are held twice - once in the OS file cache (mmap) and once in
echo   device memory - so memory roughly DOUBLES (28GB model - 56GB RAM).
echo   On an iGPU you should disable mmap per request:
echo     curl http://127.0.0.1:11434/api/generate -d "{\"model\":\"...\",\"options\":{\"use_mmap\":false}}"
echo   This removes the duplicate copy and also loads ~3x faster.
echo   Do NOT use "num_gpu" (partial offload) on an iGPU - it can hang/crash.
echo.

ollama serve
