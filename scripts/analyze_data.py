#!/usr/bin/env python3
"""
数据分析脚本 - 分析编译器优化对代码大小的影响
"""

import pandas as pd
import sys
import os
import argparse
from pathlib import Path


def load_data(csv_file):
    """
    加载CSV文件到pandas DataFrame
    
    Args:
        csv_file: CSV文件路径
        
    Returns:
        pandas DataFrame包含代码大小数据
        
    Raises:
        FileNotFoundError: 如果文件不存在
        pd.errors.EmptyDataError: 如果文件为空
    """
    if not os.path.exists(csv_file):
        raise FileNotFoundError(f"数据文件不存在: {csv_file}")
    
    try:
        df = pd.read_csv(csv_file)
        print(f"成功加载 {len(df)} 条记录")
        return df
    except pd.errors.EmptyDataError:
        raise pd.errors.EmptyDataError(f"数据文件为空: {csv_file}")
    except Exception as e:
        raise Exception(f"加载数据失败: {e}")


def validate_data(df):
    """
    验证数据完整性和必需列
    
    Args:
        df: pandas DataFrame
        
    Returns:
        验证后的DataFrame
        
    Raises:
        ValueError: 如果缺少必需列或数据无效
    """
    # 检查必需列
    required_columns = ['program', 'compiler', 'opt_level', 'text_size', 
                       'data_size', 'bss_size', 'total_size', 'timestamp']
    missing_columns = set(required_columns) - set(df.columns)
    
    if missing_columns:
        raise ValueError(f"缺少必需列: {missing_columns}")
    
    # 检查数据完整性
    if df.empty:
        raise ValueError("数据集为空")
    
    # 检查数值列
    numeric_columns = ['text_size', 'data_size', 'bss_size', 'total_size']
    for col in numeric_columns:
        if not pd.api.types.is_numeric_dtype(df[col]):
            raise ValueError(f"列 {col} 必须是数值类型")
    
    # 处理缺失值
    missing_count = df.isnull().sum().sum()
    if missing_count > 0:
        print(f"警告: 发现 {missing_count} 个缺失值")
        # 删除包含缺失值的行
        df = df.dropna()
        print(f"删除缺失值后剩余 {len(df)} 条记录")
    
    # 检查异常数据（负数）
    for col in numeric_columns:
        negative_count = (df[col] < 0).sum()
        if negative_count > 0:
            print(f"警告: 列 {col} 中发现 {negative_count} 个负值")
            df = df[df[col] >= 0]
    
    print("数据验证通过")
    return df


def calculate_statistics(df, output_file):
    """
    计算统计信息：平均值、中位数、标准差
    按程序、编译器和优化级别分组
    
    Args:
        df: pandas DataFrame
        output_file: 输出CSV文件路径
        
    Returns:
        统计结果DataFrame
    """
    print("\n计算统计信息...")
    
    # 按程序、编译器和优化级别分组
    grouped = df.groupby(['program', 'compiler', 'opt_level'])
    
    # 计算统计指标
    stats = grouped.agg({
        'text_size': ['mean', 'median', 'std', 'min', 'max'],
        'data_size': ['mean', 'median', 'std', 'min', 'max'],
        'bss_size': ['mean', 'median', 'std', 'min', 'max'],
        'total_size': ['mean', 'median', 'std', 'min', 'max']
    }).reset_index()
    
    # 展平多级列名
    stats.columns = ['_'.join(col).strip('_') if col[1] else col[0] 
                     for col in stats.columns.values]
    
    # 保存结果
    stats.to_csv(output_file, index=False)
    print(f"统计结果已保存到: {output_file}")
    print(f"生成了 {len(stats)} 条统计记录")
    
    return stats


def compare_compilers(df, output_file):
    """
    比较GCC和Clang编译器
    计算相同优化级别下的代码大小差异和百分比差异
    
    Args:
        df: pandas DataFrame
        output_file: 输出CSV文件路径
        
    Returns:
        编译器比较结果DataFrame
    """
    print("\n比较编译器...")
    
    # 获取GCC和Clang的数据
    gcc_data = df[df['compiler'] == 'gcc'].copy()
    clang_data = df[df['compiler'] == 'clang'].copy()
    
    # 合并数据以进行比较
    comparison = pd.merge(
        gcc_data[['program', 'opt_level', 'total_size']],
        clang_data[['program', 'opt_level', 'total_size']],
        on=['program', 'opt_level'],
        suffixes=('_gcc', '_clang'),
        how='outer'
    )
    
    # 计算差异
    comparison['size_diff'] = comparison['total_size_clang'] - comparison['total_size_gcc']
    comparison['size_diff_pct'] = (comparison['size_diff'] / comparison['total_size_gcc'] * 100).round(2)
    
    # 添加比较结果标签
    comparison['smaller_compiler'] = comparison.apply(
        lambda row: 'gcc' if row['total_size_gcc'] < row['total_size_clang'] 
        else ('clang' if row['total_size_clang'] < row['total_size_gcc'] else 'equal'),
        axis=1
    )
    
    # 保存结果
    comparison.to_csv(output_file, index=False)
    print(f"编译器比较结果已保存到: {output_file}")
    print(f"生成了 {len(comparison)} 条比较记录")
    
    # 打印汇总统计
    gcc_wins = (comparison['smaller_compiler'] == 'gcc').sum()
    clang_wins = (comparison['smaller_compiler'] == 'clang').sum()
    print(f"GCC生成更小代码: {gcc_wins} 次")
    print(f"Clang生成更小代码: {clang_wins} 次")
    
    return comparison


