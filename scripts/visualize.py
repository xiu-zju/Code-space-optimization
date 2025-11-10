#!/usr/bin/env python3
"""
数据可视化脚本 - 生成代码空间优化分析图表
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import sys
import os
import argparse
from pathlib import Path
import numpy as np


# 设置中文字体支持
plt.rcParams['font.sans-serif'] = ['DejaVu Sans', 'Arial', 'sans-serif']
plt.rcParams['axes.unicode_minus'] = False

# 设置seaborn样式
sns.set_style("whitegrid")
sns.set_palette("husl")


def load_data(csv_file):
    """
    加载CSV文件到pandas DataFrame
    
    Args:
        csv_file: CSV文件路径
        
    Returns:
        pandas DataFrame包含代码大小数据
    """
    if not os.path.exists(csv_file):
        raise FileNotFoundError(f"数据文件不存在: {csv_file}")
    
    df = pd.read_csv(csv_file)
    print(f"成功加载 {len(df)} 条记录")
    return df


def plot_code_size_by_program(df, output_dir):
    """
    为每个测试程序生成柱状图，显示不同优化级别的代码大小
    按编译器分组显示
    
    Args:
        df: pandas DataFrame
        output_dir: 输出目录路径
    """
    print("\n生成按程序的代码大小可视化...")
    
    programs = sorted(df['program'].unique())
    
    for program in programs:
        program_data = df[df['program'] == program].copy()
        
        # 创建图表
        fig, ax = plt.subplots(figsize=(12, 6))
        
        # 获取编译器和优化级别
        compilers = sorted(program_data['compiler'].unique())
        opt_levels = sorted(program_data['opt_level'].unique(), 
                           key=lambda x: (x not in ['-O0', '-O1', '-O2', '-O3', '-Os', '-Oz'], x))
        
        # 设置柱状图参数
        x = np.arange(len(opt_levels))
        width = 0.35
        
        # 为每个编译器绘制柱状图
        for i, compiler in enumerate(compilers):
            compiler_data = program_data[program_data['compiler'] == compiler]
            sizes = [compiler_data[compiler_data['opt_level'] == opt]['total_size'].values[0] 
                    if not compiler_data[compiler_data['opt_level'] == opt].empty else 0
                    for opt in opt_levels]
            
            offset = width * (i - len(compilers)/2 + 0.5)
            bars = ax.bar(x + offset, sizes, width, label=compiler.upper())
            
            # 在柱子上添加数值标签
            for bar in bars:
                height = bar.get_height()
                if height > 0:
                    ax.text(bar.get_x() + bar.get_width()/2., height,
                           f'{int(height)}',
                           ha='center', va='bottom', fontsize=8)
        
        # 设置图表属性
        ax.set_xlabel('Optimization Level', fontsize=12)
        ax.set_ylabel('Code Size (bytes)', fontsize=12)
        ax.set_title(f'Code Size Comparison for {program}', fontsize=14, fontweight='bold')
        ax.set_xticks(x)
        ax.set_xticklabels(opt_levels, rotation=45, ha='right')
        ax.legend()
        ax.grid(True, alpha=0.3)
        
        # 保存图表
        plt.tight_layout()
        output_file = output_dir / f'code_size_{program}.png'
        plt.savefig(output_file, dpi=300, bbox_inches='tight')
        plt.close()
        
        print(f"  已生成: {output_file}")
    
    print(f"完成 {len(programs)} 个程序的可视化")


def plot_optimization_comparison(df, output_dir):
    """
    生成折线图显示优化趋势
    计算并显示所有程序的平均值
    
    Args:
        df: pandas DataFrame
        output_dir: 输出目录路径
    """
    print("\n生成优化级别对比可视化...")
    
    # 创建图表
    fig, ax = plt.subplots(figsize=(14, 7))
    
    # 定义标准优化级别顺序
    standard_opts = ['-O0', '-O1', '-O2', '-O3', '-Os']
    clang_opts = ['-O0', '-O1', '-O2', '-O3', '-Os', '-Oz']
    
    compilers = sorted(df['compiler'].unique())
    
    for compiler in compilers:
        compiler_data = df[df['compiler'] == compiler]
        
        # 选择优化级别
        if compiler == 'clang':
            opt_levels = [opt for opt in clang_opts if opt in compiler_data['opt_level'].values]
        else:
            opt_levels = [opt for opt in standard_opts if opt in compiler_data['opt_level'].values]
        
        # 计算每个优化级别的平均代码大小
        avg_sizes = []
        for opt in opt_levels:
            opt_data = compiler_data[compiler_data['opt_level'] == opt]
            avg_size = opt_data['total_size'].mean()
            avg_sizes.append(avg_size)
        
        # 绘制折线图
        ax.plot(opt_levels, avg_sizes, marker='o', linewidth=2, 
               markersize=8, label=compiler.upper())
        
        # 添加数值标签
        for i, (opt, size) in enumerate(zip(opt_levels, avg_sizes)):
            ax.text(i, size, f'{int(size)}', 
                   ha='center', va='bottom', fontsize=9)
    
    # 设置图表属性
    ax.set_xlabel('Optimization Level', fontsize=12)
    ax.set_ylabel('Average Code Size (bytes)', fontsize=12)
    ax.set_title('Optimization Level Comparison (Average Across All Programs)', 
                fontsize=14, fontweight='bold')
    ax.legend(fontsize=11)
    ax.grid(True, alpha=0.3)
    
    # 保存图表
    plt.tight_layout()
    output_file = output_dir / 'optimization_comparison.png'
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    plt.close()
    
    print(f"  已生成: {output_file}")


def plot_compiler_comparison(df, output_dir):
    """
    生成并排柱状图比较GCC和Clang
    按优化级别分组
    
    Args:
        df: pandas DataFrame
        output_dir: 输出目录路径
    """
    print("\n生成编译器对比可视化...")
    
    # 创建图表
    fig, ax = plt.subplots(figsize=(14, 7))
    
    # 获取共同的优化级别
    gcc_opts = set(df[df['compiler'] == 'gcc']['opt_level'].unique())
    clang_opts = set(df[df['compiler'] == 'clang']['opt_level'].unique())
    common_opts = sorted(gcc_opts & clang_opts,
                        key=lambda x: (['-O0', '-O1', '-O2', '-O3', '-Os'].index(x) 
                                      if x in ['-O0', '-O1', '-O2', '-O3', '-Os'] else 99))
    
    # 计算每个编译器在每个优化级别的平均代码大小
    gcc_sizes = []
    clang_sizes = []
    
    for opt in common_opts:
        gcc_data = df[(df['compiler'] == 'gcc') & (df['opt_level'] == opt)]
        clang_data = df[(df['compiler'] == 'clang') & (df['opt_level'] == opt)]
        
        gcc_sizes.append(gcc_data['total_size'].mean())
        clang_sizes.append(clang_data['total_size'].mean())
    
    # 设置柱状图参数
    x = np.arange(len(common_opts))
    width = 0.35
    
    # 绘制并排柱状图
    bars1 = ax.bar(x - width/2, gcc_sizes, width, label='GCC', alpha=0.8)
    bars2 = ax.bar(x + width/2, clang_sizes, width, label='Clang', alpha=0.8)
    
    # 添加数值标签
    for bars in [bars1, bars2]:
        for bar in bars:
            height = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2., height,
                   f'{int(height)}',
                   ha='center', va='bottom', fontsize=9)
    
    # 设置图表属性
    ax.set_xlabel('Optimization Level', fontsize=12)
    ax.set_ylabel('Average Code Size (bytes)', fontsize=12)
    ax.set_title('Compiler Comparison: GCC vs Clang (Average Across All Programs)', 
                fontsize=14, fontweight='bold')
    ax.set_xticks(x)
    ax.set_xticklabels(common_opts)
    ax.legend(fontsize=11)
    ax.grid(True, alpha=0.3, axis='y')
    
    # 保存图表
    plt.tight_layout()
    output_file = output_dir / 'compiler_comparison.png'
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    plt.close()
    
    print(f"  已生成: {output_file}")


def plot_advanced_optimizations(df, output_dir):
    """
    显示LTO和PGO的效果，与标准优化级别对比
    
    Args:
        df: pandas DataFrame
        output_dir: 输出目录路径
    """
    print("\n生成高级优化可视化...")
    
    # 创建图表
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 6))
    
    # 定义优化级别（包括高级优化）
    all_opts = ['-O0', '-O1', '-O2', '-O3', '-Os', 'lto', 'pgo']
    
    # 为每个编译器绘制图表
    for idx, compiler in enumerate(['gcc', 'clang']):
        ax = ax1 if compiler == 'gcc' else ax2
        
        compiler_data = df[df['compiler'] == compiler]
        available_opts = [opt for opt in all_opts if opt in compiler_data['opt_level'].values]
        
        # 计算平均代码大小
        avg_sizes = []
        for opt in available_opts:
            opt_data = compiler_data[compiler_data['opt_level'] == opt]
            avg_sizes.append(opt_data['total_size'].mean())
        
        # 绘制柱状图
        colors = ['#1f77b4' if opt in ['-O0', '-O1', '-O2', '-O3', '-Os', '-Oz'] 
                 else '#ff7f0e' for opt in available_opts]
        bars = ax.bar(available_opts, avg_sizes, color=colors, alpha=0.8)
        
        # 添加数值标签
        for bar in bars:
            height = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2., height,
                   f'{int(height)}',
                   ha='center', va='bottom', fontsize=9)
        
        # 设置图表属性
        ax.set_xlabel('Optimization Level', fontsize=11)
        ax.set_ylabel('Average Code Size (bytes)', fontsize=11)
        ax.set_title(f'{compiler.upper()}: Standard vs Advanced Optimizations', 
                    fontsize=12, fontweight='bold')
        ax.tick_params(axis='x', rotation=45)
        ax.grid(True, alpha=0.3, axis='y')
        
        # 添加图例
        from matplotlib.patches import Patch
        legend_elements = [Patch(facecolor='#1f77b4', alpha=0.8, label='Standard'),
                          Patch(facecolor='#ff7f0e', alpha=0.8, label='Advanced')]
        ax.legend(handles=legend_elements, fontsize=10)
    
    # 保存图表
    plt.tight_layout()
    output_file = output_dir / 'advanced_optimizations.png'
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    plt.close()
    
    print(f"  已生成: {output_file}")


def plot_size_reduction_heatmap(df, output_dir):
    """
    创建程序 x 优化级别的热力图
    使用颜色表示代码大小减少百分比
    
    Args:
        df: pandas DataFrame
        output_dir: 输出目录路径
    """
    print("\n生成代码大小减少热力图...")
    
    # 为每个编译器创建热力图
    compilers = sorted(df['compiler'].unique())
    
    for compiler in compilers:
        compiler_data = df[df['compiler'] == compiler].copy()
        
        # 计算相对于-O0的减少百分比
        programs = sorted(compiler_data['program'].unique())
        opt_levels = sorted(compiler_data['opt_level'].unique(),
                           key=lambda x: (x not in ['-O0', '-O1', '-O2', '-O3', '-Os', '-Oz'], x))
        
        # 创建矩阵
        reduction_matrix = []
        
        for program in programs:
            program_data = compiler_data[compiler_data['program'] == program]
            baseline = program_data[program_data['opt_level'] == '-O0']
            
            if baseline.empty:
                continue
            
            baseline_size = baseline['total_size'].values[0]
            
            row = []
            for opt in opt_levels:
                opt_data = program_data[program_data['opt_level'] == opt]
                if not opt_data.empty:
                    opt_size = opt_data['total_size'].values[0]
                    reduction_pct = (baseline_size - opt_size) / baseline_size * 100
                    row.append(reduction_pct)
                else:
                    row.append(np.nan)
            
            reduction_matrix.append(row)
        
        # 创建DataFrame
        heatmap_df = pd.DataFrame(reduction_matrix, 
                                 index=programs, 
                                 columns=opt_levels)
        
        # 创建热力图
        fig, ax = plt.subplots(figsize=(12, 8))
        
        sns.heatmap(heatmap_df, annot=True, fmt='.1f', cmap='RdYlGn', 
                   center=0, cbar_kws={'label': 'Size Reduction (%)'}, 
                   linewidths=0.5, ax=ax)
        
        ax.set_title(f'Code Size Reduction Heatmap - {compiler.upper()} (vs -O0)', 
                    fontsize=14, fontweight='bold')
        ax.set_xlabel('Optimization Level', fontsize=12)
        ax.set_ylabel('Program', fontsize=12)
        
        # 保存图表
        plt.tight_layout()
        output_file = output_dir / f'size_reduction_heatmap_{compiler}.png'
        plt.savefig(output_file, dpi=300, bbox_inches='tight')
        plt.close()
        
        print(f"  已生成: {output_file}")


def parse_arguments():
    """
    解析命令行参数
    
    Returns:
        argparse.Namespace: 解析后的参数
    """
    parser = argparse.ArgumentParser(
        description='代码空间优化数据可视化脚本 - 生成代码大小分析图表',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  %(prog)s                                    # 使用默认路径
  %(prog)s --input data/code_size.csv         # 指定输入文件
  %(prog)s --output charts/                   # 指定输出目录
  %(prog)s --input data.csv --output out/     # 同时指定输入和输出
        """
    )
    
    parser.add_argument(
        '--input', '-i',
        type=str,
        default='results/code_size.csv',
        help='输入CSV文件路径 (默认: results/code_size.csv)'
    )
    
    parser.add_argument(
        '--output', '-o',
        type=str,
        default='reports/figures',
        help='输出目录路径 (默认: reports/figures)'
    )
    
    parser.add_argument(
        '--version', '-v',
        action='version',
        version='%(prog)s 1.0'
    )
    
    return parser.parse_args()


def main():
    """主函数"""
    # 解析命令行参数
    args = parse_arguments()
    
    # 设置路径
    input_file = Path(args.input)
    figures_dir = Path(args.output)
    
    # 创建输出目录
    figures_dir.mkdir(parents=True, exist_ok=True)
    
    try:
        print("=" * 80)
        print("开始数据可视化")
        print("=" * 80)
        print(f"输入文件: {input_file}")
        print(f"输出目录: {figures_dir}")
        print()
        
        # 加载数据
        df = load_data(input_file)
        
        # 生成各种可视化
        plot_code_size_by_program(df, figures_dir)
        plot_optimization_comparison(df, figures_dir)
        plot_compiler_comparison(df, figures_dir)
        plot_advanced_optimizations(df, figures_dir)
        plot_size_reduction_heatmap(df, figures_dir)
        
        print("\n" + "=" * 80)
        print("可视化完成！")
        print("=" * 80)
        print(f"\n所有图表已保存到: {figures_dir}")
        
    except Exception as e:
        print(f"\n错误: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
