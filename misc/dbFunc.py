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


DB_FILE_LINE_BUFFER = 2000


if sys.version_info >= (3, 0):
    def dbMapIter(dbMapDict):
        return dbMapDict.items()
else:
    def dbMapIter(dbMapDict):
        return dbMapDict.iteritems()


def dbWordIndex(wordList, word):
    try:
        return wordList.index(word)
    except:
        return -1


ZFVimIM_dbItemReorderThreshold = 1
def dbItemReorderFunc(item1, item2):
    if (item2['count'] - item1['count']) - ZFVimIM_dbItemReorderThreshold > 0:
        return 1
    elif (item1['count'] - item2['count']) - ZFVimIM_dbItemReorderThreshold > 0:
        return -1
    else:
        return 0
def dbItemReorder(dbItem):
    tmp = []
    i = 0
    iEnd = len(dbItem['wordList'])
    while i < iEnd:
        tmp.append({
            'word' : dbItem['wordList'][i],
            'count' : dbItem['countList'][i],
        })
        i += 1
    if sys.version_info >= (3, 0):
        import functools
        tmp.sort(key = functools.cmp_to_key(dbItemReorderFunc))
    else:
        tmp.sort(cmp = dbItemReorderFunc)
    dbItem['wordList'] = []
    dbItem['countList'] = []
    for item in tmp:
        dbItem['wordList'].append(item['word'])
        dbItem['countList'].append(item['count'])


def dbItemDecode(dbItemEncoded):
    split = dbItemEncoded.split(ZFVimIM_KEY_S_MAIN)
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


# since python has low performance on List search,
# we use different db struct with vim side
#
# return pyMap: {
#   'a' : {
#     'a' : 'a#AAA,BBB#3,2',
#     'ai' : 'ai#CCC,DDD#3',
#   },
#   'c' : {
#     'ceshi' : 'ceshi#EEE',
#   },
# }
def detectFileFormatPy(dbFile):
    """检测文件格式：YAML 或 TXT"""
    try:
        with io.open(dbFile, 'r', encoding='utf-8') as f:
            yamlCount = 0
            txtCount = 0
            checked = 0
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                # Check if line looks like YAML format (key: value)
                if ':' in line and line.split(':')[0].strip().isalpha():
                    # Try to parse as YAML
                    try:
                        yamlCount += 1
                    except:
                        pass
                # Check if line looks like TXT format (key word1 word2 ...)
                elif line and line[0].islower() and ' ' in line:
                    txtCount += 1
                checked += 1
                if checked >= 10:
                    break
            # If more YAML-like lines, return 'yaml', otherwise 'txt'
            if yamlCount > txtCount:
                return 'yaml'
            else:
                return 'txt'
    except:
        return 'yaml'  # Default to YAML

