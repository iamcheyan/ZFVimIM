#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
根据常用单字列表过滤 YAML 文件，删除包含不常用单字的词组

用法:
    python3 filter_yaml_by_single_chars.py <常用单字文件> <输入YAML文件> <输出YAML文件>

示例:
    python3 filter_yaml_by_single_chars.py "dict/个人词库/声笔自然/个人常用单字.txt" "dict/sbxlm.sbzr_backup_20251221_225724.yaml" "dict/sbxlm.sbzr_backup_20251221_225724_filtered.yaml"
"""

import sys
import os


def load_single_chars(single_chars_file):
    """
    加载常用单字列表
    
    Args:
        single_chars_file: 常用单字文件路径（每行一个单字）
    
    Returns:
        set: 常用单字集合
    """
    single_chars = set()
    
    if not os.path.exists(single_chars_file):
        print(f'错误: 常用单字文件不存在: {single_chars_file}', file=sys.stderr)
        return single_chars
    
    try:
        with open(single_chars_file, 'r', encoding='utf-8') as f:
            for line in f:
                char = line.strip()
                if char:
                    single_chars.add(char)
    except Exception as e:
        print(f'错误: 读取常用单字文件时出错: {e}', file=sys.stderr)
    
    return single_chars


def filter_yaml_by_single_chars(single_chars_file, input_yaml_file, output_yaml_file):
    """
    根据常用单字列表过滤 YAML 文件
    
    Args:
        single_chars_file: 常用单字文件路径
        input_yaml_file: 输入 YAML 文件路径
        output_yaml_file: 输出 YAML 文件路径
    """
    # 加载常用单字
    print('正在加载常用单字列表...')
    single_chars = load_single_chars(single_chars_file)
    if not single_chars:
        print('错误: 常用单字列表为空', file=sys.stderr)
        return False
    
    print(f'已加载 {len(single_chars)} 个常用单字')
    
    # 读取并过滤 YAML 文件
    if not os.path.exists(input_yaml_file):
        print(f'错误: 输入 YAML 文件不存在: {input_yaml_file}', file=sys.stderr)
        return False
    
    print('正在过滤 YAML 文件...')
    
    total_lines = 0
    kept_lines = 0
    removed_lines = 0
    total_words = 0
    removed_words = 0
    
    try:
        with open(input_yaml_file, 'r', encoding='utf-8') as f_in, \
             open(output_yaml_file, 'w', encoding='utf-8') as f_out:
            
            for line in f_in:
                line = line.rstrip('\n')
                if not line:
                    f_out.write('\n')
                    continue
                
                total_lines += 1
                
                # 处理转义的空格：将 \ 替换为占位符
                line_tmp = line.replace('\\ ', '_ZFVimIM_space_')
                parts = line_tmp.split()
                
                if len(parts) < 2:
                    # 只有编码，没有词，跳过
                    continue
                
                encoding = parts[0]
                words = parts[1:]
                
                # 过滤词：只保留所有字符都在常用单字列表中的词
                filtered_words = []
                for word_part in words:
                    # 恢复空格
                    word = word_part.replace('_ZFVimIM_space_', ' ')
                    
                    # 检查词中的所有字符是否都在常用单字列表中
                    all_chars_valid = True
                    for char in word:
                        if len(char) == 1 and char not in single_chars:
                            # 单字符不在常用单字列表中
                            all_chars_valid = False
                            break
                        elif len(char) > 1:
                            # 多字节字符（如 emoji），检查每个字符
                            for c in char:
                                if len(c) == 1 and c not in single_chars:
                                    all_chars_valid = False
                                    break
                            if not all_chars_valid:
                                break
                    
                    if all_chars_valid:
                        filtered_words.append(word)
                    else:
                        removed_words += 1
                    
                    total_words += 1
                
                # 如果还有词，写入输出文件
                if filtered_words:
                    # 转义空格
                    escaped_words = [word.replace(' ', '\\ ') for word in filtered_words]
                    output_line = encoding + ' ' + ' '.join(escaped_words)
                    f_out.write(output_line + '\n')
                    kept_lines += 1
                else:
                    removed_lines += 1
        
        print(f'✅ 过滤完成！')
        print(f'   总行数: {total_lines}')
        print(f'   保留行数: {kept_lines}')
        print(f'   删除行数: {removed_lines}')
        print(f'   总词数: {total_words}')
        print(f'   删除词数: {removed_words}')
        print(f'   输出文件: {output_yaml_file}')
        return True
        
    except Exception as e:
        print(f'错误: 处理 YAML 文件时出错: {e}', file=sys.stderr)
        import traceback
        traceback.print_exc()
        return False


def main():
    if len(sys.argv) < 4:
        print(__doc__)
        sys.exit(1)
    
    single_chars_file = sys.argv[1]
    input_yaml_file = sys.argv[2]
    output_yaml_file = sys.argv[3]
    
    success = filter_yaml_by_single_chars(single_chars_file, input_yaml_file, output_yaml_file)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()

