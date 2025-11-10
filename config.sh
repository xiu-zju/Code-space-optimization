#!/bin/bash
# 配置文件 - 代码空间优化研究系统

# 编译器配置
COMPILERS="gcc clang"
GCC_OPT_LEVELS="-O0 -O1 -O2 -O3 -Os"
CLANG_OPT_LEVELS="-O0 -O1 -O2 -O3 -Os -Oz"

# 高级优化
ENABLE_LTO=true
ENABLE_PGO=true

# 输出目录
BUILD_DIR="build"
RESULTS_DIR="results"
ANALYSIS_DIR="analysis"
REPORTS_DIR="reports"

# 源代码目录
SRC_DIR="src"

# 并行编译
PARALLEL_JOBS=4

# 工具路径（通常在PATH中，可以根据需要修改）
GCC_PATH="gcc"
CLANG_PATH="clang"
SIZE_PATH="size"
OBJDUMP_PATH="objdump"
READELF_PATH="readelf"
NM_PATH="nm"
