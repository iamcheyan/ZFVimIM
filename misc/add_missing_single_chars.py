#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
检查并补充缺失的单字
从1字.yaml中提取单字，检查sbxlm.sbzr.yaml中是否缺失，缺失的补充到文件末尾的=========================后面
"""

import sys
import os
from pypinyin import lazy_pinyin, Style

# 自然码双拼映射表
INITIAL_MAP = {
    'zh': 'v',
    'ch': 'i',
    'sh': 'u',
}

FINAL_MAP = {
    'a': 'a', 'o': 'o', 'e': 'e', 'i': 'i', 'u': 'u', 'v': 'v', 'ü': 'v',
    'ai': 'l', 'ei': 'z', 'ao': 'k', 'ou': 'b',
    'an': 'j', 'en': 'f', 'ang': 'h', 'eng': 'g', 'ong': 's', 'iong': 's',
    'ia': 'w', 'iao': 'c', 'ian': 'r', 'iang': 'd', 'ie': 'x', 'iu': 'q',
    'in': 'n', 'ing': 'y',
    'ua': 'w', 'uai': 'y', 'uan': 'r', 'uang': 'd', 'ue': 't', 've': 't',
    'ui': 'v', 'un': 'p', 'uo': 'o',
    'er': 'r', 'van': 'r',
}

def split_pinyin(pinyin):
    """将拼音分割为声母和韵母"""
    if pinyin.startswith('zh'):
        return 'zh', pinyin[2:]
    elif pinyin.startswith('ch'):
        return 'ch', pinyin[2:]
    elif pinyin.startswith('sh'):
        return 'sh', pinyin[2:]
    elif pinyin.startswith('z'):
        return 'z', pinyin[1:]
    elif pinyin.startswith('c'):
        return 'c', pinyin[1:]
    elif pinyin.startswith('s'):
        return 's', pinyin[1:]
    elif pinyin.startswith('r'):
        return 'r', pinyin[1:]
    elif pinyin.startswith('y'):
        if pinyin.startswith('yu'):
            return '', 'v' + pinyin[2:]
        elif pinyin.startswith('yi'):
            return '', 'i' + pinyin[2:]
        elif pinyin.startswith('ya'):
            return '', 'ia' + pinyin[2:]
        elif pinyin.startswith('yao'):
            return '', 'iao' + pinyin[3:]
        elif pinyin.startswith('yan'):
            return '', 'ian' + pinyin[3:]
        elif pinyin.startswith('yang'):
            return '', 'iang' + pinyin[4:]
        elif pinyin.startswith('ye'):
            return '', 'ie' + pinyin[2:]
        elif pinyin.startswith('you'):
            return '', 'iu' + pinyin[3:]
        elif pinyin.startswith('yin'):
            return '', 'in' + pinyin[3:]
        elif pinyin.startswith('ying'):
            return '', 'ing' + pinyin[4:]
        elif pinyin.startswith('yong'):
            return '', 'iong' + pinyin[4:]
        else:
            return '', pinyin[1:]
    elif pinyin.startswith('w'):
        if pinyin.startswith('wu'):
            return '', 'u' + pinyin[2:]
        elif pinyin.startswith('wa'):
            return '', 'ua' + pinyin[2:]
        elif pinyin.startswith('wai'):
            return '', 'uai' + pinyin[3:]
        elif pinyin.startswith('wan'):
            return '', 'uan' + pinyin[3:]
        elif pinyin.startswith('wang'):
            return '', 'uang' + pinyin[4:]
        elif pinyin.startswith('wei'):
            return '', 'ui' + pinyin[3:]
        elif pinyin.startswith('wen'):
            return '', 'un' + pinyin[3:]
        elif pinyin.startswith('weng'):
            return '', 'ueng' + pinyin[4:]
        elif pinyin.startswith('wo'):
            return '', 'uo' + pinyin[2:]
        else:
            return '', pinyin[1:]
    else:
        if len(pinyin) > 0 and pinyin[0] in 'bpmfdtnlgkhjqx':
            return pinyin[0], pinyin[1:]
        else:
            return '', pinyin

def pinyin_to_shuangpin(pinyin):
    """将拼音转换为双拼编码"""
    if not pinyin or len(pinyin) == 0:
        return ''
    
    if len(pinyin) == 1:
        return pinyin
    
    initial, final = split_pinyin(pinyin)
    
    if not final:
        return initial if initial else pinyin
    
    # 韵母映射（从长到短检查）
    final_code = None
    for final_key in sorted(FINAL_MAP.keys(), key=len, reverse=True):
        if final.startswith(final_key):
            final_code = FINAL_MAP[final_key]
            break
    
    if final_code is None:
        final_code = final[0] if final else ''
    
    # 声母映射
    if initial:
        initial_code = INITIAL_MAP.get(initial, initial[0])
    else:
        initial_code = ''
    
    result = initial_code + final_code
    return result if result else pinyin

def load_single_chars_from_1char(single_char_file):
    """从1字.yaml中加载所有单字和编码"""
    print(f"正在加载单字文件 {single_char_file}...")
    char_to_pinyin = {}  # 单字 -> 全拼编码
    
    with open(single_char_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            
            # 格式：编码\t单字
            parts = line.split('\t')
            if len(parts) >= 2:
                pinyin = parts[0].strip()
                char = parts[1].strip()
                if char and len(char) == 1:
                    # 如果同一个字有多个编码，保留第一个
                    if char not in char_to_pinyin:
                        char_to_pinyin[char] = pinyin
    
    print(f"  已加载 {len(char_to_pinyin)} 个单字")
    return char_to_pinyin

def load_existing_chars(input_file):
    """从输入文件中加载所有已存在的单字"""
    print(f"正在检查 {input_file} 中的单字...")
    existing_chars = set()
    
    with open(input_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('='):
                continue
            
            # 格式：编码\t词组1\t词组2\t...
            parts = line.split('\t')
            if len(parts) >= 2:
                for word in parts[1:]:
                    word = word.strip()
                    # 只检查单字
                    if word and len(word) == 1 and '\u4e00' <= word <= '\u9fff':
                        existing_chars.add(word)
    
    print(f"  已存在 {len(existing_chars)} 个单字")
    return existing_chars

def add_missing_chars(single_char_file, input_file):
    """检查并补充缺失的单字"""
    # 加载单字和编码
    char_to_pinyin = load_single_chars_from_1char(single_char_file)
    
    # 加载已存在的单字
    existing_chars = load_existing_chars(input_file)
    
    # 找出缺失的单字
    missing_chars = []
    for char, pinyin in char_to_pinyin.items():
        if char not in existing_chars:
            # 将全拼转换为双拼
            shuangpin = pinyin_to_shuangpin(pinyin)
            missing_chars.append((shuangpin, char))
    
    print(f"\n发现 {len(missing_chars)} 个缺失的单字")
    
    if not missing_chars:
        print("没有缺失的单字，无需补充")
        return
    
    # 按编码分组
    encoding_to_chars = {}
    for shuangpin, char in missing_chars:
        if shuangpin not in encoding_to_chars:
            encoding_to_chars[shuangpin] = []
        encoding_to_chars[shuangpin].append(char)
    
    # 读取原文件内容
    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # 找到分隔符位置
    separator_index = -1
    for i, line in enumerate(lines):
        if line.strip() == '=========================':
            separator_index = i
            break
    
    # 如果没有分隔符，在文件末尾添加
    if separator_index == -1:
        lines.append('\n')
        lines.append('=========================\n')
        separator_index = len(lines) - 1
    
    # 在分隔符后添加缺失的单字
    new_lines = []
    for encoding in sorted(encoding_to_chars.keys()):
        chars = sorted(set(encoding_to_chars[encoding]))
        new_lines.append(encoding + '\t' + '\t'.join(chars) + '\n')
    
    # 插入新行
    lines.insert(separator_index + 1, '\n')
    for i, new_line in enumerate(new_lines):
        lines.insert(separator_index + 2 + i, new_line)
    
    # 写入文件
    with open(input_file, 'w', encoding='utf-8') as f:
        f.writelines(lines)
    
    print(f"\n处理完成！")
    print(f"  补充了 {len(missing_chars)} 个缺失的单字")
    print(f"  补充到 {input_file} 的 ========================= 后面")

def main():
    if len(sys.argv) < 3:
        print("使用方法: python add_missing_single_chars.py <1字文件> <输入文件>", file=sys.stderr)
        sys.exit(1)
    
    single_char_file = sys.argv[1]
    input_file = sys.argv[2]
    
    if not os.path.exists(single_char_file):
        print(f"错误: 文件不存在: {single_char_file}", file=sys.stderr)
        sys.exit(1)
    
    if not os.path.exists(input_file):
        print(f"错误: 文件不存在: {input_file}", file=sys.stderr)
        sys.exit(1)
    
    add_missing_chars(single_char_file, input_file)

if __name__ == '__main__':
    main()

