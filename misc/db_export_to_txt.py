#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
从数据库导出到 YAML 文件

用法:
    python3 db_export_to_txt.py <db_file> [txt_file]

示例:
    python3 db_export_to_txt.py dict/sbzr.userdb.db dict/sbzr.userdb.yaml
"""

import sys
import os
import sqlite3
from collections import defaultdict


def export_db_to_txt(db_file, txt_file):
    """
    从数据库导出到 YAML 文件
    
    Args:
        db_file: SQLite 数据库文件路径
        txt_file: 输出的 YAML 文件路径
    """
    if not os.path.exists(db_file):
        print(f'错误: 数据库文件不存在: {db_file}')
        return False
    
    try:
        # 连接数据库
        conn = sqlite3.connect(db_file)
        cursor = conn.cursor()
        
        # 读取所有数据，按 key 分组
        cursor.execute('SELECT key, word FROM words ORDER BY key, word')
        rows = cursor.fetchall()
        conn.close()
        
        # 按 key 分组组织数据
        key_words_map = defaultdict(list)
        for key, word in rows:
            key_words_map[key].append(word)
        
        # 如果 YAML 文件已存在，删除它
        if os.path.exists(txt_file):
            os.remove(txt_file)
            print(f'已删除现有文件: {txt_file}')
        
        # 写入 YAML 文件
        with open(txt_file, 'w', encoding='utf-8') as f:
            # 按 key 排序
            for key in sorted(key_words_map.keys()):
                words = key_words_map[key]
                # 转义空格：将空格替换为 \ 
                escaped_words = [word.replace(' ', '\\ ') for word in words]
                # 格式：key word1 word2 word3 ...
                line = key + ' ' + ' '.join(escaped_words)
                f.write(line + '\n')
        
        # 统计信息
        total_keys = len(key_words_map)
        total_words = len(rows)
        
        print(f'导出成功: {txt_file}')
        print(f'统计: {total_keys} 个编码, {total_words} 条记录')
        return True
        
    except Exception as e:
        print(f'错误: {e}')
        return False


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    
    db_file = sys.argv[1]
    
    # 如果没有指定 YAML 文件，自动生成（将 .db 替换为 .yaml）
    if len(sys.argv) >= 3:
        txt_file = sys.argv[2]
    else:
        if db_file.endswith('.db'):
            txt_file = db_file[:-3] + '.yaml'
        else:
            txt_file = db_file + '.yaml'
    
    success = export_db_to_txt(db_file, txt_file)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()

