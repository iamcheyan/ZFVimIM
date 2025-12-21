#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
从字典文件中提取指定字数的词
"""

import sys
import os
from collections import defaultdict

def count_chinese_chars(word):
    """统计词组中的汉字数量"""
    count = 0
    for char in word:
        if '\u4e00' <= char <= '\u9fff':
            count += 1
    return count

def extract_words_by_length(input_file, output_file, target_length):
    """从字典文件中提取指定字数的词"""
    print(f"正在处理 {input_file}...")
    print(f"提取 {target_length} 字词")
    
    # 使用字典来按编码分类
    encoding_to_words = defaultdict(list)
    
    line_count = 0
    with open(input_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            
            line_count += 1
            if line_count % 100000 == 0:
                print(f"  已处理 {line_count} 行...")
            
            # 格式：编码\t词组1\t词组2\t... 或 编码 词组1 词组2 ...
            if '\t' in line:
                parts = line.split('\t')
            else:
                parts = line.split()
            
            if len(parts) < 2:
                continue
            
            encoding = parts[0].strip()
            words = parts[1:]
            
            if not encoding:
                continue
            
            # 只提取指定字数的词
            for word in words:
                word = word.strip()
                if not word:
                    continue
                
                char_count = count_chinese_chars(word)
                if char_count == target_length:
                    encoding_to_words[encoding].append(word)
    
    print(f"  共处理 {line_count} 行")
    print(f"正在写入 {output_file}...")
    
    # 写入输出文件
    total_words = 0
    with open(output_file, 'w', encoding='utf-8') as f:
        # 按编码排序
        for encoding in sorted(encoding_to_words.keys()):
            words = encoding_to_words[encoding]
            # 去重并排序
            words = sorted(set(words))
            total_words += len(words)
            # 写入：编码\t词组1\t词组2\t...
            line = encoding + '\t' + '\t'.join(words)
            f.write(line + '\n')
    
    print(f"\n处理完成！")
    print(f"  总编码数: {len(encoding_to_words)}")
    print(f"  总词组数: {total_words}")
    print(f"  输出文件: {output_file}")

def main():
    if len(sys.argv) < 4:
        print("使用方法: python extract_words_by_length.py <输入文件> <输出文件> <字数>", file=sys.stderr)
        print("示例: python extract_words_by_length.py dict/moran.base.dict.yaml dict/3字.yaml 3", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    target_length = int(sys.argv[3])
    
    if not os.path.exists(input_file):
        print(f"错误: 文件不存在: {input_file}", file=sys.stderr)
        sys.exit(1)
    
    extract_words_by_length(input_file, output_file, target_length)

if __name__ == '__main__':
    main()

