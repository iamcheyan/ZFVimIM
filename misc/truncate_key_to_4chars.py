#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
将编码截取为前4位，并合并相同前4位编码下的所有词

用法:
    python3 truncate_key_to_4chars.py <input_yaml> <output_yaml>

示例:
    python3 truncate_key_to_4chars.py dict/sbzr.userdb.yaml dict/sbzr.userdb.yaml
"""

import sys
import os
from collections import defaultdict


def truncate_key_to_4chars(input_file, output_file):
    """
    将编码截取为前4位，并合并相同前4位编码下的所有词
    
    Args:
        input_file: 输入的 YAML 文件路径
        output_file: 输出的 YAML 文件路径
    
    Returns:
        tuple: (success, stats_dict) - 是否成功，统计信息
    """
    if not os.path.exists(input_file):
        print(f'错误: 输入文件不存在: {input_file}', file=sys.stderr)
        return False, {}
    
    print('正在处理编码截取...')
    print('=' * 60)
    
    # 读取并处理文件
    key_to_words = defaultdict(set)  # key -> set of words (去重)
    total_lines = 0
    processed_lines = 0
    
    with open(input_file, 'r', encoding='utf-8') as f:
        for line in f:
            total_lines += 1
            line = line.rstrip('\n').strip()
            
            # 跳过空行和注释
            if not line or line.startswith('#'):
                continue
            
            # 处理转义空格
            if '\\ ' in line:
                line_tmp = line.replace('\\ ', '_ZFVimIM_space_')
                parts = line_tmp.split()
                words = [w.replace('_ZFVimIM_space_', ' ') for w in parts[1:]]
            else:
                parts = line.split()
                words = parts[1:]
            
            if len(parts) < 2:
                continue
            
            original_key = parts[0]
            processed_lines += 1
            
            # 截取前4位
            if len(original_key) >= 4:
                truncated_key = original_key[:4]
            else:
                truncated_key = original_key
            
            # 添加词到集合（自动去重）
            for word in words:
                word = word.strip()
                if word:
                    key_to_words[truncated_key].add(word)
    
    print(f'读取完成: 总行数 {total_lines}, 处理行数 {processed_lines}')
    print(f'原始编码数: {processed_lines}')
    print(f'截取后编码数: {len(key_to_words)}')
    
    # 统计总词数
    total_words = sum(len(words) for words in key_to_words.values())
    print(f'总词数（去重后）: {total_words}')
    
    # 将 set 转换为 list，并按词数从多到少排序编码
    key_to_words_list = {}
    for key, words_set in key_to_words.items():
        # 转换为列表（保持顺序，但为了稳定性可以排序）
        key_to_words_list[key] = sorted(list(words_set))
    
    # 按词数从多到少排序编码
    sorted_keys = sorted(key_to_words_list.items(), key=lambda x: len(x[1]), reverse=True)
    
    # 写入文件
    print('正在写入文件...')
    with open(output_file, 'w', encoding='utf-8') as f:
        for key, words in sorted_keys:
            if not words:
                continue
            # 转义空格
            escaped_words = [w.replace(' ', '\\ ') for w in words]
            # 格式：编码 词1 词2 词3 ...
            f.write(f'{key} {" ".join(escaped_words)}\n')
    
    print('处理完成！')
    print('=' * 60)
    
    stats = {
        'total_lines': total_lines,
        'processed_lines': processed_lines,
        'original_keys': processed_lines,
        'truncated_keys': len(key_to_words),
        'total_words': total_words,
    }
    return True, stats


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    success, stats = truncate_key_to_4chars(input_file, output_file)
    
    if success:
        print(f"统计信息:")
        print(f"  总行数: {stats['total_lines']}")
        print(f"  处理行数: {stats['processed_lines']}")
        print(f"  原始编码数: {stats['original_keys']}")
        print(f"  截取后编码数: {stats['truncated_keys']}")
        print(f"  总词数（去重后）: {stats['total_words']}")
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == '__main__':
    main()

