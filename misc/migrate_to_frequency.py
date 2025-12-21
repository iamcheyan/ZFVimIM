#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
将数据库从 created_at 字段迁移到 frequency 字段

用法:
    python3 migrate_to_frequency.py <db_file>

示例:
    python3 migrate_to_frequency.py dict/sbzr.userdb.db
"""

import sys
import os
import sqlite3


def migrate_database(db_file):
    """
    迁移数据库：将 created_at 字段改为 frequency 字段
    
    Args:
        db_file: SQLite数据库文件路径
    """
    if not os.path.exists(db_file):
        print(f'错误: 数据库文件不存在: {db_file}')
        return False
    
    print(f'迁移数据库: {db_file}')
    print('=' * 60)
    
    conn = sqlite3.connect(db_file)
    cursor = conn.cursor()
    
    # 检查表结构
    cursor.execute("PRAGMA table_info(words)")
    columns = [col[1] for col in cursor.fetchall()]
    
    has_created_at = 'created_at' in columns
    has_frequency = 'frequency' in columns
    
    if not has_created_at and not has_frequency:
        print('错误: 表结构异常，找不到 created_at 或 frequency 字段')
        conn.close()
        return False
    
    if has_frequency and not has_created_at:
        print('数据库已经是新格式（使用 frequency 字段），无需迁移')
        conn.close()
        return True
    
    if has_created_at and has_frequency:
        print('数据库同时包含 created_at 和 frequency 字段')
        print('删除 created_at 字段...')
        # SQLite 不支持直接删除列，需要重建表
        cursor.execute('''
            CREATE TABLE words_new (
                key TEXT NOT NULL,
                word TEXT NOT NULL,
                frequency INTEGER DEFAULT 0,
                PRIMARY KEY (key, word)
            )
        ''')
        cursor.execute('INSERT INTO words_new (key, word, frequency) SELECT key, word, 0 FROM words')
        cursor.execute('DROP TABLE words')
        cursor.execute('ALTER TABLE words_new RENAME TO words')
        
        # 重建索引
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_key ON words(key)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_word ON words(word)')
        conn.commit()
        print('迁移完成！')
        conn.close()
        return True
    
    # 只有 created_at，需要迁移
    print('检测到旧格式（created_at 字段），开始迁移...')
    
    # SQLite 不支持直接修改列，需要重建表
    print('1. 创建新表结构...')
    cursor.execute('''
        CREATE TABLE words_new (
            key TEXT NOT NULL,
            word TEXT NOT NULL,
            frequency INTEGER DEFAULT 0,
            PRIMARY KEY (key, word)
        )
    ''')
    
    print('2. 迁移数据（所有频率初始化为 0）...')
    cursor.execute('INSERT INTO words_new (key, word, frequency) SELECT key, word, 0 FROM words')
    
    print('3. 删除旧表...')
    cursor.execute('DROP TABLE words')
    
    print('4. 重命名新表...')
    cursor.execute('ALTER TABLE words_new RENAME TO words')
    
    print('5. 重建索引...')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_key ON words(key)')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_word ON words(word)')
    
    conn.commit()
    
    # 获取统计信息
    cursor.execute('SELECT COUNT(*) FROM words')
    total_count = cursor.fetchone()[0]
    
    conn.close()
    
    print('\n' + '=' * 60)
    print('迁移完成！')
    print(f'  总记录数: {total_count:,} 条')
    print(f'  所有记录的 frequency 已初始化为 0')
    print(f'  数据库文件: {db_file}')
    
    return True


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    
    db_file = sys.argv[1]
    success = migrate_database(db_file)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()