def analyze_optimization_impact(df, output_file):
    """
    分析优化级别的影响
    计算相对于-O0的代码大小减少百分比
    识别最有效的优化级别
    
    Args:
        df: pandas DataFrame
        output_file: 输出CSV文件路径
        
    Returns:
        优化影响分析结果DataFrame
    """
    print("\n分析优化影响...")
    
    results = []
    
    # 按程序和编译器分组
    for (program, compiler), group in df.groupby(['program', 'compiler']):
        # 获取-O0基准
        baseline = group[group['opt_level'] == '-O0']
        if baseline.empty:
            continue
        
        baseline_size = baseline['total_size'].values[0]
        
        # 计算每个优化级别相对于-O0的减少
        for _, row in group.iterrows():
            opt_level = row['opt_level']
            total_size = row['total_size']
            
            size_reduction = baseline_size - total_size
            reduction_pct = (size_reduction / baseline_size * 100).round(2)
            
            results.append({
                'program': program,
                'compiler': compiler,
                'opt_level': opt_level,
                'baseline_size': baseline_size,
                'optimized_size': total_size,
                'size_reduction': size_reduction,
                'reduction_pct': reduction_pct
            })
    
    impact_df = pd.DataFrame(results)
    
    # 保存结果
    impact_df.to_csv(output_file, index=False)
    print(f"优化影响分析已保存到: {output_file}")
    print(f"生成了 {len(impact_df)} 条分析记录")
    
    # 识别最有效的优化级别
    print("\n最有效的优化级别（按平均代码减少百分比）:")
    best_opts = impact_df.groupby(['compiler', 'opt_level'])['reduction_pct'].mean().sort_values(ascending=False)
    for (compiler, opt_level), avg_reduction in best_opts.head(10).items():
        print(f"  {compiler} {opt_level}: {avg_reduction:.2f}%")
    
    return impact_df


