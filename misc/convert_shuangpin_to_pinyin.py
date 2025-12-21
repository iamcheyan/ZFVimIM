#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
将双拼编码转换为全拼编码
自然码双拼 -> 全拼
"""

import sys
import os

# 自然码双拼反向映射表
# 声母（Initial）反向映射
INITIAL_REVERSE_MAP = {
    'v': 'zh',
    'i': 'ch',
    'u': 'sh',
}

# 韵母（Final）反向映射
FINAL_REVERSE_MAP = {
    # 单韵母
    'a': 'a',
    'o': 'o',
    'e': 'e',
    'i': 'i',
    'u': 'u',
    'v': 'v',
    
    # 复合韵母
    'l': 'ai',
    'z': 'ei',
    'k': 'ao',
    'b': 'ou',
    'j': 'an',
    'f': 'en',
    'h': 'ang',
    'g': 'eng',
    's': 'ong',
    
    'w': 'ia',  # 注意：ua也是w，需要根据上下文判断
    'c': 'iao',
    'r': 'ian',  # 注意：uan也是r，需要根据上下文判断
    'd': 'iang',  # 注意：uang也是d，需要根据上下文判断
    'x': 'ie',
    'q': 'iu',
    'n': 'in',
    'y': 'ing',  # 注意：uai也是y，需要根据上下文判断
    
    't': 'ue',  # ve也是t
    'p': 'un',
}

def shuangpin_to_pinyin(shuangpin):
    """
    将双拼编码转换为全拼
    自然码双拼规则：
    - 2个字符：声母+韵母
    - 1个字符：只有韵母（零声母）
    """
    if len(shuangpin) == 0:
        return ''
    
    if len(shuangpin) == 1:
        # 只有韵母（零声母）
        final = shuangpin[0]
        pinyin_final = FINAL_REVERSE_MAP.get(final, final)
        # 零声母韵母的特殊处理
        if pinyin_final.startswith('i'):
            return 'y' + pinyin_final[1:] if len(pinyin_final) > 1 else 'yi'
        elif pinyin_final.startswith('u'):
            return 'w' + pinyin_final[1:] if len(pinyin_final) > 1 else 'wu'
        elif pinyin_final.startswith('v'):
            return 'yu' + pinyin_final[1:] if len(pinyin_final) > 1 else 'yu'
        else:
            return pinyin_final
    
    elif len(shuangpin) == 2:
        # 声母 + 韵母
        initial_char = shuangpin[0]
        final_char = shuangpin[1]
        
        # 获取声母
        if initial_char in INITIAL_REVERSE_MAP:
            initial = INITIAL_REVERSE_MAP[initial_char]
        else:
            initial = initial_char
        
        # 获取韵母
        final = FINAL_REVERSE_MAP.get(final_char, final_char)
        
        # 特殊处理：某些韵母需要根据声母判断
        # w可能是ia或ua
        if final_char == 'w':
            if initial in ['g', 'k', 'h']:
                final = 'ua'
            else:
                final = 'ia'
        # r可能是ian或uan
        elif final_char == 'r':
            if initial in ['g', 'k', 'h', 'zh', 'ch', 'sh', 'r', 'z', 'c', 's']:
                final = 'uan'
            else:
                final = 'ian'
        # d可能是iang或uang
        elif final_char == 'd':
            if initial in ['g', 'k', 'h', 'zh', 'ch', 'sh', 'r', 'z', 'c', 's']:
                final = 'uang'
            else:
                final = 'iang'
        # y可能是ing或uai
        elif final_char == 'y':
            if initial in ['g', 'k', 'h', 'zh', 'ch', 'sh', 'r', 'z', 'c', 's']:
                final = 'uai'
            else:
                final = 'ing'
        
        return initial + final
    
    else:
        # 多字符：可能是多字词的编码，需要逐个转换
        result = []
        i = 0
        while i < len(shuangpin):
            if i + 1 < len(shuangpin):
                # 尝试2字符
                two_char = shuangpin[i:i+2]
                pinyin = shuangpin_to_pinyin(two_char)
                if pinyin:
                    result.append(pinyin)
                    i += 2
                    continue
            # 尝试1字符
            one_char = shuangpin[i]
            pinyin = shuangpin_to_pinyin(one_char)
            if pinyin:
                result.append(pinyin)
                i += 1
            else:
                # 无法转换，保留原字符
                result.append(shuangpin[i])
                i += 1
        return ''.join(result)

def convert_file(input_file, output_file):
    """
    转换文件：将双拼编码转换为全拼编码
    """
    with open(input_file, 'r', encoding='utf-8') as f_in, \
         open(output_file, 'w', encoding='utf-8') as f_out:
        
        for line in f_in:
            line = line.rstrip('\n')
            if not line:
                f_out.write('\n')
                continue
            
            # 分割：编码 + 汉字（可能有多个，用制表符分隔）
            parts = line.split('\t')
            if len(parts) < 2:
                # 如果没有制表符，尝试用空格分割
                parts = line.split(' ', 1)
            
            if len(parts) < 2:
                # 格式不正确，直接输出
                f_out.write(line + '\n')
                continue
            
            # 获取双拼编码
            shuangpin_code = parts[0].strip()
            
            # 转换为全拼编码
            pinyin_code = shuangpin_to_pinyin(shuangpin_code)
            
            # 重建行：全拼编码 + 制表符 + 汉字部分
            new_line = pinyin_code + '\t' + '\t'.join(parts[1:])
            f_out.write(new_line + '\n')

def main():
    if len(sys.argv) < 3:
        print("使用方法: python convert_shuangpin_to_pinyin.py <双拼目录> <全拼目录>", file=sys.stderr)
        sys.exit(1)
    
    shuangpin_dir = sys.argv[1]
    pinyin_dir = sys.argv[2]
    
    if not os.path.isdir(shuangpin_dir):
        print(f"错误: 目录不存在: {shuangpin_dir}", file=sys.stderr)
        sys.exit(1)
    
    # 创建全拼目录
    os.makedirs(pinyin_dir, exist_ok=True)
    
    # 处理所有YAML文件
    import glob
    yaml_files = glob.glob(os.path.join(shuangpin_dir, '*.yaml'))
    yaml_files.sort()
    
    if not yaml_files:
        print(f"错误: 在 {shuangpin_dir} 中未找到 YAML 文件", file=sys.stderr)
        sys.exit(1)
    
    print(f"找到 {len(yaml_files)} 个文件，开始转换...")
    
    for yaml_file in yaml_files:
        filename = os.path.basename(yaml_file)
        output_file = os.path.join(pinyin_dir, filename)
        print(f"转换: {filename}")
        convert_file(yaml_file, output_file)
    
    print(f"\n转换完成！全拼文件已保存到: {pinyin_dir}")

if __name__ == '__main__':
    main()

