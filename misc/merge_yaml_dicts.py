#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
合并拆分目录下的所有 YAML 词库文件为一个文件
"""

import os
import sys
import re
from collections import defaultdict

def parse_dict_line(line):
    """解析词库行，返回 (编码, 词列表)"""
    line = line.strip()
    if not line or line.startswith('#'):
        return None, None
    
    # 按制表符分割
    parts = line.split('\t')
    if len(parts) < 2:
        # 如果没有制表符，尝试按空格分割
        parts = line.split()
        if len(parts) < 2:
            return None, None
    
    key = parts[0].strip().lower()
    words = [w.strip() for w in parts[1:] if w.strip()]
    
    if not key or not words:
        return None, None
    
    return key, words

def merge_dicts(input_dir, output_file):
    """合并所有字典文件"""
    # 存储合并后的字典 {编码: [词列表]}
    merged_dict = defaultdict(set)
    
    # 获取所有 YAML 文件，按数字排序
    yaml_files = []
    for filename in os.listdir(input_dir):
        if filename.endswith('.yaml') or filename.endswith('.yml'):
            # 提取文件名中的数字用于排序
            match = re.search(r'(\d+)', filename)
            if match:
                num = int(match.group(1))
                yaml_files.append((num, filename))
    
    # 按数字排序
    yaml_files.sort(key=lambda x: x[0])
    
    print(f"找到 {len(yaml_files)} 个文件，开始合并...")
    
    total_lines = 0
    for num, filename in yaml_files:
        filepath = os.path.join(input_dir, filename)
        print(f"处理: {filename} ({num}字)...")
        
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                file_lines = 0
                for line in f:
                    key, words = parse_dict_line(line)
                    if key and words:
                        # 合并相同编码的词
                        merged_dict[key].update(words)
                        file_lines += 1
                print(f"  -> 读取了 {file_lines} 行")
                total_lines += file_lines
        except Exception as e:
            print(f"  -> 错误: {e}")
            continue
    
    print(f"\n总共处理了 {total_lines} 行")
    print(f"合并后共有 {len(merged_dict)} 个唯一编码")
    
    # 统计总词数
    total_words = sum(len(words) for words in merged_dict.values())
    print(f"总词数: {total_words}")
    
    # 写入输出文件
    print(f"\n正在写入: {output_file}...")
    
    # 按编码排序
    sorted_keys = sorted(merged_dict.keys())
    
    # 按词数量从多到少排序（词多的在前面）
    entries = []
    for key in sorted_keys:
        words = list(merged_dict[key])
        entries.append((key, words, len(words)))
    
    # 按词数量排序
    entries.sort(key=lambda x: x[2], reverse=True)
    
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            for key, words, count in entries:
                # 格式: 编码 词1 词2 词3 ...
                line = key + '\t' + '\t'.join(words)
                f.write(line + '\n')
        
        print(f"✓ 成功写入 {len(entries)} 条记录到 {output_file}")
        print(f"  文件大小: {os.path.getsize(output_file) / 1024 / 1024:.2f} MB")
    except Exception as e:
        print(f"✗ 写入失败: {e}")
        return False
    
    return True

if __name__ == '__main__':
    # 默认路径
    script_dir = os.path.dirname(os.path.abspath(__file__))
    plugin_dir = os.path.dirname(script_dir)
    input_dir = os.path.join(plugin_dir, 'dict', '拆分')
    
    # 输出文件
    output_file = os.path.join(plugin_dir, 'dict', 'merged_dict.txt')
    
    # 支持命令行参数
    if len(sys.argv) >= 2:
        input_dir = sys.argv[1]
    if len(sys.argv) >= 3:
        output_file = sys.argv[2]
    
    if not os.path.isdir(input_dir):
        print(f"错误: 输入目录不存在: {input_dir}")
        sys.exit(1)
    
    # 确认输出文件路径
    output_dir = os.path.dirname(output_file)
    if not os.path.isdir(output_dir):
        print(f"错误: 输出目录不存在: {output_dir}")
        sys.exit(1)
    
    print(f"输入目录: {input_dir}")
    print(f"输出文件: {output_file}")
    print()
    
    success = merge_dicts(input_dir, output_file)
    sys.exit(0 if success else 1)

