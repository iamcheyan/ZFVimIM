#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
检查全拼文件夹中的汉字是否都在 default_pinyin.txt 中
"""

import sys
import os
import glob

def load_chars_from_file(file_path):
    """
    从文件中提取所有汉字
    """
    chars = set()
    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            
            # 提取所有汉字
            for char in line:
                if '\u4e00' <= char <= '\u9fff':
                    chars.add(char)
    
    return chars

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

def main():
    if len(sys.argv) < 3:
        print("使用方法: python check_chars_match.py <default_pinyin.txt> <全拼目录>", file=sys.stderr)
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
    default_chars = load_default_pinyin_chars(default_pinyin_file)
    print(f"default_pinyin.txt 中有 {len(default_chars)} 个不同的汉字")
    
    # 获取所有YAML文件
    yaml_files = glob.glob(os.path.join(pinyin_dir, '*.yaml'))
    yaml_files.sort()
    
    if not yaml_files:
        print(f"错误: 在 {pinyin_dir} 中未找到 YAML 文件", file=sys.stderr)
        sys.exit(1)
    
    print(f"\n正在检查 {len(yaml_files)} 个文件...")
    
    # 收集全拼文件夹中的所有汉字
    all_pinyin_chars = set()
    file_chars_map = {}
    
    for yaml_file in yaml_files:
        filename = os.path.basename(yaml_file)
        print(f"检查: {filename}")
        chars = load_chars_from_file(yaml_file)
        file_chars_map[filename] = chars
        all_pinyin_chars.update(chars)
        print(f"  {len(chars)} 个不同的汉字")
    
    print(f"\n全拼文件夹中总共有 {len(all_pinyin_chars)} 个不同的汉字")
    
    # 检查是否有不在 default_pinyin.txt 中的汉字
    missing_chars = all_pinyin_chars - default_chars
    
    if missing_chars:
        print(f"\n⚠️  发现 {len(missing_chars)} 个汉字不在 default_pinyin.txt 中：")
        sorted_missing = sorted(missing_chars)
        for char in sorted_missing:
            # 找出包含这个汉字的文件
            files_with_char = [f for f, chars in file_chars_map.items() if char in chars]
            print(f"  {char} (出现在: {', '.join(files_with_char[:3])}{'...' if len(files_with_char) > 3 else ''})")
    else:
        print(f"\n✅ 完美匹配！全拼文件夹中的所有汉字都在 default_pinyin.txt 中")
    
    # 额外信息：检查 default_pinyin.txt 中有但全拼文件夹中没有的汉字
    extra_chars = default_chars - all_pinyin_chars
    if extra_chars:
        print(f"\nℹ️  default_pinyin.txt 中有 {len(extra_chars)} 个汉字未在全拼文件夹中使用（这是正常的）")

if __name__ == '__main__':
    main()

