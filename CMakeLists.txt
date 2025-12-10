cmake_minimum_required(VERSION 3.15)
project(ZumaHD VERSION 1.0 LANGUAGES C)

# 设置C标准
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# 编译选项
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -O2")

# 检测系统架构
if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|amd64|AMD64")
    set(ARCH "x86_64")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|arm64|ARM64")
    set(ARCH "aarch64")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "armv7l|armhf")
    set(ARCH "armhf")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "i686|i386|x86")
    set(ARCH "x86")
else()
    message(FATAL_ERROR "Unsupported architecture: ${CMAKE_SYSTEM_PROCESSOR}")
endif()

message(STATUS "Detected architecture: ${ARCH}")

# 依赖路径
set(DEPS_DIR "${CMAKE_SOURCE_DIR}/deps")
set(BASS_DIR "${DEPS_DIR}/bass")
set(BASSFX_DIR "${DEPS_DIR}/bassfx")
set(EXPAT_DIR "${DEPS_DIR}/libexpat")

# ============================================
# 下载BASS/BASSFX Audio Libraries
# ============================================
set(BASS_LIB "${BASS_DIR}/libs/${ARCH}/libbass.so")
set(BASSFX_LIB "${BASSFX_DIR}/libs/${ARCH}/libbass_fx.so")

