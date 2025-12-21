#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
从词库文件中删除所有单字词（1个字的词）
"""

import sys
import os
import shutil

def remove_single_char_words(txt_file):
    """
    从词库文件中删除所有单字词
    
    Args:
        txt_file: 词库文件路径
    """
    # 创建备份
    backup_file = txt_file + '.backup'
    if not os.path.exists(backup_file):
        print(f'创建备份文件: {backup_file}')
        shutil.copy2(txt_file, backup_file)
    else:
        print(f'备份文件已存在: {backup_file}')
    
    # 读取文件并处理
    print(f'正在读取文件: {txt_file}')
    new_lines = []
    removed_count = 0
    total_lines = 0
    modified_lines = 0
    
    with open(txt_file, 'r', encoding='utf-8') as f:
        for line in f:
            total_lines += 1
            line = line.rstrip('\n')
            
            # 保留空行
            if not line:
                new_lines.append('')
                continue
            
            # 解析行：key word1 word2 ...
            # 处理转义的空格
            parts = []
            current_part = ''
            i = 0
            while i < len(line):
                if line[i] == '\\' and i + 1 < len(line) and line[i + 1] == ' ':
                    current_part += ' '
                    i += 2
                elif line[i] == ' ':
                    if current_part:
                        parts.append(current_part)
                        current_part = ''
                    i += 1
                else:
                    current_part += line[i]
                    i += 1
            if current_part:
                parts.append(current_part)
            
            if len(parts) < 2:
                # 只有编码没有词，保留空行或跳过
                continue
            
            key = parts[0]
            words = parts[1:]
            
            # 过滤掉单字词（长度为1的汉字）
            filtered_words = []
            for word in words:
                # 判断是否是单字（长度为1且是汉字）
                if len(word) == 1 and '\u4e00' <= word <= '\u9fff':
                    removed_count += 1
                else:
                    filtered_words.append(word)
            
            # 如果没有词了，跳过这一行
            if not filtered_words:
                modified_lines += 1
                continue
            
            # 重新构建行
            # 需要转义空格
            escaped_words = []
            for word in filtered_words:
                escaped_word = word.replace(' ', '\\ ')
                escaped_words.append(escaped_word)
            
            new_line = key + ' ' + ' '.join(escaped_words)
            new_lines.append(new_line)
            
            if len(filtered_words) < len(words):
                modified_lines += 1
    
    # 写入新文件
    print(f'正在写入文件: {txt_file}')
    with open(txt_file, 'w', encoding='utf-8') as f:
        for line in new_lines:
            f.write(line + '\n')
    
    # 统计信息
    print(f'\n处理完成！')
    print(f'输出文件: {txt_file}')
    print(f'\n统计信息:')
    print(f'  - 原始文件行数: {total_lines} 行')
    print(f'  - 删除的单字词数: {removed_count} 个')
    print(f'  - 修改的行数: {modified_lines} 行')
    print(f'  - 最终文件行数: {len(new_lines)} 行')
    print(f'  - 备份文件: {backup_file}')

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('用法: python3 remove_single_char_words.py <词库文件>')
        print('示例: python3 remove_single_char_words.py dict/sbzr.userdb.yaml')
        sys.exit(1)
    
    txt_file = sys.argv[1]
    
    if not os.path.isfile(txt_file):
        print(f'错误: 文件不存在: {txt_file}')
        sys.exit(1)
    
    remove_single_char_words(txt_file)

