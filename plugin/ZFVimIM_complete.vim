
" params:
"   key : the input key, e.g. `ceshi`
"   option: {
"     'sentence' : '0/1, default to g:ZFVimIM_sentence',
"     'crossDb' : 'maxNum, default to g:ZFVimIM_crossDbLimit',
"     'predict' : 'maxNum, default to g:ZFVimIM_predictLimit',
"     'match' : '', // > 0 : limit to this num, allow sub match
"                   // = 0 : disable match
"                   // < 0 : limit to (0-match) num, disallow sub match
"                   // default to g:ZFVimIM_matchLimit
"     'db' : {
"       // db object in g:ZFVimIM_db
"       // when specified, use the specified db, otherwise use current db
"     },
"   }
" return : [
"   {
"     'dbId' : 'match from which db',
"     'len' : 'match count in key',
"     'key' : 'matched full key',
"     'word' : 'matched word',
"     'type' : 'type of completion: sentence/match/predict/subMatchLongest/subMatch',
"     'sentenceList' : [ // (optional) for sentence type only, list of word that complete as sentence
"       {
"         'key' : '',
"         'word' : '',
"       },
"     ],
"   },
"   ...
" ]
function! ZFVimIM_completeDefault(key, ...)
    call ZFVimIM_DEBUG_profileStart('complete')
    let ret = s:completeDefault(a:key, get(a:, 1, {}))
    call ZFVimIM_DEBUG_profileStop()
    return ret
endfunction

function! s:completeDefault(key, ...)
    let option = get(a:, 1, {})
    let db = get(option, 'db', {})
    if empty(db) && g:ZFVimIM_dbIndex < len(g:ZFVimIM_db)
        let db = g:ZFVimIM_db[g:ZFVimIM_dbIndex]
    endif
    if empty(a:key) || empty(db)
        return []
    endif

    if !exists("option['dbSearchCache']")
        let option['dbSearchCache'] = {}
    endif

    if ZFVimIM_funcCallable(get(db, 'dbCallback', ''))
        let option = copy(option)
        let option['db'] = db
        call ZFVimIM_DEBUG_profileStart('dbCallback')
        let ret = ZFVimIM_funcCall(db['dbCallback'], [a:key, option])
        call ZFVimIM_DEBUG_profileStop()
        for item in ret
            if !exists("item['dbId']")
                let item['dbId'] = db['dbId']
            endif
        endfor
        return ret
    endif

    let data = {
                \   'sentence' : [],
                \   'crossDb' : [],
                \   'predict' : [],
                \   'match' : [],
                \   'subMatchLongest' : [],
                \   'subMatch' : [],
                \ }

    call s:complete_sentence(data['sentence'], a:key, option, db)
    call s:complete_crossDb(data['crossDb'], a:key, option, db)
    call s:complete_predict(data['predict'], a:key, option, db)
    call s:complete_match(data['match'], data['subMatchLongest'], data['subMatch'], a:key, option, db)

    return s:mergeResult(data, a:key, option, db)
endfunction


" complete exact match only
function! ZFVimIM_completeExact(key, ...)
    let max = get(a:, 1, -1)
    if max < 0
        let max = 99999
    endif
    return ZFVimIM_complete(a:key, {
                \   'sentence' : 0,
                \   'crossDb' : 0,
                \   'predict' : 0,
                \   'match' : (0 - max),
                \ })
endfunction


