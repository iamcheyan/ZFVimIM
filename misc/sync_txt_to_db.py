#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
将TXT文件中的新数据同步到SQLite数据库
只插入TXT中存在但数据库中不存在的数据

用法:
    python3 sync_txt_to_db.py <txt_file> [db_file]

示例:
    python3 sync_txt_to_db.py dict/sbzr.userdb.txt dict/sbzr.userdb.db
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


def get_existing_data(conn):
    """
    获取数据库中已存在的 (key, word) 对
    返回一个set，元素为 (key, word) 元组
    """
    cursor = conn.cursor()
    cursor.execute('SELECT key, word FROM words')
    return set(cursor.fetchall())


def sync_txt_to_db(txt_file, db_file=None):
    """
    将TXT文件中的新数据同步到SQLite数据库
    
    Args:
        txt_file: TXT词库文件路径
        db_file: SQLite数据库文件路径（可选，默认为txt_file同目录下的.db文件）
    """
    if not os.path.exists(txt_file):
        print(f'错误: TXT文件不存在: {txt_file}')
        return False
    
    # 如果没有指定db_file，使用txt_file同目录下的.db文件
    if db_file is None:
        base_name = os.path.splitext(txt_file)[0]
        db_file = base_name + '.db'
    
    # 确保db_file的目录存在
    db_dir = os.path.dirname(db_file)
    if db_dir and not os.path.exists(db_dir):
        os.makedirs(db_dir, exist_ok=True)
    
    print(f'同步词库: {txt_file} -> {db_file}')
    print('=' * 60)
    
    # 初始化数据库（如果不存在）
    conn = sqlite3.connect(db_file)
    cursor = conn.cursor()
    
    # 创建表（如果不存在）
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS words (
            key TEXT NOT NULL,
            word TEXT NOT NULL,
            frequency INTEGER DEFAULT 0,
            PRIMARY KEY (key, word)
        )
    ''')
    
    # 创建索引（如果不存在）
    cursor.execute('''
        CREATE INDEX IF NOT EXISTS idx_key ON words(key)
    ''')
    cursor.execute('''
        CREATE INDEX IF NOT EXISTS idx_word ON words(word)
    ''')
    
    conn.commit()
    
    # 获取已存在的数据
    print('读取数据库中已存在的数据...')
    existing_data = get_existing_data(conn)
    print(f'  数据库中已有 {len(existing_data)} 条记录')
    
    # 读取TXT文件并找出新数据
    print('\n读取TXT文件并对比数据...')
    new_data = []
    total_lines = 0
    processed_lines = 0
    
    with open(txt_file, 'r', encoding='utf-8') as f:
        for line_num, line in enumerate(f, 1):
            total_lines += 1
            
            if total_lines % 100000 == 0:
                print(f'  处理中... 已处理 {total_lines} 行, 发现 {len(new_data)} 条新数据')
            
            result = parse_line(line)
            if result is None:
                continue
            
            key, words = result
            processed_lines += 1
            
            # 检查每个词是否已存在
            for word in words:
                if (key, word) not in existing_data:
                    new_data.append((key, word))
                    # 添加到已存在集合中，避免同一批次重复
                    existing_data.add((key, word))
    
    # 插入新数据
    if new_data:
        print(f'\n发现 {len(new_data)} 条新数据，开始插入...')
        inserted = 0
        skipped = 0
        
        for key, word in new_data:
            try:
                cursor.execute(
                    'INSERT INTO words (key, word, frequency) VALUES (?, ?, ?)',
                    (key, word, 0)
                )
                inserted += 1
            except sqlite3.IntegrityError:
                # 如果因为并发等原因导致主键冲突，跳过
                skipped += 1
        
        conn.commit()
        
        print(f'  成功插入: {inserted} 条')
        if skipped > 0:
            print(f'  跳过（已存在）: {skipped} 条')
    else:
        print('\n没有新数据需要插入')
    
    # 获取最终统计
    cursor.execute('SELECT COUNT(*) FROM words')
    total_in_db = cursor.fetchone()[0]
    
    conn.close()
    
    # 输出统计信息
    print('\n' + '=' * 60)
    print('同步完成！')
    print(f'  TXT文件总行数: {total_lines}')
    print(f'  TXT文件有效行数: {processed_lines}')
    print(f'  本次新增: {len(new_data)} 条')
    print(f'  数据库总记录数: {total_in_db} 条')
    print(f'  数据库文件: {db_file}')
    
    return True


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    
    txt_file = sys.argv[1]
    db_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    success = sync_txt_to_db(txt_file, db_file)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()

