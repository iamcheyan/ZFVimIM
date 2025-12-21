#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
过滤单字编码表，删除不常用的汉字
"""

import sys
import os

# 常用汉字集合（基于 GB2312 一级字库 + 常用扩展，约 3500 个常用汉字）
# 这里使用 Unicode 范围和一些特殊判断
def is_common_char(char):
    """
    判断一个汉字是否常用
    标准：使用更严格的范围，主要保留最常用的汉字
    """
    code = ord(char)
    
    # 主要保留 CJK Unified Ideographs 基本区的前半部分
    # 4E00-77FF: 最常用汉字区域（约 10000 个字符）
    if 0x4E00 <= code <= 0x77FF:
        return True
    
    # 7800-8CFF: 次常用汉字区域，也保留
    if 0x7800 <= code <= 0x8CFF:
        return True
    
    # 8D00-9EFF: 较少用但仍在常用范围内，保留
    if 0x8D00 <= code <= 0x9EFF:
        return True
    
    # 9F00-9FFF: 这个范围内的很多字都是生僻字，需要特别判断
    if 0x9F00 <= code <= 0x9FFF:
        # 保留一些相对常用的字
        common_9f_chars = {
            '鼎', '鼓', '鼠', '鼻',  # 相对常用
            '齐', '龄', '龙',  # 相对常用
        }
        if char in common_9f_chars:
            return True
        # 删除明显生僻的字
        rare_9f_chars = {
            '齉', '龊', '龌', '龋', '龌', '龍', '龎', '龏', '龐', '龑',
            '龒', '龓', '龔', '龕', '龖', '龗', '龘', '龚', '龛',
            '龜', '龝', '龞', '龟', '龠', '龡', '龢', '龣', '龤', '龥'
        }
        if char in rare_9f_chars:
            return False
        # 9F40 以后的大部分都是生僻字，删除
        if code >= 0x9F40:
            return False
        # 9F00-9F3F 范围内的其他字保留（相对常用）
        return True
    
    # 9FA6-9FFF: 扩展A区末尾，通常不常用，删除
    # 扩展A区 (3400-4DBF): 包含很多不常用汉字，删除
    # 其他扩展区: 删除
    
    return False

def filter_single_char_codes(input_file, output_file):
    """
    过滤单字编码表，删除不常用的汉字
    """
    common_lines = []
    removed_lines = []
    removed_chars = set()
    
    print(f'正在读取文件: {input_file}')
    with open(input_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            
            # 保留注释行
            if not line or line.startswith('#'):
                common_lines.append(line)
                continue
            
            # 解析：编码 汉字
            parts = line.split()
            if len(parts) < 2:
                common_lines.append(line)
                continue
            
            code = parts[0]
            char = parts[1]
            
            # 判断是否常用
            if is_common_char(char):
                common_lines.append(line)
            else:
                removed_lines.append(line)
                removed_chars.add(char)
    
    # 写入过滤后的文件
    print(f'正在写入文件: {output_file}')
    with open(output_file, 'w', encoding='utf-8') as f:
        # 更新注释
        common_count = len([l for l in common_lines if l and not l.startswith('#')])
        for line in common_lines:
            if line.startswith('#') and '共' in line:
                # 更新统计信息
                f.write(f'# 单字编码表（共 {common_count} 个单字，已过滤不常用汉字）\n')
            else:
                f.write(line + '\n')
    
    # 统计信息
    print(f'\n过滤完成！')
    print(f'输出文件: {output_file}')
    print(f'\n统计信息:')
    print(f'  - 保留的单字: {common_count} 个')
    print(f'  - 删除的单字: {len(removed_chars)} 个')
    print(f'  - 删除的行数: {len(removed_lines)} 行')
    
    if removed_chars:
        print(f'\n删除的不常用汉字示例（前20个）:')
        removed_list = sorted(list(removed_chars))[:20]
        for char in removed_list:
            print(f'    {char} (U+{ord(char):04X})')

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('用法: python3 filter_common_chars.py <输入文件> [输出文件]')
        print('示例: python3 filter_common_chars.py dict/single_char_codes.yaml dict/single_char_codes.yaml')
        sys.exit(1)
    
    input_file = sys.argv[1]
    if len(sys.argv) >= 3:
        output_file = sys.argv[2]
    else:
        # 默认覆盖原文件（先备份）
        output_file = input_file
    
    if not os.path.isfile(input_file):
        print(f'错误: 输入文件不存在: {input_file}')
        sys.exit(1)
    
    # 创建备份
    if output_file == input_file:
        backup_file = input_file + '.backup'
        print(f'创建备份文件: {backup_file}')
        import shutil
        shutil.copy2(input_file, backup_file)
    
    filter_single_char_codes(input_file, output_file)

