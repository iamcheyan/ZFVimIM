#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
整理词库文件：去重、格式化、去掉不规范条目

用法:
    python3 clean_dict.py <yaml_file>

示例:
    python3 clean_dict.py dict/sbzr.yaml
"""

import sys
import os
import re


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


def clean_dict_file(yaml_file):
    """
    整理词库文件：
    1. 去重（同一个编码下的重复词）
    2. 格式化清理（去除空行、注释等）
    3. 去掉不规范的条目（无效的编码或词）
    4. 按词数从多到少排序
    
    Args:
        yaml_file: YAML 文件路径
    
    Returns:
        tuple: (success, stats_dict) - 是否成功，统计信息
    """
    if not os.path.exists(yaml_file):
        print(f'错误: YAML 文件不存在: {yaml_file}', file=sys.stderr)
        return False, {}
    
    print('正在整理词库文件...')
    print('=' * 60)
    
    # 读取并处理文件
    key_to_words = {}  # key -> set of words (去重)
    total_lines = 0
    processed_lines = 0
    skipped_lines = 0
    invalid_keys = 0
    invalid_words = 0
    duplicate_words = 0
    
    with open(yaml_file, 'r', encoding='utf-8') as f:
        for line in f:
            total_lines += 1
            original_line = line.rstrip('\n').strip()
            
            # 跳过空行和注释
            if not original_line or original_line.startswith('#'):
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
                skipped_lines += 1
                continue
            
            key = parts[0].strip()
            processed_lines += 1
            
            # 检查编码是否规范
            if not is_valid_key(key):
                invalid_keys += 1
                skipped_lines += 1
                continue
            
            # 初始化编码对应的词集合（使用 set 自动去重）
            if key not in key_to_words:
                key_to_words[key] = set()
            
            # 处理词
            for word in words:
                word = word.strip()
                if not word:
                    continue
                
                # 检查词是否规范
                if not is_valid_word(word):
                    invalid_words += 1
                    continue
                
                # 去重：如果词已存在，跳过
                if word in key_to_words[key]:
                    duplicate_words += 1
                    continue
                
                key_to_words[key].add(word)
    
    print(f'读取完成: 总行数 {total_lines}, 处理行数 {processed_lines}')
    print(f'跳过行数: {skipped_lines}')
    print(f'无效编码: {invalid_keys}')
    print(f'无效词: {invalid_words}')
    print(f'重复词: {duplicate_words}')
    print(f'有效编码数: {len(key_to_words)}')
    
    # 统计去重后的词数
    total_words = sum(len(words) for words in key_to_words.values())
    print(f'总词数（去重后）: {total_words}')
    
    # 按词数从多到少排序
    sorted_keys = sorted(key_to_words.items(), key=lambda x: len(x[1]), reverse=True)
    if sorted_keys:
        max_words = len(sorted_keys[0][1])
        print(f'排序完成: 词数最多的编码有 {max_words} 个词')
    
    # 写入整理后的文件
    print('正在写入整理后的文件...')
    with open(yaml_file, 'w', encoding='utf-8') as f:
        for key, words_set in sorted_keys:
            if not words_set:
                continue
            # 将 set 转为列表并排序（保持一致性）
            words_list = sorted(list(words_set))
            # 转义空格
            escaped_words = [w.replace(' ', '\\ ') for w in words_list]
            f.write(f'{key} {" ".join(escaped_words)}\n')
    
    stats = {
        'total_lines': total_lines,
        'processed_lines': processed_lines,
        'skipped_lines': skipped_lines,
        'invalid_keys': invalid_keys,
        'invalid_words': invalid_words,
        'duplicate_words': duplicate_words,
        'valid_keys': len(key_to_words),
        'total_words': total_words,
    }
    
    print(f'✅ 整理完成！')
    print('=' * 60)
    return True, stats


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    
    yaml_file = sys.argv[1]
    
    success, stats = clean_dict_file(yaml_file)
    if success:
        print(f'\n整理统计:')
        print(f'  总行数: {stats["total_lines"]}')
        print(f'  处理行数: {stats["processed_lines"]}')
        print(f'  跳过行数: {stats["skipped_lines"]}')
        print(f'  无效编码: {stats["invalid_keys"]}')
        print(f'  无效词: {stats["invalid_words"]}')
        print(f'  重复词: {stats["duplicate_words"]}')
        print(f'  有效编码数: {stats["valid_keys"]}')
        print(f'  总词数（去重后）: {stats["total_words"]}')
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == '__main__':
    main()

