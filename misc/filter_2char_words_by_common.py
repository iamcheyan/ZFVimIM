#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
根据常用2字词库清理字典文件中的2字词
只清理2字词，不影响1字词
"""

import sys
import os

def count_chinese_chars(word):
    """统计词组中的汉字数量"""
    count = 0
    for char in word:
        if '\u4e00' <= char <= '\u9fff':
            count += 1
    return count

def load_common_2char_words(common_file):
    """从常用2字词库中加载所有2字词"""
    print(f"正在加载常用2字词库 {common_file}...")
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
                        # 只加载2字词
                        if count_chinese_chars(word) == 2:
                            common_words.add(word)
    
    print(f"  已加载 {len(common_words)} 个常用2字词")
    return common_words

def filter_2char_words_by_common(common_file, input_file, output_file=None):
    """根据常用2字词库清理字典文件中的2字词"""
    if output_file is None:
        output_file = input_file
    
    # 加载常用2字词
    common_2char_words = load_common_2char_words(common_file)
    
    print(f"\n正在处理 {input_file}...")
    
    kept_count = 0
    removed_2char_count = 0
    kept_1char_count = 0
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
                print(f"  已处理 {line_count} 行，保留 {kept_count} 个词组，删除2字词 {removed_2char_count} 个...")
            
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
            
            # 过滤词组
            valid_words = []
            for word in words:
                word = word.strip()
                if not word:
                    continue
                
                char_count = count_chinese_chars(word)
                
                if char_count == 1:
                    # 1字词：保留（不受影响）
                    valid_words.append(word)
                    kept_1char_count += 1
                    kept_count += 1
                elif char_count == 2:
                    # 2字词：只在常用词库中才保留
                    if word in common_2char_words:
                        valid_words.append(word)
                        kept_count += 1
                    else:
                        removed_2char_count += 1
                else:
                    # 其他字数：保留（不受影响）
                    valid_words.append(word)
                    kept_count += 1
            
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
    print(f"  保留了 {kept_count} 个词组（包括 {kept_1char_count} 个1字词）")
    print(f"  删除了 {removed_2char_count} 个2字词（不在常用词库中）")
    print(f"  输出文件: {output_file}")

def main():
    if len(sys.argv) < 3:
        print("使用方法: python filter_2char_words_by_common.py <常用2字词库> <输入文件> [输出文件]", file=sys.stderr)
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
    
    filter_2char_words_by_common(common_file, input_file, output_file)

if __name__ == '__main__':
    main()

