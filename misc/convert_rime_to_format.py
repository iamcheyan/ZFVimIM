#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
将 rime_mint.base.dict.yaml 转换为我们的格式
清理编码和数字，重新生成拼音编码
"""

import sys
import os
import re
from collections import defaultdict

def load_pinyin_map(default_file):
    """
    从 default.yaml 加载汉字到拼音的映射
    格式：拼音 汉字1 汉字2 汉字3 ...
    """
    pinyin_map = {}
    with open(default_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            
            # 格式：拼音 汉字1 汉字2 ...
            parts = line.split()
            if len(parts) >= 2:
                pinyin = parts[0].strip()
                # 从第二个部分开始都是汉字
                for word in parts[1:]:
                    # 提取所有汉字字符
                    for char in word:
                        if '\u4e00' <= char <= '\u9fff':
                            # 如果汉字还没有映射，或者这是第一个映射，则添加
                            if char not in pinyin_map:
                                pinyin_map[char] = pinyin
    
    return pinyin_map

def word_to_pinyin(word, pinyin_map):
    """
    将汉字词转换为拼音编码（不带声调）
    例如：'你好' -> 'nihao'
    """
    pinyin_list = []
    for char in word:
        if '\u4e00' <= char <= '\u9fff':
            # 查找汉字的拼音
            pinyin = pinyin_map.get(char, '')
            if pinyin:
                pinyin_list.append(pinyin)
            else:
                # 如果找不到拼音，返回空字符串
                return ''
        else:
            # 非汉字字符，跳过
            continue
    
    return ''.join(pinyin_list)

def parse_rime_line(line):
    """
    解析 rime 格式的行
    格式：词\t拼音（带声调）\t数字
    例如：阿爸	ā bà	525
    返回：词（如果有效）
    """
    line = line.strip()
    if not line or line.startswith('#'):
        return None
    
    # 分割：词\t拼音\t数字
    parts = line.split('\t')
    if len(parts) < 1:
        return None
    
    word = parts[0].strip()
    if not word:
        return None
    
    # 只保留汉字词（过滤非汉字）
    if not re.search(r'[\u4e00-\u9fff]', word):
        return None
    
    return word

def convert_rime_file(rime_file, default_file, output_file):
    """
    转换 rime 文件到我们的格式
    """
    # 加载拼音映射
    print(f"正在加载 {default_file} 中的拼音映射...")
    pinyin_map = load_pinyin_map(default_file)
    print(f"已加载 {len(pinyin_map)} 个汉字的拼音映射")
    
    # 读取 rime 文件，按编码分组
    print(f"\n正在读取 {rime_file}...")
    code_to_words = defaultdict(set)  # 编码 -> 词集合
    
    total_lines = 0
    processed_words = 0
    skipped_words = 0
    
    with open(rime_file, 'r', encoding='utf-8') as f:
        for line in f:
            total_lines += 1
            if total_lines % 100000 == 0:
                print(f"  处理中... 已处理 {total_lines} 行, 已收集 {processed_words} 个词")
            
            word = parse_rime_line(line)
            if word is None:
                continue
            
            # 生成拼音编码
            pinyin_code = word_to_pinyin(word, pinyin_map)
            if not pinyin_code:
                skipped_words += 1
                continue
            
            # 添加到对应编码的集合中
            code_to_words[pinyin_code].add(word)
            processed_words += 1
    
    print(f"\n读取完成！")
    print(f"  总行数: {total_lines}")
    print(f"  处理了 {processed_words} 个词")
    print(f"  跳过了 {skipped_words} 个词（无法生成拼音）")
    print(f"  生成了 {len(code_to_words)} 个不同的编码")
    
    # 写入输出文件
    print(f"\n正在写入 {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        # 按编码排序
        for code in sorted(code_to_words.keys()):
            words = sorted(list(code_to_words[code]))
            # 格式：编码\t词1\t词2\t...
            line = code + '\t' + '\t'.join(words) + '\n'
            f.write(line)
    
    print(f"转换完成！")
    print(f"  输出文件: {output_file}")
    print(f"  总词条数: {len(code_to_words)}")

def main():
    if len(sys.argv) < 3:
        print("使用方法: python convert_rime_to_format.py <rime_file> <default.yaml> [output_file]", file=sys.stderr)
        sys.exit(1)
    
    rime_file = sys.argv[1]
    default_file = sys.argv[2]
    output_file = sys.argv[3] if len(sys.argv) > 3 else rime_file.replace('.yaml', '_converted.yaml')
    
    if not os.path.exists(rime_file):
        print(f"错误: 文件不存在: {rime_file}", file=sys.stderr)
        sys.exit(1)
    
    if not os.path.exists(default_file):
        print(f"错误: 文件不存在: {default_file}", file=sys.stderr)
        sys.exit(1)
    
    convert_rime_file(rime_file, default_file, output_file)

if __name__ == '__main__':
    main()