function! s:complete_sentence(ret, key, option, db)
    if !get(a:option, 'sentence', g:ZFVimIM_sentence)
        return
    endif

    let sentence = {
                \   'dbId' : a:db['dbId'],
                \   'len' : 0,
                \   'key' : '',
                \   'word' : '',
                \   'type' : 'sentence',
                \   'sentenceList' : [],
                \ }
    let keyLen = len(a:key)
    let iL = 0
    let iR = keyLen
    while iL < keyLen && iR > iL
        let subKey = strpart(a:key, iL, iR - iL)
        let index = ZFVimIM_dbSearch(a:db, subKey[0],
                    \ '^' . subKey,
                    \ 0)
        if index < 0
            let iR -= 1
            continue
        endif
        let index = ZFVimIM_dbSearch(a:db, subKey[0],
                    \ '^' . subKey . g:ZFVimIM_KEY_S_MAIN,
                    \ 0)
        if index < 0
            let iR -= 1
            continue
        endif

        let dbItem = ZFVimIM_dbItemDecode(a:db['dbMap'][subKey[0]][index])
        if empty(dbItem['wordList'])
            let iR -= 1
            continue
        endif
        let sentence['len'] += len(subKey)
        let sentence['key'] .= subKey
        let sentence['word'] .= dbItem['wordList'][0]
        call add(sentence['sentenceList'], {
                    \   'key' : subKey,
                    \   'word' : dbItem['wordList'][0],
                    \ })
        let iL = iR
        let iR = keyLen
    endwhile

    if len(sentence['sentenceList']) > 1
        call add(a:ret, sentence)
    endif
endfunction


function! s:complete_crossDb(ret, key, option, db)
    if get(a:option, 'crossDb', g:ZFVimIM_crossDbLimit) <= 0
        return
    endif

    let crossDbRetList = []
    for crossDbTmp in g:ZFVimIM_db
        if crossDbTmp['dbId'] == a:db['dbId']
                    \ || crossDbTmp['crossable'] == 0
                    \ || crossDbTmp['crossDbLimit'] <= 0
            continue
        endif

        let otherDbRetLimit = crossDbTmp['crossDbLimit']
        let otherDbRet = ZFVimIM_complete(a:key, {
                    \   'sentence' : 0,
                    \   'crossDb' : 0,
                    \   'predict' : ((crossDbTmp['crossable'] >= 2) ? otherDbRetLimit : 0),
                    \   'match' : ((crossDbTmp['crossable'] >= 3) ? otherDbRetLimit : (0 - otherDbRetLimit)),
                    \   'db' : crossDbTmp,
                    \ })
        if !empty(otherDbRet)
            if len(otherDbRet) > otherDbRetLimit
                call remove(otherDbRet, otherDbRetLimit, -1)
            endif
            call add(crossDbRetList, otherDbRet)
        endif
    endfor
    if empty(crossDbRetList)
        return
    endif

    " before g:ZFVimIM_crossDbLimit, take first from each cross db, if match
    let crossDbIndex = 0
    let hasMatch = 0
    while !empty(crossDbRetList) && len(a:ret) < g:ZFVimIM_crossDbLimit
        if empty(crossDbRetList[crossDbIndex])
            call remove(crossDbRetList, crossDbIndex)
            let crossDbIndex = crossDbIndex % len(crossDbRetList)
            continue
        endif
        if crossDbRetList[crossDbIndex][0]['type'] == 'match'
            call add(a:ret, crossDbRetList[crossDbIndex][0])
            call remove(crossDbRetList[crossDbIndex], 0)
        endif
        let crossDbIndex = (crossDbIndex + 1) % len(crossDbRetList)
        if crossDbIndex == 0
            if !hasMatch
                break
            else
                let hasMatch = 0
            endif
        endif
    endwhile

    " before g:ZFVimIM_crossDbLimit, take first from each cross db, even if not match
    let crossDbIndex = 0
    while !empty(crossDbRetList) && len(a:ret) < g:ZFVimIM_crossDbLimit
        if empty(crossDbRetList[crossDbIndex])
            call remove(crossDbRetList, crossDbIndex)
            let crossDbIndex = crossDbIndex % len(crossDbRetList)
            continue
        endif
        call add(a:ret, crossDbRetList[crossDbIndex][0])
        call remove(crossDbRetList[crossDbIndex], 0)
        let crossDbIndex = (crossDbIndex + 1) % len(crossDbRetList)
    endwhile

    " after g:ZFVimIM_crossDbLimit, add all to tail, by db index
    for crossDbRet in crossDbRetList
        call extend(a:ret, crossDbRet)
    endfor
endfunction

