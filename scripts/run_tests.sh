#!/bin/bash
# 代码空间优化研究系统 - 主测试脚本

# 默认选项
QUICK_MODE=false
SPECIFIC_PROGRAM=""
SPECIFIC_COMPILER=""
SKIP_ADVANCED=false

# 显示帮助信息
show_help() {
    cat << EOF
用法: $0 [选项]

代码空间优化研究系统 - 自动化编译测试脚本

选项:
  --help              显示此帮助信息并退出
  --quick             快速测试模式，仅测试一个程序（fibonacci）
  --program NAME      指定要测试的程序名称（不含.c扩展名）
  --compiler NAME     指定编译器（gcc 或 clang）
  --no-advanced       跳过LTO和PGO高级优化测试

示例:
  $0                              # 运行所有测试
  $0 --quick                      # 快速测试模式
  $0 --program fibonacci          # 仅测试fibonacci程序
  $0 --compiler gcc               # 仅使用GCC编译器
  $0 --program quicksort --compiler clang  # 测试quicksort，仅使用Clang
  $0 --no-advanced                # 跳过LTO和PGO测试

EOF
    exit 0
}

# 解析命令行参数
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                ;;
            --quick)
                QUICK_MODE=true
                shift
                ;;
            --program)
                if [ -z "$2" ] || [[ "$2" == --* ]]; then
                    echo "错误: --program 需要指定程序名称"
                    exit 1
                fi
                SPECIFIC_PROGRAM="$2"
                shift 2
                ;;
            --compiler)
                if [ -z "$2" ] || [[ "$2" == --* ]]; then
                    echo "错误: --compiler 需要指定编译器名称"
                    exit 1
                fi
                if [ "$2" != "gcc" ] && [ "$2" != "clang" ]; then
                    echo "错误: 编译器必须是 gcc 或 clang"
                    exit 1
                fi
                SPECIFIC_COMPILER="$2"
                shift 2
                ;;
            --no-advanced)
                SKIP_ADVANCED=true
                shift
                ;;
            *)
                echo "错误: 未知选项 $1"
                echo "使用 --help 查看帮助信息"
                exit 1
                ;;
        esac
    done
}

# 加载配置文件
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_ROOT/config.sh"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "错误: 找不到配置文件 $CONFIG_FILE"
    exit 1
fi

# 日志文件
LOG_FILE="$PROJECT_ROOT/test_run.log"

# 日志函数
log_message() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" | tee -a "$LOG_FILE"
}

log_error() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $message" | tee -a "$LOG_FILE" >&2
}

# 工具检查和环境验证函数
check_tools() {
    log_message "检查必需工具..."
    
    local tools_missing=0
    
    # 检查编译器
    for compiler in $COMPILERS; do
        if ! command -v "$compiler" &> /dev/null; then
            log_error "$compiler 未安装"
            echo "  安装建议: sudo apt-get install $compiler"
            tools_missing=1
        else
            log_message "  ✓ $compiler 已安装"
        fi
    done
    
    # 检查分析工具
    local analysis_tools=("size" "objdump" "readelf" "nm")
    for tool in "${analysis_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "$tool 未安装"
            echo "  安装建议: sudo apt-get install binutils"
            tools_missing=1
        else
            log_message "  ✓ $tool 已安装"
        fi
    done
    
    if [ $tools_missing -eq 1 ]; then
        log_error "缺少必需工具，请安装后重试"
        exit 1
    fi
    
    log_message "所有必需工具已安装"
}

# 版本检测函数
detect_versions() {
    log_message "检测编译器版本..."
    
    # GCC版本
    if command -v gcc &> /dev/null; then
        local gcc_version=$(gcc --version | head -n 1)
        log_message "  GCC: $gcc_version"
        echo "GCC_VERSION=$gcc_version" >> "$LOG_FILE"
    fi
    
    # Clang版本
    if command -v clang &> /dev/null; then
        local clang_version=$(clang --version | head -n 1)
        log_message "  Clang: $clang_version"
        echo "CLANG_VERSION=$clang_version" >> "$LOG_FILE"
    fi
    
    # 系统信息
    log_message "系统信息:"
    log_message "  OS: $(uname -s)"
    log_message "  Kernel: $(uname -r)"
    log_message "  Architecture: $(uname -m)"
}

