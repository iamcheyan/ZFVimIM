#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
删除字典文件中每行最后的频率数字
格式：词条\t编码\t频率
处理后：词条\t编码
"""

import sys
import os

def remove_frequency_numbers(input_file, output_file=None):
    """删除每行最后的频率数字"""
    if output_file is None:
        output_file = input_file
    
    processed_count = 0
    total_count = 0
    
    print(f"正在处理 {input_file}...")
    
    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    processed_lines = []
    
    for line in lines:
        original_line = line
        line = line.rstrip('\n')
        
        # 空行保留
        if not line.strip():
            processed_lines.append('')
            continue
        
        # 按制表符分割：词条\t编码\t频率
        parts = line.split('\t')
        
        if len(parts) >= 3:
            # 有频率列，删除最后一列
            word = parts[0].strip()
            encoding = parts[1].strip()
            # 只保留词条和编码
            processed_line = f"{word}\t{encoding}"
            processed_lines.append(processed_line)
            processed_count += 1
        elif len(parts) == 2:
            # 只有两列，可能是词条\t编码，保留
            processed_lines.append(line)
            processed_count += 1
        else:
            # 其他格式，保留原样
            processed_lines.append(line)
            processed_count += 1
        
        total_count += 1
    
    # 写入文件
    with open(output_file, 'w', encoding='utf-8') as f:
        for line in processed_lines:
            f.write(line + '\n')
    
    print(f"\n处理完成！")
    print(f"  总行数: {total_count}")
    print(f"  处理了 {processed_count} 行")
    print(f"  输出文件: {output_file}")

def main():
    if len(sys.argv) < 2:
        print("使用方法: python remove_frequency_numbers.py <输入文件> [输出文件]", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    if not os.path.exists(input_file):
        print(f"错误: 文件不存在: {input_file}", file=sys.stderr)
        sys.exit(1)
    
    remove_frequency_numbers(input_file, output_file)

if __name__ == '__main__':
    main()

