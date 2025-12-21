#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
从数据库删除词

用法:
    python3 db_remove_word.py <db_file> <word1> [word2] [word3] ...

示例:
    python3 db_remove_word.py dict/sbzr.userdb.db 测试
    python3 db_remove_word.py dict/sbzr.userdb.db 词1 词2 词3
"""

import sys
import os
import sqlite3


def remove_words_from_db(db_file, words, fuzzy=False):
    """
    从数据库删除词
    
    Args:
        db_file: SQLite 数据库文件路径
        words: 要删除的词列表
        fuzzy: 是否使用模糊匹配（包含匹配）
    """
    if not os.path.exists(db_file):
        print(f'错误: 数据库文件不存在: {db_file}')
        return False
    
    try:
        conn = sqlite3.connect(db_file)
        cursor = conn.cursor()
        
        removed_count = {}
        removed_words = {}  # 记录实际删除的词
        total_records = 0  # 记录实际删除的数据库记录数
        
        for word in words:
            if fuzzy:
                # 模糊匹配：删除所有包含该词的记录
                cursor.execute('SELECT word FROM words WHERE word LIKE ?', (f'%{word}%',))
                matching_words = [row[0] for row in cursor.fetchall()]
                
                total_count = 0
                for matching_word in matching_words:
                    cursor.execute('DELETE FROM words WHERE word = ?', (matching_word,))
                    count = cursor.rowcount
                    total_count += count
                    total_records += count
                    if matching_word not in removed_words:
                        removed_words[matching_word] = 0
                    removed_words[matching_word] += count
                
                removed_count[word] = total_count
            else:
                # 精确匹配：删除完全匹配该词的记录
                cursor.execute('DELETE FROM words WHERE word = ?', (word,))
                count = cursor.rowcount
                removed_count[word] = count
                if count > 0:
                    removed_words[word] = count
        
        conn.commit()
        
        # 输出结果
        result = []
        for word in words:
            count = removed_count.get(word, 0)
            if count > 0:
                result.append(f'{word}({count})')
            else:
                result.append(f'{word}(0)')
        
        # 如果有模糊匹配，也输出实际删除的词列表和记录数
        if fuzzy and removed_words:
            word_list = list(removed_words.keys())[:20]  # 最多显示20个
            if len(removed_words) > 20:
                word_list.append(f'... (共 {len(removed_words)} 个词)')
            result.append('WORDS:' + ','.join(word_list))
            # 添加总记录数信息
            result.append(f'RECORDS:{total_records}')
        
        print('OK:' + ':'.join(result))
        return True
        
    except Exception as e:
        print(f'错误: {e}')
        return False
    finally:
        if 'conn' in locals():
            conn.close()


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        print('\n模糊匹配模式:')
        print('    python3 db_remove_word.py <db_file> --fuzzy <word1> [word2] ...')
        print('    python3 db_remove_word.py <db_file> -f <word1> [word2] ...')
        sys.exit(1)
    
    db_file = sys.argv[1]
    fuzzy = False
    words = []
    
    # 解析参数
    for arg in sys.argv[2:]:
        if arg in ['--fuzzy', '-f']:
            fuzzy = True
        else:
            words.append(arg)
    
    if not words:
        print('错误: 请提供要删除的词')
        sys.exit(1)
    
    success = remove_words_from_db(db_file, words, fuzzy)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()

