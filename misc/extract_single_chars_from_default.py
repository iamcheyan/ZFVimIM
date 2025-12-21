#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
从 default.yaml 中提取单字，保存到 1字.yaml
格式：编码\t词组1\t词组2\t...
只保留长度为1的汉字
"""

import sys
import os
from collections import defaultdict

def is_single_char(word):
    """检查是否为单字（长度为1的汉字）"""
    if len(word) != 1:
        return False
    # 检查是否为汉字
    return '\u4e00' <= word <= '\u9fff'

def extract_single_chars(input_file, output_file):
    """从 default.yaml 提取单字"""
    print(f"正在处理 {input_file}...")
    
    # 使用字典来收集相同编码的单字
    encoding_to_chars = defaultdict(list)
    
    line_count = 0
    with open(input_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            
            line_count += 1
            if line_count % 10000 == 0:
                print(f"  已处理 {line_count} 行...")
            
            # 格式：编码 词组1 词组2 ...
            parts = line.split()
            if len(parts) < 2:
                continue
            
            encoding = parts[0].strip()
            words = parts[1:]
            
            if not encoding:
                continue
            
            # 只保留单字
            for word in words:
                word = word.strip()
                if is_single_char(word):
                    encoding_to_chars[encoding].append(word)
    
    print(f"  共处理 {line_count} 行")
    print(f"正在写入 {output_file}...")
    
    # 确保输出目录存在
    output_dir = os.path.dirname(output_file)
    if output_dir and not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    # 写入输出文件
    with open(output_file, 'w', encoding='utf-8') as f:
        # 按编码排序
        for encoding in sorted(encoding_to_chars.keys()):
            chars = encoding_to_chars[encoding]
            # 去重并排序
            chars = sorted(set(chars))
            # 写入：编码\t单字1\t单字2\t...
            line = encoding + '\t' + '\t'.join(chars)
            f.write(line + '\n')
    
    print(f"\n处理完成！")
    print(f"  总编码数: {len(encoding_to_chars)}")
    print(f"  总单字数: {sum(len(chars) for chars in encoding_to_chars.values())}")
    print(f"  输出文件: {output_file}")

def main():
    if len(sys.argv) < 3:
        print("使用方法: python extract_single_chars_from_default.py <输入文件> <输出文件>", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    if not os.path.exists(input_file):
        print(f"错误: 文件不存在: {input_file}", file=sys.stderr)
        sys.exit(1)
    
    extract_single_chars(input_file, output_file)

if __name__ == '__main__':
    main()