# 创建输出目录结构
create_output_dirs() {
    local compiler=$1
    local opt_level=$2
    
    # 移除优化级别前的 - 符号用于目录名
    local opt_dir=$(echo "$opt_level" | sed 's/^-//')
    local output_dir="$PROJECT_ROOT/$BUILD_DIR/$compiler/$opt_dir"
    
    mkdir -p "$output_dir" >&2
    echo "$output_dir"
}

# 基础编译函数
compile_program() {
    local compiler=$1
    local opt_level=$2
    local source_file=$3
    local output_dir=$4
    
    local program_name=$(basename "$source_file" .c)
    local output_file="$output_dir/$program_name"
    
    log_message "编译 $program_name 使用 $compiler $opt_level..." >&2
    
    # 编译命令
    local compile_cmd="$compiler $opt_level -o $output_file $source_file"
    
    # 执行编译并记录输出
    if $compile_cmd 2>> "$LOG_FILE"; then
        log_message "  ✓ 编译成功: $output_file" >&2
        echo "$output_file"
        return 0
    else
        log_error "编译失败: $program_name with $compiler $opt_level" >&2
        return 1
    fi
}

# 自动检测源文件
detect_source_files() {
    local src_dir="$PROJECT_ROOT/$SRC_DIR"
    
    if [ ! -d "$src_dir" ]; then
        log_error "源代码目录不存在: $src_dir"
        exit 1
    fi
    
    local source_files=""
    
    # 如果指定了特定程序
    if [ -n "$SPECIFIC_PROGRAM" ]; then
        local specific_file="$src_dir/${SPECIFIC_PROGRAM}.c"
        if [ -f "$specific_file" ]; then
            source_files="$specific_file"
            log_message "使用指定程序: $SPECIFIC_PROGRAM" >&2
        else
            log_error "找不到指定的程序: $specific_file"
            exit 1
        fi
    # 快速模式：仅测试fibonacci
    elif [ "$QUICK_MODE" = true ]; then
        local quick_file="$src_dir/fibonacci.c"
        if [ -f "$quick_file" ]; then
            source_files="$quick_file"
            log_message "快速测试模式: 仅测试 fibonacci" >&2
        else
            log_error "快速测试模式失败: 找不到 fibonacci.c"
            exit 1
        fi
    # 默认：检测所有源文件
    else
        source_files=$(find "$src_dir" -name "*.c" -type f)
    fi
    
    if [ -z "$source_files" ]; then
        log_error "在 $src_dir 中未找到 .c 文件"
        exit 1
    fi
    
    echo "$source_files"
}

# 初始化CSV文件
initialize_csv() {
    local csv_file="$PROJECT_ROOT/$RESULTS_DIR/code_size.csv"
    
    # 创建results目录
    mkdir -p "$PROJECT_ROOT/$RESULTS_DIR" >&2
    
    # 如果CSV文件不存在，创建并写入表头
    if [ ! -f "$csv_file" ]; then
        echo "program,compiler,opt_level,text_size,data_size,bss_size,total_size,timestamp" > "$csv_file"
        log_message "创建CSV文件: $csv_file" >&2
    fi
    
    echo "$csv_file"
}

# LTO编译函数
compile_with_lto() {
    local compiler=$1
    local source_file=$2
    local output_dir=$3
    
    local program_name=$(basename "$source_file" .c)
    local output_file="$output_dir/$program_name"
    
    log_message "编译 $program_name 使用 $compiler -flto..." >&2
    
    # LTO编译命令
    local compile_cmd="$compiler -O2 -flto -o $output_file $source_file"
    
    # 执行编译并记录输出
    if $compile_cmd 2>> "$LOG_FILE"; then
        log_message "  ✓ LTO编译成功: $output_file" >&2
        echo "$output_file"
        return 0
    else
        log_error "LTO编译失败: $program_name with $compiler" >&2
        return 1
    fi
}

