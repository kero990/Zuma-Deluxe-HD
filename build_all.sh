#!/bin/bash
# Zuma Deluxe HD - 完整构建脚本
# 此脚本会自动下载依赖、编译项目并打包成绿色便携版

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 清屏并显示欢迎信息
clear
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                   Zuma Deluxe HD                              ║"
echo "║                  完整构建系统                                 ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# 步骤1: 检查必要工具
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}[1/6] 检查必要工具...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}✗ 错误: 未找到 $1${NC}"
        echo -e "${YELLOW}  请安装: $2${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ $1${NC}"
    fi
}

check_command "git" "git"
check_command "cmake" "cmake (>= 3.15)"
check_command "make" "make 或 build-essential"
check_command "gcc" "gcc 或 build-essential"
check_command "pkg-config" "pkg-config"

# 检查下载工具 (wget或curl其中之一即可)
if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
    echo -e "${RED}✗ 错误: 需要 wget 或 curl 来下载依赖${NC}"
    exit 1
else
    if command -v wget &> /dev/null; then
        echo -e "${GREEN}✓ wget${NC}"
    else
        echo -e "${GREEN}✓ curl${NC}"
    fi
fi

check_command "unzip" "unzip"

# 检查SDL2依赖
echo ""
echo -e "${YELLOW}检查SDL2依赖...${NC}"
if ! pkg-config --exists sdl2; then
    echo -e "${RED}✗ 错误: 未找到SDL2${NC}"
    echo -e "${YELLOW}  请安装: libsdl2-dev${NC}"
    exit 1
else
    echo -e "${GREEN}✓ SDL2 $(pkg-config --modversion sdl2)${NC}"
fi

if ! pkg-config --exists SDL2_image; then
    echo -e "${RED}✗ 错误: 未找到SDL2_image${NC}"
    echo -e "${YELLOW}  请安装: libsdl2-image-dev${NC}"
    exit 1
else
    echo -e "${GREEN}✓ SDL2_image$(NC}"
fi

if ! pkg-config --exists SDL2_ttf; then
    echo -e "${RED}✗ 错误: 未找到SDL2_ttf${NC}"
    echo -e "${YELLOW}  请安装: libsdl2-ttf-dev${NC}"
    exit 1
else
    echo -e "${GREEN}✓ SDL2_ttf${NC}"
fi

echo ""
sleep 1

# 步骤2: 初始化Git子模块
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}[2/6] 初始化Git子模块 (libexpat)...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ ! -d "deps/libexpat/.git" ]; then
    echo "正在初始化libexpat子模块..."
    git submodule update --init --recursive deps/libexpat
    echo -e "${GREEN}✓ libexpat子模块初始化完成${NC}"
else
    echo "正在更新libexpat子模块..."
    git submodule update --recursive deps/libexpat
    echo -e "${GREEN}✓ libexpat子模块已是最新${NC}"
fi

echo ""
sleep 1

# 步骤3: 下载BASS和BASSFX依赖（如果需要）
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}[3/6] 检查并下载音频库依赖...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 检测架构
ARCH=$(uname -m)
case "$ARCH" in
    x86_64|amd64)
        BASS_ARCH="x86_64"
        ;;
    aarch64|arm64)
        BASS_ARCH="aarch64"
        ;;
    armv7l|armhf)
        BASS_ARCH="armhf"
        ;;
    i686|i386|x86)
        BASS_ARCH="x86"
        ;;
    *)
        echo -e "${RED}错误: 不支持的架构 $ARCH${NC}"
        exit 1
        ;;
esac

echo -e "${CYAN}系统架构: $ARCH -> $BASS_ARCH${NC}"
echo ""

# 检查并下载依赖
if [ -f "deps/bass/libs/$BASS_ARCH/libbass.so" ] && [ -f "deps/bassfx/libs/$BASS_ARCH/libbass_fx.so" ]; then
    echo -e "${GREEN}✓ 音频库依赖已存在，跳过下载${NC}"
else
    echo -e "${YELLOW}运行依赖下载脚本...${NC}"
    echo ""
    bash scripts/download_deps.sh
fi

echo ""
sleep 1

# 步骤4: 配置CMake
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}[4/6] 配置CMake...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 创建构建目录
BUILD_DIR="build"
if [ -d "$BUILD_DIR" ]; then
    echo -e "${YELLOW}清理旧的构建目录...${NC}"
    rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "运行CMake配置..."
cmake .. -DCMAKE_BUILD_TYPE=Release

echo ""
echo -e "${GREEN}✓ CMake配置完成${NC}"
echo ""
sleep 1

# 步骤5: 编译项目
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}[5/6] 编译项目...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 获取CPU核心数以加速编译
NPROC=$(nproc 2>/dev/null || echo 4)
echo "使用 $NPROC 个线程进行编译..."
echo ""

make -j$NPROC

echo ""
echo -e "${GREEN}✓ 编译完成${NC}"
echo ""
sleep 1

# 步骤6: 安装（打包绿色便携版）
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}[6/6] 打包绿色便携版...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 清理旧的安装目录
INSTALL_DIR="install"
if [ -d "$INSTALL_DIR" ]; then
    echo "清理旧的安装目录..."
    rm -rf "$INSTALL_DIR"
fi

echo "安装文件到 build/install/ ..."
make install

echo ""
echo -e "${GREEN}✓ 打包完成${NC}"
echo ""

# 显示完成信息
cd ..  # 回到项目根目录

echo ""
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                     构建成功！                                ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${GREEN}绿色便携版已创建在: ${YELLOW}build/install/${NC}"
echo ""
echo -e "${CYAN}目录结构:${NC}"
echo "  build/install/"
echo "    ├── ZumaHD           (游戏主程序)"
echo "    ├── run.sh           (启动脚本)"
echo "    ├── README.txt       (使用说明)"
echo "    ├── content/         (游戏资源)"
echo "    └── lib/             (依赖库)"
echo ""
echo -e "${CYAN}运行方法:${NC}"
echo -e "  1. 进入目录: ${YELLOW}cd build/install/${NC}"
echo -e "  2. 运行游戏: ${YELLOW}./run.sh${NC}"
echo ""
echo -e "${CYAN}打包方法:${NC}"
echo -e "  ${YELLOW}tar -czf ZumaHD-linux-$BASS_ARCH.tar.gz -C build/install .${NC}"
echo ""
echo -e "${GREEN}可以将整个 build/install 目录复制到任何位置或其他电脑使用！${NC}"
echo ""
