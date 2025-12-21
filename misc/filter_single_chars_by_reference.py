#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
根据参考文件过滤单字，只保留参考文件中出现的常用汉字

用法:
    python3 filter_single_chars_by_reference.py <参考文件> <目标文件> <输出文件>

示例:
    python3 filter_single_chars_by_reference.py "dict/常用词库（薄荷全拼）/1字（常用汉字单字）.yaml" "dict/个人词库/声笔自然/single_chars.txt" "dict/个人词库/声笔自然/single_chars_filtered.txt"
"""

import sys
import os


def extract_chars_from_yaml(yaml_file):
    """
    从 YAML 文件中提取所有单字
    
    Args:
        yaml_file: YAML 文件路径（格式：编码\t词1\t词2 ...）
    
    Returns:
        set: 单字集合
    """
    chars = set()
    
    if not os.path.exists(yaml_file):
        print(f'错误: 参考文件不存在: {yaml_file}', file=sys.stderr)
        return chars
    
    try:
        with open(yaml_file, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                
                # YAML 格式：编码\t词1\t词2 ...
                parts = line.split('\t')
                if len(parts) < 2:
                    continue
                
                # 跳过编码部分，处理所有词
                for word in parts[1:]:
                    # 提取每个字符
                    for char in word:
                        if len(char) == 1:  # 单字符
                            chars.add(char)
    except Exception as e:
        print(f'错误: 读取参考文件时出错: {e}', file=sys.stderr)
    
    return chars


def filter_single_chars(reference_file, target_file, output_file):
    """
    根据参考文件过滤单字
    
    Args:
        reference_file: 参考 YAML 文件路径
        target_file: 目标单字文件路径
        output_file: 输出文件路径
    """
    # 从参考文件中提取常用汉字
    print('正在读取参考文件...')
    reference_chars = extract_chars_from_yaml(reference_file)
    print(f'参考文件包含 {len(reference_chars)} 个常用汉字')
    
    if not reference_chars:
        print('错误: 参考文件中没有找到常用汉字', file=sys.stderr)
        return False
    
    # 读取目标文件
    if not os.path.exists(target_file):
        print(f'错误: 目标文件不存在: {target_file}', file=sys.stderr)
        return False
    
    print('正在读取目标文件...')
    target_chars = []
    try:
        with open(target_file, 'r', encoding='utf-8') as f:
            for line in f:
                char = line.strip()
                if char:
                    target_chars.append(char)
    except Exception as e:
        print(f'错误: 读取目标文件时出错: {e}', file=sys.stderr)
        return False
    
    print(f'目标文件包含 {len(target_chars)} 个单字')
    
    # 过滤：只保留在参考文件中出现的单字
    filtered_chars = []
    removed_count = 0
    for char in target_chars:
        if char in reference_chars:
            filtered_chars.append(char)
        else:
            removed_count += 1
    
    # 确保输出目录存在
    output_dir = os.path.dirname(output_file)
    if output_dir and not os.path.exists(output_dir):
        os.makedirs(output_dir, exist_ok=True)
    
    # 写入输出文件
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            for char in filtered_chars:
                f.write(char + '\n')
        
        print(f'✅ 过滤完成！')
        print(f'   原始单字数: {len(target_chars)}')
        print(f'   保留单字数: {len(filtered_chars)}')
        print(f'   移除单字数: {removed_count}')
        print(f'   输出文件: {output_file}')
        return True
    except Exception as e:
        print(f'错误: 写入输出文件时出错: {e}', file=sys.stderr)
        return False


def main():
    if len(sys.argv) < 4:
        print(__doc__)
        sys.exit(1)
    
    reference_file = sys.argv[1]
    target_file = sys.argv[2]
    output_file = sys.argv[3]
    
    success = filter_single_chars(reference_file, target_file, output_file)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()

