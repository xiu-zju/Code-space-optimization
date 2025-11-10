#!/bin/bash
# 集成测试脚本 - 端到端测试完整流程

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试结果统计
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# 项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 日志文件
TEST_LOG="$PROJECT_ROOT/integration_test.log"

# 初始化日志
echo "集成测试开始: $(date)" > "$TEST_LOG"

# 打印函数
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
    echo "[TEST] $1" >> "$TEST_LOG"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    echo "[PASS] $1" >> "$TEST_LOG"
    # 只在测试函数内部增加计数，通过第二个参数控制
    if [ "${2:-count}" = "count" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    echo "[FAIL] $1" >> "$TEST_LOG"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "[INFO] $1" >> "$TEST_LOG"
}

# 测试函数
test_file_exists() {
    local file=$1
    local description=$2
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    print_test "$description"
    
    if [ -f "$file" ]; then
        print_pass "文件存在: $file"
        return 0
    else
        print_fail "文件不存在: $file"
        return 1
    fi
}

test_dir_exists() {
    local dir=$1
    local description=$2
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    print_test "$description"
    
    if [ -d "$dir" ]; then
        print_pass "目录存在: $dir"
        return 0
    else
        print_fail "目录不存在: $dir"
        return 1
    fi
}

test_csv_format() {
    local csv_file=$1
    local description=$2
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    print_test "$description"
    
    if [ ! -f "$csv_file" ]; then
        print_fail "CSV文件不存在: $csv_file"
        return 1
    fi
    
    # 检查是否有表头
    local header=$(head -n 1 "$csv_file")
    if [ -z "$header" ]; then
        print_fail "CSV文件为空"
        return 1
    fi
    
    # 检查是否有数据行
    local line_count=$(wc -l < "$csv_file")
    if [ "$line_count" -lt 2 ]; then
        print_fail "CSV文件没有数据行 (仅有表头)"
        return 1
    fi
    
    print_pass "CSV格式正确，包含 $((line_count - 1)) 条数据"
    return 0
}

test_csv_columns() {
    local csv_file=$1
    local expected_columns=$2
    local description=$3
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    print_test "$description"
    
    if [ ! -f "$csv_file" ]; then
        print_fail "CSV文件不存在: $csv_file"
        return 1
    fi
    
    local header=$(head -n 1 "$csv_file")
    
    # 检查每个必需列
    local missing_columns=""
    for col in $expected_columns; do
        if ! echo "$header" | grep -q "$col"; then
            missing_columns="$missing_columns $col"
        fi
    done
    
    if [ -n "$missing_columns" ]; then
        print_fail "缺少列:$missing_columns"
        return 1
    fi
    
    print_pass "所有必需列都存在"
    return 0
}

test_image_file() {
    local image_file=$1
    local description=$2
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    print_test "$description"
    
    if [ ! -f "$image_file" ]; then
        print_fail "图像文件不存在: $image_file"
        return 1
    fi
    
    # 检查文件大小（图像文件应该大于1KB）
    local file_size=$(stat -c%s "$image_file" 2>/dev/null || stat -f%z "$image_file" 2>/dev/null)
    if [ "$file_size" -lt 1024 ]; then
        print_fail "图像文件太小 ($file_size 字节)，可能损坏"
        return 1
    fi
    
    # 检查是否是PNG文件
    if ! file "$image_file" | grep -q "PNG"; then
        print_fail "文件不是有效的PNG图像"
        return 1
    fi
    
    print_pass "图像文件有效 ($file_size 字节)"
    return 0
}