function! s:complete_predict(ret, key, option, db)
    let predictLimit = get(a:option, 'predict', g:ZFVimIM_predictLimit)
    if predictLimit <= 0
        return
    endif

    let keyLen = len(a:key)
    let p = keyLen
    while p > 0
        if keyLen == 2 && p < keyLen
            break
        endif
        " try to find
        let subKey = strpart(a:key, 0, p)
        let subMatchIndex = ZFVimIM_dbSearch(a:db, a:key[0],
                    \ '^' . subKey,
                    \ 0)
        if subMatchIndex < 0
            let p -= 1
            continue
        endif
        let dbItem = ZFVimIM_dbItemDecode(a:db['dbMap'][a:key[0]][subMatchIndex])

        " found things to predict
        let wordIndex = 0
        while len(a:ret) < predictLimit
            call add(a:ret, {
                        \   'dbId' : a:db['dbId'],
                        \   'len' : p,
                        \   'key' : dbItem['key'],
                        \   'word' : dbItem['wordList'][wordIndex],
                        \   'type' : 'predict',
                        \ })
            let wordIndex += 1
            if wordIndex < len(dbItem['wordList'])
                continue
            endif

            " find next predict
            let subMatchIndex = ZFVimIM_dbSearch(a:db, a:key[0],
                        \ '^' . subKey,
                        \ subMatchIndex + 1)
            if subMatchIndex < 0
                break
            endif
            let dbItem = ZFVimIM_dbItemDecode(a:db['dbMap'][a:key[0]][subMatchIndex])
            let wordIndex = 0
        endwhile

        break
    endwhile
endfunction

function! s:complete_match(matchRet, subMatchLongestRet, subMatchRet, key, option, db)
    let matchLimit = get(a:option, 'match', g:ZFVimIM_matchLimit)
    if matchLimit < 0
        call s:complete_match_exact(a:matchRet, a:key, a:option, a:db, 0 - matchLimit)
    elseif matchLimit > 0
        call s:complete_match_allowSubMatch(a:matchRet, a:subMatchLongestRet, a:subMatchRet, a:key, a:option, a:db, matchLimit)
    endif
endfunction

function! s:complete_match_exact(ret, key, option, db, matchLimit)
    let index = ZFVimIM_dbSearch(a:db, a:key[0],
                \ '^' . a:key,
                \ 0)
    if index < 0
        return
    endif
    let index = ZFVimIM_dbSearch(a:db, a:key[0],
                \ '^' . a:key . g:ZFVimIM_KEY_S_MAIN,
                \ 0)
    if index < 0
        return
    endif

    " found match
    let matchLimit = a:matchLimit
    let keyLen = len(a:key)
    let singleChars = []
    let multiChars = []
    
    " First pass: collect all items, separate single chars and multi chars
    let tempIndex = index
    while tempIndex >= 0
        let dbItem = ZFVimIM_dbItemDecode(a:db['dbMap'][a:key[0]][tempIndex])
        " Get the actual key from database
        let dbItemKey = dbItem['key']
        for word in dbItem['wordList']
            let item = {
                        \   'dbId' : a:db['dbId'],
                        \   'len' : keyLen,
                        \   'key' : dbItemKey,
                        \   'word' : word,
                        \   'type' : 'match',
                        \ }
            if len(word) == 1
                call add(singleChars, item)
            else
                call add(multiChars, item)
            endif
        endfor
        let tempIndex = ZFVimIM_dbSearch(a:db, a:key[0],
                    \ '^' . a:key . g:ZFVimIM_KEY_S_MAIN,
                    \ tempIndex + 1)
    endwhile
    
    " Extract common first character from multi-chars - DISABLED in intermediate stages
    " Only extract in mergeResult to avoid duplicate extraction
    
    " Add all single characters first (no limit)
    call extend(a:ret, singleChars)
    
    " Then add multi-character words up to limit
    let remainingLimit = matchLimit - len(singleChars)
    if remainingLimit > 0
        let wordIndex = 0
        while wordIndex < len(multiChars) && remainingLimit > 0
            call add(a:ret, multiChars[wordIndex])
            let wordIndex += 1
            let remainingLimit -= 1
        endwhile
    endif
