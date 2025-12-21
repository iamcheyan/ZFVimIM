#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
根据 default.yaml 为全拼文件夹中的词组添加拼音编码
"""

import sys
import os
import glob

def load_pinyin_map(pinyin_file):
    """
    从 default.yaml 加载汉字到拼音的映射
    格式：拼音 汉字
    """
    pinyin_map = {}
    with open(pinyin_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            
            # 格式：拼音 汉字
            parts = line.split(' ', 1)
            if len(parts) >= 2:
                pinyin = parts[0].strip()
                char = parts[1].strip()
                # 只取第一个汉字（如果有多个）
                if char:
                    first_char = char[0]
                    # 如果汉字还没有映射，或者这是第一个映射，则添加
                    if first_char not in pinyin_map:
                        pinyin_map[first_char] = pinyin
    
    return pinyin_map

def word_to_pinyin(word, pinyin_map):
    """
    将汉字词转换为拼音编码
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

def add_pinyin_to_file(input_file, pinyin_map, backup=True):
    """
    为文件中的每个词条添加拼音编码
    """
    lines = []
    processed_count = 0
    
    with open(input_file, 'r', encoding='utf-8') as f:
        for line in f:
            original_line = line
            line = line.strip()
            if not line:
                lines.append('')
                continue
            
            # 分割词条（用制表符分隔）
            words = line.split('\t')
            
            # 为第一个词生成拼音编码
            if words:
                first_word = words[0].strip()
                if first_word:
                    pinyin_code = word_to_pinyin(first_word, pinyin_map)
                    if pinyin_code:
                        # 格式：拼音编码\t词1\t词2\t...
                        new_line = pinyin_code + '\t' + '\t'.join(words)
                        lines.append(new_line)
                        processed_count += 1
                    else:
                        # 如果无法生成拼音，跳过这一行
                        continue
                else:
                    continue
            else:
                continue
    
    # 备份原文件
    if backup:
        backup_file = input_file + '.backup'
        with open(backup_file, 'w', encoding='utf-8') as f:
            with open(input_file, 'r', encoding='utf-8') as original:
                f.write(original.read())
        print(f"  已备份到: {backup_file}")
    
    # 写入修改后的内容
    with open(input_file, 'w', encoding='utf-8') as f:
        for line in lines:
            f.write(line + '\n')
    
    return processed_count

def main():
    if len(sys.argv) < 3:
        print("使用方法: python add_pinyin_to_words.py <default.yaml> <全拼目录>", file=sys.stderr)
        sys.exit(1)
    
    default_file = sys.argv[1]
    pinyin_dir = sys.argv[2]
    
    if not os.path.exists(default_file):
        print(f"错误: 文件不存在: {default_file}", file=sys.stderr)
        sys.exit(1)
    
    if not os.path.isdir(pinyin_dir):
        print(f"错误: 目录不存在: {pinyin_dir}", file=sys.stderr)
        sys.exit(1)
    
    # 加载拼音映射
    print(f"正在加载 {default_file} 中的拼音映射...")
    pinyin_map = load_pinyin_map(default_file)
    print(f"已加载 {len(pinyin_map)} 个汉字的拼音映射")
    
    # 获取所有 YAML 文件
    yaml_files = glob.glob(os.path.join(pinyin_dir, '*.yaml'))
    yaml_files.sort()
    
    if not yaml_files:
        print(f"错误: 在 {pinyin_dir} 中未找到 YAML 文件", file=sys.stderr)
        sys.exit(1)
    
    print(f"\n找到 {len(yaml_files)} 个文件，开始处理...")
    
    total_processed = 0
    for yaml_file in yaml_files:
        filename = os.path.basename(yaml_file)
        print(f"\n处理: {filename}")
        processed = add_pinyin_to_file(yaml_file, pinyin_map)
        print(f"  处理了 {processed} 个词条")
        total_processed += processed
    
    print(f"\n处理完成！总共处理了 {total_processed} 个词条")
    print(f"所有文件已备份为 .backup 文件")

if __name__ == '__main__':
    main()