# PGO编译函数（两阶段）
compile_with_pgo() {
    local compiler=$1
    local source_file=$2
    local output_dir=$3
    
    local program_name=$(basename "$source_file" .c)
    local output_file="$output_dir/$program_name"
    local profile_dir="$output_dir/profile_data"
    
    # 创建profile数据目录
    mkdir -p "$profile_dir"
    
    log_message "PGO编译 $program_name 使用 $compiler (两阶段)..." >&2
    
    # 阶段1: 使用 -fprofile-generate 编译
    log_message "  阶段1: 生成profile数据..." >&2
    local stage1_output="$output_dir/${program_name}_stage1"
    
    local stage1_cmd=""
    if [ "$compiler" = "gcc" ]; then
        stage1_cmd="$compiler -O2 -fprofile-generate=$profile_dir -o $stage1_output $source_file"
    elif [ "$compiler" = "clang" ]; then
        stage1_cmd="$compiler -O2 -fprofile-instr-generate -o $stage1_output $source_file"
    else
        log_error "不支持的编译器: $compiler" >&2
        return 1
    fi
    
    if ! $stage1_cmd 2>> "$LOG_FILE"; then
        log_error "PGO阶段1编译失败: $program_name with $compiler" >&2
        return 1
    fi
    
    # 运行程序收集profile数据
    log_message "  运行程序收集profile数据..." >&2
    
    if [ "$compiler" = "clang" ]; then
        # Clang需要设置环境变量
        export LLVM_PROFILE_FILE="$profile_dir/${program_name}.profraw"
    fi
    
    # 运行程序（使用timeout防止程序挂起）
    if timeout 10s "$stage1_output" > /dev/null 2>&1; then
        log_message "  ✓ Profile数据收集成功" >&2
    else
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            log_error "程序运行超时: $program_name" >&2
        else
            log_error "程序运行失败: $program_name (退出码: $exit_code)" >&2
        fi
        return 1
    fi
    
    # Clang需要额外的profile数据处理步骤
    if [ "$compiler" = "clang" ]; then
        log_message "  处理Clang profile数据..." >&2
        local profdata_file="$profile_dir/${program_name}.profdata"
        
        if command -v llvm-profdata &> /dev/null; then
            if ! llvm-profdata merge -output="$profdata_file" "$profile_dir/${program_name}.profraw" 2>> "$LOG_FILE"; then
                log_error "Profile数据合并失败: $program_name" >&2
                return 1
            fi
        else
            log_error "llvm-profdata 未安装，无法处理Clang PGO数据" >&2
            return 1
        fi
    fi
    
    # 阶段2: 使用 -fprofile-use 重新编译
    log_message "  阶段2: 使用profile数据优化编译..." >&2
    
    local stage2_cmd=""
    if [ "$compiler" = "gcc" ]; then
        stage2_cmd="$compiler -O2 -fprofile-use=$profile_dir -o $output_file $source_file"
    elif [ "$compiler" = "clang" ]; then
        local profdata_file="$profile_dir/${program_name}.profdata"
        stage2_cmd="$compiler -O2 -fprofile-instr-use=$profdata_file -o $output_file $source_file"
    fi
    
    if $stage2_cmd 2>> "$LOG_FILE"; then
        log_message "  ✓ PGO编译成功: $output_file" >&2
        
        # 清理临时文件
        rm -f "$stage1_output"
        
        echo "$output_file"
        return 0
    else
        log_error "PGO阶段2编译失败: $program_name with $compiler" >&2
        return 1
    fi
}

