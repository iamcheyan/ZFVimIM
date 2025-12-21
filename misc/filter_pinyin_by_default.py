#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
根据 default_pinyin.txt 过滤全拼文件夹
删除包含不在 default_pinyin.txt 中的汉字的词条
"""

import sys
import os
import glob

def load_default_pinyin_chars(file_path):
    """
    从 default_pinyin.txt 中加载所有汉字（格式：拼音 汉字）
    """
    chars = set()
    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            
            # 格式：拼音 汉字
            parts = line.split(' ', 1)
            if len(parts) >= 2:
                # 获取汉字部分
                word = parts[1].strip()
                # 提取所有汉字
                for char in word:
                    if '\u4e00' <= char <= '\u9fff':
                        chars.add(char)
    
    return chars

def contains_invalid_char(word, valid_chars):
    """
    检查词条是否包含不在有效字符集合中的汉字
    """
    for char in word:
        if '\u4e00' <= char <= '\u9fff':
            if char not in valid_chars:
                return True
    return False

def filter_file(input_file, valid_chars, backup=True):
    """
    过滤文件，删除包含无效汉字的词条
    """
    # 读取文件
    lines = []
    removed_count = 0
    
    with open(input_file, 'r', encoding='utf-8') as f:
        for line in f:
            original_line = line
            line = line.strip()
            if not line:
                lines.append('')
                continue
            
            # 检查这一行是否包含无效汉字
            # 行中可能有多个词，用制表符分隔
            words = line.split('\t')
            
            # 检查所有词
            has_invalid = False
            for word in words:
                if contains_invalid_char(word, valid_chars):
                    has_invalid = True
                    break
            
            if has_invalid:
                removed_count += 1
                continue  # 跳过这一行
            
            # 保留这一行
            lines.append(line)
    
    # 备份原文件
    if backup and removed_count > 0:
        backup_file = input_file + '.backup'
        with open(backup_file, 'w', encoding='utf-8') as f:
            with open(input_file, 'r', encoding='utf-8') as original:
                f.write(original.read())
        print(f"  已备份到: {backup_file}")
    
    # 写入过滤后的内容
    if removed_count > 0:
        with open(input_file, 'w', encoding='utf-8') as f:
            for line in lines:
                f.write(line + '\n')
    
    return removed_count

def main():
    if len(sys.argv) < 3:
        print("使用方法: python filter_pinyin_by_default.py <default_pinyin.txt> <全拼目录>", file=sys.stderr)
        sys.exit(1)
    
    default_pinyin_file = sys.argv[1]
    pinyin_dir = sys.argv[2]
    
    if not os.path.exists(default_pinyin_file):
        print(f"错误: 文件不存在: {default_pinyin_file}", file=sys.stderr)
        sys.exit(1)
    
    if not os.path.isdir(pinyin_dir):
        print(f"错误: 目录不存在: {pinyin_dir}", file=sys.stderr)
        sys.exit(1)
    
    # 加载 default_pinyin.txt 中的所有汉字
    print(f"正在加载 {default_pinyin_file} 中的汉字...")
    valid_chars = load_default_pinyin_chars(default_pinyin_file)
    print(f"已加载 {len(valid_chars)} 个有效汉字")
    
    # 获取所有 YAML 文件
    yaml_files = glob.glob(os.path.join(pinyin_dir, '*.yaml'))
    yaml_files.sort()
    
    if not yaml_files:
        print(f"错误: 在 {pinyin_dir} 中未找到 YAML 文件", file=sys.stderr)
        sys.exit(1)
    
    print(f"\n找到 {len(yaml_files)} 个文件，开始处理...")
    
    total_removed = 0
    for yaml_file in yaml_files:
        filename = os.path.basename(yaml_file)
        print(f"\n处理: {filename}")
        removed = filter_file(yaml_file, valid_chars)
        if removed > 0:
            print(f"  删除了 {removed} 个词条")
            total_removed += removed
        else:
            print(f"  无需删除")
    
    print(f"\n处理完成！总共删除了 {total_removed} 个词条")
    print(f"所有文件已备份为 .backup 文件")

if __name__ == '__main__':
    main()