# 主测试流程
main() {
    print_header "集成测试 - 端到端测试"
    
    cd "$PROJECT_ROOT"
    
    # 1. 清理旧数据
    print_header "步骤 1: 清理旧数据"
    print_info "清理旧的测试输出..."
    make clean >> "$TEST_LOG" 2>&1 || true
    print_pass "清理完成" "nocount"
    
    # 2. 运行快速编译测试
    print_header "步骤 2: 运行编译测试"
    print_info "执行: bash scripts/run_tests.sh"
    
    if bash scripts/run_tests.sh >> "$TEST_LOG" 2>&1; then
        print_pass "编译测试执行成功" "nocount"
    else
        print_fail "编译测试执行失败" "nocount"
        echo "查看日志: $TEST_LOG"
        exit 1
    fi
    
    # 3. 验证编译输出
    print_header "步骤 3: 验证编译输出"
    
    test_dir_exists "$PROJECT_ROOT/build" "检查build目录"
    test_dir_exists "$PROJECT_ROOT/results" "检查results目录"
    test_file_exists "$PROJECT_ROOT/results/code_size.csv" "检查code_size.csv"
    
    # 4. 验证CSV数据格式
    print_header "步骤 4: 验证CSV数据格式"
    
    test_csv_format "$PROJECT_ROOT/results/code_size.csv" "验证code_size.csv格式"
    test_csv_columns "$PROJECT_ROOT/results/code_size.csv" \
        "program compiler opt_level text_size data_size bss_size total_size timestamp" \
        "验证code_size.csv列"
    
    # 5. 验证分析工具输出
    print_header "步骤 5: 验证分析工具输出"
    
    test_dir_exists "$PROJECT_ROOT/results/objdump" "检查objdump目录"
    test_dir_exists "$PROJECT_ROOT/results/readelf" "检查readelf目录"
    test_dir_exists "$PROJECT_ROOT/results/nm" "检查nm目录"
    
    # 检查是否有分析文件生成
    local objdump_count=$(find "$PROJECT_ROOT/results/objdump" -name "*.asm" 2>/dev/null | wc -l)
    local readelf_count=$(find "$PROJECT_ROOT/results/readelf" -name "*.txt" 2>/dev/null | wc -l)
    local nm_count=$(find "$PROJECT_ROOT/results/nm" -name "*.txt" 2>/dev/null | wc -l)
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    print_test "验证分析文件数量"
    if [ "$objdump_count" -gt 0 ] && [ "$readelf_count" -gt 0 ] && [ "$nm_count" -gt 0 ]; then
        print_pass "生成了 $objdump_count 个objdump文件, $readelf_count 个readelf文件, $nm_count 个nm文件"
    else
        print_fail "分析文件数量不足"
    fi
    
    # 6. 运行数据分析
    print_header "步骤 6: 运行数据分析"
    print_info "执行: python3 scripts/analyze_data.py"
    
    if python3 scripts/analyze_data.py >> "$TEST_LOG" 2>&1; then
        print_pass "数据分析执行成功" "nocount"
    else
        print_fail "数据分析执行失败" "nocount"
        echo "查看日志: $TEST_LOG"
        exit 1
    fi
    
    # 7. 验证分析输出
    print_header "步骤 7: 验证分析输出"
    
    test_dir_exists "$PROJECT_ROOT/analysis" "检查analysis目录"
    test_file_exists "$PROJECT_ROOT/analysis/summary_statistics.csv" "检查summary_statistics.csv"
    test_file_exists "$PROJECT_ROOT/analysis/compiler_comparison.csv" "检查compiler_comparison.csv"
    test_file_exists "$PROJECT_ROOT/analysis/optimization_impact.csv" "检查optimization_impact.csv"
    test_file_exists "$PROJECT_ROOT/analysis/summary_report.txt" "检查summary_report.txt"
    
    # 8. 运行可视化
    print_header "步骤 8: 运行可视化"
    print_info "执行: python3 scripts/visualize.py"
    
    if python3 scripts/visualize.py >> "$TEST_LOG" 2>&1; then
        print_pass "可视化执行成功" "nocount"
    else
        print_fail "可视化执行失败" "nocount"
        echo "查看日志: $TEST_LOG"
        exit 1
    fi
    
    # 9. 验证图表输出
    print_header "步骤 9: 验证图表输出"
    
    test_dir_exists "$PROJECT_ROOT/reports/figures" "检查figures目录"
    
    # 检查关键图表
    test_image_file "$PROJECT_ROOT/reports/figures/code_size_fibonacci.png" "检查fibonacci图表"
    test_image_file "$PROJECT_ROOT/reports/figures/optimization_comparison.png" "检查优化对比图表"
    test_image_file "$PROJECT_ROOT/reports/figures/compiler_comparison.png" "检查编译器对比图表"
    test_image_file "$PROJECT_ROOT/reports/figures/advanced_optimizations.png" "检查高级优化图表"
    
    # 检查热力图
    if [ -f "$PROJECT_ROOT/results/code_size.csv" ]; then
        local has_gcc=$(grep -q "gcc" "$PROJECT_ROOT/results/code_size.csv" && echo "yes" || echo "no")
        local has_clang=$(grep -q "clang" "$PROJECT_ROOT/results/code_size.csv" && echo "yes" || echo "no")
        
        if [ "$has_gcc" = "yes" ]; then
            test_image_file "$PROJECT_ROOT/reports/figures/size_reduction_heatmap_gcc.png" "检查GCC热力图"
        fi
        
        if [ "$has_clang" = "yes" ]; then
            test_image_file "$PROJECT_ROOT/reports/figures/size_reduction_heatmap_clang.png" "检查Clang热力图"
        fi
    fi
    
    # 10. 测试摘要
    print_header "测试摘要"
    
    echo ""
    echo "总测试数: $TESTS_TOTAL"
    echo -e "${GREEN}通过: $TESTS_PASSED${NC}"
    echo -e "${RED}失败: $TESTS_FAILED${NC}"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}所有测试通过！${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo ""
        echo "集成测试成功完成: $(date)" >> "$TEST_LOG"
        exit 0
    else
        echo -e "${RED}========================================${NC}"
        echo -e "${RED}有测试失败！${NC}"
        echo -e "${RED}========================================${NC}"
        echo ""
        echo "查看详细日志: $TEST_LOG"
        echo "集成测试失败: $(date)" >> "$TEST_LOG"
        exit 1
    fi
}

# 执行主函数
main "$@"
