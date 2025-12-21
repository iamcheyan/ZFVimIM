#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
根据单字列表过滤字典文件
删除包含不在单字列表中的字符的词组
"""

import sys
import os

def load_single_chars(single_char_file):
    """从单字文件中加载所有单字"""
    print(f"正在加载单字文件 {single_char_file}...")
    single_chars = set()
    
    with open(single_char_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            
            # 格式：编码\t单字
            parts = line.split('\t')
            if len(parts) >= 2:
                char = parts[1].strip()
                if char and len(char) == 1:
                    single_chars.add(char)
    
    print(f"  已加载 {len(single_chars)} 个单字")
    return single_chars

def contains_invalid_char(word, valid_chars):
    """检查词组是否包含无效字符"""
    for char in word:
        # 只检查汉字字符
        if '\u4e00' <= char <= '\u9fff':
            if char not in valid_chars:
                return True
    return False

def filter_by_single_chars(single_char_file, input_file, output_file=None):
    """根据单字列表过滤字典文件"""
    if output_file is None:
        output_file = input_file
    
    # 加载单字列表
    valid_chars = load_single_chars(single_char_file)
    
    print(f"\n正在处理 {input_file}...")
    
    kept_count = 0
    removed_count = 0
    line_count = 0
    
    # 使用字典来收集相同编码的有效词组
    encoding_to_words = {}
    
    with open(input_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            
            line_count += 1
            if line_count % 50000 == 0:
                print(f"  已处理 {line_count} 行，保留 {kept_count} 个词组，删除 {removed_count} 个词组...")
            
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
            
            # 过滤词组：只保留所有字符都在单字列表中的词组
            valid_words = []
            for word in words:
                word = word.strip()
                if not word:
                    continue
                
                # 检查是否包含无效字符
                if not contains_invalid_char(word, valid_chars):
                    valid_words.append(word)
                    kept_count += 1
                else:
                    removed_count += 1
            
            # 如果有有效词组，添加到字典中
            if valid_words:
                if encoding not in encoding_to_words:
                    encoding_to_words[encoding] = []
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
    print(f"  保留了 {kept_count} 个词组")
    print(f"  删除了 {removed_count} 个词组（包含不在单字列表中的字符）")
    print(f"  输出文件: {output_file}")

def main():
    if len(sys.argv) < 3:
        print("使用方法: python filter_by_single_chars.py <单字文件> <输入文件> [输出文件]", file=sys.stderr)
        sys.exit(1)
    
    single_char_file = sys.argv[1]
    input_file = sys.argv[2]
    output_file = sys.argv[3] if len(sys.argv) > 3 else None
    
    if not os.path.exists(single_char_file):
        print(f"错误: 文件不存在: {single_char_file}", file=sys.stderr)
        sys.exit(1)
    
    if not os.path.exists(input_file):
        print(f"错误: 文件不存在: {input_file}", file=sys.stderr)
        sys.exit(1)
    
    filter_by_single_chars(single_char_file, input_file, output_file)

if __name__ == '__main__':
    main()

