#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
将txt文件转换为yaml格式
"""

import sys
import os

def convert_txt_to_yaml(txt_file, yaml_file=None):
    """
    将txt文件转换为yaml格式
    支持两种格式：
    1. 空格分隔：拼音 汉字 -> 拼音\t汉字
    2. 制表符分隔：编码\t词1\t词2 -> 保持原样（已经是yaml格式）
    """
    if yaml_file is None:
        yaml_file = txt_file.replace('.yaml', '.yaml')
    
    lines = []
    with open(txt_file, 'r', encoding='utf-8') as f:
        for line in f:
            original_line = line
            line = line.rstrip('\n')
            
            # 跳过空行和注释行
            if not line or line.strip().startswith('#'):
                lines.append(line)
                continue
            
            # 检查是否包含制表符（已经是yaml格式）
            if '\t' in line:
                # 已经是yaml格式，直接使用
                lines.append(line)
            else:
                # 空格分隔格式，转换为制表符分隔
                # 格式：拼音 汉字 或 编码 词1 词2 ...
                parts = line.split(' ', 1)
                if len(parts) >= 2:
                    # 第一个是编码/拼音，后面是词
                    code = parts[0].strip()
                    words = parts[1].strip()
                    # 转换为制表符分隔
                    new_line = code + '\t' + words
                    lines.append(new_line)
                else:
                    # 只有编码，没有词，保持原样
                    lines.append(line)
    
    # 写入yaml文件
    with open(yaml_file, 'w', encoding='utf-8') as f:
        for line in lines:
            f.write(line + '\n')
    
    print(f"转换完成: {txt_file} -> {yaml_file}")

def main():
    if len(sys.argv) < 2:
        print("使用方法: python convert_txt_to_yaml.py <txt文件> [yaml文件]", file=sys.stderr)
        print("或者: python convert_txt_to_yaml.py <目录>", file=sys.stderr)
        sys.exit(1)
    
    target = sys.argv[1]
    
    if os.path.isfile(target):
        # 单个文件
        if target.endswith('.yaml'):
            yaml_file = sys.argv[2] if len(sys.argv) > 2 else None
            convert_txt_to_yaml(target, yaml_file)
        else:
            print(f"错误: 文件不是.txt格式: {target}", file=sys.stderr)
            sys.exit(1)
    elif os.path.isdir(target):
        # 目录，转换所有txt文件
        import glob
        txt_files = glob.glob(os.path.join(target, '**/*.yaml'), recursive=True)
        if not txt_files:
            print(f"在 {target} 中未找到txt文件", file=sys.stderr)
            sys.exit(1)
        
        print(f"找到 {len(txt_files)} 个txt文件，开始转换...")
        for txt_file in txt_files:
            convert_txt_to_yaml(txt_file)
        print(f"\n转换完成！共转换了 {len(txt_files)} 个文件")
    else:
        print(f"错误: 路径不存在: {target}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()

