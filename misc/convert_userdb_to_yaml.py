#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
将 Rime 用户词典格式转换为标准 YAML 格式

功能：
1. 解析 Rime userdb.txt 格式（编码\t词\tc=计数 d=权重 t=时间戳）
2. 按编码分组，同一编码下的词按频率排序
3. 转换成标准 YAML 格式（编码 词1 词2 ...）
4. 去重、清理不规范条目

用法:
    python3 convert_userdb_to_yaml.py <input_userdb.txt> <output_yaml>

示例:
    python3 convert_userdb_to_yaml.py dict/sbzr.userdb.txt dict/sbzr.yaml
"""

import sys
import os
import re
from collections import defaultdict


def is_valid_key(key):
    """
    检查编码是否规范：
    - 只包含小写字母和数字
    - 长度合理（1-20个字符）
    """
    if not key:
        return False
    # 只允许小写字母、数字
    if not re.match(r'^[a-z0-9]+$', key):
        return False
    # 长度限制
    if len(key) > 20:
        return False
    return True


def is_valid_word(word):
    """
    检查词是否规范：
    - 非空
    - 不包含控制字符
    - 长度合理（1-50个字符）
    """
    if not word or not word.strip():
        return False
    # 检查控制字符（保留制表符、换行符等，但排除其他控制字符）
    if re.search(r'[\x00-\x08\x0b-\x0c\x0e-\x1f\x7f]', word):
        return False
    # 长度限制
    if len(word) > 50:
        return False
    return True


def parse_frequency(metadata):
    """
    从元数据中解析频率（c= 值）
    如果 c=-1 或不存在，返回 0
    """
    if not metadata:
        return 0
    match = re.search(r'c=(-?\d+)', metadata)
    if match:
        freq = int(match.group(1))
        return max(0, freq)  # 负数视为 0
    return 0


def convert_userdb_to_yaml(input_file, output_file):
    """
    将 Rime 用户词典转换为标准 YAML 格式
    
    Args:
        input_file: 输入的 userdb.txt 文件路径
        output_file: 输出的 YAML 文件路径
    
    Returns:
        tuple: (success, stats_dict) - 是否成功，统计信息
    """
    if not os.path.exists(input_file):
        print(f'错误: 输入文件不存在: {input_file}', file=sys.stderr)
        return False, {}
    
    print('正在转换用户词典...')
    print('=' * 60)
    
    # 读取并处理文件
    key_to_words = defaultdict(list)  # key -> list of (word, frequency) tuples
    total_lines = 0
    processed_lines = 0
    skipped_lines = 0
    invalid_keys = 0
    invalid_words = 0
    
    with open(input_file, 'r', encoding='utf-8') as f:
        for line in f:
            total_lines += 1
            line = line.rstrip('\n')
            
            # 跳过注释行和空行
            if not line or line.startswith('#'):
                continue
            
            # 解析格式：编码\t词\tc=计数 d=权重 t=时间戳
            # 使用 \t 分割
            parts = line.split('\t')
            if len(parts) < 2:
                skipped_lines += 1
                continue
            
            key = parts[0].strip()
            word = parts[1].strip()
            metadata = parts[2] if len(parts) > 2 else ''
            
            processed_lines += 1
            
            # 检查编码是否规范
            if not is_valid_key(key):
                invalid_keys += 1
                continue
            
            # 检查词是否规范
            if not is_valid_word(word):
                invalid_words += 1
                continue
            
            # 解析频率
            frequency = parse_frequency(metadata)
            
            # 添加到字典（去重：如果词已存在，保留频率更高的）
            word_exists = False
            for i, (existing_word, existing_freq) in enumerate(key_to_words[key]):
                if existing_word == word:
                    # 如果新频率更高，更新
                    if frequency > existing_freq:
                        key_to_words[key][i] = (word, frequency)
                    word_exists = True
                    break
            
            if not word_exists:
                key_to_words[key].append((word, frequency))
    
    print(f'读取完成: 总行数 {total_lines}, 处理行数 {processed_lines}')
    print(f'跳过行数: {skipped_lines}')
    print(f'无效编码数: {invalid_keys}')
    print(f'无效词数: {invalid_words}')
    print(f'发现 {len(key_to_words)} 个编码')
    
    # 按频率排序每个编码下的词（频率高的在前）
    for key in key_to_words:
        key_to_words[key].sort(key=lambda x: x[1], reverse=True)
    
    # 统计总词数
    total_words = sum(len(words) for words in key_to_words.values())
    print(f'总词数（去重后）: {total_words}')
    
    # 按词数从多到少排序编码
    sorted_keys = sorted(key_to_words.items(), key=lambda x: len(x[1]), reverse=True)
    
    # 写入 YAML 文件
    print('正在写入 YAML 文件...')
    with open(output_file, 'w', encoding='utf-8') as f:
        for key, word_freq_list in sorted_keys:
            # 只取词，不取频率
            words = [word for word, freq in word_freq_list]
            # 转义空格
            escaped_words = [w.replace(' ', '\\ ') for w in words]
            # 格式：编码 词1 词2 词3 ...
            f.write(f'{key} {" ".join(escaped_words)}\n')
    
    print('转换完成！')
    print('=' * 60)
    
    stats = {
        'total_lines': total_lines,
        'processed_lines': processed_lines,
        'skipped_lines': skipped_lines,
        'invalid_keys': invalid_keys,
        'invalid_words': invalid_words,
        'total_keys': len(key_to_words),
        'total_words': total_words,
    }
    return True, stats


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    success, stats = convert_userdb_to_yaml(input_file, output_file)
    
    if success:
        print(f"统计信息:")
        print(f"  总行数: {stats['total_lines']}")
        print(f"  处理行数: {stats['processed_lines']}")
        print(f"  跳过行数: {stats['skipped_lines']}")
        print(f"  无效编码数: {stats['invalid_keys']}")
        print(f"  无效词数: {stats['invalid_words']}")
        print(f"  有效编码数: {stats['total_keys']}")
        print(f"  总词数（去重后）: {stats['total_words']}")
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == '__main__':
    main()