endfunction

function! s:complete_match_allowSubMatch(matchRet, subMatchLongestRet, subMatchRet, key, option, db, matchLimit)
    let matchLimit = a:matchLimit
    let keyLen = len(a:key)
    let p = keyLen
    let subMatchLongestFlag = 1
    while p > 0 && matchLimit > 0
        if keyLen == 2 && p < keyLen
            break
        endif
        let subKey = strpart(a:key, 0, p)
        let index = ZFVimIM_dbSearch(a:db, a:key[0],
                    \ '^' . subKey,
                    \ 0)
        if index < 0
            let p -= 1
            continue
        endif
        let index = ZFVimIM_dbSearch(a:db, a:key[0],
                    \ '^' . subKey . g:ZFVimIM_KEY_S_MAIN,
                    \ 0)
        if index < 0
            let p -= 1
            continue
        endif

        " found match
        let dbItem = ZFVimIM_dbItemDecode(a:db['dbMap'][a:key[0]][index])
        
        if p == keyLen
            let ret = a:matchRet
            let type = 'match'
        elseif subMatchLongestFlag
            let ret = a:subMatchLongestRet
            let type = 'subMatchLongest'
            let subMatchLongestFlag = 0
        else
            let ret = a:subMatchRet
            let type = 'subMatch'
        endif
        
        " Separate single characters and multi-character words
        let singleChars = []
        let multiChars = []
        " Get the actual key from database
        let dbItemKey = dbItem['key']
        for word in dbItem['wordList']
            let item = {
                        \   'dbId' : a:db['dbId'],
                        \   'len' : p,
                        \   'key' : dbItemKey,
                        \   'word' : word,
                        \   'type' : type,
                        \ }
            if len(word) == 1
                call add(singleChars, item)
            else
                call add(multiChars, item)
            endif
        endfor
        
        " Extract common first character - DISABLED in intermediate stages
        " Only extract in mergeResult to avoid duplicate extraction
        
        " Add all single characters first (no limit)
        call extend(ret, singleChars)
        
        " Then add multi-character words up to remaining limit
        let remainingLimit = matchLimit - len(singleChars)
        if remainingLimit > 0
            let wordIndex = 0
            while wordIndex < len(multiChars) && remainingLimit > 0
                call add(ret, multiChars[wordIndex])
                let wordIndex += 1
                let remainingLimit -= 1
            endwhile
        endif
        
        " Update matchLimit (only count multi-chars towards limit)
        let matchLimit -= len(multiChars)
        if matchLimit < 0
            let matchLimit = 0
        endif

        let p -= 1
    endwhile
endfunction

" Extract common first character from multi-chars if they share first 2 key chars
" Example: When input is 'gz', and we have [{'key':'gzcu','word':'给出'}, {'key':'gzli','word':'给力'}, {'key':'gznn','word':'给您'}]
" These keys all start with 'gz' (first 2 chars), so extract '给' with key 'gz'
" Only extract when currentKey has exactly 2 characters, and only from keys that start with currentKey
" Returns: List of extracted items [{'dbId':'...', 'len':2, 'key':'gz', 'word':'给', 'type':'match'}, ...]
function! s:extractCommonFirstChar(multiChars, currentKey, db)
    let extractedItems = []
    
    " Only extract when currentKey has exactly 2 characters (e.g., 'gz', not 'g')
    if len(a:currentKey) != 2
        return extractedItems
    endif
    
    if empty(a:multiChars) || len(a:multiChars) < 2
        return extractedItems
    endif
    
    let currentKeyPrefix = a:currentKey  " e.g., 'gz'
    
    " Group multi-chars by their key prefix, but ONLY if key starts with currentKeyPrefix
    let keyPrefixGroups = {}
    for item in a:multiChars
        let key = item['key']
        " Only process if key has at least 2 characters and starts with currentKeyPrefix
        if len(key) >= 2
            let prefix = strpart(key, 0, 2)
            " ONLY process keys that exactly match currentKeyPrefix (e.g., 'gz')
            if prefix ==# currentKeyPrefix
                if !has_key(keyPrefixGroups, prefix)
                    let keyPrefixGroups[prefix] = []
                endif
                call add(keyPrefixGroups[prefix], item)
            endif
        endif
    endfor
    
    " Find prefix group with 2+ items and extract common first char
    for prefix in keys(keyPrefixGroups)
        let group = keyPrefixGroups[prefix]
        if len(group) >= 2
            " Extract first character from all words in this group
            let firstChars = {}
            for item in group
                let word = item['word']
                if len(word) > 0
                    let firstChar = strcharpart(word, 0, 1)
                    if !has_key(firstChars, firstChar)
                        let firstChars[firstChar] = 0
                    endif
                    let firstChars[firstChar] += 1
                endif
            endfor
            
            " Extract all first chars that appear in at least 2 words
            for char in keys(firstChars)
                if firstChars[char] >= 2
                    " Create new item with extracted char
                    let newItem = {
                                \   'dbId' : group[0]['dbId'],
                                \   'len' : 2,
                                \   'key' : currentKeyPrefix,
                                \   'word' : char,
                                \   'type' : 'match',
                                \ }
                    call add(extractedItems, newItem)
                endif
            endfor
        endif
    endfor
    
    return extractedItems
