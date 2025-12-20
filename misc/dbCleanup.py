#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
词库整理脚本
功能：按词数量从多到少排序（词多的在前面，少的在后面）
"""

import io
import os
import shutil
import sys

def loadDictionary(dbFile):
    """加载词库文件（TXT 格式：key word1 word2 ...）"""
    entries_dict = {}  # 使用字典来合并相同编码的条目
    
    try:
        with io.open(dbFile, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.rstrip('\n').strip()
                # 跳过空行和注释
                if not line or line.startswith('#'):
                    continue
                
                # 处理转义空格
                if '\\ ' in line:
                    parts = line.replace('\\ ', '_ZFVimIM_space_').split()
                    if len(parts) > 0:
                        key = parts[0]
                        words = [w.replace('_ZFVimIM_space_', ' ') for w in parts[1:]]
                    else:
                        continue
                else:
                    parts = line.split()
                    if len(parts) > 0:
                        key = parts[0]
                        words = parts[1:]
                    else:
                        continue
                
                # 过滤空词并规范空格（去除首尾空格）
                words = [w.strip() for w in words if w.strip()]
                if len(words) > 0:
                    # 合并相同编码的条目，去重
                    if key in entries_dict:
                        # 合并词列表并去重
                        existing_words = entries_dict[key]['words']
                        for word in words:
                            if word not in existing_words:
                                existing_words.append(word)
                    else:
                        entries_dict[key] = {
                            'key': key,
                            'words': words
                        }
    except Exception as e:
        print("Error loading dictionary: " + str(e), file=sys.stderr)
        return None
    
    # 转换为列表
    entries = list(entries_dict.values())
    return entries

def saveDictionary(entries, dbFile, cachePath):
    """保存词库文件，按词数量从多到少排序"""
    # 按词数量从多到少排序
    entries.sort(key=lambda x: len(x['words']), reverse=True)
    
    # 写入临时文件
    tmpFile = os.path.join(cachePath, 'dbFileTmp')
    try:
        with io.open(tmpFile, 'w', encoding='utf-8') as f:
            for entry in entries:
                # 去重词列表（再次确保）
                words = list(dict.fromkeys(entry['words']))  # 保持顺序的去重
                
                # 重建行：key word1 word2 ...
                # 规范空格：词中包含空格的需要转义
                line = entry['key']
                for word in words:
                    # 如果词中包含空格，需要转义
                    escaped_word = word.replace(' ', '\\ ')
                    line += ' ' + escaped_word
                f.write(line + '\n')
        
        # 移动到目标文件
        shutil.move(tmpFile, dbFile)
    except Exception as e:
        print("Error saving dictionary: " + str(e), file=sys.stderr)
        return False
    
    return True

def cleanupDictionary(dbFile, cachePath):
    """整理词库的主函数"""
    if not os.path.isfile(dbFile):
        print("Dictionary file not found: " + dbFile, file=sys.stderr)
        return False
    
    # 加载词库
    entries = loadDictionary(dbFile)
    if entries is None:
        return False
    
    print(f"Loaded {len(entries)} entries", file=sys.stderr)
    
    # 保存整理后的词库
    return saveDictionary(entries, dbFile, cachePath)

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: dbCleanup.py <dbFile> <cachePath>", file=sys.stderr)
        sys.exit(1)
    
    dbFile = sys.argv[1]
    cachePath = sys.argv[2]
    
    if not os.path.isdir(cachePath):
        try:
            os.makedirs(cachePath)
        except Exception as e:
            print("Error creating cache directory: " + str(e), file=sys.stderr)
            sys.exit(1)
    
    success = cleanupDictionary(dbFile, cachePath)
    if success:
        print("Dictionary sorted successfully", file=sys.stderr)
    sys.exit(0 if success else 1)
