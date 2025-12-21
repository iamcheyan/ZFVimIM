#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
删除字典文件中没有编码的词条
格式：词条\t编码\t频率
如果没有编码，格式为：词条\t\t频率
"""

import sys
import os

def remove_no_encoding(input_file, output_file=None):
    """删除没有编码的词条"""
    if output_file is None:
        output_file = input_file
    
    removed_count = 0
    kept_count = 0
    
    print(f"正在处理 {input_file}...")
    
    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    filtered_lines = []
    
    for line in lines:
        original_line = line
        line = line.rstrip('\n')
        
        # 空行保留
        if not line.strip():
            filtered_lines.append(original_line)
            continue
        
        # 按制表符分割
        parts = line.split('\t')
        
        # 如果只有词条和频率，没有编码（中间为空），则删除
        # 格式：词条\t\t频率 或 词条\t频率（只有一个制表符）
        if len(parts) == 2:
            # 词条\t频率（没有编码列）
            removed_count += 1
            continue
        elif len(parts) == 3:
            # 词条\t编码\t频率
            word = parts[0].strip()
            encoding = parts[1].strip()
            freq = parts[2].strip()
            
            # 如果编码为空，删除
            if not encoding:
                removed_count += 1
                continue
            
            # 保留这一行
            filtered_lines.append(original_line)
            kept_count += 1
        else:
            # 其他格式，保留
            filtered_lines.append(original_line)
            kept_count += 1
    
    # 写入文件
    with open(output_file, 'w', encoding='utf-8') as f:
        for line in filtered_lines:
            f.write(line + '\n')
    
    print(f"\n处理完成！")
    print(f"  删除了 {removed_count} 个没有编码的词条")
    print(f"  保留了 {kept_count} 个词条")
    print(f"  输出文件: {output_file}")

def main():
    if len(sys.argv) < 2:
        print("使用方法: python remove_no_encoding.py <输入文件> [输出文件]", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    if not os.path.exists(input_file):
        print(f"错误: 文件不存在: {input_file}", file=sys.stderr)
        sys.exit(1)
    
    remove_no_encoding(input_file, output_file)

if __name__ == '__main__':
    main()

