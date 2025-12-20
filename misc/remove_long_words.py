#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
3文字以上の単語を辞書ファイルから削除するスクリプト
"""

import sys
import os

def remove_long_words(input_file, output_file):
    """
    入力ファイルから3文字以上の単語を削除し、出力ファイルに保存
    """
    processed_lines = 0
    removed_count = 0
    
    with open(input_file, 'r', encoding='utf-8') as f_in, \
         open(output_file, 'w', encoding='utf-8') as f_out:
        
        for line in f_in:
            line = line.rstrip('\n\r')
            if not line:
                f_out.write('\n')
                continue
            
            # ピンイン部分と単語部分を分離
            parts = line.split(' ', 1)
            if len(parts) == 1:
                # 単語がない行（ピンインのみ）
                f_out.write(line + '\n')
                continue
            
            pinyin = parts[0]
            words = parts[1].split(' ')
            
            # 2文字以下の単語のみを保持
            short_words = [word for word in words if len(word) <= 2]
            
            # 削除された単語数をカウント
            removed_count += len(words) - len(short_words)
            
            # 結果を書き込み
            if short_words:
                f_out.write(pinyin + ' ' + ' '.join(short_words) + '\n')
            else:
                # 単語が全て削除された場合はピンインのみ
                f_out.write(pinyin + '\n')
            
            processed_lines += 1
            if processed_lines % 10000 == 0:
                print(f"処理済み: {processed_lines} 行", flush=True)
    
    print(f"処理完了: {processed_lines} 行処理")
    print(f"削除された単語数: {removed_count} 個")
    return processed_lines, removed_count

if __name__ == '__main__':
    input_file = '/Users/tetsuya/.local/share/nvim/lazy/ZFVimIM/dict/sbzr.userdb.txt'
    output_file = '/Users/tetsuya/.local/share/nvim/lazy/ZFVimIM/dict/sbzr.userdb.txt'
    temp_file = '/Users/tetsuya/.local/share/nvim/lazy/ZFVimIM/dict/sbzr.userdb.txt.tmp'
    
    print("3文字以上の単語を削除中...")
    processed, removed = remove_long_words(input_file, temp_file)
    
    # 一時ファイルを元のファイルに置き換え
    os.replace(temp_file, output_file)
    print(f"ファイルを更新しました: {output_file}")

