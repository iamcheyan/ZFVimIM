#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
根据常用词库（薄荷全拼）清理墨染双拼文件
只保留在常用词库中也存在的词
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

def load_common_words(common_file, target_word_length):
    """从常用词库中加载指定字数的词"""
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
                        # 只加载指定字数的词
                        if count_chinese_chars(word) == target_word_length:
                            common_words.add(word)
    
    print(f"  已加载 {len(common_words)} 个常用{target_word_length}字词")
    return common_words

def filter_by_common_words(common_file, input_file, output_file=None, target_word_length=None):
    """根据常用词库过滤文件"""
    if output_file is None:
        output_file = input_file
    
    # 如果没有指定字数，从文件名推断
    if target_word_length is None:
        if '2字' in input_file:
            target_word_length = 2
        elif '3字' in input_file:
            target_word_length = 3
        elif '4字' in input_file:
            target_word_length = 4
        else:
            print("错误: 无法从文件名推断字数，请指定 target_word_length", file=sys.stderr)
            sys.exit(1)
    
    # 加载常用词
    common_words = load_common_words(common_file, target_word_length)
    
    print(f"\n正在处理 {input_file}...")
    print(f"只保留 {target_word_length} 字词，且必须在常用词库中")
    
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
            if line_count % 10000 == 0:
                print(f"  已处理 {line_count} 行，保留 {kept_count} 个词组，删除 {removed_count} 个词组...")
            
            # 格式：编码\t词组1\t词组2\t...
            parts = line.split('\t')
            if len(parts) < 2:
                continue
            
            encoding = parts[0].strip()
            words = parts[1:]
            
            if not encoding:
                continue
            
            # 过滤词组：只保留指定字数且在常用词库中的词
            valid_words = []
            for word in words:
                word = word.strip()
                if not word:
                    continue
                
                char_count = count_chinese_chars(word)
                
                # 只保留指定字数的词
                if char_count == target_word_length:
                    # 必须在常用词库中
                    if word in common_words:
                        valid_words.append(word)
                        kept_count += 1
                    else:
                        removed_count += 1
                else:
                    # 其他字数的词：删除
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
    print(f"  删除了 {removed_count} 个词组（不在常用词库中或字数不对）")
    print(f"  输出文件: {output_file}")

def main():
    if len(sys.argv) < 3:
        print("使用方法: python filter_moran_by_common.py <常用词库文件> <输入文件> [输出文件] [字数]", file=sys.stderr)
        print("示例: python filter_moran_by_common.py dict/常用词库（薄荷全拼）/2字.yaml dict/常用词库（墨染双拼）/2字.yaml", file=sys.stderr)
        sys.exit(1)
    
    common_file = sys.argv[1]
    input_file = sys.argv[2]
    output_file = sys.argv[3] if len(sys.argv) > 3 else None
    target_word_length = int(sys.argv[4]) if len(sys.argv) > 4 else None
    
    if not os.path.exists(common_file):
        print(f"错误: 文件不存在: {common_file}", file=sys.stderr)
        sys.exit(1)
    
    if not os.path.exists(input_file):
        print(f"错误: 文件不存在: {input_file}", file=sys.stderr)
        sys.exit(1)
    
    filter_by_common_words(common_file, input_file, output_file, target_word_length)

if __name__ == '__main__':
    main()

