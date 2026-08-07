# IPEX-Ollama

**Ollama（Windows 版）· Intel oneAPI (SYCL) 后端构建** — 参考 [IPEX-LLM](https://github.com/intel/ipex-llm) 项目的思路，让 Ollama 通过 Intel oneAPI / Level Zero 直接调用 Intel 显卡（Arc、Iris Xe、核显）加速本地大模型推理。

本项目基于上游 [ollama/ollama](https://github.com/ollama/ollama)（v0.32.6，commit `c82ebbd`）fork，仅以少量最小化改动（约 150 行）增加 **SYCL 后端**，便于持续合并上游更新。

## 特性

- ✅ Ollama v0.32.6 + llama.cpp SYCL 后端（`ggml-sycl.dll`，使用 Intel oneAPI DPC++ 编译器构建）
- ✅ 通过 Level Zero 直接驱动 Intel GPU（Arc B580 实测 33/33 层全量卸载，约 150 tok/s）
- ✅ 成品包自包含：oneDNN / oneMKL / SYCL 运行时 / Level Zero 适配器全部内置，**目标机无需安装 oneAPI**
- ✅ `build.bat` 一键编译 / 打包
- ✅ 改动收敛为 4 个提交、6 个文件，`update_upstream.bat` 可一键 rebase 上游并导出补丁

## 硬件与系统要求

- Windows 10/11 x64
- Intel GPU：Arc A/B 系列、Iris Xe、Intel 核显（11 代酷睿及以上）
- 最新 Intel 显卡驱动（需包含 Level Zero 运行时）

## 下载与使用

从本项目 **Releases** 页面下载 `IPEX-Ollama.zip`（约 170 MB），解压后双击 `start-ollama.bat`：

```bat
start-ollama.bat
```

服务启动后默认监听 `127.0.0.1:11434`，验证 GPU 是否被识别：

```bat
curl http://127.0.0.1:11434/api/tags
ollama run qwen2.5:3b
```

启动日志中应出现：

```
inference compute ... library=SYCL name=SYCL0 description="Intel(R) Arc(TM) B580 Graphics"
  type=discrete total="11.6 GiB" available="10.2 GiB"
```

推理时日志确认模型全部卸载到 GPU：

```
llama_prepare_model_devices: using device SYCL0 (Intel(R) Arc(TM) B580 Graphics)
load_tensors: offloaded 33/33 layers to GPU
```

> 如果同时安装了 Vulkan 包，可用 `set OLLAMA_LLM_LIBRARY=sycl` 强制走 SYCL。
> 多卡时用 `ONEAPI_DEVICE_SELECTOR=level_zero:0;level_zero:1` 选择设备。

## 目录结构

```
IPEX-Ollama/
├─ Source/                 # 源码（含 build.bat 构建脚本、codex/sycl 分支）
├─ IPEX-Ollama/            # 成品文件夹（解压即用）
├─ IPEX-Ollama.zip         # 成品压缩包
└─ README.md
```

## 从源码构建

### 前置条件

- Visual Studio 2022 Build Tools（VC v143）
- Intel oneAPI Base Toolkit（默认路径 `C:\Program Files (x86)\Intel\oneAPI`，建议 2025.1+）
- CMake、Ninja、Git、Go（或在 `work\tools` 中放置，脚本会自动识别）
- 构建时需要联网拉取 llama.cpp（或本地已有固定版本的 llama.cpp 源码）

### 构建

```bat
cd Source
build.bat package
```

等价于 `configure` → `build` → 组装成品到 `..\IPEX-Ollama\`，之后可按提示打包为 `IPEX-Ollama.zip`。

### 对上游的改动

`Source` 的 `main` 分支包含 4 个提交（`codex/sycl` 分支为开发分支）：

| 提交 | 内容 |
|---|---|
| build | `OLLAMA_LLAMA_BACKENDS` 新增 `sycl` 后端（Ninja + cl/icx，安装时自动捆绑 oneAPI 运行库） |
| discover | SYCL 设备识别 + `ONEAPI_DEVICE_SELECTOR` 设备选择 |
| build | 子构建显式继承父级生成器 |
| build | MSVC 编译器按短名透传（避免工具链漂移） |

## 同步上游更新

```bat
cd Source
update_upstream.bat
```

脚本会 fetch 上游 master → rebase 本地 SYCL 提交 → 重新导出 `Source\patches\ollama-sycl.patch`。补丁也可手动应用到任意上游 checkout：

```bat
git apply ollama-sycl.patch
```

## 致谢

- [ollama/ollama](https://github.com/ollama/ollama) — 上游项目
- [ggml-org/llama.cpp](https://github.com/ggml-org/llama.cpp) — SYCL 推理后端
- [intel/ipex-llm](https://github.com/intel/ipex-llm) — Intel GPU 上运行 LLM 的参考项目
- Intel oneAPI — DPC++ 编译器与 Level Zero 运行时

## License

Ollama 上游使用 MIT License，本项目同样遵循。
