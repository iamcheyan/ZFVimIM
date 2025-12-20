#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
词库整理脚本
功能：
1. 合并重复编码为一条信息
2. 从多到少排序（按词的数量）
3. 清理格式，多余空行
4. 清理只有编码没有字或词的条目
"""

import io
import os
import re
import shutil
import sys

try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False

ZFVimIM_KEY_S_MAIN = '#'
ZFVimIM_KEY_S_SUB = ','
ZFVimIM_KEY_SR_MAIN = '_ZFVimIM_m_'
ZFVimIM_KEY_SR_SUB = '_ZFVimIM_s_'

def dbItemDecode(dbItemEncoded):
    """解码词库条目"""
    split = dbItemEncoded.split(ZFVimIM_KEY_S_MAIN)
    if len(split) < 2:
        return None
    wordList = split[1].split(ZFVimIM_KEY_S_SUB)
    for i in range(len(wordList)):
        wordList[i] = re.sub(ZFVimIM_KEY_SR_SUB, ZFVimIM_KEY_S_SUB,
                re.sub(ZFVimIM_KEY_SR_MAIN, ZFVimIM_KEY_S_MAIN, wordList[i])
            )
    countList = []
    if len(split) >= 3:
        for cnt in split[2].split(ZFVimIM_KEY_S_SUB):
            countList.append(int(cnt))
    while len(countList) < len(wordList):
        countList.append(0)
    return {
        'key' : split[0],
        'wordList' : wordList,
        'countList' : countList,
    }

def dbItemEncode(dbItem):
    """编码词库条目"""
    dbItemEncoded = dbItem['key']
    dbItemEncoded += ZFVimIM_KEY_S_MAIN
    for i in range(len(dbItem['wordList'])):
        if i != 0:
            dbItemEncoded += ZFVimIM_KEY_S_SUB
        dbItemEncoded += re.sub(ZFVimIM_KEY_S_SUB, ZFVimIM_KEY_SR_SUB,
                re.sub(ZFVimIM_KEY_S_MAIN, ZFVimIM_KEY_SR_MAIN, dbItem['wordList'][i])
            )
    iEnd = len(dbItem['countList']) - 1
    while iEnd >= 0:
        if dbItem['countList'][iEnd] > 0:
            break
        iEnd -= 1
    i = 0
    while i <= iEnd:
        if i == 0:
            dbItemEncoded += ZFVimIM_KEY_S_MAIN
        else:
            dbItemEncoded += ZFVimIM_KEY_S_SUB
        dbItemEncoded += str(dbItem['countList'][i])
        i += 1
    return dbItemEncoded

def loadDictionary(dbFile):
    """加载词库文件"""
    pyMap = {}
    isYaml = dbFile.endswith('.yaml') or dbFile.endswith('.yml')
    
    if isYaml and HAS_YAML:
        # Load from YAML format
        try:
            with io.open(dbFile, 'r', encoding='utf-8') as dbFilePtr:
                yamlData = yaml.safe_load(dbFilePtr)
                if yamlData and isinstance(yamlData, dict):
                    for key, wordList in yamlData.items():
                        if not isinstance(wordList, list):
                            wordList = [wordList]
                        # 清理：跳过只有编码没有字或词的条目
                        wordList = [w for w in wordList if w and w.strip()]
                        if len(wordList) <= 0:
                            continue
                        key = re.sub('[^a-z]', '', key.lower())
                        if key == '':
                            continue
                        # 合并重复编码
                        if key[0] not in pyMap:
                            pyMap[key[0]] = {}
                        if key in pyMap[key[0]]:
                            dbItem = dbItemDecode(pyMap[key[0]][key])
                            for word in wordList:
                                if word not in dbItem['wordList']:
                                    dbItem['wordList'].append(word)
                        else:
                            dbItem = {
                                'key' : key,
                                'wordList' : wordList,
                                'countList' : [],
                            }
                        pyMap[key[0]][key] = dbItemEncode(dbItem)
        except Exception as e:
            print("Error loading YAML: " + str(e), file=sys.stderr)
            return None
    else:
        # Load from TXT format
        try:
            with io.open(dbFile, 'r', encoding='utf-8') as dbFilePtr:
                for line in dbFilePtr:
                    line = line.rstrip('\n').strip()
                    # 跳过空行和注释
                    if not line or line.startswith('#'):
                        continue
                    if line.find('\\ ') >= 0:
                        wordListTmp = line.replace('\\ ', '_ZFVimIM_space_').split()
                        if len(wordListTmp) > 0:
                            key = wordListTmp[0]
                            del wordListTmp[0]
                        wordList = []
                        for word in wordListTmp:
                            word = word.replace('_ZFVimIM_space_', ' ').strip()
                            if word:
                                wordList.append(word)
                    else:
                        wordList = line.split()
                        if len(wordList) > 0:
                            key = wordList[0]
                            del wordList[0]
                        wordList = [w.strip() for w in wordList if w.strip()]
                    # 清理：跳过只有编码没有字或词的条目
                    if len(wordList) <= 0:
                        continue
                    key = re.sub('[^a-z]', '', key.lower())
                    if key == '':
                        continue
                    # 合并重复编码
                    if key[0] not in pyMap:
                        pyMap[key[0]] = {}
                    if key in pyMap[key[0]]:
                        dbItem = dbItemDecode(pyMap[key[0]][key])
                        for word in wordList:
                            if word not in dbItem['wordList']:
                                dbItem['wordList'].append(word)
                    else:
                        dbItem = {
                            'key' : key,
                            'wordList' : wordList,
                            'countList' : [],
                        }
                    pyMap[key[0]][key] = dbItemEncode(dbItem)
        except Exception as e:
            print("Error loading TXT: " + str(e), file=sys.stderr)
            return None
    
    return pyMap

def saveDictionary(pyMap, dbFile, cachePath):
    """保存词库文件，按词数量从多到少排序"""
    isYaml = dbFile.endswith('.yaml') or dbFile.endswith('.yml')
    
    # 准备所有条目，合并重复编码
    # 不按字母顺序遍历，直接收集所有条目
    mergedMap = {}
    for c in pyMap.keys():
        for key, dbItemEncoded in pyMap[c].items():
            dbItem = dbItemDecode(dbItemEncoded)
            if dbItem is None:
                continue
            # 再次清理：确保没有空词
            dbItem['wordList'] = [w for w in dbItem['wordList'] if w and w.strip()]
            if len(dbItem['wordList']) <= 0:
                continue  # 跳过只有编码没有字或词的条目
            
            # 合并重复编码：去重词列表
            if key in mergedMap:
                existingItem = mergedMap[key]
                for word in dbItem['wordList']:
                    if word not in existingItem['wordList']:
                        existingItem['wordList'].append(word)
            else:
                mergedMap[key] = dbItem
    
    # 转换为列表并按词数量从多到少排序（只按数量，不按字母）
    allItems = list(mergedMap.values())
    # 按词数量从多到少排序，相同数量时保持原有顺序
    allItems.sort(key=lambda x: len(x['wordList']), reverse=True)
    
    if isYaml and HAS_YAML:
        # Save as YAML format
        yamlData = {}
        for dbItem in allItems:
            yamlData[dbItem['key']] = dbItem['wordList']
        
        # Write to temporary file first
        tmpFile = os.path.join(cachePath, 'dbFileTmp')
        try:
            with io.open(tmpFile, 'w', encoding='utf-8') as dbFilePtr:
                yaml.dump(yamlData, dbFilePtr, allow_unicode=True, default_flow_style=False, sort_keys=False)
            shutil.move(tmpFile, dbFile)
        except Exception as e:
            print("Error saving YAML: " + str(e), file=sys.stderr)
            return False
    else:
        # Save as TXT format
        lines = []
        for dbItem in allItems:
            line = dbItem['key']
            for word in dbItem['wordList']:
                line += ' ' + word.replace(' ', '\\ ')
            lines.append(line)
        
        tmpFile = os.path.join(cachePath, 'dbFileTmp')
        try:
            with io.open(tmpFile, 'w', encoding='utf-8') as dbFilePtr:
                dbFilePtr.write('\n'.join(lines))
                if lines:  # 只在有内容时添加最后的换行
                    dbFilePtr.write('\n')
            shutil.move(tmpFile, dbFile)
        except Exception as e:
            print("Error saving TXT: " + str(e), file=sys.stderr)
            return False
    
    return True

def cleanupDictionary(dbFile, cachePath):
    """整理词库的主函数"""
    if not os.path.isfile(dbFile):
        print("Dictionary file not found: " + dbFile, file=sys.stderr)
        return False
    
    # 加载词库
    pyMap = loadDictionary(dbFile)
    if pyMap is None:
        return False
    
    # 保存整理后的词库
    return saveDictionary(pyMap, dbFile, cachePath)

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
    sys.exit(0 if success else 1)
