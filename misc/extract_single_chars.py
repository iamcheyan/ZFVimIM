#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
从数据库提取所有去重单字

用法:
    python3 extract_single_chars.py <db_file> <output_file>

示例:
    python3 extract_single_chars.py dict/sbxlm.sbzr_backup_20251221_225724.db dict/single_chars.txt
"""

import sys
import os
import sqlite3


def extract_single_chars(db_file, output_file):
    """
    从数据库提取所有去重单字
    
    Args:
        db_file: SQLite 数据库文件路径
        output_file: 输出的文件路径
    """
    if not os.path.exists(db_file):
        print(f'错误: 数据库文件不存在: {db_file}', file=sys.stderr)
        return False
    
    try:
        # 连接数据库
        conn = sqlite3.connect(db_file)
        cursor = conn.cursor()
        
        # 读取所有单词
        try:
            cursor.execute('SELECT DISTINCT word FROM words')
        except sqlite3.OperationalError:
            # 如果 DISTINCT 不支持，使用普通查询然后去重
            cursor.execute('SELECT word FROM words')
        
        rows = cursor.fetchall()
        conn.close()
        
        # 提取单字（长度为 1 的字符）
        single_chars = set()
        for (word,) in rows:
            # 检查每个字符，如果是单字就添加
            for char in word:
                if len(char) == 1:  # 单字符
                    single_chars.add(char)
        
        # 转换为排序列表（按 Unicode 码点排序）
        single_chars_list = sorted(single_chars)
        
        # 写入文件
        with open(output_file, 'w', encoding='utf-8') as f:
            for char in single_chars_list:
                f.write(char + '\n')
        
        print(f'成功提取 {len(single_chars_list)} 个去重单字')
        print(f'输出文件: {output_file}')
        return True
        
    except Exception as e:
        print(f'错误: 提取单字时出错: {e}', file=sys.stderr)
        return False


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    
    db_file = sys.argv[1]
    output_file = sys.argv[2]
    
    success = extract_single_chars(db_file, output_file)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()

