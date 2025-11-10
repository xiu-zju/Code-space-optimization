# Makefile for Code Space Optimization Research System
# 代码空间优化研究系统构建文件

# 配置变量
SHELL := /bin/bash
PROJECT_ROOT := $(shell pwd)
SCRIPTS_DIR := $(PROJECT_ROOT)/scripts
BUILD_DIR := $(PROJECT_ROOT)/build
RESULTS_DIR := $(PROJECT_ROOT)/results
ANALYSIS_DIR := $(PROJECT_ROOT)/analysis
REPORTS_DIR := $(PROJECT_ROOT)/reports

# Python解释器
PYTHON := python3

# 脚本文件
TEST_SCRIPT := $(SCRIPTS_DIR)/run_tests.sh
ANALYZE_SCRIPT := $(SCRIPTS_DIR)/analyze_data.py
VISUALIZE_SCRIPT := $(SCRIPTS_DIR)/visualize.py

# 颜色输出
COLOR_RESET := \033[0m
COLOR_BOLD := \033[1m
COLOR_GREEN := \033[32m
COLOR_YELLOW := \033[33m
COLOR_BLUE := \033[34m

# 默认目标
.DEFAULT_GOAL := help

# 帮助信息
.PHONY: help
help:
	@echo "$(COLOR_BOLD)代码空间优化研究系统 - Makefile$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_BOLD)可用目标:$(COLOR_RESET)"
	@echo "  $(COLOR_GREEN)all$(COLOR_RESET)        - 依次执行 test, analyze, visualize"
	@echo "  $(COLOR_GREEN)test$(COLOR_RESET)       - 运行编译测试脚本"
	@echo "  $(COLOR_GREEN)analyze$(COLOR_RESET)    - 运行数据分析脚本"
	@echo "  $(COLOR_GREEN)visualize$(COLOR_RESET)  - 运行可视化脚本"
	@echo "  $(COLOR_GREEN)clean$(COLOR_RESET)      - 删除所有生成的文件和目录"
	@echo "  $(COLOR_GREEN)clean-build$(COLOR_RESET) - 仅删除编译输出"
	@echo "  $(COLOR_GREEN)clean-results$(COLOR_RESET) - 仅删除测试结果"
	@echo "  $(COLOR_GREEN)clean-analysis$(COLOR_RESET) - 仅删除分析结果"
	@echo "  $(COLOR_GREEN)clean-reports$(COLOR_RESET) - 仅删除报告和图表"
	@echo "  $(COLOR_GREEN)help$(COLOR_RESET)       - 显示此帮助信息"
	@echo ""
	@echo "$(COLOR_BOLD)使用示例:$(COLOR_RESET)"
	@echo "  make all       # 运行完整流程"
	@echo "  make test      # 仅运行测试"
	@echo "  make clean     # 清理所有输出"
	@echo ""

# all目标：依次执行test、analyze、visualize
.PHONY: all
all: test analyze visualize
	@echo ""
	@echo "$(COLOR_BOLD)$(COLOR_GREEN)✓ 所有任务完成！$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_BOLD)输出文件位置:$(COLOR_RESET)"
	@echo "  - 编译输出: $(BUILD_DIR)/"
	@echo "  - 测试结果: $(RESULTS_DIR)/"
	@echo "  - 分析结果: $(ANALYSIS_DIR)/"
	@echo "  - 图表报告: $(REPORTS_DIR)/figures/"
	@echo ""

# test目标：运行编译测试脚本
.PHONY: test
test:
	@echo "$(COLOR_BOLD)$(COLOR_BLUE)>>> 运行编译测试脚本...$(COLOR_RESET)"
	@if [ ! -f "$(TEST_SCRIPT)" ]; then \
		echo "$(COLOR_BOLD)错误: 测试脚本不存在: $(TEST_SCRIPT)$(COLOR_RESET)"; \
		exit 1; \
	fi
	@chmod +x $(TEST_SCRIPT)
	@bash $(TEST_SCRIPT)
	@echo "$(COLOR_BOLD)$(COLOR_GREEN)✓ 测试完成$(COLOR_RESET)"
	@echo ""

# analyze目标：运行数据分析脚本
.PHONY: analyze
analyze:
	@echo "$(COLOR_BOLD)$(COLOR_BLUE)>>> 运行数据分析脚本...$(COLOR_RESET)"
	@if [ ! -f "$(ANALYZE_SCRIPT)" ]; then \
		echo "$(COLOR_BOLD)错误: 分析脚本不存在: $(ANALYZE_SCRIPT)$(COLOR_RESET)"; \
		exit 1; \
	fi
	@if [ ! -f "$(RESULTS_DIR)/code_size.csv" ]; then \
		echo "$(COLOR_BOLD)$(COLOR_YELLOW)警告: 未找到测试结果文件，请先运行 'make test'$(COLOR_RESET)"; \
		exit 1; \
	fi
	@$(PYTHON) $(ANALYZE_SCRIPT)
	@echo "$(COLOR_BOLD)$(COLOR_GREEN)✓ 分析完成$(COLOR_RESET)"
	@echo ""

# visualize目标：运行可视化脚本
.PHONY: visualize
visualize:
	@echo "$(COLOR_BOLD)$(COLOR_BLUE)>>> 运行可视化脚本...$(COLOR_RESET)"
	@if [ ! -f "$(VISUALIZE_SCRIPT)" ]; then \
		echo "$(COLOR_BOLD)错误: 可视化脚本不存在: $(VISUALIZE_SCRIPT)$(COLOR_RESET)"; \
		exit 1; \
	fi
	@if [ ! -f "$(RESULTS_DIR)/code_size.csv" ]; then \
		echo "$(COLOR_BOLD)$(COLOR_YELLOW)警告: 未找到测试结果文件，请先运行 'make test'$(COLOR_RESET)"; \
		exit 1; \
	fi
	@$(PYTHON) $(VISUALIZE_SCRIPT)
	@echo "$(COLOR_BOLD)$(COLOR_GREEN)✓ 可视化完成$(COLOR_RESET)"
	@echo ""

# clean目标：删除所有生成的文件和目录
.PHONY: clean
clean: clean-build clean-results clean-analysis clean-figures
	@echo "$(COLOR_BOLD)$(COLOR_GREEN)✓ 清理完成$(COLOR_RESET)"
	@if [ -f "test_run.log" ]; then \
		rm -f test_run.log; \
		echo "  - 删除日志文件: test_run.log"; \
	fi
	@echo ""

# clean-build目标：仅删除编译输出
.PHONY: clean-build
clean-build:
	@echo "$(COLOR_BOLD)$(COLOR_YELLOW)>>> 清理编译输出...$(COLOR_RESET)"
	@if [ -d "$(BUILD_DIR)" ]; then \
		rm -rf $(BUILD_DIR); \
		echo "  - 删除目录: $(BUILD_DIR)/"; \
	else \
		echo "  - 目录不存在: $(BUILD_DIR)/"; \
	fi

# clean-results目标：仅删除测试结果
.PHONY: clean-results
clean-results:
	@echo "$(COLOR_BOLD)$(COLOR_YELLOW)>>> 清理测试结果...$(COLOR_RESET)"
	@if [ -d "$(RESULTS_DIR)" ]; then \
		rm -rf $(RESULTS_DIR); \
		echo "  - 删除目录: $(RESULTS_DIR)/"; \
	else \
		echo "  - 目录不存在: $(RESULTS_DIR)/"; \
	fi

# clean-analysis目标：仅删除分析结果
.PHONY: clean-analysis
clean-analysis:
	@echo "$(COLOR_BOLD)$(COLOR_YELLOW)>>> 清理分析结果...$(COLOR_RESET)"
	@if [ -d "$(ANALYSIS_DIR)" ]; then \
		rm -rf $(ANALYSIS_DIR); \
		echo "  - 删除目录: $(ANALYSIS_DIR)/"; \
	else \
		echo "  - 目录不存在: $(ANALYSIS_DIR)/"; \
	fi

# clean-figures目标：仅删除图表
.PHONY: clean-figures
clean-reports:
	@echo "$(COLOR_BOLD)$(COLOR_YELLOW)>>> 清理图表...$(COLOR_RESET)"
	@if [ -d "$(REPORTS_DIR)/figures" ]; then \
		rm -rf $(REPORTS_DIR)/figures; \
		echo "  - 删除目录: $(REPORTS_DIR)/figures/"; \
	else \
		echo "  - 目录不存在: $(REPORTS_DIR)/figures"; \
	fi

# 检查依赖
.PHONY: check-deps
check-deps:
	@echo "$(COLOR_BOLD)$(COLOR_BLUE)>>> 检查系统依赖...$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_BOLD)编译器:$(COLOR_RESET)"
	@command -v gcc >/dev/null 2>&1 && echo "  $(COLOR_GREEN)✓$(COLOR_RESET) gcc: $$(gcc --version | head -n1)" || echo "  $(COLOR_YELLOW)✗$(COLOR_RESET) gcc: 未安装"
	@command -v clang >/dev/null 2>&1 && echo "  $(COLOR_GREEN)✓$(COLOR_RESET) clang: $$(clang --version | head -n1)" || echo "  $(COLOR_YELLOW)✗$(COLOR_RESET) clang: 未安装"
	@echo ""
	@echo "$(COLOR_BOLD)分析工具:$(COLOR_RESET)"
	@command -v size >/dev/null 2>&1 && echo "  $(COLOR_GREEN)✓$(COLOR_RESET) size" || echo "  $(COLOR_YELLOW)✗$(COLOR_RESET) size: 未安装"
	@command -v objdump >/dev/null 2>&1 && echo "  $(COLOR_GREEN)✓$(COLOR_RESET) objdump" || echo "  $(COLOR_YELLOW)✗$(COLOR_RESET) objdump: 未安装"
	@command -v readelf >/dev/null 2>&1 && echo "  $(COLOR_GREEN)✓$(COLOR_RESET) readelf" || echo "  $(COLOR_YELLOW)✗$(COLOR_RESET) readelf: 未安装"
	@command -v nm >/dev/null 2>&1 && echo "  $(COLOR_GREEN)✓$(COLOR_RESET) nm" || echo "  $(COLOR_YELLOW)✗$(COLOR_RESET) nm: 未安装"
	@echo ""
	@echo "$(COLOR_BOLD)Python环境:$(COLOR_RESET)"
	@command -v $(PYTHON) >/dev/null 2>&1 && echo "  $(COLOR_GREEN)✓$(COLOR_RESET) $(PYTHON): $$($(PYTHON) --version)" || echo "  $(COLOR_YELLOW)✗$(COLOR_RESET) $(PYTHON): 未安装"
	@command -v $(PYTHON) >/dev/null 2>&1 && $(PYTHON) -c "import pandas" 2>/dev/null && echo "  $(COLOR_GREEN)✓$(COLOR_RESET) pandas" || echo "  $(COLOR_YELLOW)✗$(COLOR_RESET) pandas: 未安装"
	@command -v $(PYTHON) >/dev/null 2>&1 && $(PYTHON) -c "import matplotlib" 2>/dev/null && echo "  $(COLOR_GREEN)✓$(COLOR_RESET) matplotlib" || echo "  $(COLOR_YELLOW)✗$(COLOR_RESET) matplotlib: 未安装"
	@command -v $(PYTHON) >/dev/null 2>&1 && $(PYTHON) -c "import seaborn" 2>/dev/null && echo "  $(COLOR_GREEN)✓$(COLOR_RESET) seaborn" || echo "  $(COLOR_YELLOW)✗$(COLOR_RESET) seaborn: 未安装"
	@echo ""

# 显示项目状态
.PHONY: status
status:
	@echo "$(COLOR_BOLD)$(COLOR_BLUE)>>> 项目状态$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_BOLD)目录状态:$(COLOR_RESET)"
	@if [ -d "$(BUILD_DIR)" ]; then \
		echo "  $(COLOR_GREEN)✓$(COLOR_RESET) $(BUILD_DIR)/ (存在)"; \
	else \
		echo "  $(COLOR_YELLOW)✗$(COLOR_RESET) $(BUILD_DIR)/ (不存在)"; \
	fi
	@if [ -d "$(RESULTS_DIR)" ]; then \
		echo "  $(COLOR_GREEN)✓$(COLOR_RESET) $(RESULTS_DIR)/ (存在)"; \
	else \
		echo "  $(COLOR_YELLOW)✗$(COLOR_RESET) $(RESULTS_DIR)/ (不存在)"; \
	fi
	@if [ -d "$(ANALYSIS_DIR)" ]; then \
		echo "  $(COLOR_GREEN)✓$(COLOR_RESET) $(ANALYSIS_DIR)/ (存在)"; \
	else \
		echo "  $(COLOR_YELLOW)✗$(COLOR_RESET) $(ANALYSIS_DIR)/ (不存在)"; \
	fi
	@if [ -d "$(REPORTS_DIR)" ]; then \
		echo "  $(COLOR_GREEN)✓$(COLOR_RESET) $(REPORTS_DIR)/ (存在)"; \
	else \
		echo "  $(COLOR_YELLOW)✗$(COLOR_RESET) $(REPORTS_DIR)/ (不存在)"; \
	fi
	@echo ""
	@echo "$(COLOR_BOLD)关键文件:$(COLOR_RESET)"
	@if [ -f "$(RESULTS_DIR)/code_size.csv" ]; then \
		echo "  $(COLOR_GREEN)✓$(COLOR_RESET) code_size.csv (存在)"; \
	else \
		echo "  $(COLOR_YELLOW)✗$(COLOR_RESET) code_size.csv (不存在)"; \
	fi
	@if [ -f "$(RESULTS_DIR)/extended_metrics.csv" ]; then \
		echo "  $(COLOR_GREEN)✓$(COLOR_RESET) extended_metrics.csv (存在)"; \
	else \
		echo "  $(COLOR_YELLOW)✗$(COLOR_RESET) extended_metrics.csv (不存在)"; \
	fi
	@echo ""
