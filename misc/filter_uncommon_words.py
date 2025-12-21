#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
根据常用词库过滤不常用的词组
只保留在常用词库中也存在的词组
"""

import sys
import os
from collections import defaultdict

def load_common_words(common_file):
    """从常用词库中加载所有词组"""
    print(f"正在加载常用词库 {common_file}...")
    common_words = set()
    
    with open(common_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            
            # 格式：编码\t词组1\t词组2\t...
            parts = line.split('\t')
            if len(parts) >= 2:
                for word in parts[1:]:
                    word = word.strip()
                    if word:
                        common_words.add(word)
    
    print(f"  已加载 {len(common_words)} 个常用词组")
    return common_words

def filter_uncommon_words(common_file, input_file, output_file=None):
    """根据常用词库过滤不常用的词组"""
    if output_file is None:
        output_file = input_file
    
    # 加载常用词组
    common_words = load_common_words(common_file)
    
    print(f"\n正在处理 {input_file}...")
    
    kept_count = 0
    removed_count = 0
    line_count = 0
    
    # 使用字典来收集相同编码的常用词组
    encoding_to_words = defaultdict(list)
    
    with open(input_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            
            line_count += 1
            if line_count % 10000 == 0:
                print(f"  已处理 {line_count} 行，保留 {kept_count} 行，删除 {removed_count} 行...")
            
            # 格式：编码\t词组1\t词组2\t...
            parts = line.split('\t')
            if len(parts) < 2:
                continue
            
            encoding = parts[0].strip()
            words = parts[1:]
            
            if not encoding:
                continue
            
            # 只保留在常用词库中也存在的词组
            valid_words = []
            for word in words:
                word = word.strip()
                if not word:
                    continue
                
                if word in common_words:
                    valid_words.append(word)
                    kept_count += 1
                else:
                    removed_count += 1
            
            # 如果有有效词组，添加到字典中
            if valid_words:
                encoding_to_words[encoding].extend(valid_words)
    
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
    print(f"  保留了 {len(encoding_to_words)} 个编码")
    print(f"  保留了 {kept_count} 个常用词组")
    print(f"  删除了 {removed_count} 个不常用词组")
    print(f"  输出文件: {output_file}")

def main():
    if len(sys.argv) < 3:
        print("使用方法: python filter_uncommon_words.py <常用词库文件> <输入文件> [输出文件]", file=sys.stderr)
        sys.exit(1)
    
    common_file = sys.argv[1]
    input_file = sys.argv[2]
    output_file = sys.argv[3] if len(sys.argv) > 3 else None
    
    if not os.path.exists(common_file):
        print(f"错误: 文件不存在: {common_file}", file=sys.stderr)
        sys.exit(1)
    
    if not os.path.exists(input_file):
        print(f"错误: 文件不存在: {input_file}", file=sys.stderr)
        sys.exit(1)
    
    filter_uncommon_words(common_file, input_file, output_file)

if __name__ == '__main__':
    main()

