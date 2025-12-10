#!/bin/bash
# 依赖下载脚本 - 自动下载BASS和BASSFX库

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEPS_DIR="$PROJECT_ROOT/deps"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Zuma Deluxe HD - 依赖下载脚本${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检测系统架构
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

echo -e "${GREEN}检测到系统架构: $ARCH -> $BASS_ARCH${NC}"
echo ""

# 下载BASS
echo -e "${YELLOW}[1/2] 下载BASS Audio Library...${NC}"
BASS_DIR="$DEPS_DIR/bass"
BASS_URL="https://www.un4seen.com/files/bass24-linux.zip"
BASS_TEMP="$DEPS_DIR/bass24-linux.zip"

if [ -f "$BASS_DIR/libs/$BASS_ARCH/libbass.so" ]; then
    echo -e "${GREEN}✓ BASS已存在，跳过下载${NC}"
else
    echo "  下载URL: $BASS_URL"
    mkdir -p "$BASS_DIR"

    if command -v wget &> /dev/null; then
        wget -q --show-progress -O "$BASS_TEMP" "$BASS_URL"
    elif command -v curl &> /dev/null; then
        curl -L -o "$BASS_TEMP" "$BASS_URL"
    else
        echo -e "${RED}错误: 需要wget或curl来下载依赖${NC}"
        exit 1
    fi

    echo "  解压BASS..."
    unzip -q -o "$BASS_TEMP" -d "$BASS_DIR"
    rm -f "$BASS_TEMP"

    # 验证文件
    if [ ! -f "$BASS_DIR/libs/$BASS_ARCH/libbass.so" ]; then
        echo -e "${RED}错误: 无法找到架构 $BASS_ARCH 的BASS库${NC}"
        echo "可用架构:"
        ls -l "$BASS_DIR/libs/"
        exit 1
    fi

    echo -e "${GREEN}✓ BASS下载完成${NC}"
fi

echo ""

# 下载BASSFX
echo -e "${YELLOW}[2/2] 下载BASS FX Library...${NC}"
BASSFX_DIR="$DEPS_DIR/bassfx"
BASSFX_URL="https://www.un4seen.com/files/bass_fx24-linux.zip"
BASSFX_TEMP="$DEPS_DIR/bass_fx24-linux.zip"

if [ -f "$BASSFX_DIR/libs/$BASS_ARCH/libbass_fx.so" ]; then
    echo -e "${GREEN}✓ BASS FX已存在，跳过下载${NC}"
else
    echo "  下载URL: $BASSFX_URL"
    mkdir -p "$BASSFX_DIR"

    if command -v wget &> /dev/null; then
        wget -q --show-progress -O "$BASSFX_TEMP" "$BASSFX_URL"
    elif command -v curl &> /dev/null; then
        curl -L -o "$BASSFX_TEMP" "$BASSFX_URL"
    else
        echo -e "${RED}错误: 需要wget或curl来下载依赖${NC}"
        exit 1
    fi

    echo "  解压BASS FX..."
    unzip -q -o "$BASSFX_TEMP" -d "$BASSFX_DIR"
    rm -f "$BASSFX_TEMP"

    # 验证文件
    if [ ! -f "$BASSFX_DIR/libs/$BASS_ARCH/libbass_fx.so" ]; then
        echo -e "${RED}错误: 无法找到架构 $BASS_ARCH 的BASS FX库${NC}"
        echo "可用架构:"
        ls -l "$BASSFX_DIR/libs/"
        exit 1
    fi

    echo -e "${GREEN}✓ BASS FX下载完成${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}依赖下载完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "已下载的库:"
echo "  - BASS:    $BASS_DIR/libs/$BASS_ARCH/libbass.so"
echo "  - BASS FX: $BASSFX_DIR/libs/$BASS_ARCH/libbass_fx.so"
echo ""
echo -e "${YELLOW}注意: libexpat将在CMake构建时自动从git子模块编译${NC}"
echo ""
