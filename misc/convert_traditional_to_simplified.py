#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
将字典文件中的繁体字转换为简体字
"""

import sys
import os
import zhconv

def convert_to_simplified(input_file, output_file=None):
    """将文件中的繁体字转换为简体字"""
    if output_file is None:
        output_file = input_file
    
    converted_count = 0
    total_count = 0
    
    print(f"正在处理 {input_file}...")
    
    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    converted_lines = []
    
    for line in lines:
        original_line = line
        line = line.rstrip('\n')
        
        # 空行保留
        if not line.strip():
            converted_lines.append(line)
            continue
        
        # 分割：词条\t编码\t频率
        parts = line.split('\t')
        
        if not parts:
            converted_lines.append(line)
            continue
        
        # 只转换词条部分（第一部分）
        word = parts[0].strip()
        
        if word:
            # 转换为简体
            simplified_word = zhconv.convert(word, 'zh-cn')
            
            # 如果转换后有变化，记录
            if simplified_word != word:
                converted_count += 1
            
            # 重建行
            parts[0] = simplified_word
            converted_line = '\t'.join(parts)
            converted_lines.append(converted_line)
        else:
            converted_lines.append(line)
        
        total_count += 1
    
    # 写入文件
    with open(output_file, 'w', encoding='utf-8') as f:
        for line in converted_lines:
            f.write(line + '\n')
    
    print(f"\n处理完成！")
    print(f"  总词条数: {total_count}")
    print(f"  转换了 {converted_count} 个繁体词条为简体")
    print(f"  输出文件: {output_file}")

def main():
    if len(sys.argv) < 2:
        print("使用方法: python convert_traditional_to_simplified.py <输入文件> [输出文件]", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    if not os.path.exists(input_file):
        print(f"错误: 文件不存在: {input_file}", file=sys.stderr)
        sys.exit(1)
    
    convert_to_simplified(input_file, output_file)

if __name__ == '__main__':
    main()

