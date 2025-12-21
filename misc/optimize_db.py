#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
优化 SQLite 数据库，减小文件大小

优化方法：
1. VACUUM - 重建数据库，回收碎片空间
2. 调整页面大小（可选，默认保持 4096）
3. 启用 auto_vacuum（可选）

用法:
    python3 optimize_db.py <db_file> [--page-size SIZE] [--auto-vacuum]

示例:
    python3 optimize_db.py dict/sbzr.userdb.db
    python3 optimize_db.py dict/sbzr.userdb.db --page-size 8192
    python3 optimize_db.py dict/sbzr.userdb.db --auto-vacuum
"""

import sys
import os
import sqlite3
import shutil
import argparse


def get_db_size(db_file):
    """获取数据库文件大小（MB）"""
    if os.path.exists(db_file):
        return os.path.getsize(db_file) / (1024 * 1024)
    return 0


def optimize_database(db_file, page_size=None, auto_vacuum=False):
    """
    优化数据库
    
    Args:
        db_file: SQLite 数据库文件路径
        page_size: 页面大小（可选，默认保持原值）
        auto_vacuum: 是否启用 auto_vacuum
    """
    if not os.path.exists(db_file):
        print(f'错误: 数据库文件不存在: {db_file}')
        return False
    
    original_size = get_db_size(db_file)
    print(f'优化数据库: {db_file}')
    print('=' * 60)
    print(f'原始大小: {original_size:.2f} MB')
    
    # 创建备份
    backup_file = db_file + '.backup'
    print(f'\n1. 创建备份: {backup_file}')
    shutil.copy2(db_file, backup_file)
    
    conn = sqlite3.connect(db_file)
    cursor = conn.cursor()
    
    # 获取当前设置
    cursor.execute('PRAGMA page_size')
    current_page_size = cursor.fetchone()[0]
    cursor.execute('PRAGMA auto_vacuum')
    current_auto_vacuum = cursor.fetchone()[0]
    
    print(f'\n当前设置:')
    print(f'  页面大小: {current_page_size} 字节')
    print(f'  auto_vacuum: {current_auto_vacuum}')
    
    # 如果需要修改页面大小，需要重建数据库
    if page_size and page_size != current_page_size:
        print(f'\n2. 调整页面大小: {current_page_size} -> {page_size}')
        # SQLite 只能在创建数据库时设置页面大小
        # 需要导出数据并重新导入
        print('   (需要重建数据库，这可能需要一些时间...)')
        
        # 导出所有数据
        cursor.execute('SELECT key, word, frequency FROM words ORDER BY key, word')
        all_data = cursor.fetchall()
        total_count = len(all_data)
        print(f'   导出 {total_count:,} 条记录...')
        
        conn.close()
        
        # 删除原数据库
        os.remove(db_file)
        
        # 创建新数据库（使用新页面大小）
        conn = sqlite3.connect(db_file)
        cursor = conn.cursor()
        cursor.execute(f'PRAGMA page_size = {page_size}')
        cursor.execute('PRAGMA auto_vacuum = FULL' if auto_vacuum else 'PRAGMA auto_vacuum = NONE')
        
        # 创建表
        cursor.execute('''
            CREATE TABLE words (
                key TEXT NOT NULL,
                word TEXT NOT NULL,
                frequency INTEGER DEFAULT 0,
                PRIMARY KEY (key, word)
            )
        ''')
        
        # 创建索引
        cursor.execute('CREATE INDEX idx_key ON words(key)')
        cursor.execute('CREATE INDEX idx_word ON words(word)')
        
        # 批量插入数据
        print(f'   重新导入 {total_count:,} 条记录...')
        batch_size = 10000
        for i in range(0, total_count, batch_size):
            batch = all_data[i:i+batch_size]
            cursor.executemany(
                'INSERT INTO words (key, word, frequency) VALUES (?, ?, ?)',
                batch
            )
            if (i + batch_size) % 100000 == 0:
                print(f'     已导入 {i + batch_size:,} / {total_count:,} 条')
            conn.commit()
        
        print(f'   导入完成')
        conn.commit()
    
    # 设置 auto_vacuum（如果指定）
    if auto_vacuum and current_auto_vacuum == 0:
        print(f'\n3. 启用 auto_vacuum...')
        # 注意：auto_vacuum 只能在创建数据库时设置
        # 如果数据库已存在，需要重建
        if not page_size:
            print('   (auto_vacuum 需要在创建数据库时设置，跳过)')
        else:
            cursor.execute('PRAGMA auto_vacuum = FULL')
            conn.commit()
    
    # 执行 VACUUM（重建数据库，回收空间）
    print(f'\n4. 执行 VACUUM（重建数据库，回收碎片空间）...')
    print('   (这可能需要一些时间，请耐心等待...)')
    cursor.execute('VACUUM')
    conn.commit()
    
    # 获取优化后的统计
    cursor.execute('SELECT COUNT(*) FROM words')
    total_count = cursor.fetchone()[0]
    cursor.execute('PRAGMA page_count')
    page_count = cursor.fetchone()[0]
    cursor.execute('PRAGMA page_size')
    final_page_size = cursor.fetchone()[0]
    
    conn.close()
    
    # 获取最终文件大小
    final_size = get_db_size(db_file)
    saved = original_size - final_size
    saved_percent = (saved / original_size * 100) if original_size > 0 else 0
    
    print('\n' + '=' * 60)
    print('优化完成！')
    print(f'  原始大小: {original_size:.2f} MB')
    print(f'  优化后: {final_size:.2f} MB')
    print(f'  节省: {saved:.2f} MB ({saved_percent:.1f}%)')
    print(f'  记录数: {total_count:,}')
    print(f'  页面大小: {final_page_size} 字节')
    print(f'  页面数量: {page_count:,}')
    print(f'  备份文件: {backup_file}')
    print('\n提示: 如果优化结果满意，可以删除备份文件')
    
    return True


def main():
    parser = argparse.ArgumentParser(description='优化 SQLite 数据库，减小文件大小')
    parser.add_argument('db_file', help='数据库文件路径')
    parser.add_argument('--page-size', type=int, help='页面大小（字节），可选值: 512, 1024, 2048, 4096, 8192, 16384, 32768')
    parser.add_argument('--auto-vacuum', action='store_true', help='启用 auto_vacuum（自动回收空间）')
    
    args = parser.parse_args()
    
    # 验证页面大小
    if args.page_size:
        valid_sizes = [512, 1024, 2048, 4096, 8192, 16384, 32768]
        if args.page_size not in valid_sizes:
            print(f'错误: 页面大小必须是以下值之一: {valid_sizes}')
            sys.exit(1)
    
    success = optimize_database(args.db_file, args.page_size, args.auto_vacuum)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()