def generate_summary_report(df, stats_df, comparison_df, impact_df, output_file):
    """
    生成汇总报告
    整合所有分析结果，生成易读的文本报告
    
    Args:
        df: 原始数据DataFrame
        stats_df: 统计结果DataFrame
        comparison_df: 编译器比较结果DataFrame
        impact_df: 优化影响分析结果DataFrame
        output_file: 输出文本文件路径
    """
    print("\n生成汇总报告...")
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("=" * 80 + "\n")
        f.write("代码空间优化分析报告\n")
        f.write("=" * 80 + "\n\n")
        
        # 1. 数据概览
        f.write("1. 数据概览\n")
        f.write("-" * 80 + "\n")
        f.write(f"总记录数: {len(df)}\n")
        f.write(f"测试程序数: {df['program'].nunique()}\n")
        f.write(f"编译器: {', '.join(df['compiler'].unique())}\n")
        f.write(f"优化级别: {', '.join(sorted(df['opt_level'].unique()))}\n")
        f.write("\n")
        
        # 2. 整体统计
        f.write("2. 整体代码大小统计\n")
        f.write("-" * 80 + "\n")
        f.write(f"平均总大小: {df['total_size'].mean():.2f} 字节\n")
        f.write(f"最小总大小: {df['total_size'].min()} 字节\n")
        f.write(f"最大总大小: {df['total_size'].max()} 字节\n")
        f.write(f"标准差: {df['total_size'].std():.2f} 字节\n")
        f.write("\n")
        
        # 3. 按编译器统计
        f.write("3. 按编译器统计\n")
        f.write("-" * 80 + "\n")
        for compiler in df['compiler'].unique():
            compiler_data = df[df['compiler'] == compiler]
            f.write(f"\n{compiler.upper()}:\n")
            f.write(f"  平均总大小: {compiler_data['total_size'].mean():.2f} 字节\n")
            f.write(f"  最小总大小: {compiler_data['total_size'].min()} 字节\n")
            f.write(f"  最大总大小: {compiler_data['total_size'].max()} 字节\n")
        f.write("\n")
        
        # 4. 编译器比较
        f.write("4. 编译器比较\n")
        f.write("-" * 80 + "\n")
        gcc_wins = (comparison_df['smaller_compiler'] == 'gcc').sum()
        clang_wins = (comparison_df['smaller_compiler'] == 'clang').sum()
        equal = (comparison_df['smaller_compiler'] == 'equal').sum()
        f.write(f"GCC生成更小代码: {gcc_wins} 次 ({gcc_wins/len(comparison_df)*100:.1f}%)\n")
        f.write(f"Clang生成更小代码: {clang_wins} 次 ({clang_wins/len(comparison_df)*100:.1f}%)\n")
        f.write(f"相同大小: {equal} 次 ({equal/len(comparison_df)*100:.1f}%)\n")
        f.write(f"\n平均大小差异: {comparison_df['size_diff'].abs().mean():.2f} 字节\n")
        f.write("\n")
        
        # 5. 优化影响
        f.write("5. 优化级别影响（相对于-O0的平均减少）\n")
        f.write("-" * 80 + "\n")
        for compiler in impact_df['compiler'].unique():
            f.write(f"\n{compiler.upper()}:\n")
            compiler_impact = impact_df[impact_df['compiler'] == compiler]
            opt_impact = compiler_impact.groupby('opt_level')['reduction_pct'].mean().sort_values(ascending=False)
            for opt_level, reduction in opt_impact.items():
                f.write(f"  {opt_level:8s}: {reduction:6.2f}% 减少\n")
        f.write("\n")
        
        # 6. 最佳优化配置
        f.write("6. 最佳优化配置（代码最小）\n")
        f.write("-" * 80 + "\n")
        for program in df['program'].unique():
            program_data = df[df['program'] == program]
            min_size = program_data['total_size'].min()
            best_config = program_data[program_data['total_size'] == min_size].iloc[0]
            f.write(f"{program:15s}: {best_config['compiler']:6s} {best_config['opt_level']:6s} "
                   f"({min_size} 字节)\n")
        f.write("\n")
        
        # 7. 按程序统计
        f.write("7. 按程序统计\n")
        f.write("-" * 80 + "\n")
        for program in sorted(df['program'].unique()):
            program_data = df[df['program'] == program]
            f.write(f"\n{program}:\n")
            f.write(f"  平均大小: {program_data['total_size'].mean():.2f} 字节\n")
            f.write(f"  大小范围: {program_data['total_size'].min()} - {program_data['total_size'].max()} 字节\n")
            f.write(f"  最大减少: {(1 - program_data['total_size'].min() / program_data['total_size'].max()) * 100:.2f}%\n")
        
        f.write("\n")
        f.write("=" * 80 + "\n")
        f.write("报告生成完成\n")
        f.write("=" * 80 + "\n")
    
    print(f"汇总报告已保存到: {output_file}")


def parse_arguments():
    """
    解析命令行参数
    
    Returns:
        argparse.Namespace: 解析后的参数
    """
    parser = argparse.ArgumentParser(
        description='代码空间优化数据分析脚本 - 分析编译器优化对代码大小的影响',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  %(prog)s                                    # 使用默认路径
  %(prog)s --input data/code_size.csv         # 指定输入文件
  %(prog)s --output results/                  # 指定输出目录
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
        default='analysis',
        help='输出目录路径 (默认: analysis)'
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
    analysis_dir = Path(args.output)
    
    # 创建输出目录
    analysis_dir.mkdir(parents=True, exist_ok=True)
    
    # 输出文件
    stats_file = analysis_dir / 'summary_statistics.csv'
    comparison_file = analysis_dir / 'compiler_comparison.csv'
    impact_file = analysis_dir / 'optimization_impact.csv'
    report_file = analysis_dir / 'summary_report.txt'
    
    try:
        # 加载和验证数据
        print("=" * 80)
        print("开始数据分析")
        print("=" * 80)
        print(f"输入文件: {input_file}")
        print(f"输出目录: {analysis_dir}")
        print()
        
        df = load_data(input_file)
        df = validate_data(df)
        
        # 执行分析
        stats_df = calculate_statistics(df, stats_file)
        comparison_df = compare_compilers(df, comparison_file)
        impact_df = analyze_optimization_impact(df, impact_file)
        
        # 生成汇总报告
        generate_summary_report(df, stats_df, comparison_df, impact_df, report_file)
        
        print("\n" + "=" * 80)
        print("分析完成！")
        print("=" * 80)
        print(f"\n输出文件:")
        print(f"  - 统计结果: {stats_file}")
        print(f"  - 编译器比较: {comparison_file}")
        print(f"  - 优化影响: {impact_file}")
        print(f"  - 汇总报告: {report_file}")
        
    except Exception as e:
        print(f"\n错误: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