endfunction

function! s:removeDuplicate(ret, exists)
    let i = 0
    let iEnd = len(a:ret)
    while i < iEnd
        let item = a:ret[i]
        let hash = item['key'] . item['word']
        if exists('a:exists[hash]')
            call remove(a:ret, i)
            let iEnd -= 1
            let i -= 1
        else
            let a:exists[hash] = 1
        endif
        let i += 1
    endwhile
endfunction

" Sort list to prioritize single characters
function! s:sortSingleCharPriority(ret)
    if len(a:ret) <= 1
        return
    endif
    " Separate single characters and multi-character words
    let singleChars = []
    let multiChars = []
    for item in a:ret
        if len(item['word']) == 1
            call add(singleChars, item)
        else
            call add(multiChars, item)
        endif
    endfor
    " Clear and rebuild with single chars first
    call remove(a:ret, 0, len(a:ret) - 1)
    call extend(a:ret, singleChars)
    call extend(a:ret, multiChars)
endfunction

" Sort function with frequency support
" This function sorts items by frequency (higher frequency first)
function! s:sortByFrequency(item1, item2)
    " Get word frequency if available
    let freq1 = 0
    let freq2 = 0
    
    " Try to get frequency from global function
    if exists('*ZFVimIM_getWordFrequency')
        let freq1 = ZFVimIM_getWordFrequency(a:item1['key'], a:item1['word'])
        let freq2 = ZFVimIM_getWordFrequency(a:item2['key'], a:item2['word'])
    endif
    
    " Sort by frequency (higher frequency first)
    if freq1 > freq2
        return -1
    elseif freq1 < freq2
        return 1
    else
        " If frequency is same, keep original order
        return 0
    endif
endfunction

" Sort list by frequency (used words first) within single char priority groups
function! s:sortByFrequencyPriority(ret)
    if len(a:ret) <= 1
        return
    endif
    
    " First separate single chars and multi-chars
    let singleChars = []
    let multiChars = []
    for item in a:ret
        if len(item['word']) == 1
            call add(singleChars, item)
        else
            call add(multiChars, item)
        endif
    endfor
    
    " Sort each group by frequency
    if len(singleChars) > 1
        call sort(singleChars, function('s:sortByFrequency'))
    endif
    if len(multiChars) > 1
        call sort(multiChars, function('s:sortByFrequency'))
    endif
    
    " Rebuild with single chars first, sorted by frequency
    call remove(a:ret, 0, len(a:ret) - 1)
    call extend(a:ret, singleChars)
    call extend(a:ret, multiChars)
endfunction

" Sort exact matches by length first, then frequency
function! s:sortExactMatches(ret)
    if len(a:ret) <= 1
        return
    endif
    call sort(a:ret, function('s:compareExactMatch'))
