#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
将代码中的.txt引用替换为.yaml
"""

import sys
import os
import re
import glob

def replace_in_file(file_path):
    """
    在文件中替换.txt为.yaml
    """
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # 替换规则
    replacements = [
        # 文件扩展名检查
        (r'\.yaml\$', r'.yaml$'),
        (r'\.yaml\b', r'.yaml'),
        
        # 默认文件名
        (r'default\.yaml', r'default.yaml'),
        
        # 注释中的说明
        (r'Default dictionary is default\.yaml', r'Default dictionary is default.yaml'),
        (r'Default dictionary: default\.yaml', r'Default dictionary: default.yaml'),
        (r'YAML dictionary', r'YAML dictionary'),
        (r'YAML 文件', r'YAML 文件'),
        (r'YAML词库', r'YAML词库'),
        (r'\.yaml file', r'.yaml file'),
        (r'\.yaml files', r'.yaml files'),
        (r'\.yaml format', r'.yaml format'),
        
        # 变量名和路径（保留变量名，只改扩展名）
        (r'yamlPath', r'yamlPath'),  # 但要注意有些地方可能需要保留yamlPath变量名
        
        # 函数和脚本中的引用
        (r'\.yaml to \.db', r'.yaml to .db'),
        (r'convert \.yaml', r'convert .yaml'),
        (r'\.yaml extension', r'.yaml extension'),
        
        # 文件操作
        (r'BufWritePost \*\.yaml', r'BufWritePost *.yaml'),
    ]
    
    for pattern, replacement in replacements:
        content = re.sub(pattern, replacement, content)
    
    # 特殊处理：有些地方需要保留.yaml（如word_freq.txt等非词库文件）
    # 恢复非词库文件的.txt引用
    content = re.sub(r'word_freq\.yaml', r'word_freq.txt', content)
    content = re.sub(r'ZFVimIM_word_freq\.yaml', r'ZFVimIM_word_freq.txt', content)
    
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def main():
    if len(sys.argv) < 2:
        print("使用方法: python replace_txt_with_yaml.py <文件或目录>", file=sys.stderr)
        sys.exit(1)
    
    target = sys.argv[1]
    
    files_to_process = []
    
    if os.path.isfile(target):
        files_to_process = [target]
    elif os.path.isdir(target):
        # 处理.vim和.py文件
        files_to_process = (
            glob.glob(os.path.join(target, '**/*.vim'), recursive=True) +
            glob.glob(os.path.join(target, '**/*.py'), recursive=True)
        )
    else:
        print(f"错误: 路径不存在: {target}", file=sys.stderr)
        sys.exit(1)
    
    if not files_to_process:
        print(f"在 {target} 中未找到.vim或.py文件", file=sys.stderr)
        sys.exit(1)
    
    print(f"找到 {len(files_to_process)} 个文件，开始处理...")
    
    modified_count = 0
    for file_path in files_to_process:
        if replace_in_file(file_path):
            print(f"修改: {file_path}")
            modified_count += 1
    
    print(f"\n处理完成！共修改了 {modified_count} 个文件")

if __name__ == '__main__':
    main()

