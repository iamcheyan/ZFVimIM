#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
为单字文件中的每个汉字添加拼音（全拼）
"""

import sys
import os

try:
    from pypinyin import lazy_pinyin, Style
except ImportError:
    print("错误: 需要安装 pypinyin 库", file=sys.stderr)
    print("安装命令: pip3 install --break-system-packages pypinyin", file=sys.stderr)
    sys.exit(1)

def add_pinyin_to_file(input_file, output_file=None):
    """
    为文件中的每个汉字添加拼音
    """
    if output_file is None:
        output_file = input_file
    
    # 临时文件
    temp_file = output_file + '.tmp'
    
    with open(input_file, 'r', encoding='utf-8') as f_in, \
         open(temp_file, 'w', encoding='utf-8') as f_out:
        
        for line in f_in:
            line = line.strip()
            if not line:
                f_out.write('\n')
                continue
            
            # 每行应该只有一个汉字
            char = line
            if char:
                # 获取拼音
                pinyin_list = lazy_pinyin(char, style=Style.NORMAL)
                pinyin = pinyin_list[0] if pinyin_list else ''
                
                # 输出格式：拼音 汉字
                if pinyin:
                    f_out.write(f"{pinyin} {char}\n")
                else:
                    # 如果没有拼音，只输出汉字
                    f_out.write(f"{char}\n")
    
    # 替换原文件
    os.replace(temp_file, output_file)
    print(f"处理完成: {output_file}")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("使用方法: python add_pinyin_to_chars.py <输入文件> [输出文件]", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    if not os.path.exists(input_file):
        print(f"错误: 文件不存在: {input_file}", file=sys.stderr)
        sys.exit(1)
    
    add_pinyin_to_file(input_file, output_file)

