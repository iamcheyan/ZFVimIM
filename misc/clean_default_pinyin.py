#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
根据单字列表清理 default_pinyin.txt，删除不在单字列表中的单字

逻辑：以单字列表为准，删除 default_pinyin.txt 中包含不在单字列表中的单字的所有词

用法:
    python3 clean_default_pinyin.py <single_char_file> <default_pinyin_file>
"""

import sys
import os
import shutil
from datetime import datetime


def load_single_chars(single_char_file):
    """从单字列表中加载所有单字"""
    single_chars = set()
    
    if not os.path.exists(single_char_file):
        print(f'错误: 单字列表文件不存在: {single_char_file}')
        return single_chars
    
    with open(single_char_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            
            # 格式: 编码 字
            parts = line.split()
            if len(parts) >= 2:
                # 第二个部分应该是字
                char = parts[1]
                if len(char) == 1 and '\u4e00' <= char <= '\u9fff':
                    single_chars.add(char)
    
    return single_chars


def contains_missing_char(word, single_chars):
    """检查词中是否包含不在单字列表中的单字"""
    for char in word:
        if '\u4e00' <= char <= '\u9fff':
            if char not in single_chars:
                return True, char
    return False, None


def clean_default_pinyin(single_char_file, default_pinyin_file):
    """清理 default_pinyin.txt 文件"""
    
    # 加载单字列表
    print('正在加载单字列表...')
    single_chars = load_single_chars(single_char_file)
    print(f'单字列表中的单字数: {len(single_chars)}')
    
    if len(single_chars) == 0:
        print('错误: 单字列表为空')
        return False
    
    # 创建备份
    backup_file = default_pinyin_file + '.backup.' + datetime.now().strftime('%Y%m%d_%H%M%S')
    print(f'创建备份文件: {backup_file}')
    shutil.copy2(default_pinyin_file, backup_file)
    
    # 读取并处理 default_pinyin.txt
    print('正在处理 default_pinyin.txt...')
    new_lines = []
    removed_words_count = {}  # 记录被删除的词
    removed_lines_count = 0
    total_lines = 0
    total_words_before = 0
    total_words_after = 0
    
    with open(default_pinyin_file, 'r', encoding='utf-8') as f:
        for line in f:
            total_lines += 1
            line = line.rstrip('\n')
            
            if not line:
                new_lines.append('')
                continue
            
            # 格式: key word1 word2 ...
            # 处理转义空格
            line_tmp = line.replace('\\ ', '_ZFVimIM_space_')
            parts = line_tmp.split()
            
            if len(parts) <= 1:
                # 只有key，没有词，保留
                new_lines.append(line)
                continue
            
            key = parts[0]
            words = parts[1:]
            
            # 过滤词：只保留不包含缺失单字的词
            valid_words = []
            for word_part in words:
                word = word_part.replace('_ZFVimIM_space_', ' ')
                total_words_before += 1
                
                # 检查词中是否包含不在单字列表中的单字
                has_missing, missing_char = contains_missing_char(word, single_chars)
                
                if has_missing:
                    # 记录被删除的词
                    if missing_char not in removed_words_count:
                        removed_words_count[missing_char] = []
                    removed_words_count[missing_char].append(word)
                else:
                    valid_words.append(word_part)
                    total_words_after += 1
            
            # 如果还有有效词，保留这一行
            if valid_words:
                # 重建行（转义空格）
                new_line = key
                for w in valid_words:
                    new_line += ' ' + w
                new_lines.append(new_line)
            else:
                # 这一行的所有词都被删除了
                removed_lines_count += 1
    
    # 写入新文件
    print('正在写入清理后的文件...')
    with open(default_pinyin_file, 'w', encoding='utf-8') as f:
        for line in new_lines:
            f.write(line + '\n')
    
    # 统计信息
    print()
    print('=' * 60)
    print('清理完成！')
    print('=' * 60)
    print(f'总行数: {total_lines}')
    print(f'删除的行数: {removed_lines_count}')
    print(f'保留的行数: {len(new_lines) - removed_lines_count}')
    print(f'总词数（处理前）: {total_words_before}')
    print(f'总词数（处理后）: {total_words_after}')
    print(f'删除的词数: {total_words_before - total_words_after}')
    print()
    
    if removed_words_count:
        print(f'按缺失单字统计（共 {len(removed_words_count)} 个缺失单字）:')
        # 只显示前20个缺失单字
        sorted_missing = sorted(removed_words_count.keys())
        for missing_char in sorted_missing[:20]:
            words = removed_words_count[missing_char]
            print(f'  缺失单字 "{missing_char}": 删除了 {len(words)} 个词')
            # 显示前3个被删除的词作为示例
            if len(words) <= 3:
                print(f'    示例: {", ".join(words)}')
            else:
                print(f'    示例: {", ".join(words[:3])} ... (还有 {len(words) - 3} 个)')
        if len(sorted_missing) > 20:
            print(f'  ... (还有 {len(sorted_missing) - 20} 个缺失单字)')
    
    print()
    print(f'备份文件: {backup_file}')
    print('=' * 60)
    
    return True


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    
    single_char_file = sys.argv[1]
    default_pinyin_file = sys.argv[2]
    
    success = clean_default_pinyin(single_char_file, default_pinyin_file)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()

