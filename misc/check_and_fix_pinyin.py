#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
检查并修正 default_pinyin.txt 中的拼音错误

功能：
1. 检查拼音拼写是否正确
2. 修正明显的拼写错误
3. 可选：转换为双拼格式（2个字母）
"""
import sys
import os
import re
import shutil
from datetime import datetime

# 常见拼音错误映射
COMMON_PINYIN_ERRORS = {
    # 这里可以添加常见的拼写错误映射
    # '错误拼音': '正确拼音',
}

# 有效的拼音声母
VALID_INITIALS = set([
    'b', 'p', 'm', 'f', 'd', 't', 'n', 'l', 'g', 'k', 'h',
    'j', 'q', 'x', 'zh', 'ch', 'sh', 'r', 'z', 'c', 's',
    'y', 'w'
])

# 有效的拼音韵母（常见）
VALID_FINALS = set([
    'a', 'o', 'e', 'i', 'u', 'v', 'ü',
    'ai', 'ei', 'ao', 'ou', 'an', 'en', 'ang', 'eng', 'ong',
    'ia', 'iao', 'ian', 'iang', 'ie', 'in', 'ing', 'iong', 'iu',
    'ua', 'uai', 'uan', 'uang', 'ue', 'ui', 'un', 'uo',
    've', 'van', 'vn'
])

def is_valid_pinyin(pinyin):
    """
    检查拼音是否有效（基本检查）
    """
    if not pinyin or len(pinyin) < 1:
        return False
    
    # 移除声调标记
    pinyin = re.sub(r'[1-5]', '', pinyin)
    
    # 检查是否只包含字母
    if not pinyin.isalpha():
        return False
    
    # 基本格式检查（可以更严格）
    return True

def check_pinyin_file(txt_file):
    """
    检查拼音文件中的错误
    """
    if not os.path.exists(txt_file):
        print(f'错误: 文件不存在: {txt_file}')
        return False
    
    print('正在检查拼音文件...')
    print('=' * 60)
    
    errors = []
    warnings = []
    line_num = 0
    total_lines = 0
    total_keys = 0
    
    with open(txt_file, 'r', encoding='utf-8') as f:
        for line in f:
            line_num += 1
            original_line = line.rstrip('\n')
            line = original_line.strip()
            
            # 跳过空行和注释
            if not line or line.startswith('#'):
                continue
            
            total_lines += 1
            
            # 解析行：key word1 word2 ...
            if '\\ ' in line:
                parts = line.replace('\\ ', '_ZFVimIM_space_').split()
                words = [w.replace('_ZFVimIM_space_', ' ') for w in parts[1:]]
            else:
                parts = line.split()
                words = parts[1:]
            
            if len(parts) < 2:
                warnings.append({
                    'line': line_num,
                    'content': line[:50],
                    'issue': '只有编码没有词'
                })
                continue
            
            key = parts[0]
            total_keys += 1
            
            # 检查编码格式
            if len(key) != 2:
                # 不是双拼格式，记录为警告
                warnings.append({
                    'line': line_num,
                    'key': key,
                    'words': words[:2] if words else [],
                    'issue': f'编码长度不是2（当前是{len(key)}），可能是全拼格式',
                    'original': original_line[:80]
                })
            
            # 检查是否包含无效字符
            if not key.isalpha():
                errors.append({
                    'line': line_num,
                    'key': key,
                    'words': words[:2] if words else [],
                    'error': f'编码包含非字母字符: "{key}"',
                    'original': original_line[:80]
                })
            elif not key.islower():
                errors.append({
                    'line': line_num,
                    'key': key,
                    'words': words[:2] if words else [],
                    'error': f'编码包含大写字母: "{key}"',
                    'original': original_line[:80]
                })
            
            # 检查拼音拼写（基本检查）
            if not is_valid_pinyin(key):
                errors.append({
                    'line': line_num,
                    'key': key,
                    'words': words[:2] if words else [],
                    'error': f'编码格式可能不正确: "{key}"',
                    'original': original_line[:80]
                })
    
    print(f'统计信息:')
    print(f'  总行数: {total_lines}')
    print(f'  总编码数: {total_keys}')
    print(f'  发现错误: {len(errors)} 个')
    print(f'  发现警告: {len(warnings)} 个')
    print()
    
    if errors:
        print(f'错误列表（前20个）:')
        print('=' * 60)
        for i, err in enumerate(errors[:20], 1):
            words_str = ' '.join(err['words'][:2])
            if len(err['words']) > 2:
                words_str += ' ...'
            print(f'{i}. 第 {err["line"]} 行: {err["key"]} -> {words_str}')
            print(f'   错误: {err["error"]}')
            print(f'   原文: {err["original"]}')
            print()
        
        if len(errors) > 20:
            print(f'... 还有 {len(errors) - 20} 个错误未显示')
    
    if warnings:
        print(f'\n警告列表（前20个）:')
        print('=' * 60)
        for i, warn in enumerate(warnings[:20], 1):
            if 'key' in warn:
                words_str = ' '.join(warn['words'][:2])
                if len(warn['words']) > 2:
                    words_str += ' ...'
                print(f'{i}. 第 {warn["line"]} 行: {warn["key"]} -> {words_str}')
                print(f'   警告: {warn["issue"]}')
            else:
                print(f'{i}. 第 {warn["line"]} 行: {warn["issue"]}')
                print(f'   内容: {warn["content"]}')
            print()
        
        if len(warnings) > 20:
            print(f'... 还有 {len(warnings) - 20} 个警告未显示')
    
    if not errors and not warnings:
        print('✅ 未发现错误或警告')
    
    return len(errors) == 0

def fix_pinyin_file(txt_file, convert_to_shuangpin=False):
    """
    修正拼音文件中的错误
    """
    if not os.path.exists(txt_file):
        print(f'错误: 文件不存在: {txt_file}')
        return False
    
    print('正在修正拼音文件...')
    print('=' * 60)
    
    # 创建备份
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_file = f'{txt_file}.backup.{timestamp}'
    shutil.copy(txt_file, backup_file)
    print(f'创建备份文件: {backup_file}')
    
    fixed_lines = []
    fixed_count = 0
    line_num = 0
    
    with open(txt_file, 'r', encoding='utf-8') as f:
        for line in f:
            line_num += 1
            original_line = line.rstrip('\n')
            line = original_line.strip()
            
            # 保留空行和注释
            if not line or line.startswith('#'):
                fixed_lines.append(original_line)
                continue
            
            # 解析行
            if '\\ ' in line:
                parts = line.replace('\\ ', '_ZFVimIM_space_').split()
                words = [w.replace('_ZFVimIM_space_', ' ') for w in parts[1:]]
            else:
                parts = line.split()
                words = parts[1:]
            
            if len(parts) < 2:
                fixed_lines.append(original_line)
                continue
            
            key = parts[0]
            fixed_key = key
            
            # 修正常见错误
            if key in COMMON_PINYIN_ERRORS:
                fixed_key = COMMON_PINYIN_ERRORS[key]
                fixed_count += 1
                print(f'第 {line_num} 行: 修正 "{key}" -> "{fixed_key}"')
            
            # 转换为小写
            if fixed_key != fixed_key.lower():
                fixed_key = fixed_key.lower()
                if fixed_key != key:
                    fixed_count += 1
                    print(f'第 {line_num} 行: 转换为小写 "{key}" -> "{fixed_key}"')
            
            # 如果转换为双拼（需要实现转换逻辑）
            if convert_to_shuangpin and len(fixed_key) != 2:
                # TODO: 实现全拼到双拼的转换
                pass
            
            # 重建行
            if fixed_key != key:
                escaped_words = [w.replace(' ', '\\ ') for w in words]
                fixed_line = f'{fixed_key} {" ".join(escaped_words)}'
                fixed_lines.append(fixed_line)
            else:
                fixed_lines.append(original_line)
    
    # 写入修正后的文件
    with open(txt_file, 'w', encoding='utf-8') as f:
        for line in fixed_lines:
            f.write(line + '\n')
    
    print(f'\n修正完成！')
    print(f'修正了 {fixed_count} 处')
    print(f'备份文件: {backup_file}')
    print('=' * 60)
    
    return True

def main():
    if len(sys.argv) < 2:
        print('用法: python3 check_and_fix_pinyin.py <txt_file> [--fix] [--convert]')
        print('  --fix: 修正错误')
        print('  --convert: 转换为双拼格式（需要实现转换逻辑）')
        sys.exit(1)
    
    txt_file = sys.argv[1]
    do_fix = '--fix' in sys.argv
    convert_to_shuangpin = '--convert' in sys.argv
    
    # 先检查
    has_errors = not check_pinyin_file(txt_file)
    
    if do_fix:
        print()
        fix_pinyin_file(txt_file, convert_to_shuangpin)
    elif has_errors:
        print()
        print('提示: 使用 --fix 参数可以自动修正错误')
    
    sys.exit(0 if not has_errors else 1)

if __name__ == '__main__':
    main()

