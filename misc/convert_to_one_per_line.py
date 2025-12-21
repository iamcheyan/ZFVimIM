#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
将字典文件转换为一行一个的形式
输入格式：编码\t词组1\t词组2\t...
输出格式：编码\t词组1
        编码\t词组2
        ...
"""

import sys
import os

def convert_to_one_per_line(input_file, output_file=None):
    """转换为一行一个的形式"""
    if output_file is None:
        output_file = input_file
    
    print(f"正在处理 {input_file}...")
    
    output_lines = []
    line_count = 0
    
    with open(input_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            
            # 分割：编码\t词组1\t词组2\t...
            parts = line.split('\t')
            if len(parts) < 2:
                continue
            
            encoding = parts[0].strip()
            words = parts[1:]
            
            if not encoding:
                continue
            
            # 每个词组一行
            for word in words:
                word = word.strip()
                if word:
                    output_lines.append(f"{encoding}\t{word}")
                    line_count += 1
    
    print(f"  共生成 {line_count} 行")
    print(f"正在写入 {output_file}...")
    
    # 写入输出文件
    with open(output_file, 'w', encoding='utf-8') as f:
        for line in output_lines:
            f.write(line + '\n')
    
    print(f"\n处理完成！")
    print(f"  总行数: {line_count}")
    print(f"  输出文件: {output_file}")

def main():
    if len(sys.argv) < 2:
        print("使用方法: python convert_to_one_per_line.py <输入文件> [输出文件]", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    if not os.path.exists(input_file):
        print(f"错误: 文件不存在: {input_file}", file=sys.stderr)
        sys.exit(1)
    
    convert_to_one_per_line(input_file, output_file)

if __name__ == '__main__':
    main()

