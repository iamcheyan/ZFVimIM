#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
从词库文件中提取单字编码表
格式：编码 字
"""

import sys
import os

def generate_single_char_codes(txt_file, output_file):
    """
    从词库文件中提取单字编码表
    
    Args:
        txt_file: 词库文件路径
        output_file: 输出文件路径
    """
    # 存储单字及其编码：{字: set(编码1, 编码2, ...)}
    single_char_map = {}
    
    # 读取词库文件
    print(f'正在读取词库文件: {txt_file}')
    with open(txt_file, 'r', encoding='utf-8') as f:
        line_count = 0
        for line in f:
            line = line.strip()
            if not line:
                continue
            
            # 解析行：key word1 word2 ...
            parts = line.split()
            if len(parts) < 2:
                continue
            
            key = parts[0]  # 编码
            words = parts[1:]  # 词列表
            
            # 提取单字（长度为1的汉字）
            for word in words:
                # 处理转义的空格
                word = word.replace('\\ ', ' ')
                
                # 只处理单字（长度为1的字符，且是汉字）
                if len(word) == 1 and '\u4e00' <= word <= '\u9fff':
                    if word not in single_char_map:
                        single_char_map[word] = set()
                    single_char_map[word].add(key)
            
            line_count += 1
            if line_count % 100000 == 0:
                print(f'  已处理 {line_count} 行...')
    
    print(f'共处理 {line_count} 行')
    print(f'提取到 {len(single_char_map)} 个单字')
    
    # 转换为列表并排序
    # 格式：[(字, [编码列表]), ...]
    single_char_list = []
    for char, codes in single_char_map.items():
        codes_list = sorted(list(codes))  # 编码按字母顺序排序
        single_char_list.append((char, codes_list))
    
    # 按编码数量从多到少排序，数量相同则按Unicode顺序
    single_char_list.sort(key=lambda x: (-len(x[1]), x[0]))
    
    # 写入输出文件
    print(f'正在写入输出文件: {output_file}')
    with open(output_file, 'w', encoding='utf-8') as f:
        # 写入注释
        f.write('# 单字编码表（共 {} 个单字）\n'.format(len(single_char_list)))
        f.write('# 格式：编码 汉字\n')
        f.write('# 提取自：{}\n'.format(os.path.basename(txt_file)))
        f.write('# 说明：每个编码都是2个字母（双拼）\n')
        f.write('# 排序：按编码数量从多到少，数量相同按Unicode顺序\n')
        f.write('\n')
        
        # 写入数据
        # 格式：编码 字（每个编码一行）
        for char, codes_list in single_char_list:
            for code in codes_list:
                f.write(f'{code} {char}\n')
    
    # 统计信息
    total_codes = sum(len(codes) for _, codes in single_char_list)
    multi_code_chars = sum(1 for _, codes in single_char_list if len(codes) > 1)
    
    print(f'\n生成完成！')
    print(f'输出文件: {output_file}')
    print(f'\n统计信息:')
    print(f'  - 单字数量: {len(single_char_list)} 个')
    print(f'  - 总编码数: {total_codes} 个')
    print(f'  - 有多个编码的单字: {multi_code_chars} 个 ({multi_code_chars/len(single_char_list)*100:.1f}%)')
    print(f'  - 平均每个单字的编码数: {total_codes/len(single_char_list):.2f} 个')
    
    if single_char_list:
        max_codes_char, max_codes = single_char_list[0]
        print(f'  - 最多编码的单字: "{max_codes_char}" ({len(max_codes)} 个编码)')

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('用法: python3 generate_single_char_codes.py <词库文件> [输出文件]')
        print('示例: python3 generate_single_char_codes.py dict/sbzr.userdb.txt dict/single_char_codes.txt')
        sys.exit(1)
    
    txt_file = sys.argv[1]
    if len(sys.argv) >= 3:
        output_file = sys.argv[2]
    else:
        # 默认输出到 dict 目录
        output_dir = os.path.dirname(txt_file) or 'dict'
        output_file = os.path.join(output_dir, 'single_char_codes.txt')
    
    if not os.path.isfile(txt_file):
        print(f'错误: 词库文件不存在: {txt_file}')
        sys.exit(1)
    
    generate_single_char_codes(txt_file, output_file)

