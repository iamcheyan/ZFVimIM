#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
各漢字の前に全拼（ピンイン）を追加するスクリプト
"""

import sys
import os

try:
    from pypinyin import lazy_pinyin, Style
except ImportError:
    print("pypinyinライブラリが必要です。インストールしてください: pip install pypinyin", file=sys.stderr)
    sys.exit(1)

def add_pinyin_to_file(input_file, output_file=None):
    """
    ファイル内の各漢字の前にピンインを追加
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
            
            # 各行は1つの漢字のみと仮定
            char = line
            if char:
                # ピンインを取得（全拼、小文字）
                pinyin_list = lazy_pinyin(char, style=Style.NORMAL)
                pinyin = pinyin_list[0] if pinyin_list else ''
                
                # ピンイン + スペース + 漢字の形式で出力
                if pinyin:
                    f_out.write(f"{pinyin} {char}\n")
                else:
                    # ピンインが取得できない場合は漢字のみ
                    f_out.write(f"{char}\n")
    
    # 一時ファイルを元のファイルに移動
    os.replace(temp_file, output_file)
    print(f"処理完了: {output_file}")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("使用方法: python add_pinyin.py <入力ファイル> [出力ファイル]", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    if not os.path.exists(input_file):
        print(f"エラー: ファイルが見つかりません: {input_file}", file=sys.stderr)
        sys.exit(1)
    
    add_pinyin_to_file(input_file, output_file)

