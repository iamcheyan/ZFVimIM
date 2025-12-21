#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
将墨染双拼格式转换为标准格式
输入格式：词组\t编码1 编码2 ...
输出格式：编码\t词组1\t词组2\t...
"""

import sys
import os
from collections import defaultdict

def convert_moran_to_standard(input_file, output_file=None):
    """将墨染双拼格式转换为标准格式"""
    if output_file is None:
        # 创建新文件，不覆盖原文件
        base_name = os.path.splitext(input_file)[0]
        output_file = base_name + "_converted.yaml"
    
    print(f"正在处理 {input_file}...")
    
    # 使用字典来收集相同编码的词组
    # key: 编码, value: list of 词组
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
            
            # 分割：词组\t编码1 编码2 ...
            parts = line.split('\t')
            if len(parts) < 2:
                # 尝试用空格分割
                parts = line.split(None, 1)
                if len(parts) < 2:
                    continue
            
            word = parts[0].strip()
            encodings = parts[1].strip()
            
            if not word or not encodings:
                continue
            
            # 将编码组合成完整编码（保持空格分隔）
            # 例如："dy dy" -> "dy dy"
            full_encoding = encodings
            
            # 添加到字典中
            encoding_to_words[full_encoding].append(word)
    
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
        print("使用方法: python convert_moran_to_standard.py <输入文件> [输出文件]", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    if not os.path.exists(input_file):
        print(f"错误: 文件不存在: {input_file}", file=sys.stderr)
        sys.exit(1)
    
    convert_moran_to_standard(input_file, output_file)

if __name__ == '__main__':
    main()

