#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
1. 根据 default.yaml 过滤不常用字
2. 检查双拼编码是否正确
"""

import sys
import os
import re
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

def load_common_chars(default_file):
    """从 default.yaml 加载所有常用字"""
    chars = set()
    with open(default_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            
            parts = line.split()
            if len(parts) >= 2:
                for word in parts[1:]:
                    for char in word:
                        if '\u4e00' <= char <= '\u9fff':
                            chars.add(char)
    return chars

def check_and_filter_file(input_file, default_file, output_file=None):
    """过滤不常用字并检查双拼编码"""
    if output_file is None:
        output_file = input_file
    
    # 加载常用字
    print(f"正在加载 {default_file} 中的常用字...")
    common_chars = load_common_chars(default_file)
    print(f"已加载 {len(common_chars)} 个常用字")
    
    # 读取并处理文件
    print(f"\n正在处理 {input_file}...")
    lines = []
    removed_count = 0
    wrong_code_count = 0
    wrong_codes = []
    
    with open(input_file, 'r', encoding='utf-8') as f:
        for line in f:
            original_line = line
            line = line.strip()
            if not line:
                lines.append('')
                continue
            
            # 格式：双拼编码 汉字
            parts = line.split()
            if len(parts) < 2:
                continue
            
            code = parts[0].strip()
            char = parts[1].strip()
            
            # 检查是否常用字
            if char not in common_chars:
                removed_count += 1
                continue
            
            # 检查双拼编码是否正确
            pinyin_list = lazy_pinyin(char, style=Style.NORMAL)
            if pinyin_list:
                correct_pinyin = pinyin_list[0]
                correct_code = pinyin_to_shuangpin(correct_pinyin)
                
                if code != correct_code:
                    wrong_code_count += 1
                    wrong_codes.append({
                        'char': char,
                        'file_code': code,
                        'correct_code': correct_code,
                        'pinyin': correct_pinyin
                    })
                    # 使用正确的编码
                    code = correct_code
            
            # 保留这一行（使用正确的编码）
            lines.append(f"{code} {char}")
    
    # 写入文件
    with open(output_file, 'w', encoding='utf-8') as f:
        for line in lines:
            f.write(line + '\n')
    
    print(f"\n处理完成！")
    print(f"  删除了 {removed_count} 个不常用字")
    print(f"  修正了 {wrong_code_count} 个错误的双拼编码")
    print(f"  保留了 {len(lines)} 个字")
    
    if wrong_codes:
        print(f"\n错误的双拼编码（前20个）：")
        for item in wrong_codes[:20]:
            print(f"  {item['char']}: 文件中的编码={item['file_code']}, 正确编码={item['correct_code']} (拼音={item['pinyin']})")
        if len(wrong_codes) > 20:
            print(f"  ... 还有 {len(wrong_codes) - 20} 个")

def main():
    if len(sys.argv) < 3:
        print("使用方法: python filter_and_check_shuangpin.py <输入文件> <default.yaml> [输出文件]", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    default_file = sys.argv[2]
    output_file = sys.argv[3] if len(sys.argv) > 3 else None
    
    if not os.path.exists(input_file):
        print(f"错误: 文件不存在: {input_file}", file=sys.stderr)
        sys.exit(1)
    
    if not os.path.exists(default_file):
        print(f"错误: 文件不存在: {default_file}", file=sys.stderr)
        sys.exit(1)
    
    check_and_filter_file(input_file, default_file, output_file)

if __name__ == '__main__':
    main()


