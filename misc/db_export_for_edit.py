#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
从数据库导出为文本格式（用于编辑），按词数量从多到少排序

用法:
    python3 db_export_for_edit.py <db_file>

输出格式:
    编码 候选词1 候选词2 ...
    按词数量从多到少排序
"""

import sys
import os
import sqlite3
from collections import defaultdict


def export_db_for_edit(db_file):
    """
    从数据库导出为文本格式，按词数量从多到少排序
    
    Args:
        db_file: SQLite 数据库文件路径
    
    Returns:
        list: 文本行列表，每行格式为 "编码 候选词1 候选词2 ..."
    """
    if not os.path.exists(db_file):
        print(f'错误: 数据库文件不存在: {db_file}', file=sys.stderr)
        return None
    
    try:
        # 连接数据库
        conn = sqlite3.connect(db_file)
        cursor = conn.cursor()
        
        # 读取所有数据，按 key 分组，并按 frequency 排序
        cursor.execute('''
            SELECT key, word, frequency 
            FROM words 
            ORDER BY key, frequency DESC, word
        ''')
        rows = cursor.fetchall()
        conn.close()
        
        # 按 key 分组组织数据
        key_words_map = defaultdict(list)
        for key, word, frequency in rows:
            key_words_map[key].append(word)
        
        # 转换为列表，按词数量从多到少排序
        result = []
        for key, words in sorted(key_words_map.items(), key=lambda x: len(x[1]), reverse=True):
            if not words:
                continue
            # 转义空格：将空格替换为 \ 
            escaped_words = [word.replace(' ', '\\ ') for word in words]
            # 格式：key word1 word2 word3 ... (使用空格分隔，与 YAML 格式一致)
            line = key + ' ' + ' '.join(escaped_words)
            result.append(line)
        
        return result
        
    except Exception as e:
        print(f'错误: {e}', file=sys.stderr)
        return None


def main():
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        sys.exit(1)
    
    db_file = sys.argv[1]
    
    lines = export_db_for_edit(db_file)
    if lines is None:
        sys.exit(1)
    
    # 输出到标准输出
    for line in lines:
        print(line)
    
    sys.exit(0)


if __name__ == '__main__':
    main()