endfunction

function! s:compareExactMatch(item1, item2)
    let len1 = len(get(a:item1, 'word', ''))
    let len2 = len(get(a:item2, 'word', ''))
    if len1 < len2
        return -1
    elseif len1 > len2
        return 1
    endif
    return s:sortByFrequency(a:item1, a:item2)
endfunction

function! s:sortMatchResults(matchRet, inputKey)
    if len(a:matchRet) <= 1
        return
    endif

    let exactMatches = []
    let otherMatches = []
    for item in a:matchRet
        if get(item, 'key', '') ==# a:inputKey
            call add(exactMatches, item)
        else
            call add(otherMatches, item)
        endif
    endfor

    call s:sortExactMatches(exactMatches)
    call s:sortByFrequencyPriority(otherMatches)

    call remove(a:matchRet, 0, len(a:matchRet) - 1)
    call extend(a:matchRet, exactMatches)
    call extend(a:matchRet, otherMatches)
endfunction
" data: {
"   'sentence' : [],
"   'crossDb' : [],
"   'predict' : [],
"   'match' : [],
" }
" return final result list
function! s:mergeResult(data, key, option, db)
    let ret = []
    let sentenceRet = a:data['sentence']
    let crossDbRet = a:data['crossDb']
    let predictRet = a:data['predict']
    let matchRet = a:data['match']
    let subMatchLongestRet = a:data['subMatchLongest']
    let subMatchRet = a:data['subMatch']
    let tailRet = []

    " remove duplicate
    let exists = {}
    " ordered from high priority to low
    call s:removeDuplicate(matchRet, exists)
    call s:removeDuplicate(subMatchLongestRet, exists)
    call s:removeDuplicate(predictRet, exists)
    call s:removeDuplicate(sentenceRet, exists)
    call s:removeDuplicate(subMatchRet, exists)
    call s:removeDuplicate(crossDbRet, exists)

    " crossDb may return different type
    let iCrossDb = 0
    while iCrossDb < len(crossDbRet)
        if 0
        elseif crossDbRet[iCrossDb]['type'] == 'sentence'
            call add(sentenceRet, remove(crossDbRet, iCrossDb))
        elseif crossDbRet[iCrossDb]['type'] == 'predict'
            call add(predictRet, remove(crossDbRet, iCrossDb))
        elseif crossDbRet[iCrossDb]['type'] == 'match'
            call add(matchRet, remove(crossDbRet, iCrossDb))
        else
            let iCrossDb += 1
        endif
    endwhile

    " limit predict if has match
    if len(sentenceRet) + len(matchRet) + len(subMatchLongestRet) + len(subMatchRet) >= 5 && len(predictRet) > g:ZFVimIM_predictLimitWhenMatch
        call extend(tailRet, remove(predictRet, g:ZFVimIM_predictLimitWhenMatch, len(predictRet) - 1))
    endif

    " Sort match list with exact matches prioritized and length-aware ordering
    call s:sortMatchResults(matchRet, a:key)
    call s:sortByFrequencyPriority(sentenceRet)
    call s:sortByFrequencyPriority(subMatchLongestRet)
    call s:sortByFrequencyPriority(subMatchRet)
    call s:sortByFrequencyPriority(predictRet)
    call s:sortByFrequencyPriority(tailRet)

    " order:
    "   exact match
    "   sentence
    "   subMatchLongest
    "   predict(len > match)
    "   subMatch
    "   predict(len <= match)
    "   tail
    "   all crossDb
    call extend(ret, matchRet)
    call extend(ret, sentenceRet)

    " longer predict should higher than match for smart recommend
    " But single characters should always be prioritized
    let maxMatchLen = 0
    if !empty(subMatchRet)
        let maxMatchLen = subMatchRet[0]['len']
    endif
    let longPredictRet = []
    let shortPredictRet = []
    if maxMatchLen > 0
        let iPredict = 0
        while iPredict < len(predictRet)
            if predictRet[iPredict]['len'] > maxMatchLen
                call add(longPredictRet, remove(predictRet, iPredict))
            else
                let iPredict += 1
            endif
        endwhile
        " Sort long predict to prioritize single characters, then by frequency
        call s:sortByFrequencyPriority(longPredictRet)
        call extend(ret, longPredictRet)
    endif

    call extend(ret, subMatchLongestRet)
    call extend(ret, subMatchRet)
    call extend(ret, predictRet)
    call extend(ret, tailRet)

    " Sort crossDb to prioritize single characters
    call s:sortSingleCharPriority(crossDbRet)

    " crossDb should be placed at lower order,
    if g:ZFVimIM_crossDbPos >= len(ret)
        call extend(ret, crossDbRet)
    elseif len(crossDbRet) > g:ZFVimIM_crossDbLimit
        let i = 0
        let iEnd = g:ZFVimIM_crossDbLimit
        while i < iEnd
            call insert(ret, crossDbRet[i], g:ZFVimIM_crossDbPos + i)
            let i += 1
        endwhile
        let iEnd = len(crossDbRet)
        while i < iEnd
            call insert(ret, crossDbRet[i], g:ZFVimIM_crossDbPos + i)
            let i += 1
        endwhile
    else
        let i = 0
        let iEnd = len(crossDbRet)
        while i < iEnd
            call insert(ret, crossDbRet[i], g:ZFVimIM_crossDbPos + i)
            let i += 1
        endwhile
    endif

    " Extract common first character from multi-chars ONLY when key length is exactly 2
    " Only extract from multi-chars whose key matches the user input prefix exactly
    if len(a:key) == 2
        let allMultiChars = []
        let currentKeyPrefix = a:key  " e.g., 'gz'
        
        " Collect only multi-chars that match the current key prefix exactly
        for item in ret
            " Only include multi-chars whose key starts with currentKeyPrefix
            if len(item['word']) > 1 && len(item['key']) >= 2
                let itemPrefix = strpart(item['key'], 0, 2)
                if itemPrefix ==# currentKeyPrefix
                    call add(allMultiChars, item)
                endif
            endif
        endfor
        
        if len(allMultiChars) >= 2
            let extractedChars = s:extractCommonFirstChar(allMultiChars, a:key, a:db)
            let pendingExtracted = []
            for extractedChar in extractedChars
                " Tag extracted result so we can treat it with lower priority later
                let extractedChar['source'] = 'extracted_common_char'

                " Skip if exact same candidate already exists
                let alreadyExists = 0
                for item in ret
                    if item['word'] ==# extractedChar['word'] && item['key'] ==# extractedChar['key']
                        let alreadyExists = 1
                        break
                    endif
                endfor
                if !alreadyExists
                    call add(pendingExtracted, extractedChar)
                endif
            endfor

            if !empty(pendingExtracted)
                " Insert extracted chars after real exact-match entries from current db
                let insertPos = 0
                while insertPos < len(ret)
                    let item = ret[insertPos]
                    if get(item, 'type', '') ==# 'match'
                                \ && get(item, 'key', '') ==# a:key
                                \ && get(item, 'dbId', -1) == a:db['dbId']
                                \ && get(item, 'source', '') !=# 'extracted_common_char'
                        let insertPos += 1
                        continue
                    endif
                    break
                endwhile

                let offset = 0
                for extractedChar in pendingExtracted
                    call insert(ret, extractedChar, insertPos + offset)
                    let offset += 1
                endfor
            endif
        endif
    endif

    " For 2-letter input, keep only items whose key matches the input prefix
    if len(a:key) == 2
        let filteredRet = []
        for item in ret
            if len(get(item, 'key', '')) >= 2 && strpart(item['key'], 0, 2) ==# a:key
                call add(filteredRet, item)
            endif
        endfor
        let ret = filteredRet
    endif

    " Final deduplication: remove duplicates from the final result
    let finalExists = {}
    let finalRet = []
    for item in ret
        let hash = item['key'] . "\t" . item['word']
        if !has_key(finalExists, hash)
            let finalExists[hash] = 1
            call add(finalRet, item)
        endif
    endfor

    return finalRet
endfunction
