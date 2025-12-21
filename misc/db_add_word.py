#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
向数据库添加词

用法:
    python3 db_add_word.py <db_file> <key> <word>

示例:
    python3 db_add_word.py dict/sbzr.userdb.db ceshi 测试
"""

import sys
import os
import sqlite3


def add_word_to_db(db_file, key, word):
    """
    向数据库添加词
    
    Args:
        db_file: SQLite 数据库文件路径
        key: 编码
        word: 词
    """
    if not os.path.exists(db_file):
        print(f'错误: 数据库文件不存在: {db_file}')
        return False
    
    try:
        conn = sqlite3.connect(db_file)
        cursor = conn.cursor()
        
        # 检查表是否存在
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='words'")
        if not cursor.fetchone():
            # 创建表
            cursor.execute('''
                CREATE TABLE words (
                    key TEXT NOT NULL,
                    word TEXT NOT NULL,
                    frequency INTEGER DEFAULT 0,
                    PRIMARY KEY (key, word)
                )
            ''')
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_key ON words(key)')
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_word ON words(word)')
        
        # 插入词（如果已存在则忽略）
        try:
            cursor.execute(
                'INSERT INTO words (key, word, frequency) VALUES (?, ?, ?)',
                (key, word, 0)
            )
            conn.commit()
            print('OK')
            return True
        except sqlite3.IntegrityError:
            # 已存在，忽略
            print('EXISTS')
            return True
        
    except Exception as e:
        print(f'错误: {e}')
        return False
    finally:
        if 'conn' in locals():
            conn.close()


def main():
    if len(sys.argv) < 4:
        print(__doc__)
        sys.exit(1)
    
    db_file = sys.argv[1]
    key = sys.argv[2]
    word = sys.argv[3]
    
    success = add_word_to_db(db_file, key, word)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()

