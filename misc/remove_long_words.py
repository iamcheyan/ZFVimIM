#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
从词库文件中移除指定长度以上的词

用法:
    python3 remove_long_words.py <txt_file> [max_length]

参数:
    txt_file: YAML词库文件路径
    max_length: 最大词长度（默认 8，即移除 9 字及以上的词）

示例:
    python3 remove_long_words.py dict/sbzr.userdb.yaml        # 移除 9 字及以上
    python3 remove_long_words.py dict/sbzr.userdb.yaml 5      # 移除 6 字及以上
    python3 remove_long_words.py dict/sbzr.userdb.yaml 6      # 移除 7 字及以上
"""

import sys
import os
import shutil


def remove_long_words(txt_file, max_length=8):
    """
    从词库文件中移除指定长度以上的词
    
    Args:
        txt_file: YAML词库文件路径
        max_length: 最大词长度（默认8，即移除9字及以上的词）
    """
    if not os.path.exists(txt_file):
        print(f'错误: 文件不存在: {txt_file}')
        return False
    
    # 创建备份
    backup_file = txt_file + '.backup'
    print(f'创建备份: {backup_file}')
    shutil.copy2(txt_file, backup_file)
    
    print(f'处理文件: {txt_file}')
    print(f'移除 {max_length + 1} 字及以上的词')
    print('=' * 60)
    
    total_lines = 0
    processed_lines = 0
    removed_count = 0
    lines_modified = 0
    lines_empty_after_removal = 0
    
    new_lines = []
    
    with open(txt_file, 'r', encoding='utf-8') as f:
        for line_num, line in enumerate(f, 1):
            original_line = line
            line = line.rstrip('\n')
            total_lines += 1
            
            # 保留空行和注释
            if not line.strip() or line.startswith('#'):
                new_lines.append(original_line)
                continue
            
            # 处理转义的空格
            if '\\\\ ' in line:
                parts = line.replace('\\\\ ', '_ZFVimIM_space_').split()
                words = [w.replace('_ZFVimIM_space_', ' ') for w in parts[1:]]
            else:
                parts = line.split()
                words = parts[1:]
            
            if len(parts) < 2:
                new_lines.append(original_line)
                continue
            
            key = parts[0]
            processed_lines += 1
            
            # 过滤掉长度超过 max_length 的词
            original_word_count = len(words)
            filtered_words = [w for w in words if len(w) <= max_length]
            removed_in_line = original_word_count - len(filtered_words)
            
            if removed_in_line > 0:
                removed_count += removed_in_line
                lines_modified += 1
                
                # 如果移除后没有词了，保留编码行（空词列表）
                if len(filtered_words) == 0:
                    lines_empty_after_removal += 1
                    # 保留编码，但移除所有词（只保留编码）
                    new_line = key + '\n'
                else:
                    # 重建行，处理转义的空格
                    word_parts = []
                    for word in filtered_words:
                        if ' ' in word:
                            escaped_word = word.replace(' ', '\\\\ ')
                            word_parts.append(escaped_word)
                        else:
                            word_parts.append(word)
                    new_line = key + ' ' + ' '.join(word_parts) + '\n'
                
                new_lines.append(new_line)
            else:
                # 没有需要移除的词，保留原行
                new_lines.append(original_line)
            
            if line_num % 100000 == 0:
                print(f'已处理 {line_num:,} 行，移除 {removed_count:,} 个长词...')
    
    # 写入新文件
    print(f'\n写入修改后的文件...')
    with open(txt_file, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    
    # 输出统计信息
    print('\n' + '=' * 60)
    print('处理完成！')
    print(f'  总行数: {total_lines:,}')
    print(f'  处理行数: {processed_lines:,}')
    print(f'  修改的行数: {lines_modified:,}')
    print(f'  移除的长词数: {removed_count:,}')
    print(f'  移除后变空的行数: {lines_empty_after_removal:,}')
    print(f'  备份文件: {backup_file}')
    print('\n提示: 如果结果满意，可以删除备份文件')
    
    return True


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    
    txt_file = sys.argv[1]
    # 支持第二个参数指定最大长度，默认 8
    max_length = int(sys.argv[2]) if len(sys.argv) > 2 else 8
    success = remove_long_words(txt_file, max_length=max_length)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
