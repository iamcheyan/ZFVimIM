#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
删除文件中的编码部分，只保留汉字
"""

import sys
import os
import glob

def remove_codes_from_file(input_file, backup=True):
    """
    删除文件中的编码部分，只保留汉字
    格式：编码\t汉字1\t汉字2\t... -> 汉字1\t汉字2\t...
    """
    # 读取文件
    lines = []
    with open(input_file, 'r', encoding='utf-8') as f:
        for line in f:
            original_line = line
            line = line.rstrip('\n')
            if not line:
                lines.append('')
                continue
            
            # 分割：编码 + 汉字（用制表符分隔）
            parts = line.split('\t')
            if len(parts) < 2:
                # 如果没有制表符，尝试用空格分割
                parts = line.split(' ', 1)
            
            if len(parts) < 2:
                # 只有编码，没有汉字，跳过这一行
                continue
            
            # 只保留汉字部分（去掉第一个元素，即编码）
            words_only = '\t'.join(parts[1:])
            lines.append(words_only)
    
    # 备份原文件
    if backup:
        backup_file = input_file + '.backup'
        with open(backup_file, 'w', encoding='utf-8') as f:
            with open(input_file, 'r', encoding='utf-8') as original:
                f.write(original.read())
    
    # 写入修改后的内容
    with open(input_file, 'w', encoding='utf-8') as f:
        for line in lines:
            f.write(line + '\n')
    
    return len(lines)

def main():
    if len(sys.argv) < 2:
        print("使用方法: python remove_codes_from_files.py <目录路径>", file=sys.stderr)
        sys.exit(1)
    
    target_dir = sys.argv[1]
    
    if not os.path.isdir(target_dir):
        print(f"错误: 目录不存在: {target_dir}", file=sys.stderr)
        sys.exit(1)
    
    # 获取所有YAML文件
    yaml_files = glob.glob(os.path.join(target_dir, '*.yaml'))
    yaml_files.sort()
    
    if not yaml_files:
        print(f"错误: 在 {target_dir} 中未找到 YAML 文件", file=sys.stderr)
        sys.exit(1)
    
    print(f"找到 {len(yaml_files)} 个文件，开始处理...")
    
    total_lines = 0
    for yaml_file in yaml_files:
        filename = os.path.basename(yaml_file)
        print(f"处理: {filename}")
        lines_count = remove_codes_from_file(yaml_file)
        print(f"  保留了 {lines_count} 行")
        total_lines += lines_count
    
    print(f"\n处理完成！总共处理了 {total_lines} 行")
    print(f"原文件已备份为 .backup 文件")

if __name__ == '__main__':
    main()