def dbLoadPy(dbFile, dbCountFile):
    pyMap = {}
    # load db
    # Detect actual file format (not just by extension)
    fileFormat = detectFileFormatPy(dbFile)
    
    if fileFormat == 'txt':
        # Load from TXT format (key word1 word2 ...)
        with io.open(dbFile, 'r', encoding='utf-8') as dbFilePtr:
            for line in dbFilePtr:
                line = line.rstrip('\n').strip()
                # Skip empty lines and comments
                if not line or line.startswith('#'):
                    continue
                # Handle escaped spaces
                if '\\ ' in line:
                    wordListTmp = line.replace('\\ ', '_ZFVimIM_space_').split()
                    if len(wordListTmp) > 0:
                        key = wordListTmp[0]
                        wordList = [w.replace('_ZFVimIM_space_', ' ') for w in wordListTmp[1:]]
                    else:
                        continue
                else:
                    wordList = line.split()
                    if len(wordList) > 0:
                        key = wordList[0]
                        wordList = wordList[1:]
                    else:
                        continue
                # Filter empty words
                wordList = [w for w in wordList if w.strip()]
                if len(wordList) > 0 and key and key[0].islower() and key.isalpha():
                    if key[0] not in pyMap:
                        pyMap[key[0]] = {}
                    # Merge with existing entries if key already exists
                    if key in pyMap[key[0]]:
                        existingItem = dbItemDecode(pyMap[key[0]][key])
                        for word in wordList:
                            if word not in existingItem['wordList']:
                                existingItem['wordList'].append(word)
                                existingItem['countList'].append(0)
                        pyMap[key[0]][key] = dbItemEncode(existingItem)
                    else:
                        pyMap[key[0]][key] = dbItemEncode({
                            'key' : key,
                            'wordList' : wordList,
                            'countList' : [],
                        })
    else:
        # Load from YAML format
        if not HAS_YAML:
            raise ValueError("YAML library not available. Please install PyYAML.")
        
        with io.open(dbFile, 'r', encoding='utf-8') as dbFilePtr:
            yamlData = yaml.safe_load(dbFilePtr)
            if yamlData and isinstance(yamlData, dict):
                for key, wordList in yamlData.items():
                    if not isinstance(wordList, list):
                        wordList = [wordList]
                    if len(wordList) > 0:
                        if key[0] not in pyMap:
                            pyMap[key[0]] = {}
                        # Merge with existing entries if key already exists
                        if key in pyMap[key[0]]:
                            existingItem = dbItemDecode(pyMap[key[0]][key])
                            for word in wordList:
                                if word not in existingItem['wordList']:
                                    existingItem['wordList'].append(word)
                                    existingItem['countList'].append(0)
                            pyMap[key[0]][key] = dbItemEncode(existingItem)
                        else:
                            pyMap[key[0]][key] = dbItemEncode({
                                'key' : key,
                                'wordList' : wordList,
                                'countList' : [],
                            })
    # load word count
    if len(dbCountFile) > 0 and os.path.isfile(dbCountFile) and os.access(dbCountFile, os.R_OK):
        with io.open(dbCountFile, 'r', encoding='utf-8') as dbCountFilePtr:
            for line in dbCountFilePtr:
                line = line.rstrip('\n')
                countTextList = line.split(' ')
                if len(countTextList) <= 1:
                    continue
                key = countTextList[0]
                dbItemEncoded = pyMap.get(key[0], {}).get(key, '')
                if dbItemEncoded == '':
                    continue
                dbItem = dbItemDecode(dbItemEncoded)
                wordListLen = len(dbItem['wordList'])
                for i in range(len(countTextList) - 1):
                    if i >= wordListLen:
                        break
                    dbItem['countList'][i] = int(countTextList[i + 1])
                dbItemReorder(dbItem)
                pyMap[key[0]][key] = dbItemEncode(dbItem)
    return pyMap
    # end of dbLoadPy


# similar to dbFunc.dbLoad()
# but transform db file to formal format:
# * ensure key only contains a-z
# * sort lines
# * transform:
#     key a1 a2
#     key a1 a3
#   to:
#     key a1 a2 a3
def dbLoadNormalizePy(dbFile):
    pyMap = {}
    # load db
    # Check if file is YAML format
    isYaml = dbFile.endswith('.yaml') or dbFile.endswith('.yml')
    
    if not isYaml:
        raise ValueError("Only .yaml and .yml files are supported. File: " + dbFile)
    
    if not HAS_YAML:
        raise ValueError("YAML library not available. Please install PyYAML.")
    
    # Load from YAML format
    with io.open(dbFile, 'r', encoding='utf-8') as dbFilePtr:
        yamlData = yaml.safe_load(dbFilePtr)
        if yamlData and isinstance(yamlData, dict):
            for key, wordList in yamlData.items():
                if not isinstance(wordList, list):
                    wordList = [wordList]
                if len(wordList) <= 0:
                    continue
                key = re.sub('[^a-z]', '', key)
                if key == '':
                    continue
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
    return pyMap
    # end of dbLoadNormalizePy


