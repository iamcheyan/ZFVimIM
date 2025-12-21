#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
根据 default.yaml 中的单字过滤常用词库
删除包含不在 default.yaml 中的汉字的词条
"""

import sys
import os
import glob
import shutil

def load_chars_from_default(default_file):
    """
    从 default.yaml 中加载所有单字
    格式：拼音 汉字1 汉字2 汉字3 ...
    """
    chars = set()
    with open(default_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            
            # 格式：拼音 汉字1 汉字2 ...
            parts = line.split()
            if len(parts) >= 2:
                # 从第二个部分开始都是汉字
                for word in parts[1:]:
                    # 提取所有汉字字符
                    for char in word:
                        if '\u4e00' <= char <= '\u9fff':
                            chars.add(char)
    
    return chars

def contains_invalid_char(word, valid_chars):
    """
    检查词条是否包含不在有效字符集合中的汉字
    """
    for char in word:
        if '\u4e00' <= char <= '\u9fff':
            if char not in valid_chars:
                return True
    return False

def filter_file(input_file, valid_chars, backup=True):
    """
    过滤文件，删除包含无效汉字的词条
    """
    lines = []
    removed_count = 0
    
    with open(input_file, 'r', encoding='utf-8') as f:
        for line in f:
            original_line = line
            line = line.strip()
            if not line:
                lines.append('')
                continue
            
            # 分割词条（用制表符分隔）
            parts = line.split('\t')
            if len(parts) < 2:
                # 只有编码，没有词，保留
                lines.append(line)
                continue
            
            # 检查所有词
            has_invalid = False
            for word in parts[1:]:
                if contains_invalid_char(word, valid_chars):
                    has_invalid = True
                    break
            
            if has_invalid:
                removed_count += 1
                continue  # 跳过这一行
            
            # 保留这一行
            lines.append(line)
    
    # 备份原文件
    if backup and removed_count > 0:
        backup_file = input_file + '.backup'
        shutil.copyfile(input_file, backup_file)
        print(f"  已备份到: {backup_file}")
    
    # 写入过滤后的内容
    if removed_count > 0:
        with open(input_file, 'w', encoding='utf-8') as f:
            for line in lines:
                f.write(line + '\n')
    
    return removed_count

def main():
    if len(sys.argv) < 3:
        print("使用方法: python filter_common_dict_by_default.py <default.yaml> <常用词库目录>", file=sys.stderr)
        sys.exit(1)
    
    default_file = sys.argv[1]
    common_dict_dir = sys.argv[2]
    
    if not os.path.exists(default_file):
        print(f"错误: 文件不存在: {default_file}", file=sys.stderr)
        sys.exit(1)
    
    if not os.path.isdir(common_dict_dir):
        print(f"错误: 目录不存在: {common_dict_dir}", file=sys.stderr)
        sys.exit(1)
    
    # 加载 default.yaml 中的所有单字
    print(f"正在加载 {default_file} 中的单字...")
    valid_chars = load_chars_from_default(default_file)
    print(f"已加载 {len(valid_chars)} 个有效单字")
    
    # 获取所有 YAML 文件（包括全拼和双拼）
    yaml_files = []
    for subdir in ['全拼', '双拼']:
        subdir_path = os.path.join(common_dict_dir, subdir)
        if os.path.isdir(subdir_path):
            yaml_files.extend(glob.glob(os.path.join(subdir_path, '*.yaml')))
    
    yaml_files.sort()
    
    if not yaml_files:
        print(f"错误: 在 {common_dict_dir} 中未找到 YAML 文件", file=sys.stderr)
        sys.exit(1)
    
    print(f"\n找到 {len(yaml_files)} 个文件，开始处理...")
    
    total_removed = 0
    for yaml_file in yaml_files:
        filename = os.path.basename(yaml_file)
        subdir = os.path.basename(os.path.dirname(yaml_file))
        print(f"\n处理: {subdir}/{filename}")
        removed = filter_file(yaml_file, valid_chars)
        if removed > 0:
            print(f"  删除了 {removed} 个词条")
            total_removed += removed
        else:
            print(f"  无需删除")
    
    print(f"\n处理完成！总共删除了 {total_removed} 个词条")
    print(f"所有文件已备份为 .backup 文件")

if __name__ == '__main__':
    main()

