#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
按字数拆分字典文件
将不同字数的词组保存到不同的文件中（1字.yaml, 2字.yaml, 3字.yaml等）
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

def split_by_word_length(input_file, output_dir=None):
    """按字数拆分字典文件"""
    if output_dir is None:
        output_dir = os.path.dirname(input_file)
    
    print(f"正在处理 {input_file}...")
    
    # 使用字典来按字数分类：{字数: {编码: [词组列表]}}
    word_length_dict = defaultdict(lambda: defaultdict(list))
    
    line_count = 0
    with open(input_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            
            line_count += 1
            if line_count % 100000 == 0:
                print(f"  已处理 {line_count} 行...")
            
            # 格式：编码\t词组1\t词组2\t...
            parts = line.split('\t')
            if len(parts) < 2:
                continue
            
            encoding = parts[0].strip()
            words = parts[1:]
            
            if not encoding:
                continue
            
            # 按字数分类词组
            for word in words:
                word = word.strip()
                if not word:
                    continue
                
                # 统计汉字数量
                char_count = count_chinese_chars(word)
                if char_count > 0:
                    word_length_dict[char_count][encoding].append(word)
    
    print(f"  共处理 {line_count} 行")
    print(f"正在写入文件...")
    
    # 确保输出目录存在
    if output_dir and not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    # 按字数写入不同的文件
    total_files = 0
    total_words = 0
    
    for word_length in sorted(word_length_dict.keys()):
        output_file = os.path.join(output_dir, f"{word_length}字.yaml")
        
        encoding_to_words = word_length_dict[word_length]
        file_word_count = 0
        
        with open(output_file, 'w', encoding='utf-8') as f:
            # 按编码排序
            for encoding in sorted(encoding_to_words.keys()):
                words = encoding_to_words[encoding]
                # 去重并排序
                words = sorted(set(words))
                # 写入：编码\t词组1\t词组2\t...
                line = encoding + '\t' + '\t'.join(words)
                f.write(line + '\n')
                file_word_count += len(words)
        
        total_files += 1
        total_words += file_word_count
        print(f"  已写入 {word_length}字.yaml: {len(encoding_to_words)} 个编码, {file_word_count} 个词组")
    
    print(f"\n处理完成！")
    print(f"  生成了 {total_files} 个文件")
    print(f"  总词组数: {total_words}")
    print(f"  输出目录: {output_dir}")

def main():
    if len(sys.argv) < 2:
        print("使用方法: python split_by_word_length.py <输入文件> [输出目录]", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else None
    
    if not os.path.exists(input_file):
        print(f"错误: 文件不存在: {input_file}", file=sys.stderr)
        sys.exit(1)
    
    split_by_word_length(input_file, output_dir)

if __name__ == '__main__':
    main()
