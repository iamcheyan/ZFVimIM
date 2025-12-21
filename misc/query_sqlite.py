#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
查询SQLite词库数据库的示例工具

用法:
    python3 query_sqlite.py <db_file> <key>
    python3 query_sqlite.py <db_file> --word <word>
    python3 query_sqlite.py <db_file> --stats
"""

import sys
import sqlite3


def query_by_key(db_file, key):
    """根据编码查询词"""
    conn = sqlite3.connect(db_file)
    cursor = conn.cursor()
    
    cursor.execute('SELECT word FROM words WHERE key = ? ORDER BY word', (key,))
    words = [row[0] for row in cursor.fetchall()]
    
    conn.close()
    return words


def query_by_word(db_file, word):
    """根据词查询编码"""
    conn = sqlite3.connect(db_file)
    cursor = conn.cursor()
    
    cursor.execute('SELECT key FROM words WHERE word = ? ORDER BY key', (word,))
    keys = [row[0] for row in cursor.fetchall()]
    
    conn.close()
    return keys


def show_stats(db_file):
    """显示数据库统计信息"""
    conn = sqlite3.connect(db_file)
    cursor = conn.cursor()
    
    cursor.execute('SELECT COUNT(*) FROM words')
    total = cursor.fetchone()[0]
    
    cursor.execute('SELECT COUNT(DISTINCT key) FROM words')
    key_count = cursor.fetchone()[0]
    
    cursor.execute('SELECT COUNT(DISTINCT word) FROM words')
    word_count = cursor.fetchone()[0]
    
    print(f'数据库统计: {db_file}')
    print(f'  总记录数: {total}')
    print(f'  不同编码数: {key_count}')
    print(f'  不同词数: {word_count}')
    
    conn.close()


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    
    db_file = sys.argv[1]
    
    if len(sys.argv) == 2:
        show_stats(db_file)
    elif sys.argv[2] == '--word' and len(sys.argv) > 3:
        word = sys.argv[3]
        keys = query_by_word(db_file, word)
        print(f'词 "{word}" 的编码: {keys}')
    elif sys.argv[2] == '--stats':
        show_stats(db_file)
    else:
        key = sys.argv[2]
        words = query_by_key(db_file, key)
        print(f'编码 "{key}" 的词 ({len(words)} 个):')
        for word in words[:50]:  # 只显示前50个
            print(f'  {word}')
        if len(words) > 50:
            print(f'  ... 还有 {len(words) - 50} 个词')


if __name__ == '__main__':
    main()

