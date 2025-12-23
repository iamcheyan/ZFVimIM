#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
辞書ファイルから4文字以上のエンコーディングを持つ行を削除

用法:
    python3 remove_long_encoding.py <input_file> <output_file>
"""

import sys
import os


def remove_long_encoding(input_file, output_file):
    """
    辞書ファイルから4文字以上のエンコーディングを持つ行を削除
    
    Args:
        input_file: 入力ファイルパス
        output_file: 出力ファイルパス
    """
    if not os.path.exists(input_file):
        print(f'错误: 文件不存在: {input_file}')
        return False
    
    try:
        with open(input_file, 'r', encoding='utf-8') as f_in, \
             open(output_file, 'w', encoding='utf-8') as f_out:
            
            total_lines = 0
            kept_lines = 0
            removed_lines = 0
            
            for line in f_in:
                total_lines += 1
                line = line.rstrip('\n\r')
                
                # 空行をそのまま出力
                if not line.strip():
                    f_out.write(line + '\n')
                    kept_lines += 1
                    continue
                
                # エンコーディング部分を取得（最初のスペースまで）
                parts = line.split(' ', 1)
                encoding = parts[0]
                
                # エンコーディングが4文字未満（1-3文字）の行のみを出力
                if len(encoding) < 4:
                    f_out.write(line + '\n')
                    kept_lines += 1
                else:
                    removed_lines += 1
            
            print(f'処理完了:')
            print(f'  総行数: {total_lines}')
            print(f'  保持行数: {kept_lines}')
            print(f'  削除行数: {removed_lines}')
            return True
            
    except Exception as e:
        print(f'错误: {e}')
        return False


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    success = remove_long_encoding(input_file, output_file)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()

