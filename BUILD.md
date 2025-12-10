# Zuma Deluxe HD - 构建指南

本项目使用CMake构建系统，支持自动下载依赖、编译和打包绿色便携版。

## 目录

- [快速开始](#快速开始)
- [系统要求](#系统要求)
- [详细构建步骤](#详细构建步骤)
- [依赖说明](#依赖说明)
- [手动构建](#手动构建)
- [故障排除](#故障排除)

## 快速开始

一键构建（推荐）:

```bash
./build_all.sh
```

这个脚本会自动完成以下所有步骤：
1. 检查必要工具和依赖
2. 初始化libexpat子模块
3. 自动下载BASS和BASSFX库
4. 配置CMake
5. 编译项目
6. 打包成绿色便携版

构建完成后，程序位于 `build/install/` 目录。

## 系统要求

### 必须的系统工具

- **编译工具**:
  - gcc
  - make
  - cmake (>= 3.15)
  - pkg-config

- **下载工具**（二选一）:
  - wget 或 curl

- **其他工具**:
  - git
  - unzip

### 系统依赖库

需要通过系统包管理器安装SDL2相关库：

**Debian/Ubuntu**:
```bash
sudo apt-get install libsdl2-dev libsdl2-image-dev libsdl2-ttf-dev
```

**Fedora/RHEL**:
```bash
sudo dnf install SDL2-devel SDL2_image-devel SDL2_ttf-devel
```

**Arch Linux**:
```bash
sudo pacman -S sdl2 sdl2_image sdl2_ttf
```

### 支持的架构

- x86_64 (amd64)
- aarch64 (arm64)
- armhf (armv7l)
- x86 (i686)

## 详细构建步骤

### 1. 克隆仓库

```bash
git clone <repository-url>
cd Zuma-Deluxe-HD
```

### 2. 初始化子模块

libexpat作为git子模块管理：

```bash
git submodule update --init --recursive
```

### 3. 下载音频库依赖

BASS和BASSFX会自动从官方网站下载：

```bash
./scripts/download_deps.sh
```

这会根据系统架构自动下载对应版本的：
- BASS Audio Library (来自 www.un4seen.com)
- BASS FX Audio Effects (来自 www.un4seen.com)

### 4. 配置CMake

```bash
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
```

CMake会自动：
- 检测系统架构
- 查找SDL2依赖
- 编译libexpat子模块
- 验证BASS/BASSFX库是否存在（如不存在会自动下载）

### 5. 编译

```bash
make -j$(nproc)
```

### 6. 安装（打包）

```bash
make install
```

这会创建绿色便携版到 `build/install/` 目录，包含：
- `ZumaHD` - 游戏主程序
- `run.sh` - 启动脚本（推荐使用）
- `README.txt` - 使用说明
- `content/` - 游戏资源目录
- `lib/` - 依赖库文件（libbass.so, libbass_fx.so, libexpat.so）

## 依赖说明

### 1. libexpat (Git子模块)

- **管理方式**: Git子模块
- **仓库**: https://github.com/libexpat/libexpat.git
- **用途**: XML解析
- **编译**: 由CMake自动编译，无需手动操作

### 2. BASS Audio Library (自动下载)

- **来源**: https://www.un4seen.com/files/bass24-linux.zip
- **用途**: 音频播放
- **许可**: 免费用于非商业用途
- **位置**: `deps/bass/libs/{架构}/libbass.so`

### 3. BASS FX (自动下载)

- **来源**: https://www.un4seen.com/files/bass_fx24-linux.zip
- **用途**: 音频特效
- **许可**: 免费用于非商业用途
- **位置**: `deps/bassfx/libs/{架构}/libbass_fx.so`

### 4. SDL2系列（系统安装）

- **SDL2**: 图形和窗口管理
- **SDL2_image**: 图片加载
- **SDL2_ttf**: 字体渲染
- **安装**: 通过系统包管理器

## 手动构建

如果不想使用自动脚本，可以手动执行各步骤：

```bash
# 1. 初始化子模块
git submodule update --init --recursive

# 2. 下载依赖（可选，CMake会自动调用）
./scripts/download_deps.sh

# 3. 配置并编译
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)

# 4. 安装
make install

# 5. 运行
cd install
./run.sh
```

## 绿色便携版使用

构建完成后，`build/install/` 目录是完全独立的，可以：

### 直接运行

```bash
cd build/install
./run.sh
```

### 打包分发

```bash
cd build
tar -czf ZumaHD-linux-$(uname -m).tar.gz -C install .
```

### 复制到其他位置

整个 `install` 目录可以复制到任何位置，无需重新配置：

```bash
cp -r build/install ~/Games/ZumaHD
cd ~/Games/ZumaHD
./run.sh
```

## CMake选项

### 构建类型

```bash
cmake .. -DCMAKE_BUILD_TYPE=Release   # 发布版（默认，推荐）
cmake .. -DCMAKE_BUILD_TYPE=Debug     # 调试版
```

### 自定义安装路径

默认安装到 `build/install/`，可以自定义：

```bash
cmake .. -DINSTALL_PREFIX=/path/to/install
```

## 目录结构

```
Zuma-Deluxe-HD/
├── build_all.sh              # 一键构建脚本
├── CMakeLists.txt            # CMake配置文件
├── BUILD.md                  # 本文档
├── scripts/
│   └── download_deps.sh      # 依赖下载脚本
├── deps/
│   ├── libexpat/             # libexpat子模块
│   ├── bass/                 # BASS库（自动下载）
│   └── bassfx/               # BASSFX库（自动下载）
├── include/                  # 头文件
├── src/                      # 源代码
├── content/                  # 游戏资源
└── build/                    # 构建目录（自动创建）
    ├── ZumaHD                # 编译的可执行文件
    └── install/              # 绿色便携版（make install后）
        ├── ZumaHD
        ├── run.sh
        ├── README.txt
        ├── content/
        └── lib/
```

## 故障排除

### CMake找不到SDL2

**问题**: `Could not find SDL2`

**解决**:
```bash
# Debian/Ubuntu
sudo apt-get install libsdl2-dev libsdl2-image-dev libsdl2-ttf-dev

# 或检查pkg-config路径
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH
```

### 依赖下载失败

**问题**: 无法下载BASS或BASSFX

**解决**:
1. 检查网络连接
2. 手动下载并解压到对应目录：
   - BASS: https://www.un4seen.com/files/bass24-linux.zip → `deps/bass/`
   - BASSFX: https://www.un4seen.com/files/bass_fx24-linux.zip → `deps/bassfx/`

### libexpat子模块为空

**问题**: `deps/libexpat` 目录为空

**解决**:
```bash
git submodule update --init --recursive
```

### 运行时找不到共享库

**问题**: `error while loading shared libraries: libbass.so`

**解决**: 使用 `run.sh` 启动脚本，它会自动设置 `LD_LIBRARY_PATH`

或手动设置：
```bash
export LD_LIBRARY_PATH=./lib:$LD_LIBRARY_PATH
./ZumaHD
```

### 架构不匹配

**问题**: 不支持的架构

**解决**: 检查当前架构 `uname -m`，确保BASS库支持该架构。BASS官方支持：
- x86_64
- aarch64
- armhf
- x86

## 清理构建

```bash
# 清理构建文件
rm -rf build/

# 清理下载的依赖（保留libexpat子模块）
rm -rf deps/bass/ deps/bassfx/
```

## 开发相关

### 仅编译（不安装）

```bash
cd build
make -j$(nproc)
./ZumaHD  # 需要手动设置LD_LIBRARY_PATH
```

### 重新配置

```bash
cd build
cmake .. -DCMAKE_BUILD_TYPE=Debug
make clean
make -j$(nproc)
```

## 许可说明

- **本项目代码**: [你的许可证]
- **BASS Audio Library**: 免费用于非商业用途（商业使用需授权）
- **libexpat**: MIT许可证
- **SDL2系列**: zlib许可证

## 获取帮助

如有问题，请：
1. 查看本文档的故障排除部分
2. 检查CMake输出信息
3. 提交Issue到项目仓库
