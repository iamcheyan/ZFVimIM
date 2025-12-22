#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
从 YAML 文件提取所有去重单字

用法:
    python3 extract_single_chars_from_yaml.py <yaml_file> <output_file>

示例:
    python3 extract_single_chars_from_yaml.py dict/sbzr.yaml dict/sbzr_single_chars.txt
"""

import sys
import os


def extract_single_chars_from_yaml(yaml_file, output_file):
    """
    从 YAML 文件提取所有去重单字

    Args:
        yaml_file: YAML 字典文件路径
        output_file: 输出的文件路径
    """
    if not os.path.exists(yaml_file):
        print(f'错误: YAML 文件不存在: {yaml_file}', file=sys.stderr)
        return False

    try:
        single_chars = set()
        with open(yaml_file, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue

                # Handle escaped spaces: replace \  with placeholder
                line_tmp = line.replace('\\ ', '_ZFVimIM_space_')
                parts = line_tmp.split(' ', 1)  # Split only on the first space to separate key from words

                if len(parts) < 2:  # Only key, no words
                    continue

                words_str = parts[1]
                words = [w.replace('_ZFVimIM_space_', ' ') for w in words_str.split()]

                for word in words:
                    for char in word:
                        if len(char) == 1:  # Single character
                            single_chars.add(char)

        # 转换为排序列表（按 Unicode 码点排序）
        single_chars_list = sorted(single_chars)

        # 确保输出目录存在
        output_dir = os.path.dirname(output_file)
        if output_dir and not os.path.exists(output_dir):
            os.makedirs(output_dir, exist_ok=True)

        # 写入文件
        with open(output_file, 'w', encoding='utf-8') as f:
            for char in single_chars_list:
                f.write(char + '\n')

        print(f'成功提取 {len(single_chars_list)} 个去重单字')
        print(f'输出文件: {output_file}')
        return True

    except Exception as e:
        print(f'错误: 提取单字时出错: {e}', file=sys.stderr)
        return False


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    yaml_file = sys.argv[1]
    output_file = sys.argv[2]

    success = extract_single_chars_from_yaml(yaml_file, output_file)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()