def dbSavePy(pyMap, dbFile, dbCountFile, cachePath):
    # Check if file should be saved as YAML format
    isYaml = dbFile.endswith('.yaml') or dbFile.endswith('.yml')
    
    if not isYaml:
        raise ValueError("Only .yaml and .yml files are supported. File: " + dbFile)
    
    if not HAS_YAML:
        raise ValueError("YAML library not available. Please install PyYAML.")
    
    # Save as YAML format
    yamlData = {}
    for c in pyMap.keys():
        for key, dbItemEncoded in sorted(dbMapIter(pyMap[c])):
            dbItem = dbItemDecode(dbItemEncoded)
            yamlData[dbItem['key']] = dbItem['wordList']
    
    # Write to temporary file first
    tmpFile = cachePath + '/dbFileTmp'
    with io.open(tmpFile, 'w', encoding='utf-8') as dbFilePtr:
        yaml.dump(yamlData, dbFilePtr, allow_unicode=True, default_flow_style=False, sort_keys=True)
    shutil.move(tmpFile, dbFile)
    
    # Save count file if needed (still as text format for compatibility)
    if len(dbCountFile) > 0:
        dbCountFilePtr = io.open(cachePath + '/dbCountFileTmp', 'wb')
        countLines = []
        for c in pyMap.keys():
            for key, dbItemEncoded in sorted(dbMapIter(pyMap[c])):
                dbItem = dbItemDecode(dbItemEncoded)
                countLine = dbItem['key']
                for cnt in dbItem['countList']:
                    if cnt <= 0:
                        break
                    countLine += ' '
                    countLine += str(cnt)
                if countLine != key:
                    countLines.append(countLine)
                if len(countLines) >= DB_FILE_LINE_BUFFER:
                    dbCountFilePtr.write(('\n'.join(countLines) + '\n').encode('utf-8'))
                    countLines = []
        if len(countLines) > 0:
            dbCountFilePtr.write(('\n'.join(countLines) + '\n').encode('utf-8'))
        dbCountFilePtr.close()
        shutil.move(cachePath + '/dbCountFileTmp', dbCountFile)
    # end of dbSavePy


def dbEditApplyPy(pyMap, dbEdit):
    for e in dbEdit:
        key = e['key']
        word = e['word']
        if e['action'] == 'add':
            if key[0] not in pyMap:
                pyMap[key[0]] = []
            dbItemEncoded = pyMap[key[0]].get(key, '')
            if dbItemEncoded != '':
                dbItem = dbItemDecode(dbItemEncoded)
                wordIndex = dbWordIndex(dbItem['wordList'], word)
                if wordIndex >= 0:
                    dbItem['countList'][wordIndex] += 1
                else:
                    dbItem['wordList'].append(word)
                    dbItem['countList'].append(1)
                dbItemReorder(dbItem)
                pyMap[key[0]][key] = dbItemEncode(dbItem)
            else:
                pyMap[key[0]][key] = dbItemEncode({
                    'key' : key,
                    'wordList' : [word],
                    'countList' : [1],
                })
        elif e['action'] == 'remove':
            dbItemEncoded = pyMap.get(key[0], {}).get(key, '')
            if dbItemEncoded == '':
                continue
            dbItem = dbItemDecode(dbItemEncoded)
            wordIndex = dbWordIndex(dbItem['wordList'], word)
            if wordIndex < 0:
                continue
            del dbItem['wordList'][wordIndex]
            del dbItem['countList'][wordIndex]
            if len(dbItem['wordList']) == 0:
                del pyMap[key[0]][key]
                if len(pyMap[key[0]]) == 0:
                    del pyMap[key[0]]
            else:
                pyMap[key[0]][key] = dbItemEncode(dbItem)
        elif e['action'] == 'reorder':
            dbItemEncoded = pyMap.get(key[0], {}).get(key, '')
            if dbItemEncoded == '':
                continue
            dbItem = dbItemDecode(dbItemEncoded)
            wordIndex = dbWordIndex(dbItem['wordList'], word)
            if wordIndex < 0:
                continue
            dbItem['countList'][wordIndex] = 0
            sum = 0
            for cnt in dbItem['countList']:
                sum += cnt
            dbItem['countList'][wordIndex] = int(sum / 2)
            dbItemReorder(dbItem)
            pyMap[key[0]][key] = dbItemEncode(dbItem)
    # end of dbEditApplyPy

