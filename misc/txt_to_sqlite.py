#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
将TXT格式的词库转换为SQLite数据库
支持增量插入：多次运行只会插入新数据，已存在的数据不会重复插入

用法:
    python3 txt_to_sqlite.py <txt_file> [db_file]

示例:
    python3 txt_to_sqlite.py dict/sbzr.userdb.txt dict/sbzr.userdb.db
"""

import sys
import os
import sqlite3


def parse_line(line):
    """
    解析词库文件的一行
    返回: (key, words_list) 或 None
    """
    line = line.rstrip('\n').strip()
    
    # 跳过空行和注释
    if not line or line.startswith('#'):
        return None
    
    # 处理转义的空格
    if '\\\\ ' in line:
        parts = line.replace('\\\\ ', '_ZFVimIM_space_').split()
        words = [w.replace('_ZFVimIM_space_', ' ') for w in parts[1:]]
    else:
        parts = line.split()
        words = parts[1:]
    
    if len(parts) < 2:
        return None
    
    key = parts[0]
    
    # 过滤空词
    words = [w.strip() for w in words if w.strip()]
    
    if not words:
        return None
    
    return (key, words)


def init_database(db_path):
    """
    初始化数据库，创建表结构
    """
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # 创建words表
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS words (
            key TEXT NOT NULL,
            word TEXT NOT NULL,
            frequency INTEGER DEFAULT 0,
            PRIMARY KEY (key, word)
        )
    ''')
    
    # 创建索引以提高查询性能
    cursor.execute('''
        CREATE INDEX IF NOT EXISTS idx_key ON words(key)
    ''')
    cursor.execute('''
        CREATE INDEX IF NOT EXISTS idx_word ON words(word)
    ''')
    
    conn.commit()
    return conn


def get_existing_keys(conn):
    """
    获取数据库中已存在的 (key, word) 对
    返回一个set，元素为 (key, word) 元组
    """
    cursor = conn.cursor()
    cursor.execute('SELECT key, word FROM words')
    return set(cursor.fetchall())


def insert_words(conn, key, words, existing_keys):
    """
    插入词条到数据库
    返回: (inserted_count, skipped_count)
    """
    cursor = conn.cursor()
    inserted = 0
    skipped = 0
    
    for word in words:
        if (key, word) in existing_keys:
            skipped += 1
            continue
        
        try:
            cursor.execute(
                'INSERT INTO words (key, word, frequency) VALUES (?, ?, ?)',
                (key, word, 0)
            )
            inserted += 1
            # 添加到已存在集合中，避免同一批次重复插入
            existing_keys.add((key, word))
        except sqlite3.IntegrityError:
            # 如果因为并发等原因导致主键冲突，跳过
            skipped += 1
    
    return (inserted, skipped)


def convert_txt_to_sqlite(txt_file, db_file=None):
    """
    将TXT词库文件转换为SQLite数据库
    
    Args:
        txt_file: TXT词库文件路径
        db_file: SQLite数据库文件路径（可选，默认为txt_file同目录下的.db文件）
    """
    if not os.path.exists(txt_file):
        print(f'错误: 文件不存在: {txt_file}')
        return False
    
    # 如果没有指定db_file，使用txt_file同目录下的.db文件
    if db_file is None:
        base_name = os.path.splitext(txt_file)[0]
        db_file = base_name + '.db'
    
    # 确保db_file的目录存在
    db_dir = os.path.dirname(db_file)
    if db_dir and not os.path.exists(db_dir):
        os.makedirs(db_dir, exist_ok=True)
    
    print(f'转换词库: {txt_file} -> {db_file}')
    print('=' * 60)
    
    # 初始化数据库
    print('初始化数据库...')
    conn = init_database(db_file)
    
    # 获取已存在的键值对
    print('读取已存在的数据...')
    existing_keys = get_existing_keys(conn)
    print(f'  数据库中已有 {len(existing_keys)} 条记录')
    
    # 读取并处理TXT文件
    print('\n开始处理TXT文件...')
    total_lines = 0
    processed_lines = 0
    total_inserted = 0
    total_skipped = 0
    
    try:
        with open(txt_file, 'r', encoding='utf-8') as f:
            for line_num, line in enumerate(f, 1):
                total_lines += 1
                
                if total_lines % 100000 == 0:
                    print(f'  处理中... 已处理 {total_lines} 行, '
                          f'插入 {total_inserted} 条, 跳过 {total_skipped} 条')
                
                result = parse_line(line)
                if result is None:
                    continue
                
                key, words = result
                processed_lines += 1
                
                inserted, skipped = insert_words(conn, key, words, existing_keys)
                total_inserted += inserted
                total_skipped += skipped
                
                # 每1000行提交一次，提高性能
                if processed_lines % 1000 == 0:
                    conn.commit()
        
        # 最终提交
        conn.commit()
        
    except Exception as e:
        conn.rollback()
        print(f'\n错误: 处理文件时出错: {e}')
        conn.close()
        return False
    
    # 获取最终统计
    cursor = conn.cursor()
    cursor.execute('SELECT COUNT(*) FROM words')
    total_in_db = cursor.fetchone()[0]
    
    conn.close()
    
    # 输出统计信息
    print('\n' + '=' * 60)
    print('转换完成！')
    print(f'  总行数: {total_lines}')
    print(f'  有效行数: {processed_lines}')
    print(f'  本次插入: {total_inserted} 条')
    print(f'  本次跳过: {total_skipped} 条（已存在）')
    print(f'  数据库总记录数: {total_in_db} 条')
    print(f'  数据库文件: {db_file}')
    
    return True


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    
    txt_file = sys.argv[1]
    db_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    success = convert_txt_to_sqlite(txt_file, db_file)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()

