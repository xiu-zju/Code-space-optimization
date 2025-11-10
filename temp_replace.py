#!/usr/bin/env python3
import re

with open('reports/report.tex', 'r', encoding='utf-8') as f:
    content = f.read()

# 找到"五、分析与讨论"部分的开始
start_pattern = r'\\section\{五、分析与讨论\}'
# 找到下一个section的开始（结论部分）
end_pattern = r'\\section\{结论\}'

# 新的精简内容
new_section = r'''\section{五、分析与讨论}

\subsection{优化级别的选择}

实验结果表明，不同优化级别在代码大小和性能之间存在明显的权衡关系。-Os作为专门针对代码大小的优化选项，在两个编译器上都表现出色，GCC平均减少24.20\%，Clang减少27.62\%，是标准优化级别中的最佳选择。相比之下，-O2虽然代码大小减少较少（GCC 10.30\%，Clang 6.89\%），但通常能提供更好的运行时性能，适合性能关键的应用场景。

值得注意的是，-O3优化在代码大小方面表现不佳，GCC平均仅减少0.84\%，在某些程序中甚至增加代码大小。这是因为-O3启用了循环展开、激进的函数内联等优化技术，这些优化以牺牲代码大小为代价来提升运行时性能。因此，除非性能是首要考虑因素，否则不推荐使用-O3进行代码大小优化。

\subsection{编译器对比}

Clang在代码大小优化方面整体优于GCC，平均生成的代码比GCC小3.8\%。Clang的-Oz选项是其独特优势，提供了最激进的代码大小优化，平均减少33.24\%。此外，Clang的LTO优化效果也特别出色，平均减少32.03\%，在矩阵运算等循环密集型程序中表现尤为突出。

GCC虽然在整体代码大小上略逊一筹，但在某些特定场景下仍有其优势。例如，在linked\_list程序中，GCC的PGO优化表现最佳。GCC的-O1和-Os优化效果稳定可靠，适合需要兼容性和稳定性的项目。

\subsection{程序特征的影响}

不同类型的程序对编译器优化的响应程度存在显著差异。递归算法（如fibonacci和quicksort）和循环密集型程序（如matrix\_add和matrix\_mult）对优化最为敏感，最大代码大小减少可达40-50\%。这是因为编译器能够对这些程序进行尾递归优化、循环展开和向量化等深度优化。

相比之下，字符串处理程序（如string\_search）的优化效果相对较低，最大减少约39.47\%。这类程序通常涉及大量的指针操作和条件判断，编译器的优化空间相对有限。位操作程序（如popcount）则展示了中等的优化潜力，编译器能够识别并优化常见的位操作模式。

\subsection{高级优化技术}

链接时优化（LTO）在本研究中表现最为出色，是最有效的高级优化技术。LTO能够进行跨编译单元的全局优化，消除冗余代码和未使用的函数。Clang的LTO在matrix\_add程序中达到了49.20\%的惊人效果。然而，LTO也存在编译时间显著增加、调试难度提高等局限性，在单文件程序中的优势也不如多文件项目明显。

配置文件引导优化（PGO）在本测试中的效果不如预期，GCC PGO平均仅减少4.03\%，在某些程序中甚至导致代码大小增加。这主要是因为测试程序较为简单，运行时间短，profile数据不够充分。PGO的主要目标是性能优化而非代码大小优化，更适合具有明显运行时热点的大型复杂程序。

'''

# 使用正则表达式替换
pattern = start_pattern + r'.*?' + end_pattern
replacement = new_section + r'\section{结论}'

content_new = re.sub(pattern, replacement, content, flags=re.DOTALL)

with open('reports/report.tex', 'w', encoding='utf-8') as f:
    f.write(content_new)

print("替换完成！")
