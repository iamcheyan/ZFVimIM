#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
比较单字列表和主词库，找出缺失的单字

用法:
    python3 compare_single_chars.py <single_char_file> <main_dict_file>
"""

import sys
import os
import re


def extract_single_chars_from_single_file(single_char_file):
    """从单字列表中提取所有单字"""
    single_chars = set()
    
    if not os.path.exists(single_char_file):
        print(f'错误: 单字列表文件不存在: {single_char_file}')
        return single_chars
    
    with open(single_char_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            
            # 格式: 编码 字 或 字 编码
            parts = line.split()
            if len(parts) >= 2:
                # 检查哪个是汉字（Unicode范围 4E00-9FFF）
                for part in parts:
                    if len(part) == 1 and '\u4e00' <= part <= '\u9fff':
                        single_chars.add(part)
                        break
    
    return single_chars


def extract_single_chars_from_main_dict(main_dict_file):
    """从主词库中提取所有单字（长度为1的汉字）"""
    single_chars = set()
    
    if not os.path.exists(main_dict_file):
        print(f'错误: 主词库文件不存在: {main_dict_file}')
        return single_chars
    
    with open(main_dict_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            
            # 格式: key word1 word2 ...
            # 处理转义空格
            line_tmp = line.replace('\\ ', '_ZFVimIM_space_')
            parts = line_tmp.split()
            
            if len(parts) <= 1:
                continue
            
            # 从词中提取单字
            for word_part in parts[1:]:
                # 恢复空格
                word = word_part.replace('_ZFVimIM_space_', ' ')
                # 检查是否是单字（长度为1的汉字）
                if len(word) == 1 and '\u4e00' <= word <= '\u9fff':
                    single_chars.add(word)
    
    return single_chars


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    
    single_char_file = sys.argv[1]
    main_dict_file = sys.argv[2]
    
    print('正在读取单字列表...')
    single_chars_in_list = extract_single_chars_from_single_file(single_char_file)
    print(f'单字列表中的单字数: {len(single_chars_in_list)}')
    
    print('正在读取主词库...')
    single_chars_in_dict = extract_single_chars_from_main_dict(main_dict_file)
    print(f'主词库中的单字数: {len(single_chars_in_dict)}')
    
    # 找出主词库中有但单字列表中没有的单字
    missing_in_list = single_chars_in_dict - single_chars_in_list
    
    # 找出单字列表中有但主词库中没有的单字
    missing_in_dict = single_chars_in_list - single_chars_in_dict
    
    print()
    print('=' * 60)
    print('比较结果:')
    print('=' * 60)
    
    if missing_in_list:
        print(f'\n主词库中有但单字列表中缺失的单字 ({len(missing_in_list)} 个):')
        # 按Unicode排序
        sorted_missing = sorted(missing_in_list)
        # 每行显示20个
        for i in range(0, len(sorted_missing), 20):
            chars_line = ' '.join(sorted_missing[i:i+20])
            print(f'  {chars_line}')
    else:
        print('\n✅ 主词库中的所有单字都在单字列表中')
    
    if missing_in_dict:
        print(f'\n单字列表中有但主词库中没有的单字 ({len(missing_in_dict)} 个):')
        sorted_missing = sorted(missing_in_dict)
        for i in range(0, len(sorted_missing), 20):
            chars_line = ' '.join(sorted_missing[i:i+20])
            print(f'  {chars_line}')
    else:
        print('\n✅ 单字列表中的所有单字都在主词库中')
    
    print()
    print('=' * 60)
    print('统计:')
    print(f'  单字列表中的单字数: {len(single_chars_in_list)}')
    print(f'  主词库中的单字数: {len(single_chars_in_dict)}')
    print(f'  交集（两者都有）: {len(single_chars_in_list & single_chars_in_dict)}')
    if missing_in_list:
        print(f'  缺失的单字数: {len(missing_in_list)}')
    if missing_in_dict:
        print(f'  单字列表中多余的单字数: {len(missing_in_dict)}')


if __name__ == '__main__':
    main()

