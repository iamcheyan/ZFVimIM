#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
辞書ファイルから3文字以上の単語を削除

用法:
    python3 remove_long_words.py <input_file> <output_file>
"""

import sys
import os


def remove_long_words(input_file, output_file):
    """
    辞書ファイルから3文字以上の単語を削除
    
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
            processed_lines = 0
            removed_count = 0
            
            for line in f_in:
                total_lines += 1
                line = line.rstrip('\n\r')
                
                # 空行をスキップ
                if not line.strip():
                    f_out.write(line + '\n')
                    continue
                
                # ピンインと単語を分離
                parts = line.split(' ', 1)
                if len(parts) < 2:
                    # 単語がない行はそのまま出力
                    f_out.write(line + '\n')
                    continue
                
                pinyin = parts[0]
                words = parts[1].split(' ')
                
                # 3文字未満（1-2文字）の単語のみを残す
                short_words = [word for word in words if len(word) < 3]
                
                removed_count += len(words) - len(short_words)
                
                # 短い単語が残っている場合のみ行を出力
                if short_words:
                    processed_lines += 1
                    output_line = pinyin + ' ' + ' '.join(short_words)
                    f_out.write(output_line + '\n')
                # 短い単語が残っていない場合は行をスキップ（削除）
            
            print(f'処理完了:')
            print(f'  総行数: {total_lines}')
            print(f'  出力行数: {processed_lines}')
            print(f'  削除された単語数: {removed_count}')
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
    
    success = remove_long_words(input_file, output_file)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()

