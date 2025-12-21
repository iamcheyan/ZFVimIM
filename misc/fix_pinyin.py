#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
重複したピンインを修正し、正しい形式（ピンイン + スペース + 漢字）にするスクリプト
"""

import sys
import os
from pypinyin import lazy_pinyin, Style

def fix_pinyin_file(input_file, output_file=None):
    """
    ファイル内の各行を修正：重複したピンインを削除し、正しい形式にする
    """
    if output_file is None:
        output_file = input_file
    
    # 一時ファイルに書き込む
    temp_file = output_file + '.tmp'
    
    with open(input_file, 'r', encoding='utf-8') as f_in, \
         open(temp_file, 'w', encoding='utf-8') as f_out:
        
        for line in f_in:
            line = line.strip()
            if not line:
                f_out.write('\n')
                continue
            
            # 行を分割
            parts = line.split()
            
            # 最後の部分が漢字（または漢字を含む）と仮定
            # 漢字部分を取得
            char = None
            for part in reversed(parts):
                # 漢字が含まれているかチェック
                if any('\u4e00' <= c <= '\u9fff' for c in part):
                    char = part
                    break
            
            if char:
                # ピンインを取得
                pinyin_list = lazy_pinyin(char, style=Style.NORMAL)
                pinyin = pinyin_list[0] if pinyin_list else ''
                
                # ピンイン + スペース + 漢字の形式で出力
                if pinyin:
                    f_out.write(f"{pinyin} {char}\n")
                else:
                    f_out.write(f"{char}\n")
            else:
                # 漢字が見つからない場合はそのまま出力
                f_out.write(f"{line}\n")
    
    # 一時ファイルを元のファイルに移動
    os.replace(temp_file, output_file)
    print(f"処理完了: {output_file}")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("使用方法: python fix_pinyin.py <入力ファイル> [出力ファイル]", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    if not os.path.exists(input_file):
        print(f"エラー: ファイルが見つかりません: {input_file}", file=sys.stderr)
        sys.exit(1)
    
    fix_pinyin_file(input_file, output_file)

