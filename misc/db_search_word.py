#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
在数据库中搜索词，返回所有匹配的编码信息
"""

import sys
import os
import sqlite3
import json

def search_word(db_file, word):
    """
    在数据库中搜索词，返回所有匹配的编码信息
    
    Args:
        db_file: 数据库文件路径
        word: 要搜索的词
    
    Returns:
        匹配结果的 JSON 字符串
    """
    if not os.path.isfile(db_file):
        return json.dumps({'error': 'Database file not found'}, ensure_ascii=False)
    
    try:
        conn = sqlite3.connect(db_file)
        cursor = conn.cursor()
        
        # 搜索包含该词的所有记录
        cursor.execute('SELECT key, word, frequency FROM words WHERE word = ? ORDER BY key, frequency DESC', (word,))
        rows = cursor.fetchall()
        conn.close()
        
        if not rows:
            return json.dumps({'found': False, 'word': word, 'results': []}, ensure_ascii=False)
        
        # 组织结果
        results = []
        for key, word_found, frequency in rows:
            results.append({
                'key': key,
                'word': word_found,
                'frequency': frequency
            })
        
        return json.dumps({
            'found': True,
            'word': word,
            'count': len(results),
            'results': results
        }, ensure_ascii=False)
        
    except Exception as e:
        return json.dumps({'error': str(e)}, ensure_ascii=False)

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print(json.dumps({'error': 'Usage: python3 db_search_word.py <db_file> <word>'}, ensure_ascii=False))
        sys.exit(1)
    
    db_file = sys.argv[1]
    word = sys.argv[2]
    
    result = search_word(db_file, word)
    print(result)
    
    # Also output human-readable format for easier debugging
    try:
        data = json.loads(result)
        if data.get('found'):
            print(f"\n词: {data['word']}", file=sys.stderr)
            print(f"编码数量: {data['count']}", file=sys.stderr)
            for item in data['results']:
                print(f"  编码: {item['key']}  频率: {item['frequency']}", file=sys.stderr)
        elif 'error' in data:
            print(f"错误: {data['error']}", file=sys.stderr)
        else:
            print(f"未找到词: {word}", file=sys.stderr)
    except:
        pass  # Ignore errors in human-readable output

