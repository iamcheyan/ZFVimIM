#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
删除字典文件中：
1. 词条中包含数字的词条
2. 所有空行
"""

import sys
import os
import re

# 数字字符（中文数字和阿拉伯数字）
NUMBER_CHARS = set('〇一二三四五六七八九十百千万亿零0123456789')

def contains_number(text):
    """检查文本是否包含数字"""
    return any(char in NUMBER_CHARS for char in text)

def remove_numbers_and_empty_lines(input_file, output_file=None):
    """删除包含数字的词条和空行"""
    if output_file is None:
        output_file = input_file
    
    removed_number_count = 0
    removed_empty_count = 0
    kept_count = 0
    
    print(f"正在处理 {input_file}...")
    
    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    filtered_lines = []
    
    for line in lines:
        original_line = line
        line = line.strip()
        
        # 删除空行
        if not line:
            removed_empty_count += 1
            continue
        
        # 提取词条部分（第一个制表符或空格之前）
        parts = line.split('\t')
        if not parts:
            parts = line.split()
        
        if not parts:
            removed_empty_count += 1
            continue
        
        word = parts[0].strip()
        
        # 检查词条是否包含数字
        if contains_number(word):
            removed_number_count += 1
            continue
        
        # 保留这一行
        filtered_lines.append(original_line.rstrip('\n'))
        kept_count += 1
    
    # 写入文件
    with open(output_file, 'w', encoding='utf-8') as f:
        for line in filtered_lines:
            f.write(line + '\n')
    
    print(f"\n处理完成！")
    print(f"  删除了 {removed_number_count} 个包含数字的词条")
    print(f"  删除了 {removed_empty_count} 个空行")
    print(f"  保留了 {kept_count} 个词条")
    print(f"  输出文件: {output_file}")

def main():
    if len(sys.argv) < 2:
        print("使用方法: python remove_numbers_and_empty_lines.py <输入文件> [输出文件]", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    if not os.path.exists(input_file):
        print(f"错误: 文件不存在: {input_file}", file=sys.stderr)
        sys.exit(1)
    
    remove_numbers_and_empty_lines(input_file, output_file)

if __name__ == '__main__':
    main()

