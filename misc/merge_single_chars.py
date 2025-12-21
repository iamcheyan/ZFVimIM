#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
从多个文件中提取单字并合并去重
"""

import sys
import os

def extract_single_chars_from_file(file_path):
    """
    从文件中提取单字（1个汉字）
    支持格式：编码 汉字 或 编码\t汉字
    """
    single_chars = set()
    
    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            
            # 尝试用制表符分割
            parts = line.split('\t', 1)
            if len(parts) < 2:
                # 尝试用空格分割（只分割第一个空格）
                parts = line.split(' ', 1)
            
            if len(parts) < 2:
                # 如果只有一行，可能是纯汉字
                if any('\u4e00' <= c <= '\u9fff' for c in line):
                    for char in line:
                        if '\u4e00' <= char <= '\u9fff' and len(char) == 1:
                            single_chars.add(char)
                continue
            
            # 获取汉字部分
            words = parts[1].strip()
            
            # 提取单字
            for char in words:
                if '\u4e00' <= char <= '\u9fff' and len(char) == 1:
                    single_chars.add(char)
    
    return single_chars

def merge_single_chars(input_files, output_file):
    """
    从多个文件中提取单字，合并去重后保存
    """
    all_chars = set()
    
    for input_file in input_files:
        if not os.path.exists(input_file):
            print(f"警告: 文件不存在，跳过: {input_file}")
            continue
        
        print(f"正在处理: {input_file}")
        chars = extract_single_chars_from_file(input_file)
        print(f"  提取了 {len(chars)} 个单字")
        all_chars.update(chars)
    
    # 排序
    sorted_chars = sorted(all_chars)
    
    # 保存到输出文件
    with open(output_file, 'w', encoding='utf-8') as f:
        for char in sorted_chars:
            f.write(char + '\n')
    
    print(f"\n合并完成！")
    print(f"总共 {len(sorted_chars)} 个单字")
    print(f"已保存到: {output_file}")

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("使用方法: python merge_single_chars.py <输出文件> <输入文件1> [输入文件2] ...", file=sys.stderr)
        sys.exit(1)
    
    output_file = sys.argv[1]
    input_files = sys.argv[2:]
    
    merge_single_chars(input_files, output_file)

