# GitHub Actions 自动编译与发布说明

本仓库配置了 GitHub Actions 自动编译系统,支持双架构(x86_64 和 ARM64)编译,并按照 UOS/deepin 规范打包。

## 触发方式

### 1. 自动触发(推荐)
创建新的 Git 标签即可触发自动编译和发布:

```bash
# 创建标签
git tag v1.0.0

# 推送标签到 GitHub
git push origin v1.0.0
```

推送标签后,GitHub Actions 将自动:
- 在 x86_64 和 ARM64 架构上编译
- 生成符合 UOS/deepin 规范的 .deb 安装包
- 创建 GitHub Release 并上传安装包

### 2. 手动触发
在 GitHub 仓库页面:
1. 进入 "Actions" 标签
2. 选择 "Build and Release" workflow
3. 点击 "Run workflow"

## 构建产物

每次构建会生成两个安装包:
- `io.github.kero990.zuma-deluxe-hd_{版本}_amd64.deb` - x86_64 架构
- `io.github.kero990.zuma-deluxe-hd_{版本}_arm64.deb` - ARM64 架构

## 包结构

生成的 .deb 包遵循 UOS/deepin 应用打包规范:

```
/opt/apps/io.github.kero990.zuma-deluxe-hd/
├── files/                  # 应用程序文件
│   ├── ZumaHD             # 游戏主程序
│   ├── run.sh             # 启动脚本
│   ├── content/           # 游戏资源
│   └── lib/               # 依赖库
├── entries/
│   ├── applications/      # .desktop 文件
│   └── icons/             # 应用图标
└── info                   # 应用元数据
```

## 安装方法

### UOS/Deepin 系统
```bash
sudo dpkg -i io.github.kero990.zuma-deluxe-hd_*_amd64.deb
```

### 其他 Debian 系系统
也可以使用 dpkg 安装,但图标和菜单项可能不会自动配置。

## 本地测试

如果需要在本地测试编译流程:

```bash
# 模拟 AMD64 编译
docker run --rm --platform linux/amd64 \
  -v $PWD:/workspace -w /workspace \
  debian:10 bash -c '
    apt-get update && apt-get install -y build-essential cmake git wget curl pkg-config libsdl2-dev libsdl2-image-dev libsdl2-ttf-dev
    ./scripts/download_deps.sh
    mkdir -p build && cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release
    make -j$(nproc)
    make install
  '

# 模拟 ARM64 编译(需要 QEMU 支持)
docker run --rm --platform linux/arm64 \
  -v $PWD:/workspace -w /workspace \
  debian:10 bash -c '
    apt-get update && apt-get install -y build-essential cmake git wget curl pkg-config libsdl2-dev libsdl2-image-dev libsdl2-ttf-dev
    ./scripts/download_deps.sh
    mkdir -p build && cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release
    make -j$(nproc)
    make install
  '
```

## 依赖说明

### 编译依赖
- build-essential
- cmake (>= 3.15)
- git
- wget/curl
- pkg-config
- libsdl2-dev
- libsdl2-image-dev
- libsdl2-ttf-dev

### 运行时依赖
- libsdl2-2.0-0
- libsdl2-image-2.0-0
- libsdl2-ttf-2.0-0
- BASS/BASSFX (已打包在 lib/ 目录中)

## 故障排查

### 构建失败
1. 检查 Actions 日志中的错误信息
2. 确认所有子模块已正确初始化
3. 验证 BASS/BASSFX 下载是否成功

### 安装失败
1. 检查依赖是否满足:`apt-get -f install`
2. 确认架构匹配:`dpkg --print-architecture`

## 参考

- [UOS/deepin 应用打包规范](https://github.com/kero990/auto-actions)
- [GitHub Actions 文档](https://docs.github.com/actions)
