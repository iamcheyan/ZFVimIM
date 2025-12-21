#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
単語が関連付けられていない空のエンコーディング（ピンインのみの行）を削除するスクリプト
"""

import sys
import os

def remove_empty_encodings(input_file, output_file):
    """
    入力ファイルから単語がない行（ピンインのみの行）を削除し、出力ファイルに保存
    """
    processed_lines = 0
    removed_lines = 0
    kept_lines = 0
    
    with open(input_file, 'r', encoding='utf-8') as f_in, \
         open(output_file, 'w', encoding='utf-8') as f_out:
        
        for line in f_in:
            line = line.rstrip('\n\r')
            processed_lines += 1
            
            # 空行は保持
            if not line:
                f_out.write('\n')
                kept_lines += 1
                continue
            
            # スペースで分割
            parts = line.split(' ', 1)
            
            # ピンインのみ（スペースがない、またはスペースの後に何もない）
            if len(parts) == 1 or (len(parts) == 2 and not parts[1].strip()):
                # この行は削除（書き込まない）
                removed_lines += 1
            else:
                # 単語がある行は保持
                f_out.write(line + '\n')
                kept_lines += 1
            
            if processed_lines % 10000 == 0:
                print(f"処理済み: {processed_lines} 行 (保持: {kept_lines}, 削除: {removed_lines})", flush=True)
    
    print(f"処理完了: {processed_lines} 行処理")
    print(f"保持された行: {kept_lines} 行")
    print(f"削除された行: {removed_lines} 行")
    return processed_lines, kept_lines, removed_lines

if __name__ == '__main__':
    input_file = '/Users/tetsuya/.local/share/nvim/lazy/ZFVimIM/dict/sbzr.userdb.yaml'
    output_file = '/Users/tetsuya/.local/share/nvim/lazy/ZFVimIM/dict/sbzr.userdb.yaml'
    temp_file = '/Users/tetsuya/.local/share/nvim/lazy/ZFVimIM/dict/sbzr.userdb.yaml.tmp'
    
    print("単語がない空のエンコーディングを削除中...")
    processed, kept, removed = remove_empty_encodings(input_file, temp_file)
    
    # 一時ファイルを元のファイルに置き換え
    os.replace(temp_file, output_file)
    print(f"ファイルを更新しました: {output_file}")

