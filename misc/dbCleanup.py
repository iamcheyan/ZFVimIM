#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
词库整理脚本
功能：
1. 按词数量从多到少排序（词多的在前面，少的在后面）
2. 清理重复词语
3. 规范格式（去除首尾空格、空词等）
4. 删除无效条目（空编码、空词列表等）
5. 合并相同编码的条目
"""

import io
import os
import re
import shutil
import sys

def isValidKey(key):
    """检查编码是否有效"""
    if not key or not key.strip():
        return False
    # 编码应该只包含小写字母和数字，不能为空
    if not re.match(r'^[a-z0-9]+$', key.strip()):
        return False
    return True

def isValidWord(word):
    """检查词是否有效"""
    if not word or not word.strip():
        return False
    # 词不能只包含空白字符
    if word.strip() == '':
        return False
    # 词不能包含控制字符（除了正常的空格）
    if re.search(r'[\x00-\x08\x0b-\x0c\x0e-\x1f\x7f]', word):
        return False
    return True

def normalizeWord(word):
    """规范化词（去除首尾空格，但保留中间空格）"""
    if not word:
        return ''
    # 去除首尾空白字符
    word = word.strip()
    # 规范化中间的空格（多个空格合并为一个，但保留转义的空格）
    # 这里不处理转义空格，因为它们在文件中是 \ 
    return word

def loadDictionary(dbFile):
    """加载词库文件（TXT 格式：key word1 word2 ...）"""
    entries_dict = {}  # 使用字典来合并相同编码的条目
    invalid_count = 0
    
    # 检查文件扩展名
    if not dbFile.lower().endswith('.yaml'):
        print("Error: dbCleanup.py only processes .yaml files, got: " + dbFile, file=sys.stderr)
        return None
    
    try:
        with io.open(dbFile, 'r', encoding='utf-8', errors='replace') as f:
            for line_num, line in enumerate(f, 1):
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
                        invalid_count += 1
                        continue
                else:
                    parts = line.split()
                    if len(parts) > 0:
                        key = parts[0]
                        words = parts[1:]
                    else:
                        invalid_count += 1
                        continue
                
                # 验证编码
                if not isValidKey(key):
                    invalid_count += 1
                    continue
                
                # 规范化编码（去除首尾空格，转小写）
                key = key.strip().lower()
                
                # 过滤和规范化词
                valid_words = []
                for word in words:
                    word = normalizeWord(word)
                    if isValidWord(word):
                        # 去重（在同一行内）
                        if word not in valid_words:
                            valid_words.append(word)
                
                # 如果有效词列表为空，跳过这个条目
                if len(valid_words) == 0:
                    invalid_count += 1
                    continue
                
                # 合并相同编码的条目，去重
                if key in entries_dict:
                    # 合并词列表并去重
                    existing_words = entries_dict[key]['words']
                    for word in valid_words:
                        if word not in existing_words:
                            existing_words.append(word)
                else:
                    entries_dict[key] = {
                        'key': key,
                        'words': valid_words
                    }
    except Exception as e:
        print("Error loading dictionary: " + str(e), file=sys.stderr)
        return None
    
    if invalid_count > 0:
        print(f"Removed {invalid_count} invalid entries", file=sys.stderr)
    
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
                # 再次验证和清理
                key = entry['key'].strip()
                if not isValidKey(key):
                    continue
                
                # 去重词列表（再次确保）
                words = []
                seen_words = set()
                for word in entry['words']:
                    word = normalizeWord(word)
                    if isValidWord(word) and word not in seen_words:
                        words.append(word)
                        seen_words.add(word)
                
                # 如果词列表为空，跳过
                if len(words) == 0:
                    continue
                
                # 重建行：key word1 word2 ...
                # 规范空格：词中包含空格的需要转义
                line = key
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
    
    # 只处理 .yaml 文件，忽略二进制文件（如 .db）
    if not dbFile.lower().endswith('.yaml'):
        print("Warning: dbCleanup.py only processes .yaml files, skipping: " + dbFile, file=sys.stderr)
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
