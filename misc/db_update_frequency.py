#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
更新数据库中的词频
当用户选择词后，调用此脚本更新数据库中的频率
"""
import sys
import os
import sqlite3

def update_word_frequency(db_file, key, word, increment=1):
    """
    更新数据库中某个词的频率
    
    Args:
        db_file: 数据库文件路径
        key: 编码
        word: 词
        increment: 增加的频率值（默认1）
    
    Returns:
        bool: 是否成功
    """
    if not os.path.exists(db_file):
        print(f'错误: 数据库文件不存在: {db_file}')
        return False
    
    try:
        conn = sqlite3.connect(db_file)
        cursor = conn.cursor()
        
        # 检查是否有 frequency 字段
        cursor.execute("PRAGMA table_info(words)")
        columns = [col[1] for col in cursor.fetchall()]
        if 'frequency' not in columns:
            print('错误: 数据库表没有 frequency 字段')
            conn.close()
            return False
        
        # 获取当前频率
        cursor.execute('SELECT frequency FROM words WHERE key = ? AND word = ?', (key, word))
        row = cursor.fetchone()
        
        if row is None:
            # 词不存在，插入新记录（频率设为 increment）
            cursor.execute(
                'INSERT INTO words (key, word, frequency) VALUES (?, ?, ?)',
                (key, word, increment)
            )
        else:
            # 更新频率（增加 increment）
            current_freq = row[0] or 0
            new_freq = current_freq + increment
            # 限制最大频率，防止溢出
            if new_freq > 1000000:
                new_freq = 1000000
            cursor.execute(
                'UPDATE words SET frequency = ? WHERE key = ? AND word = ?',
                (new_freq, key, word)
            )
        
        conn.commit()
        conn.close()
        return True
    except Exception as e:
        print(f'错误: {e}')
        return False

def main():
    if len(sys.argv) < 4:
        print('用法: python3 db_update_frequency.py <db_file> <key> <word> [increment]')
        print('示例: python3 db_update_frequency.py dict/sbzr.userdb.db zheng 正 1')
        sys.exit(1)
    
    db_file = sys.argv[1]
    key = sys.argv[2]
    word = sys.argv[3]
    increment = int(sys.argv[4]) if len(sys.argv) > 4 else 1
    
    success = update_word_frequency(db_file, key, word, increment)
    if success:
        print('OK')
    else:
        print('ERROR')
        sys.exit(1)

if __name__ == '__main__':
    main()