# 代码大小测量函数
measure_size() {
    local executable=$1
    local program_name=$2
    local compiler=$3
    local opt_level=$4
    local csv_file=$5
    
    if [ ! -f "$executable" ]; then
        log_error "可执行文件不存在: $executable" >&2
        return 1
    fi
    
    log_message "测量代码大小: $program_name" >&2
    
    # 使用 size 命令获取段大小
    # 使用 -A 选项获取详细的段信息
    local size_output=$(size -A "$executable" 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        log_error "无法测量 $executable 的大小" >&2
        return 1
    fi
    
    # 解析 size 输出提取 text, data, bss 段大小
    local text_size=$(echo "$size_output" | grep "^\.text" | awk '{print $2}')
    local data_size=$(echo "$size_output" | grep "^\.data" | awk '{print $2}')
    local bss_size=$(echo "$size_output" | grep "^\.bss" | awk '{print $2}')
    
    # 如果某些段不存在，设置为0
    text_size=${text_size:-0}
    data_size=${data_size:-0}
    bss_size=${bss_size:-0}
    
    # 计算总大小
    local total_size=$((text_size + data_size + bss_size))
    
    # 获取时间戳
    local timestamp=$(date -Iseconds)
    
    # 追加到CSV文件
    echo "$program_name,$compiler,$opt_level,$text_size,$data_size,$bss_size,$total_size,$timestamp" >> "$csv_file"
    
    log_message "  text: $text_size, data: $data_size, bss: $bss_size, total: $total_size" >&2
    
    return 0
}

# objdump集成函数
run_objdump_analysis() {
    local executable=$1
    local program_name=$2
    local compiler=$3
    local opt_level=$4
    
    if [ ! -f "$executable" ]; then
        log_error "可执行文件不存在: $executable" >&2
        return 1
    fi
    
    # 创建objdump输出目录
    local objdump_dir="$PROJECT_ROOT/$RESULTS_DIR/objdump"
    mkdir -p "$objdump_dir"
    
    # 生成输出文件名: program_compiler_opt.asm
    local output_file="$objdump_dir/${program_name}_${compiler}_${opt_level}.asm"
    
    log_message "  运行objdump分析: $program_name" >&2
    
    # 使用objdump -d反汇编可执行文件
    if objdump -d "$executable" > "$output_file" 2>> "$LOG_FILE"; then
        log_message "    ✓ objdump输出保存到: $output_file" >&2
        return 0
    else
        log_error "objdump分析失败: $executable" >&2
        return 1
    fi
}

# readelf集成函数
run_readelf_analysis() {
    local executable=$1
    local program_name=$2
    local compiler=$3
    local opt_level=$4
    
    if [ ! -f "$executable" ]; then
        log_error "可执行文件不存在: $executable" >&2
        return 1
    fi
    
    # 创建readelf输出目录
    local readelf_dir="$PROJECT_ROOT/$RESULTS_DIR/readelf"
    mkdir -p "$readelf_dir"
    
    # 生成输出文件名: program_compiler_opt.txt
    local output_file="$readelf_dir/${program_name}_${compiler}_${opt_level}.txt"
    
    log_message "  运行readelf分析: $program_name" >&2
    
    # 使用readelf -a提取ELF信息
    if readelf -a "$executable" > "$output_file" 2>> "$LOG_FILE"; then
        log_message "    ✓ readelf输出保存到: $output_file" >&2
        return 0
    else
        log_error "readelf分析失败: $executable" >&2
        return 1
    fi
}

# nm集成函数
run_nm_analysis() {
    local executable=$1
    local program_name=$2
    local compiler=$3
    local opt_level=$4
    
    if [ ! -f "$executable" ]; then
        log_error "可执行文件不存在: $executable" >&2
        return 1
    fi
    
    # 创建nm输出目录
    local nm_dir="$PROJECT_ROOT/$RESULTS_DIR/nm"
    mkdir -p "$nm_dir"
    
    # 生成输出文件名: program_compiler_opt.txt
    local output_file="$nm_dir/${program_name}_${compiler}_${opt_level}.txt"
    
    log_message "  运行nm分析: $program_name" >&2
    
    # 使用nm -S列出符号信息
    if nm -S "$executable" > "$output_file" 2>> "$LOG_FILE"; then
        log_message "    ✓ nm输出保存到: $output_file" >&2
        return 0
    else
        log_error "nm分析失败: $executable" >&2
        return 1
    fi
}

# 从工具输出提取额外指标
extract_additional_metrics() {
    local program_name=$1
    local compiler=$2
    local opt_level=$3
    local csv_file=$4
    
    local readelf_file="$PROJECT_ROOT/$RESULTS_DIR/readelf/${program_name}_${compiler}_${opt_level}.txt"
    local nm_file="$PROJECT_ROOT/$RESULTS_DIR/nm/${program_name}_${compiler}_${opt_level}.txt"
    
    # 检查文件是否存在
    if [ ! -f "$readelf_file" ] || [ ! -f "$nm_file" ]; then
        log_error "分析文件不存在，跳过指标提取" >&2
        return 1
    fi
    
    log_message "  提取额外指标: $program_name" >&2
    
    # 从readelf提取段大小详细信息
    # 提取.rodata段大小（只读数据）
    local rodata_size=$(grep "\.rodata" "$readelf_file" | grep PROGBITS | awk '{print $6}' | head -n 1)
    rodata_size=${rodata_size:-0}
    
    # 如果是十六进制，转换为十进制
    if [[ "$rodata_size" =~ ^0x ]]; then
        rodata_size=$((16#${rodata_size#0x}))
    fi
    
    # 从nm统计函数数量和平均大小
    # 统计类型为T（text段函数）的符号数量
    local function_count=$(grep " T " "$nm_file" | wc -l)
    
    # 计算函数的平均大小
    local total_function_size=0
    local avg_function_size=0
    local functions_with_size=0
    
    if [ $function_count -gt 0 ]; then
        # 提取所有函数的大小并求和
        # nm -S 输出格式: address size type name 或 address type name
        while read -r line; do
            # 检查是否有大小字段（第二个字段是十六进制数字）
            local size=$(echo "$line" | awk '{print $2}')
            if [[ "$size" =~ ^[0-9a-fA-F]+$ ]] && [ ${#size} -gt 8 ]; then
                # 转换十六进制为十进制
                size=$((16#$size))
                if [ $size -gt 0 ]; then
                    total_function_size=$((total_function_size + size))
                    functions_with_size=$((functions_with_size + 1))
                fi
            fi
        done < <(grep " T " "$nm_file")
        
        # 计算平均值
        if [ $functions_with_size -gt 0 ]; then
            avg_function_size=$((total_function_size / functions_with_size))
        fi
    fi
    
    log_message "    rodata段: $rodata_size, 函数数量: $function_count, 平均函数大小: $avg_function_size" >&2
    
    # 将额外指标追加到扩展CSV文件
    local extended_csv="$PROJECT_ROOT/$RESULTS_DIR/extended_metrics.csv"
    
    # 如果文件不存在，创建并写入表头
    if [ ! -f "$extended_csv" ]; then
        echo "program,compiler,opt_level,rodata_size,function_count,avg_function_size,timestamp" > "$extended_csv"
    fi
    
    local timestamp=$(date -Iseconds)
    echo "$program_name,$compiler,$opt_level,$rodata_size,$function_count,$avg_function_size,$timestamp" >> "$extended_csv"
    
    return 0
}

# 运行完整的代码分析
run_code_analysis() {
    local executable=$1
    local program_name=$2
    local compiler=$3
    local opt_level=$4
    local csv_file=$5
    
    log_message "运行代码分析工具: $program_name" >&2
    
    # 运行objdump分析
    run_objdump_analysis "$executable" "$program_name" "$compiler" "$opt_level"
    
    # 运行readelf分析
    run_readelf_analysis "$executable" "$program_name" "$compiler" "$opt_level"
    
    # 运行nm分析
    run_nm_analysis "$executable" "$program_name" "$compiler" "$opt_level"
    
    # 提取额外指标
    extract_additional_metrics "$program_name" "$compiler" "$opt_level" "$csv_file"
    
    return 0
}

# 检查编译缓存
check_compilation_cache() {
    local compiler=$1
    local opt_level=$2
    local source_file=$3
    local output_dir=$4
    
    local program_name=$(basename "$source_file" .c)
    local output_file="$output_dir/$program_name"
    local cache_file="$output_dir/.${program_name}.cache"
    
    # 如果可执行文件不存在，需要编译
    if [ ! -f "$output_file" ]; then
        return 1
    fi
    
    # 如果缓存文件不存在，需要编译
    if [ ! -f "$cache_file" ]; then
        return 1
    fi
    
    # 检查源文件是否被修改
    local source_mtime=$(stat -c %Y "$source_file" 2>/dev/null || stat -f %m "$source_file" 2>/dev/null)
    local cache_mtime=$(cat "$cache_file" 2>/dev/null)
    
    if [ "$source_mtime" -gt "$cache_mtime" ]; then
        return 1
    fi
    
    # 缓存有效
    return 0
}

# 更新编译缓存
update_compilation_cache() {
    local source_file=$1
    local output_dir=$2
    
    local program_name=$(basename "$source_file" .c)
    local cache_file="$output_dir/.${program_name}.cache"
    
    local source_mtime=$(stat -c %Y "$source_file" 2>/dev/null || stat -f %m "$source_file" 2>/dev/null)
    echo "$source_mtime" > "$cache_file"
}

# 并行编译单个任务
compile_task() {
    local compiler=$1
    local opt_level=$2
    local source_file=$3
    local output_dir=$4
    local csv_file=$5
    local task_id=$6
    local total_tasks=$7
    
    local program_name=$("basename "$source_file" .c")
    
    # 显示进度
    echo "[$task_id/$total_tasks] 编译 $program_name 使用 $compiler $opt_level..." >&2
    
    # 检查缓存
    if check_compilation_cache "$compiler" "$opt_level" "$source_file" "$output_dir"; then
        local executable="$output_dir/$program_name"
        echo "  ✓ 使用缓存: $executable" >&2
        echo "$executable"
        return 0
    fi
    
    # 编译程序
    local executable=$(compile_program "$compiler" "$opt_level" "$source_file" "$output_dir")
    
    if [ $? -eq 0 ] && [ -n "$executable" ]; then
        # 更新缓存
        update_compilation_cache "$source_file" "$output_dir"
        echo "$executable"
        return 0
    else
        return 1
    fi
}

# 导出函数供xargs使用
export -f compile_task
export -f compile_program
export -f check_compilation_cache
export -f update_compilation_cache
export -f log_message
export -f log_error

# 主测试循环（优化版本，支持并行编译）
run_basic_tests() {
    log_message "=========================================="
    log_message "开始基础编译测试"
    log_message "=========================================="
    
    # 初始化CSV文件
    local csv_file=$(initialize_csv)
    
    # 检测源文件
    local source_files=$(detect_source_files)
    local source_count=$(echo "$source_files" | wc -l)
    log_message "找到 $source_count 个测试程序"
    
    # 确定要使用的编译器列表
    local compilers_to_test="$COMPILERS"
    if [ -n "$SPECIFIC_COMPILER" ]; then
        compilers_to_test="$SPECIFIC_COMPILER"
        log_message "使用指定编译器: $SPECIFIC_COMPILER"
    fi
    
    # 生成所有编译任务列表
    local task_list=()
    for compiler in $compilers_to_test; do
        # 根据编译器选择优化级别
        local opt_levels=""
        if [ "$compiler" = "gcc" ]; then
            opt_levels="$GCC_OPT_LEVELS"
        elif [ "$compiler" = "clang" ]; then
            opt_levels="$CLANG_OPT_LEVELS"
        else
            log_error "未知编译器: $compiler"
            continue
        fi
        
        for opt_level in $opt_levels; do
            # 创建输出目录
            local output_dir=$(create_output_dirs "$compiler" "$opt_level")
            
            for source_file in $source_files; do
                task_list+=("$compiler|$opt_level|$source_file|$output_dir")
            done
        done
    done
    
    local total_tasks=${#task_list[@]}
    log_message "总编译任务数: $total_tasks"
    log_message "使用 $PARALLEL_JOBS 个并行任务"
    
    # 统计变量
    local successful_tests=0
    local failed_tests=0
    local cached_tests=0
    
    # 创建临时文件存储编译结果
    local temp_results=$(mktemp)
    local temp_errors=$(mktemp)
    
    # 并行编译
    local task_id=0
    for task in "${task_list[@]}"; do
        task_id=$((task_id + 1))
        IFS='|' read -r compiler opt_level source_file output_dir <<< "$task"
        
        echo "$compiler|$opt_level|$source_file|$output_dir|$task_id|$total_tasks"
    done | xargs -P "$PARALLEL_JOBS" -I {} bash -c '
        IFS="|" read -r compiler opt_level source_file output_dir task_id total_tasks <<< "{}"
        program_name=$(basename "$source_file" .c)
        
        # 显示进度
        echo "[$task_id/$total_tasks] 编译 $program_name 使用 $compiler $opt_level..."
        
        # 检查缓存
        executable="$output_dir/$program_name"
        cache_file="$output_dir/.${program_name}.cache"
        use_cache=false
        
        if [ -f "$executable" ] && [ -f "$cache_file" ]; then
            source_mtime=$(stat -c %Y "$source_file" 2>/dev/null || stat -f %m "$source_file" 2>/dev/null)
            cache_mtime=$(cat "$cache_file" 2>/dev/null)
            if [ "$source_mtime" -le "$cache_mtime" ]; then
                use_cache=true
                echo "  ✓ 使用缓存: $executable"
            fi
        fi
        
        # 如果没有缓存，执行编译
        if [ "$use_cache" = false ]; then
            compile_cmd="$compiler $opt_level -o $executable $source_file"
            if $compile_cmd 2>/dev/null; then
                # 更新缓存
                source_mtime=$(stat -c %Y "$source_file" 2>/dev/null || stat -f %m "$source_file" 2>/dev/null)
                echo "$source_mtime" > "$cache_file"
                echo "  ✓ 编译成功: $executable"
            else
                echo "  ✗ 编译失败: $program_name with $compiler $opt_level" >&2
                exit 1
            fi
        fi
        
        echo "$executable|$program_name|$compiler|$opt_level|$use_cache"
    ' 2>"$temp_errors" | while IFS='|' read -r executable program_name compiler opt_level use_cache; do
        if [ -n "$executable" ] && [ -f "$executable" ]; then
            # 测量代码大小
            if measure_size "$executable" "$program_name" "$compiler" "$opt_level" "$csv_file"; then
                # 运行代码分析工具（仅在非缓存情况下）
                if [ "$use_cache" = "false" ]; then
                    run_code_analysis "$executable" "$program_name" "$compiler" "$opt_level" "$csv_file"
                fi
                successful_tests=$((successful_tests + 1))
                if [ "$use_cache" = "true" ]; then
                    cached_tests=$((cached_tests + 1))
                fi
            else
                failed_tests=$((failed_tests + 1))
            fi
        else
            failed_tests=$((failed_tests + 1))
        fi
    done
    
    # 显示错误信息
    if [ -s "$temp_errors" ]; then
        log_error "编译过程中出现错误:"
        cat "$temp_errors" >> "$LOG_FILE"
    fi
    
    # 清理临时文件
    rm -f "$temp_results" "$temp_errors"
    
    # 输出测试摘要
    log_message "=========================================="
    log_message "测试完成"
    log_message "=========================================="
    log_message "总测试数: $total_tasks"
    log_message "成功: $successful_tests"
    log_message "失败: $failed_tests"
    log_message "使用缓存: $cached_tests"
    log_message "结果保存到: $csv_file"
}

# LTO测试
run_lto_tests() {
    if [ "$SKIP_ADVANCED" = true ]; then
        log_message "跳过LTO测试（--no-advanced）"
        return 0
    fi
    
    if [ "$ENABLE_LTO" != "true" ]; then
        log_message "LTO测试已禁用，跳过"
        return 0
    fi
    
    log_message "=========================================="
    log_message "开始LTO编译测试"
    log_message "=========================================="
    
    # 获取CSV文件
    local csv_file="$PROJECT_ROOT/$RESULTS_DIR/code_size.csv"
    
    # 检测源文件
    local source_files=$(detect_source_files)
    
    # 统计变量
    local total_tests=0
    local successful_tests=0
    local failed_tests=0
    
    # 确定要使用的编译器列表
    local compilers_to_test="$COMPILERS"
    if [ -n "$SPECIFIC_COMPILER" ]; then
        compilers_to_test="$SPECIFIC_COMPILER"
    fi
    
    # 遍历编译器
    for compiler in $compilers_to_test; do
        log_message "----------------------------------------"
        log_message "使用编译器: $compiler (LTO)"
        log_message "----------------------------------------"
        
        # 创建LTO输出目录
        local output_dir="$PROJECT_ROOT/$BUILD_DIR/$compiler/lto"
        mkdir -p "$output_dir"
        
        # 遍历所有源文件
        for source_file in $source_files; do
            local program_name=$(basename "$source_file" .c)
            
            total_tests=$((total_tests + 1))
            
            # 使用LTO编译程序
            local executable=$(compile_with_lto "$compiler" "$source_file" "$output_dir")
            
            if [ $? -eq 0 ] && [ -n "$executable" ]; then
                # 测量代码大小
                if measure_size "$executable" "$program_name" "$compiler" "lto" "$csv_file"; then
                    # 运行代码分析工具
                    run_code_analysis "$executable" "$program_name" "$compiler" "lto" "$csv_file"
                    successful_tests=$((successful_tests + 1))
                else
                    failed_tests=$((failed_tests + 1))
                    log_error "测量失败: $program_name (LTO)"
                fi
            else
                failed_tests=$((failed_tests + 1))
                continue
            fi
        done
    done
    
    # 输出测试摘要
    log_message "=========================================="
    log_message "LTO测试完成"
    log_message "=========================================="
    log_message "总测试数: $total_tests"
    log_message "成功: $successful_tests"
    log_message "失败: $failed_tests"
}

# PGO测试
run_pgo_tests() {
    if [ "$SKIP_ADVANCED" = true ]; then
        log_message "跳过PGO测试（--no-advanced）"
        return 0
    fi
    
    if [ "$ENABLE_PGO" != "true" ]; then
        log_message "PGO测试已禁用，跳过"
        return 0
    fi
    
    log_message "=========================================="
    log_message "开始PGO编译测试"
    log_message "=========================================="
    
    # 获取CSV文件
    local csv_file="$PROJECT_ROOT/$RESULTS_DIR/code_size.csv"
    
    # 检测源文件
    local source_files=$(detect_source_files)
    
    # 统计变量
    local total_tests=0
    local successful_tests=0
    local failed_tests=0
    
    # 确定要使用的编译器列表
    local compilers_to_test="$COMPILERS"
    if [ -n "$SPECIFIC_COMPILER" ]; then
        compilers_to_test="$SPECIFIC_COMPILER"
    fi
    
    # 遍历编译器
    for compiler in $compilers_to_test; do
        log_message "----------------------------------------"
        log_message "使用编译器: $compiler (PGO)"
        log_message "----------------------------------------"
        
        # 创建PGO输出目录
        local output_dir="$PROJECT_ROOT/$BUILD_DIR/$compiler/pgo"
        mkdir -p "$output_dir"
        
        # 遍历所有源文件
        for source_file in $source_files; do
            local program_name=$(basename "$source_file" .c)
            
            total_tests=$((total_tests + 1))
            
            # 使用PGO编译程序
            local executable=$(compile_with_pgo "$compiler" "$source_file" "$output_dir")
            
            if [ $? -eq 0 ] && [ -n "$executable" ]; then
                # 测量代码大小
                if measure_size "$executable" "$program_name" "$compiler" "pgo" "$csv_file"; then
                    # 运行代码分析工具
                    run_code_analysis "$executable" "$program_name" "$compiler" "pgo" "$csv_file"
                    successful_tests=$((successful_tests + 1))
                else
                    failed_tests=$((failed_tests + 1))
                    log_error "测量失败: $program_name (PGO)"
                fi
            else
                failed_tests=$((failed_tests + 1))
                continue
            fi
        done
    done
    
    # 输出测试摘要
    log_message "=========================================="
    log_message "PGO测试完成"
    log_message "=========================================="
    log_message "总测试数: $total_tests"
    log_message "成功: $successful_tests"
    log_message "失败: $failed_tests"
}

# 主函数
main() {
    # 解析命令行参数
    parse_arguments "$@"
    
    log_message "=========================================="
    log_message "代码空间优化研究系统"
    log_message "=========================================="
    log_message "开始时间: $(date)"
    
    # 显示运行模式
    if [ "$QUICK_MODE" = true ]; then
        log_message "运行模式: 快速测试"
    fi
    if [ -n "$SPECIFIC_PROGRAM" ]; then
        log_message "指定程序: $SPECIFIC_PROGRAM"
    fi
    if [ -n "$SPECIFIC_COMPILER" ]; then
        log_message "指定编译器: $SPECIFIC_COMPILER"
    fi
    if [ "$SKIP_ADVANCED" = true ]; then
        log_message "跳过高级优化测试"
    fi
    
    # 检查工具
    check_tools
    
    # 检测版本
    detect_versions
    
    # 运行基础测试
    run_basic_tests
    
    # 运行LTO测试
    run_lto_tests
    
    # 运行PGO测试
    run_pgo_tests
    
    log_message "=========================================="
    log_message "所有测试完成"
    log_message "结束时间: $(date)"
    log_message "=========================================="
}

# 执行主函数
main "$@"