# 检查BASS/BASSFX是否已存在
if(NOT EXISTS ${BASS_LIB} OR NOT EXISTS ${BASSFX_LIB})
    message(STATUS "Downloading BASS/BASSFX libraries using script...")

    # 调用下载脚本
    execute_process(
        COMMAND ${CMAKE_SOURCE_DIR}/scripts/download_deps.sh
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        RESULT_VARIABLE DOWNLOAD_RESULT
    )

    if(NOT DOWNLOAD_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to download BASS/BASSFX dependencies")
    endif()

    # 验证下载结果
    if(NOT EXISTS ${BASS_LIB})
        message(FATAL_ERROR "BASS library not found at ${BASS_LIB} after download")
    endif()

    if(NOT EXISTS ${BASSFX_LIB})
        message(FATAL_ERROR "BASS FX library not found at ${BASSFX_LIB} after download")
    endif()

    message(STATUS "BASS/BASSFX downloaded successfully")
else()
    message(STATUS "Using existing BASS/BASSFX libraries")
endif()

# ============================================
# SDL2 依赖处理 - 优先使用系统依赖
# ============================================
include(FetchContent)

# 尝试查找系统SDL2库
find_package(PkgConfig)
if(PKG_CONFIG_FOUND)
    # 检查SDL2
    pkg_check_modules(SDL2_SYS sdl2>=2.0.20)
    # 检查SDL2_image
    pkg_check_modules(SDL2_IMAGE_SYS SDL2_image>=2.6.0)
    # 检查SDL2_ttf
    pkg_check_modules(SDL2_TTF_SYS SDL2_ttf>=2.20.0)
endif()

# 判断是否使用系统SDL2
set(USE_SYSTEM_SDL2 OFF)
if(SDL2_SYS_FOUND AND SDL2_IMAGE_SYS_FOUND AND SDL2_TTF_SYS_FOUND)
    set(USE_SYSTEM_SDL2 ON)
    message(STATUS "Found system SDL2 ${SDL2_SYS_VERSION} (>= 2.0.20)")
    message(STATUS "Found system SDL2_image ${SDL2_IMAGE_SYS_VERSION} (>= 2.6.0)")
    message(STATUS "Found system SDL2_ttf ${SDL2_TTF_SYS_VERSION} (>= 2.20.0)")
    message(STATUS "Using system SDL2 libraries")
else()
    message(STATUS "System SDL2 not found or version too old, will download and compile")
    if(NOT SDL2_SYS_FOUND)
        message(STATUS "  - SDL2: not found or < 2.0.20")
    endif()
    if(NOT SDL2_IMAGE_SYS_FOUND)
        message(STATUS "  - SDL2_image: not found or < 2.6.0")
    endif()
    if(NOT SDL2_TTF_SYS_FOUND)
        message(STATUS "  - SDL2_ttf: not found or < 2.20.0")
    endif()
endif()

# 如果不使用系统SDL2，则通过FetchContent下载编译
if(NOT USE_SYSTEM_SDL2)
    # Fetch SDL2
    message(STATUS "Fetching SDL2...")
    FetchContent_Declare(
        sdl2
        GIT_REPOSITORY https://github.com/libsdl-org/SDL.git
        GIT_TAG        release-2.30.10
    )
    FetchContent_MakeAvailable(sdl2)

    # Fetch SDL2_image
    message(STATUS "Fetching SDL2_image...")
    FetchContent_Declare(
        sdl2_image
        GIT_REPOSITORY https://github.com/libsdl-org/SDL_image.git
        GIT_TAG        release-2.8.4
    )
    set(SDL2IMAGE_SAMPLES OFF CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(sdl2_image)

    # Fetch SDL2_ttf
    message(STATUS "Fetching SDL2_ttf...")
    FetchContent_Declare(
        sdl2_ttf
        GIT_REPOSITORY https://github.com/libsdl-org/SDL_ttf.git
        GIT_TAG        release-2.22.0
    )
    set(SDL2TTF_SAMPLES OFF CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(sdl2_ttf)
endif()

# ============================================
# libexpat 处理 - 使用git子模块
# ============================================
# 配置libexpat子模块编译选项
set(EXPAT_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(EXPAT_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(EXPAT_BUILD_TOOLS OFF CACHE BOOL "" FORCE)
set(EXPAT_SHARED_LIBS ON CACHE BOOL "" FORCE)
set(EXPAT_BUILD_DOCS OFF CACHE BOOL "" FORCE)
set(EXPAT_BUILD_FUZZERS OFF CACHE BOOL "" FORCE)

# 使用git子模块中的libexpat
if(EXISTS "${EXPAT_DIR}/expat/CMakeLists.txt")
    message(STATUS "Using libexpat from git submodule")
    add_subdirectory(${EXPAT_DIR}/expat EXCLUDE_FROM_ALL)
else()
    message(STATUS "Fetching libexpat...")
    FetchContent_Declare(
        expat
        GIT_REPOSITORY https://github.com/libexpat/libexpat.git
        GIT_TAG        R_2_6_4
    )
    FetchContent_MakeAvailable(expat)
    add_subdirectory(${expat_SOURCE_DIR}/expat ${expat_BINARY_DIR})
endif()

# ============================================
# 源文件
# ============================================
file(GLOB SOURCES "src/*.c")

# 创建可执行文件
add_executable(${PROJECT_NAME} ${SOURCES})

# 头文件目录
target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_SOURCE_DIR}/include
    ${BASS_DIR}/c
    ${BASSFX_DIR}/C
)

# 链接库目录
target_link_directories(${PROJECT_NAME} PRIVATE
    ${BASS_DIR}/libs/${ARCH}
    ${BASSFX_DIR}/libs/${ARCH}
)

# 链接库
if(USE_SYSTEM_SDL2)
    # 使用系统SDL2库
    target_link_libraries(${PROJECT_NAME} PRIVATE
        ${SDL2_SYS_LIBRARIES}
        ${SDL2_IMAGE_SYS_LIBRARIES}
        ${SDL2_TTF_SYS_LIBRARIES}
        bass
        bass_fx
        expat
        m
    )

    # 添加系统SDL2的包含目录和库目录
    target_include_directories(${PROJECT_NAME} PRIVATE
        ${SDL2_SYS_INCLUDE_DIRS}
        ${SDL2_IMAGE_SYS_INCLUDE_DIRS}
        ${SDL2_TTF_SYS_INCLUDE_DIRS}
    )

    target_link_directories(${PROJECT_NAME} PRIVATE
        ${SDL2_SYS_LIBRARY_DIRS}
        ${SDL2_IMAGE_SYS_LIBRARY_DIRS}
        ${SDL2_TTF_SYS_LIBRARY_DIRS}
    )
else()
    # 使用FetchContent编译的SDL2库
    target_link_libraries(${PROJECT_NAME} PRIVATE
        SDL2::SDL2
        SDL2_image::SDL2_image
        SDL2_ttf::SDL2_ttf
        bass
        bass_fx
        expat
        m
    )
endif()

# 设置RPATH为相对路径，使程序可移植
set_target_properties(${PROJECT_NAME} PROPERTIES
    BUILD_RPATH_USE_ORIGIN TRUE
    INSTALL_RPATH "$ORIGIN/lib"
    BUILD_WITH_INSTALL_RPATH FALSE
)

# ============================================
# 安装规则
# ============================================
set(INSTALL_PREFIX "${CMAKE_BINARY_DIR}/install" CACHE PATH "Installation directory")

# 安装可执行文件
install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION ${INSTALL_PREFIX}
)

# 安装游戏资源
install(DIRECTORY ${CMAKE_SOURCE_DIR}/content
    DESTINATION ${INSTALL_PREFIX}
    PATTERN ".git" EXCLUDE
)

# 安装依赖库
install(FILES ${BASS_LIB}
    DESTINATION ${INSTALL_PREFIX}/lib
)

install(FILES ${BASSFX_LIB}
    DESTINATION ${INSTALL_PREFIX}/lib
)

# 安装libexpat
install(TARGETS expat
    LIBRARY DESTINATION ${INSTALL_PREFIX}/lib
)

# 创建启动脚本
set(RUN_SCRIPT "${CMAKE_BINARY_DIR}/run.sh")
file(WRITE ${RUN_SCRIPT}
"#!/bin/bash
# Zuma Deluxe HD 启动脚本

# 获取脚本所在目录
cd \"$(dirname \"$0\")\"

# 设置库路径
export LD_LIBRARY_PATH=\"\$PWD/lib:\$LD_LIBRARY_PATH\"

# 运行游戏
exec ./ZumaHD \"\$@\"
")

# 安装启动脚本
install(FILES ${RUN_SCRIPT}
    DESTINATION ${INSTALL_PREFIX}
    PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                GROUP_READ GROUP_EXECUTE
                WORLD_READ WORLD_EXECUTE
)

# 创建README
set(README_FILE "${CMAKE_BINARY_DIR}/README.txt")

# 根据SDL2来源生成不同的依赖说明
if(USE_SYSTEM_SDL2)
    set(SDL2_INFO "- SDL2 ${SDL2_SYS_VERSION} (系统库)")
    set(SDL2_IMAGE_INFO "- SDL2_image ${SDL2_IMAGE_SYS_VERSION} (系统库)")
    set(SDL2_TTF_INFO "- SDL2_ttf ${SDL2_TTF_SYS_VERSION} (系统库)")
else()
    set(SDL2_INFO "- SDL2 (内置编译)")
    set(SDL2_IMAGE_INFO "- SDL2_image (内置编译)")
    set(SDL2_TTF_INFO "- SDL2_ttf (内置编译)")
endif()

file(WRITE ${README_FILE}
"# Zuma Deluxe HD - 绿色便携版

## 运行方法

1. 直接运行启动脚本（推荐）:
   ./run.sh

2. 或者直接运行可执行文件:
   LD_LIBRARY_PATH=./lib ./ZumaHD

## 目录结构

- ZumaHD       : 游戏主程序
- run.sh       : 启动脚本（推荐使用）
- content/     : 游戏资源文件
- lib/         : 依赖库文件

## 系统要求

- Linux ${ARCH}

本程序为绿色便携版，无需安装，可直接运行或复制到其他位置。

## 依赖库

${SDL2_INFO}
${SDL2_IMAGE_INFO}
${SDL2_TTF_INFO}
- BASS Audio Library (Un4seen Developments)
- BASS FX Audio Effects (Un4seen Developments)
- libexpat (XML解析库)

## 编译信息

- 编译类型: ${CMAKE_BUILD_TYPE}
- 架构: ${ARCH}
- CMake版本: ${CMAKE_VERSION}
")

# 安装README
install(FILES ${README_FILE}
    DESTINATION ${INSTALL_PREFIX}
)

# 打印构建信息
message(STATUS "")
message(STATUS "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
message(STATUS "Zuma Deluxe HD - 构建配置")
message(STATUS "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
message(STATUS "项目名称: ${PROJECT_NAME}")
message(STATUS "版本: ${PROJECT_VERSION}")
message(STATUS "架构: ${ARCH}")
message(STATUS "编译器: ${CMAKE_C_COMPILER}")
message(STATUS "构建类型: ${CMAKE_BUILD_TYPE}")
message(STATUS "安装目录: ${INSTALL_PREFIX}")
message(STATUS "")
message(STATUS "依赖库:")
message(STATUS "  BASS: ${BASS_LIB}")
message(STATUS "  BASS FX: ${BASSFX_LIB}")
message(STATUS "  libexpat: 从子模块构建")
if(USE_SYSTEM_SDL2)
    message(STATUS "  SDL2: 系统库 v${SDL2_SYS_VERSION}")
    message(STATUS "  SDL2_image: 系统库 v${SDL2_IMAGE_SYS_VERSION}")
    message(STATUS "  SDL2_ttf: 系统库 v${SDL2_TTF_SYS_VERSION}")
else()
    message(STATUS "  SDL2: FetchContent自动下载编译")
    message(STATUS "  SDL2_image: FetchContent自动下载编译")
    message(STATUS "  SDL2_ttf: FetchContent自动下载编译")
endif()
message(STATUS "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
message(STATUS "")
