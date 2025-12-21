#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
去掉编码中的所有空格
格式：编码\t词组1\t词组2\t...
处理后：编码（无空格）\t词组1\t词组2\t...
"""

import sys
import os
from collections import defaultdict

def remove_spaces_from_encoding(input_file, output_file=None):
    """去掉编码中的所有空格"""
    if output_file is None:
        output_file = input_file
    
    print(f"正在处理 {input_file}...")
    
    # 使用字典来收集相同编码（去空格后）的词组
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
            
            # 分割：编码\t词组1\t词组2\t...
            parts = line.split('\t')
            if len(parts) < 2:
                continue
            
            encoding = parts[0].strip()
            words = parts[1:]
            
            if not encoding:
                continue
            
            # 去掉编码中的所有空格
            encoding_no_space = encoding.replace(' ', '')
            
            # 添加到字典中
            for word in words:
                word = word.strip()
                if word:
                    encoding_to_words[encoding_no_space].append(word)
    
    print(f"  共处理 {line_count} 行")
    print(f"正在写入 {output_file}...")
    
    # 写入输出文件
    with open(output_file, 'w', encoding='utf-8') as f:
        # 按编码排序
        for encoding in sorted(encoding_to_words.keys()):
            words = encoding_to_words[encoding]
            # 去重并排序
            words = sorted(set(words))
            # 写入：编码\t词组1\t词组2\t...
            line = encoding + '\t' + '\t'.join(words)
            f.write(line + '\n')
    
    print(f"\n处理完成！")
    print(f"  总编码数: {len(encoding_to_words)}")
    print(f"  总词组数: {sum(len(words) for words in encoding_to_words.values())}")
    print(f"  输出文件: {output_file}")

def main():
    if len(sys.argv) < 2:
        print("使用方法: python remove_spaces_from_encoding.py <输入文件> [输出文件]", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    if not os.path.exists(input_file):
        print(f"错误: 文件不存在: {input_file}", file=sys.stderr)
        sys.exit(1)
    
    remove_spaces_from_encoding(input_file, output_file)

if __name__ == '__main__':
    main()

