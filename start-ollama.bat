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
echo Tip for large models (32B+) on Intel iGPUs:
echo   Memory roughly doubles because weights are kept both in the OS file
echo   cache (mmap) and in GPU memory. To avoid this, disable mmap per request:
echo     curl http://127.0.0.1:11434/api/generate -d "{\"model\":\"...\",\"options\":{\"use_mmap\":false}}"
echo   or reduce offload with a smaller number of GPU layers.
echo.

ollama serve
