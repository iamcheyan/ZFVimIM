#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
从 YAML 文件完整导入到数据库（清空后重新导入）

功能：
1. 清空数据库中的所有数据
2. 从 YAML 文件完整导入所有数据
3. 确保数据库和 YAML 文件内容完全一致

用法:
    python3 import_txt_to_db.py <txt_file> [db_file]

示例:
    python3 import_txt_to_db.py dict/sbzr.userdb.yaml dict/sbzr.userdb.db
"""

import sys
import os
import sqlite3
import shutil
from collections import defaultdict
from datetime import datetime


def clean_and_sort_txt_file(txt_file):
    """
    清理和整理 YAML 文件：
    1. 去重（同一个编码下的重复词）
    2. 格式化清理（去除空行、注释等）
    3. 按词数从多到少排序（每个编码下的词按数量排序）
    
    Args:
        txt_file: YAML 文件路径
    
    Returns:
        bool: 是否成功
    """
    if not os.path.exists(txt_file):
        print(f'错误: YAML 文件不存在: {txt_file}')
        return False
    
    print('正在整理 YAML 文件...')
    print('=' * 60)
    
    # 创建备份
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_file = f'{txt_file}.backup.{timestamp}'
    shutil.copy(txt_file, backup_file)
    print(f'创建备份文件: {backup_file}')
    
    # 读取并处理文件
    key_to_words = {}  # key -> list of words (去重)
    total_lines = 0
    processed_lines = 0
    
    with open(txt_file, 'r', encoding='utf-8') as f:
        for line in f:
            total_lines += 1
            line = line.rstrip('\n').strip()
            
            # 跳过空行和注释
            if not line or line.startswith('#'):
                continue
            
            # 处理转义空格
            if '\\ ' in line:
                parts = line.replace('\\ ', '_ZFVimIM_space_').split()
                words = [w.replace('_ZFVimIM_space_', ' ') for w in parts[1:]]
            else:
                parts = line.split()
                words = parts[1:]
            
            if len(parts) < 2:
                continue
            
            key = parts[0]
            processed_lines += 1
            
            # 去重：使用列表存储词，检查是否已存在
            if key not in key_to_words:
                key_to_words[key] = []
            
            # 添加到列表（保持顺序，但去重）
            for word in words:
                word = word.strip()
                if word and word not in key_to_words[key]:
                    key_to_words[key].append(word)
    
    print(f'读取完成: 总行数 {total_lines}, 处理行数 {processed_lines}')
    print(f'发现 {len(key_to_words)} 个编码')
    
    # 统计去重情况
    total_words = sum(len(words) for words in key_to_words.values())
    print(f'总词数（去重后）: {total_words}')
    
    # 按词数从多到少排序
    sorted_keys = sorted(key_to_words.items(), key=lambda x: len(x[1]), reverse=True)
    if sorted_keys:
        max_words = len(sorted_keys[0][1])
        print(f'排序完成: 词数最多的编码有 {max_words} 个词')
    
    # 写入整理后的文件
    print('正在写入整理后的文件...')
    with open(txt_file, 'w', encoding='utf-8') as f:
        for key, words in sorted_keys:
            if not words:
                continue
            # 转义空格
            escaped_words = [w.replace(' ', '\\ ') for w in words]
            f.write(f'{key} {" ".join(escaped_words)}\n')
    
    print(f'整理完成！')
    print(f'备份文件: {backup_file}')
    print('=' * 60)
    return True


def clear_database(db_file):
    """清空数据库中的所有数据"""
    if not os.path.exists(db_file):
        print(f'数据库文件不存在，将创建新文件: {db_file}')
        return True
    
    try:
        conn = sqlite3.connect(db_file)
        cursor = conn.cursor()
        
        # 删除所有数据
        cursor.execute('DELETE FROM words')
        
        # 重置自增计数器（如果存在的话）
        try:
            cursor.execute('DELETE FROM sqlite_sequence WHERE name="words"')
        except sqlite3.OperationalError:
            # sqlite_sequence 表可能不存在，忽略错误
            pass
        
        conn.commit()
        conn.close()
        
        print(f'已清空数据库: {db_file}')
        return True
    except Exception as e:
        print(f'清空数据库时出错: {e}')
        return False


def init_database(db_file):
    """初始化数据库表结构（如果不存在）"""
    try:
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
        conn.close()
        return True
    except Exception as e:
        print(f'初始化数据库时出错: {e}')
        return False


def import_txt_to_db(txt_file, db_file):
    """从 YAML 文件导入数据到数据库"""
    
    if not os.path.exists(txt_file):
        print(f'错误: YAML 文件不存在: {txt_file}')
        return False
    
    # Step 1: 清理和整理 YAML 文件
    if not clean_and_sort_txt_file(txt_file):
        print('错误: YAML 文件整理失败')
        return False
    
    print()
    
    # 初始化数据库
    if not init_database(db_file):
        return False
    
    # 清空数据库
    if not clear_database(db_file):
        return False
    
    # 读取整理后的 YAML 文件并导入
    print('正在读取整理后的 YAML 文件...')
    conn = sqlite3.connect(db_file)
    cursor = conn.cursor()
    
    # 准备批量插入
    batch_size = 10000
    batch = []
    total_lines = 0
    total_words = 0
    
    try:
        with open(txt_file, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                
                total_lines += 1
                
                # 格式: key word1 word2 ...
                # 处理转义空格
                line_tmp = line.replace('\\ ', '_ZFVimIM_space_')
                parts = line_tmp.split()
                
                if len(parts) <= 1:
                    # 只有key，没有词，跳过
                    continue
                
                key = parts[0]
                words = parts[1:]
                
                # 处理每个词，按原始顺序设置词频
                # 根据词的数量动态计算词频：第一个词频率最高（等于词数），依次递减
                word_count = len(words)
                
                for idx, word_part in enumerate(words):
                    word = word_part.replace('_ZFVimIM_space_', ' ')
                    total_words += 1
                    
                    # 按原始顺序设置词频：第一个词频率 = 词数，依次递减到 1
                    # 例如：10个词 -> 10, 9, 8, 7, 6, 5, 4, 3, 2, 1
                    frequency = word_count - idx
                    
                    # 添加到批量插入列表
                    batch.append((key, word, frequency))
                    
                    # 批量插入
                    if len(batch) >= batch_size:
                        cursor.executemany(
                            'INSERT OR IGNORE INTO words (key, word, frequency) VALUES (?, ?, ?)',
                            batch
                        )
                        batch = []
        
        # 插入剩余的数据
        if batch:
            cursor.executemany(
                'INSERT OR IGNORE INTO words (key, word, frequency) VALUES (?, ?, ?)',
                batch
            )
        
        conn.commit()
        
        # 统计导入结果
        cursor.execute('SELECT COUNT(*) FROM words')
        db_count = cursor.fetchone()[0]
        
        conn.close()
        
        print()
        print('=' * 60)
        print('导入完成！')
        print('=' * 60)
        print(f'YAML 文件行数: {total_lines}')
        print(f'YAML 文件词数: {total_words}')
        print(f'数据库记录数: {db_count}')
        print()
        
        if db_count == total_words:
            print('✅ 数据库和 YAML 文件内容完全一致')
        else:
            print(f'⚠️  注意: 数据库记录数 ({db_count}) 与 TXT 词数 ({total_words}) 不一致')
            print('   可能原因: 存在重复的 (key, word) 组合')
        
        print('=' * 60)
        
        return True
        
    except Exception as e:
        conn.rollback()
        conn.close()
        print(f'导入时出错: {e}')
        return False


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    
    txt_file = sys.argv[1]
    
    # 如果没有指定数据库文件，自动生成（将 .yaml 替换为 .db）
    if len(sys.argv) >= 3:
        db_file = sys.argv[2]
    else:
        if txt_file.endswith('.yaml'):
            db_file = txt_file[:-4] + '.db'
        else:
            db_file = txt_file + '.db'
    
    print(f'YAML 文件: {txt_file}')
    print(f'数据库文件: {db_file}')
    print()
    
    success = import_txt_to_db(txt_file, db_file)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()

