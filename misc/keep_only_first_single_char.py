#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
对于单字编码，只保留最常用的一个词

单字编码：编码对应的所有词都是单字（长度为1）
对于单字编码，只保留第一个词（最常用的）

用法:
    python3 keep_only_first_single_char.py <yaml_file>

示例:
    python3 keep_only_first_single_char.py dict/sbzr.yaml
"""

import sys
import os


def keep_only_first_single_char(yaml_file):
    """
    对于单字编码，只保留最常用的一个词
    
    Args:
        yaml_file: YAML 文件路径
    
    Returns:
        tuple: (success, stats_dict) - 是否成功，统计信息
    """
    if not os.path.exists(yaml_file):
        print(f'错误: YAML 文件不存在: {yaml_file}', file=sys.stderr)
        return False, {}
    
    print('正在处理单字编码...')
    print('=' * 60)
    
    # 读取并处理文件
    new_lines = []
    total_lines = 0
    processed_lines = 0
    single_char_keys = 0
    removed_words = 0
    
    with open(yaml_file, 'r', encoding='utf-8') as f:
        for line in f:
            total_lines += 1
            original_line = line.rstrip('\n').strip()
            
            # 保留空行和注释
            if not original_line or original_line.startswith('#'):
                new_lines.append(original_line)
                continue
            
            # 处理转义空格
            if '\\ ' in original_line:
                line_tmp = original_line.replace('\\ ', '_ZFVimIM_space_')
                parts = line_tmp.split()
                words = [w.replace('_ZFVimIM_space_', ' ') for w in parts[1:]]
            else:
                parts = original_line.split()
                words = parts[1:]
            
            if len(parts) < 2:
                new_lines.append(original_line)
                continue
            
            key = parts[0]
            processed_lines += 1
            
            # 检查是否所有词都是单字（长度为1）
            all_single_char = True
            for word in words:
                if len(word) != 1:
                    all_single_char = False
                    break
            
            if all_single_char and len(words) > 1:
                # 单字编码，只保留第一个词（最常用的）
                single_char_keys += 1
                removed_words += len(words) - 1
                new_line = key + ' ' + words[0]
                new_lines.append(new_line)
            else:
                # 非单字编码或只有一个词，保持原样
                new_lines.append(original_line)
    
    # 写入处理后的文件
    print('正在写入处理后的文件...')
    with open(yaml_file, 'w', encoding='utf-8') as f:
        for line in new_lines:
            f.write(line + '\n')
    
    print('处理完成！')
    print('=' * 60)
    
    stats = {
        'total_lines': total_lines,
        'processed_lines': processed_lines,
        'single_char_keys': single_char_keys,
        'removed_words': removed_words,
    }
    return True, stats


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    
    yaml_file = sys.argv[1]
    success, stats = keep_only_first_single_char(yaml_file)
    
    if success:
        print(f"统计信息:")
        print(f"  总行数: {stats['total_lines']}")
        print(f"  处理行数: {stats['processed_lines']}")
        print(f"  单字编码数: {stats['single_char_keys']}")
        print(f"  移除词数: {stats['removed_words']}")
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == '__main__':
    main()

