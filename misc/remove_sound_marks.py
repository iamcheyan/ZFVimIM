#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
删除编码中的声音标记（;后面的部分）
格式：词条\t编码1;标记1 编码2;标记2 ...\t频率
处理后：词条\t编码1 编码2 ...\t频率
"""

import sys
import os
import re

def remove_sound_marks(input_file, output_file=None):
    """删除编码中的声音标记"""
    if output_file is None:
        output_file = input_file
    
    processed_count = 0
    total_count = 0
    
    print(f"正在处理 {input_file}...")
    
    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    processed_lines = []
    
    for line in lines:
        original_line = line
        line = line.rstrip('\n')
        
        # 空行保留
        if not line.strip():
            processed_lines.append(original_line)
            continue
        
        # 按制表符分割：词条\t编码\t频率
        parts = line.split('\t')
        
        if len(parts) >= 2:
            word = parts[0].strip()
            encoding = parts[1].strip()
            
            # 去掉编码中所有 ; 及其后面的部分
            # 例如：vb;ri bx;xb → vb bx
            if encoding:
                # 分割每个编码，去掉 ; 后面的部分，然后重新组合
                codes = encoding.split()
                cleaned_codes = []
                for code in codes:
                    # 去掉 ; 及其后面的部分
                    cleaned_code = code.split(';')[0]
                    if cleaned_code:
                        cleaned_codes.append(cleaned_code)
                
                # 重建行
                parts[1] = ' '.join(cleaned_codes)
                processed_line = '\t'.join(parts)
                processed_lines.append(processed_line)
                processed_count += 1
            else:
                processed_lines.append(original_line)
        else:
            processed_lines.append(original_line)
        
        total_count += 1
    
    # 写入文件
    with open(output_file, 'w', encoding='utf-8') as f:
        for line in processed_lines:
            f.write(line + '\n')
    
    print(f"\n处理完成！")
    print(f"  总行数: {total_count}")
    print(f"  处理了 {processed_count} 行编码")
    print(f"  输出文件: {output_file}")

def main():
    if len(sys.argv) < 2:
        print("使用方法: python remove_sound_marks.py <输入文件> [输出文件]", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    if not os.path.exists(input_file):
        print(f"错误: 文件不存在: {input_file}", file=sys.stderr)
        sys.exit(1)
    
    remove_sound_marks(input_file, output_file)

if __name__ == '__main__':
    main()

