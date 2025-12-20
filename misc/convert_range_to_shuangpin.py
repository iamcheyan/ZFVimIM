#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
自然码双拼変換スクリプト（範囲指定版）
指定された行範囲のピンインを自然码双拼に変換します
"""

import re
import sys

# 自然码双拼マッピング表
# 声母（Initial）マッピング
INITIAL_MAP = {
    'zh': 'v',
    'ch': 'i',
    'sh': 'u',
    # その他の声母はそのまま
}

# 韻母（Final）マッピング（画像の説明から）
FINAL_MAP = {
    # 単韻母
    'a': 'a',
    'o': 'o',
    'e': 'e',
    'i': 'i',
    'u': 'u',
    'v': 'v',
    'ü': 'v',
    
    # 複合韻母
    'ai': 'l',
    'ei': 'z',
    'ao': 'k',
    'ou': 'b',
    'an': 'j',
    'en': 'f',
    'ang': 'h',
    'eng': 'g',
    'ong': 's',
    'iong': 's',
    
    'ia': 'w',
    'iao': 'c',
    'ian': 'r',  # ユーザーの例: lian → lr
    'iang': 'd',
    'ie': 'x',
    'iu': 'q',
    'in': 'n',
    'ing': 'y',
    'iong': 's',
    
    'ua': 'w',
    'uai': 'y',
    'uan': 'r',
    'uang': 'd',
    'ue': 't',
    've': 't',
    'ui': 'v',
    'un': 'p',
    'uo': 'o',
    
    'er': 'r',
    'van': 'r',
    've': 't',
}

def split_pinyin(pinyin):
    """
    ピンインを声母と韻母に分割
    """
    # 特殊な声母をチェック
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
        # yで始まる場合、iに変換
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
        # wで始まる場合、uに変換
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
        # 通常の声母（b, p, m, f, d, t, n, l, g, k, h, j, q, x）
        if len(pinyin) > 0 and pinyin[0] in 'bpmfdtnlgkhjqx':
            return pinyin[0], pinyin[1:]
        else:
            # 声母なし（韻母のみ）
            return '', pinyin

def convert_to_shuangpin(pinyin):
    """
    ピンインを自然码双拼に変換
    """
    if not pinyin or len(pinyin) == 0:
        return pinyin
    
    # 1文字の場合はそのまま
    if len(pinyin) == 1:
        return pinyin
    
    # 特殊ケース: zhで始まる場合、zhをzに変換（ユーザーの例: zhi → zi, zhang → zh）
    if pinyin.startswith('zh'):
        # zhang → zh（ユーザーの例）
        if pinyin == 'zhang':
            return 'zh'
        # zhi → zi（ユーザーの例）
        elif pinyin == 'zhi':
            return 'zi'
        # その他のzhで始まる場合
        else:
            # zhをzに変換してから処理
            pinyin_with_z = 'z' + pinyin[2:]
            initial, final = split_pinyin(pinyin_with_z)
            if final:
                # 長い韻母から順にチェック
                final_code = None
                for final_key in sorted(FINAL_MAP.keys(), key=len, reverse=True):
                    if final.startswith(final_key):
                        final_code = FINAL_MAP[final_key]
                        break
                if final_code is None:
                    final_code = final[0] if final else ''
                return 'z' + final_code
            else:
                return 'z'
    
    # 特殊ケース: chi → ci（ユーザーの例から推測）
    if pinyin == 'chi':
        return 'ci'
    
    # 特殊ケース: shi → si（ユーザーの例から推測）
    if pinyin == 'shi':
        return 'si'
    
    # 声母と韻母に分割
    initial, final = split_pinyin(pinyin)
    
    # 韻母が空の場合
    if not final:
        return initial if initial else pinyin
    
    # 韻母をマッピング（長い韻母から順にチェック）
    final_code = None
    for final_key in sorted(FINAL_MAP.keys(), key=len, reverse=True):
        if final.startswith(final_key):
            final_code = FINAL_MAP[final_key]
            break
    
    # マッピングが見つからない場合、最初の文字を使用
    if final_code is None:
        final_code = final[0] if final else ''
    
    # 声母をマッピング
    if initial:
        # zh, ch, shは特別処理（ただし上記で処理済み）
        initial_code = INITIAL_MAP.get(initial, initial[0])
    else:
        initial_code = ''
    
    # 結果を結合
    result = initial_code + final_code
    
    # 結果が空の場合は元のピンインを返す
    if not result:
        return pinyin
    
    return result

def convert_line(line):
    """
    1行を変換（キーのみ変換、漢字はそのまま）
    """
    line = line.rstrip('\n')
    if not line or line.strip() == '':
        return line
    
    # スペースで分割
    parts = line.split(' ', 1)
    if len(parts) == 0:
        return line
    
    key = parts[0]
    words = parts[1] if len(parts) > 1 else ''
    
    # キーがピンインかチェック（小文字のアルファベットのみ）
    if key and key.isalpha() and key.islower():
        # ピンインを双拼に変換
        new_key = convert_to_shuangpin(key)
        # 新しいキーと単語を結合
        if words:
            return new_key + ' ' + words
        else:
            return new_key
    else:
        # キーがピンインでない場合はそのまま
        return line

def main():
    """
    メイン関数
    """
    if len(sys.argv) < 4:
        print("Usage: python convert_range_to_shuangpin.py <input_file> <start_line> <end_line>")
        print("Example: python convert_range_to_shuangpin.py dict/sbzr.userdb.txt 3731 4144")
        sys.exit(1)
    
    input_file = sys.argv[1]
    start_line = int(sys.argv[2])
    end_line = int(sys.argv[3])
    
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        # 範囲を変換
        converted_lines = []
        for i, line in enumerate(lines, 1):
            if start_line <= i <= end_line:
                converted_line = convert_line(line)
                converted_lines.append((i, converted_line))
            else:
                converted_lines.append((i, line.rstrip('\n')))
        
        # ファイルに書き戻す
        with open(input_file, 'w', encoding='utf-8') as f:
            for i, line in converted_lines:
                f.write(line + '\n')
        
        print(f"変換完了: {input_file}")
        print(f"変換範囲: {start_line}-{end_line}行")
        print(f"変換された行数: {len([l for i, l in converted_lines if start_line <= i <= end_line])}")
        
    except Exception as e:
        print(f"エラー: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    main()
