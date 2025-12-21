#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
从字典文件中删除指定字数及以上的词
只保留1字、2字、3字的词（删除4字及以上的词）
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

def remove_long_words(input_file, output_file=None, max_length=3):
    """删除指定字数及以上的词"""
    if output_file is None or output_file == '':
        output_file = input_file
    
    print(f"正在处理 {input_file}...")
    print(f"保留 {max_length} 字及以下的词，删除 {max_length + 1} 字及以上的词")
    
    removed_count = 0
    kept_count = 0
    line_count = 0
    
    # 使用字典来收集相同编码的词组
    encoding_to_words = {}
    
    with open(input_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            
            line_count += 1
            if line_count % 50000 == 0:
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
            
            # 过滤词组：只保留指定字数及以下的词
            valid_words = []
            for word in words:
                word = word.strip()
                if not word:
                    continue
                
                char_count = count_chinese_chars(word)
                if char_count > 0 and char_count <= max_length:
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
    print(f"  删除了 {removed_count} 个词组（{max_length + 1} 字及以上）")
    print(f"  输出文件: {output_file}")

def main():
    if len(sys.argv) < 2:
        print("使用方法: python remove_long_words_from_file.py <输入文件> [输出文件] [最大字数]", file=sys.stderr)
        print("默认最大字数: 3（保留1-3字，删除4字及以上）", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    max_length = int(sys.argv[3]) if len(sys.argv) > 3 else 3
    
    if not os.path.exists(input_file):
        print(f"错误: 文件不存在: {input_file}", file=sys.stderr)
        sys.exit(1)
    
    remove_long_words(input_file, output_file, max_length)

if __name__ == '__main__':
    main()

