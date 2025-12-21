#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
按字数拆分词库文件
将文件拆分为 1字.yaml, 2字.yaml, 3字.yaml 等
"""

import sys
import os
import re
from collections import defaultdict

def count_chinese_chars(word):
    """
    统计词中的汉字数量
    """
    count = 0
    for char in word:
        if '\u4e00' <= char <= '\u9fff':
            count += 1
    return count

def split_file_by_length(input_file, output_dir=None):
    """
    按字数拆分文件
    """
    if output_dir is None:
        output_dir = os.path.dirname(input_file)
    
    # 按字数分组：length -> {code: [words]}
    length_to_entries = defaultdict(lambda: defaultdict(set))
    
    print(f"正在读取 {input_file}...")
    total_lines = 0
    
    with open(input_file, 'r', encoding='utf-8') as f:
        for line in f:
            total_lines += 1
            if total_lines % 100000 == 0:
                print(f"  处理中... 已处理 {total_lines} 行")
            
            line = line.strip()
            if not line:
                continue
            
            # 分割：编码\t词1\t词2\t...
            parts = line.split('\t')
            if len(parts) < 2:
                continue
            
            code = parts[0].strip()
            words = parts[1:]
            
            # 按每个词的字数分组
            for word in words:
                word = word.strip()
                if not word:
                    continue
                
                # 统计汉字数量
                char_count = count_chinese_chars(word)
                if char_count > 0:
                    length_to_entries[char_count][code].add(word)
    
    print(f"\n读取完成！共处理 {total_lines} 行")
    
    # 统计每个字数的词条数
    print("\n字数统计：")
    for length in sorted(length_to_entries.keys()):
        total_words = sum(len(words) for words in length_to_entries[length].values())
        print(f"  {length}字: {len(length_to_entries[length])} 个编码, {total_words} 个词")
    
    # 写入文件
    print(f"\n正在写入文件...")
    for length in sorted(length_to_entries.keys()):
        output_file = os.path.join(output_dir, f"{length}字.yaml")
        print(f"  写入: {output_file}")
        
        with open(output_file, 'w', encoding='utf-8') as f:
            # 按编码排序
            for code in sorted(length_to_entries[length].keys()):
                words = sorted(list(length_to_entries[length][code]))
                # 格式：编码\t词1\t词2\t...
                line = code + '\t' + '\t'.join(words) + '\n'
                f.write(line)
    
    print(f"\n拆分完成！")
    print(f"  输出目录: {output_dir}")
    print(f"  生成了 {len(length_to_entries)} 个文件")

def main():
    if len(sys.argv) < 2:
        print("使用方法: python split_by_word_length.py <输入文件> [输出目录]", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else None
    
    if not os.path.exists(input_file):
        print(f"错误: 文件不存在: {input_file}", file=sys.stderr)
        sys.exit(1)
    
    split_file_by_length(input_file, output_dir)

if __name__ == '__main__':
    main()

