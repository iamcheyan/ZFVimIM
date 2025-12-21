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


def remove_words_from_db(db_file, words):
    """
    从数据库删除词
    
    Args:
        db_file: SQLite 数据库文件路径
        words: 要删除的词列表
    """
    if not os.path.exists(db_file):
        print(f'错误: 数据库文件不存在: {db_file}')
        return False
    
    try:
        conn = sqlite3.connect(db_file)
        cursor = conn.cursor()
        
        removed_count = {}
        
        for word in words:
            # 删除所有匹配该词的记录
            cursor.execute('DELETE FROM words WHERE word = ?', (word,))
            count = cursor.rowcount
            removed_count[word] = count
        
        conn.commit()
        
        # 输出结果
        result = []
        for word in words:
            count = removed_count.get(word, 0)
            if count > 0:
                result.append(f'{word}({count})')
            else:
                result.append(f'{word}(0)')
        
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
        sys.exit(1)
    
    db_file = sys.argv[1]
    words = sys.argv[2:]
    
    success = remove_words_from_db(db_file, words)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()

