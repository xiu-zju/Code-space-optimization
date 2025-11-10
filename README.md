# 代码空间优化研究系统

## 项目简介

本项目是一个完整的代码空间优化研究系统，用于探索不同编译器优化选项对C语言程序代码大小和性能的影响。系统提供自动化测试脚本、数据分析工具和可视化组件，帮助研究人员快速收集、分析和展示编译优化的效果。

### 主要功能

- **自动化编译测试**: 使用GCC和Clang编译器，测试多种优化级别（-O0, -O1, -O2, -O3, -Os, -Oz）
- **高级优化支持**: 包括链接时优化（LTO）和配置文件引导优化（PGO）
- **代码分析工具集成**: 集成objdump、readelf、nm等工具进行深入分析
- **数据分析**: 自动计算统计信息、比较编译器性能、分析优化影响
- **可视化报告**: 生成多种图表，直观展示研究结果

## 系统要求

### 操作系统
- Ubuntu 18.04 或更高版本
- 其他Linux发行版（需要相应的包管理器调整）

### 必需工具
- **GCC** >= 9.0
- **Clang** >= 10.0
- **Python 3** >= 3.7
- **GNU Binutils** (size, objdump, readelf, nm)
- **Make**

### Python依赖
- pandas >= 1.3.0
- matplotlib >= 3.4.0
- seaborn >= 0.11.0
- numpy >= 1.21.0

## 安装依赖

### 安装系统工具

```bash
# 更新包列表
sudo apt-get update

# 安装编译器和构建工具
sudo apt-get install build-essential clang binutils make

# 验证安装
gcc --version
clang --version
```

### 安装Python依赖

```bash
# 使用pip安装Python包
pip3 install -r requirements.txt

# 或者手动安装
pip3 install pandas matplotlib seaborn numpy
```

## 快速开始

### 1. 运行完整测试流程

```bash
# 一键执行所有步骤：编译、分析、可视化
make all
```

### 2. 分步执行

```bash
# 步骤1: 运行编译测试
make test

# 步骤2: 分析数据
make analyze

# 步骤3: 生成可视化
make visualize
```

### 3. 清理输出文件

```bash
# 删除所有生成的文件
make clean
```

## 详细使用说明

### 编译测试脚本 (scripts/run_tests.sh)

主测试脚本，负责编译所有测试程序并收集代码大小数据。

**基本用法**:
```bash
./scripts/run_tests.sh
```

**功能**:
- 自动检测src/目录中的所有.c文件
- 使用GCC和Clang编译器编译每个程序
- 测试多种优化级别
- 执行LTO和PGO高级优化
- 运行代码分析工具（objdump, readelf, nm）
- 测量并记录代码大小数据

**输出**:
- 编译后的可执行文件: `build/[compiler]/[opt_level]/[program]`
- 代码大小数据: `results/code_size.csv`
- 反汇编输出: `results/objdump/*.asm`
- ELF信息: `results/readelf/*.txt`
- 符号表: `results/nm/*.txt`

### 数据分析脚本 (scripts/analyze_data.py)

处理原始测量数据，生成统计分析和比较报告。

**基本用法**:
```bash
python3 scripts/analyze_data.py
```

**功能**:
- 加载和验证CSV数据
- 计算统计信息（平均值、中位数、标准差）
- 比较GCC和Clang编译器性能
- 分析优化级别的影响
- 生成汇总报告

**输出**:
- 统计汇总: `analysis/summary_statistics.csv`
- 编译器比较: `analysis/compiler_comparison.csv`
- 优化影响分析: `analysis/optimization_impact.csv`
- 文本报告: `analysis/summary_report.txt`

### 可视化脚本 (scripts/visualize.py)

生成图表和可视化，展示分析结果。

**基本用法**:
```bash
python3 scripts/visualize.py
```

**功能**:
- 为每个测试程序生成代码大小对比图
- 创建优化级别趋势图
- 生成编译器对比图
- 展示高级优化效果
- 创建代码大小减少热力图

**输出**:
- 所有图表保存在 `reports/figures/` 目录
- 图表格式: PNG

## 输出文件说明

### 目录结构

```
project/
├── src/                          # 测试源代码
├── scripts/                      # 自动化脚本
├── build/                        # 编译输出（自动生成）
│   ├── gcc/                      # GCC编译结果
│   │   ├── O0/, O1/, O2/, O3/, Os/
│   │   ├── lto/                  # 链接时优化
│   │   └── pgo/                  # 配置文件引导优化
│   └── clang/                    # Clang编译结果
│       ├── O0/, O1/, O2/, O3/, Os/, Oz/
│       ├── lto/
│       └── pgo/
├── results/                      # 测量数据（自动生成）
│   ├── code_size.csv             # 代码大小数据
│   ├── extended_metrics.csv      # 扩展指标
│   ├── objdump/                  # 反汇编输出
│   ├── readelf/                  # ELF文件信息
│   └── nm/                       # 符号表信息
├── analysis/                     # 分析结果（自动生成）
│   ├── summary_statistics.csv    # 统计汇总
│   ├── compiler_comparison.csv   # 编译器对比
│   ├── optimization_impact.csv   # 优化影响分析
│   └── summary_report.txt        # 文本报告
└── reports/                      # 报告和图表（自动生成）
    ├── figures/                  # 所有生成的图表
    └── REPORT_TEMPLATE.md        # 技术报告模板
```

### 数据文件格式

#### code_size.csv
```csv
program,compiler,opt_level,text_size,data_size,bss_size,total_size,timestamp
fibonacci,gcc,O0,1234,256,8,1498,2025-11-09T10:30:00
fibonacci,gcc,O1,987,256,8,1251,2025-11-09T10:30:05
...
```

**字段说明**:
- `program`: 测试程序名称
- `compiler`: 编译器（gcc或clang）
- `opt_level`: 优化级别（O0, O1, O2, O3, Os, Oz, lto, pgo）
- `text_size`: 代码段大小（字节）
- `data_size`: 数据段大小（字节）
- `bss_size`: BSS段大小（字节）
- `total_size`: 总大小（字节）
- `timestamp`: 测量时间戳


## 项目配置

编辑 `config.sh` 文件可以自定义配置：

```bash
# 编译器配置
COMPILERS="gcc clang"
GCC_OPT_LEVELS="-O0 -O1 -O2 -O3 -Os"
CLANG_OPT_LEVELS="-O0 -O1 -O2 -O3 -Os -Oz"

# 高级优化开关
ENABLE_LTO=true
ENABLE_PGO=true

# 输出目录
BUILD_DIR="build"
RESULTS_DIR="results"
ANALYSIS_DIR="analysis"
REPORTS_DIR="reports"
```

## 测试程序说明

项目包含以下测试程序：

- **fibonacci.c**: 斐波那契数列计算（递归）
- **linked_list.c**: 链表操作（插入、删除、遍历）
- **matrix_add.c**: 矩阵加法
- **matrix_mult.c**: 矩阵乘法
- **popcount.c**: 位计数（人口计数）
- **quicksort.c**: 快速排序算法
- **string_search.c**: 字符串搜索算法