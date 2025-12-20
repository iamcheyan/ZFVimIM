
" ============================================================
if !exists('g:ZFVimIM_matchLimit')
    let g:ZFVimIM_matchLimit = 2000
endif

if !exists('g:ZFVimIM_predictLimitWhenMatch')
    let g:ZFVimIM_predictLimitWhenMatch = 5
endif
if !exists('g:ZFVimIM_predictLimit')
    let g:ZFVimIM_predictLimit = 1000
endif

if !exists('g:ZFVimIM_sentence')
    let g:ZFVimIM_sentence = 1
endif

if !exists('g:ZFVimIM_crossable')
    let g:ZFVimIM_crossable = 2
endif
if !exists('g:ZFVimIM_crossDbLimit')
    let g:ZFVimIM_crossDbLimit = 2
endif
if !exists('g:ZFVimIM_crossDbPos')
    let g:ZFVimIM_crossDbPos = 5
endif

if !exists('g:ZFVimIM_cachePath')
    let g:ZFVimIM_cachePath = get(g:, 'zf_vim_cache_path', $HOME . '/.vim_cache') . '/ZFVimIM'
endif

function! ZFVimIM_cachePath()
    if !isdirectory(g:ZFVimIM_cachePath)
        silent! call mkdir(g:ZFVimIM_cachePath, 'p')
    endif
    return g:ZFVimIM_cachePath
endfunction

function! ZFVimIM_randName()
    return fnamemodify(tempname(), ':t')
endfunction

function! ZFVimIM_rm(path)
    if (has('win32') || has('win64')) && !has('unix')
        silent! call system('rmdir /s/q "' . substitute(CygpathFix_absPath(a:path), '/', '\', 'g') . '"')
    else
        silent! call system('rm -rf "' . CygpathFix_absPath(a:path) . '"')
    endif
endfunction

if !exists('*ZFVimIM_json_available')
    " fallback to `retorillo/json-ponyfill.vim` if installed
    function! ZFVimIM_json_available()
        if !exists('s:ZFVimIM_json_available')
            if exists('*json_decode')
                let s:ZFVimIM_json_available = 1
            else
                let s:ZFVimIM_json_available = 0
                try
                    call json_ponyfill#json_decode('{}')
                    let s:ZFVimIM_json_available = 1
                catch
                endtry
            endif
        endif
        return s:ZFVimIM_json_available
    endfunction
    function! ZFVimIM_json_encode(expr)
        if exists('*json_encode')
            return json_encode(a:expr)
        else
            return json_ponyfill#json_encode(a:expr)
        endif
    endfunction
    function! ZFVimIM_json_decode(expr)
        if exists('*json_decode')
            return json_decode(a:expr)
        else
            return json_ponyfill#json_decode(a:expr)
        endif
    endfunction
endif

function! CygpathFix_absPath(path)
    if len(a:path) <= 0|return ''|endif
    if !exists('g:CygpathFix_isCygwin')
        let g:CygpathFix_isCygwin = has('win32unix') && executable('cygpath')
    endif
    let path = fnamemodify(a:path, ':p')
    if !empty(path) && g:CygpathFix_isCygwin
        if 0 " cygpath is really slow
            let path = substitute(system('cygpath -m "' . path . '"'), '[\r\n]', '', 'g')
        else
            if match(path, '^/cygdrive/') >= 0
                let path = toupper(strpart(path, len('/cygdrive/'), 1)) . ':' . strpart(path, len('/cygdrive/') + 1)
            else
                if !exists('g:CygpathFix_cygwinPrefix')
                    let g:CygpathFix_cygwinPrefix = substitute(system('cygpath -m /'), '[\r\n]', '', 'g')
                endif
                let path = g:CygpathFix_cygwinPrefix . path
            endif
        endif
    endif
    return substitute(substitute(path, '\\', '/', 'g'), '\%(\/\)\@<!\/\+$', '', '') " (?<!\/)\/+$
endfunction

" db : [
"   {
"     'dbId' : 'auto generated id',
"     'name' : '(required) name of the db',
"     'priority' : '(optional) priority of the db, smaller value has higher priority, 100 by default',
"     'switchable' : '(optional) 1 by default, when off, won't be enabled by ZFVimIME_keymap_next_n() series',
"     'editable' : '(optional) 1 by default, when off, no dbEdit would applied',
"     'crossable' : '(optional) g:ZFVimIM_crossable by default, whether to show result when inputing in other db',
"                   // 0 : disable
"                   // 1 : show only when full match
"                   // 2 : show and allow predict
"                   // 3 : show and allow predict and sub match
"     'crossDbLimit' : '(optional) g:ZFVimIM_crossDbLimit by default, when crossable, limit max result to this num',
"     'dbCallback' : '(optional) func(key, option), see ZFVimIM_complete',
"                    // when dbCallback supplied, words would be fetched from this callback instead
"     'menuLabel' : '(optional) string or function(item), when not empty, show label after key hint',
"                   // when not set, or set to number `0`, we would show db name if it's completed from crossDb
"     'implData' : {
"       // extra data for impl
"     },
"
"     // generated data:
"     'dbMap' : { // split a-z to improve performance, ensured empty if no data
"       'a' : [
"         'a#啊,阿#3,2',
"         'ai#爱,哀#3',
"       ],
"       'c' : [
"         'ceshi#测试',
"       ],
"     },
"     'dbEdit' : [
"       {
"         'action' : 'add/remove/reorder',
"         'key' : 'key',
"         'word' : 'word',
"       },
"       ...
"     ],
"   },
"   ...
" ]
if !exists('g:ZFVimIM_db')
    let g:ZFVimIM_db = []
endif
if !exists('g:ZFVimIM_dbIndex')
    let g:ZFVimIM_dbIndex = 0
endif

let g:ZFVimIM_KEY_S_MAIN = '#'
let g:ZFVimIM_KEY_S_SUB = ','
let g:ZFVimIM_KEY_SR_MAIN = '_ZFVimIM_m_'
let g:ZFVimIM_KEY_SR_SUB = '_ZFVimIM_s_'

" ============================================================
augroup ZFVimIM_event_OnUpdateDb_augroup
    autocmd!
    autocmd User ZFVimIM_event_OnUpdateDb silent
augroup END

" ============================================================
function! ZFVimIM_funcCallable(func)
    if exists('*ZFJobFuncCallable')
        return ZFJobFuncCallable(a:func)
    else
        return type(a:func) == type(function('function'))
    endif
endfunction
function! ZFVimIM_funcCall(func, argList)
    if exists('*ZFJobFuncCall')
        return ZFJobFuncCall(a:func, a:argList)
    else
        return call(a:func, a:argList)
    endif
endfunction

" option: {
"   'name' : '(required) name of your db',
"   ... // see g:ZFVimIM_db for more info
" }
function! ZFVimIM_dbInit(option)
    let db = extend({
                \   'dbId' : -1,
                \   'name' : 'ZFVimIM',
                \   'priority' : -1,
                \   'switchable' : 1,
                \   'editable' : 1,
                \   'crossable' : g:ZFVimIM_crossable,
                \   'crossDbLimit' : g:ZFVimIM_crossDbLimit,
                \   'dbCallback' : '',
                \   'menuLabel' : 0,
                \   'dbMap' : {},
                \   'dbEdit' : [],
                \   'implData' : {},
                \ }, a:option)
    if db['priority'] < 0
        let db['priority'] = 100
    endif
    call ZFVimIM_dbSearchCacheClear(db)

    let s:dbId = get(s:, 'dbId', 0) + 1
    while ZFVimIM_dbIndexForId(s:dbId) >= 0
        let s:dbId += 1
        if s:dbId <= 0
            let s:dbId = 1
        endif
    endwhile
    let db['dbId'] = s:dbId

    let index = len(g:ZFVimIM_db) - 1
    while index >= 0 && db['priority'] < g:ZFVimIM_db[index]['priority']
        let index -= 1
    endwhile
    call insert(g:ZFVimIM_db, db, index + 1)

    return db
endfunction

function! ZFVimIM_dbIndexForId(dbId)
    for dbIndex in range(len(g:ZFVimIM_db))
        if g:ZFVimIM_db[dbIndex]['dbId'] == a:dbId
            return dbIndex
        endif
    endfor
    return -1
endfunction
function! ZFVimIM_dbForId(dbId)
    for dbIndex in range(len(g:ZFVimIM_db))
        if g:ZFVimIM_db[dbIndex]['dbId'] == a:dbId
            return g:ZFVimIM_db[dbIndex]
        endif
    endfor
    return {}
endfunction

function! ZFVimIM_dbLoad(db, dbFile, ...)
    call s:dbLoad(a:db, a:dbFile, get(a:, 1, ''))
endfunction
function! ZFVimIM_dbSave(db, dbFile, ...)
    call s:dbSave(a:db, a:dbFile, get(a:, 1, ''))
endfunction

function! ZFVimIM_dbEditApply(db, dbEdit)
    call ZFVimIM_DEBUG_profileStart('dbEditApply')
    call s:dbEditApply(a:db, a:dbEdit)
    call ZFVimIM_DEBUG_profileStop()
endfunction

if !exists('g:ZFVimIM_dbEditApplyFlag')
    let g:ZFVimIM_dbEditApplyFlag = 0
endif
function! ZFVimIM_wordAdd(db, word, key)
    call s:dbEdit(a:db, a:word, a:key, 'add')
endfunction

function! ZFVimIM_wordRemove(db, word, ...)
    call s:dbEditWildKey(a:db, a:word, get(a:, 1, ''), 'remove')
endfunction

function! ZFVimIM_wordReorder(db, word, ...)
    call s:dbEditWildKey(a:db, a:word, get(a:, 1, ''), 'reorder')
endfunction

function! IMAdd(bang, db, key, word)
    " Get dictionary file path
    let dictPath = ''
    let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
    let sfileDir = expand('<sfile>:p:h:h')
    if isdirectory(sfileDir . '/dict')
        let pluginDir = sfileDir
    endif
    let dictDir = pluginDir . '/dict'
    
    if exists('g:zfvimim_default_dict_name') && !empty(g:zfvimim_default_dict_name)
        let defaultDictName = g:zfvimim_default_dict_name
        if defaultDictName !~ '\.txt$'
            let defaultDictName = defaultDictName . '.txt'
        endif
        let dictPath = dictDir . '/' . defaultDictName
    elseif exists('g:zfvimim_dict_path') && !empty(g:zfvimim_dict_path)
        let dictPath = expand(g:zfvimim_dict_path)
    else
        let dictPath = dictDir . '/default_pinyin.txt'
    endif
    
    if empty(dictPath) || !filereadable(dictPath)
        echom '[ZFVimIM] Error: Dictionary file not found: ' . dictPath
        return
    endif
    
    " Simply append the line to the end of the file
    " Format: key word (user input as-is)
    let line = a:key . ' ' . a:word
    
    " Use Python to append to file (simple and fast)
    let pythonCmd = executable('python3') ? 'python3' : 'python'
    if !executable(pythonCmd)
        " Fallback: use Vim's writefile
        let lines = readfile(dictPath)
        call add(lines, line)
        call writefile(lines, dictPath)
        echom '[ZFVimIM] Word added to dictionary file: ' . line
        return
    endif
    
    " Use Python to append (faster for large files)
    let tmpScript = ZFVimIM_cachePath() . '/append_to_dict.py'
    let scriptContent = [
                \ '#!/usr/bin/env python3',
                \ '# -*- coding: utf-8 -*-',
                \ 'import sys',
                \ '',
                \ 'dictFile = sys.argv[1]',
                \ 'line = sys.argv[2]',
                \ '',
                \ '# Append line to file',
                \ 'with open(dictFile, "a", encoding="utf-8") as f:',
                \ '    f.write(line + "\n")',
                \ '',
                \ 'print("OK")',
                \ ]
    
    " Write script file
    if type(scriptContent) == type([])
        call writefile(scriptContent, tmpScript)
    else
        call writefile(split(scriptContent, "\n", 1), tmpScript)
    endif
    
    " Execute Python script
    let cmd = pythonCmd . ' "' . tmpScript . '" "' . dictPath . '" "' . line . '"'
    let result = system(cmd)
    let result = substitute(result, '[\r\n]', '', 'g')
    
    " Clean up
    call delete(tmpScript)
    
    if result ==# 'OK'
        echom '[ZFVimIM] Word added to dictionary file: ' . line
    else
        echom '[ZFVimIM] Error: ' . result
    endif
endfunction
function! IMRemove(bang, db, word, ...)
    if a:bang == '!'
        let g:ZFVimIM_dbEditApplyFlag += 1
    endif
    
    " Collect all words to remove (support multiple words)
    let wordsToRemove = [a:word]
    if a:0 > 0
        for i in range(1, a:0)
            call add(wordsToRemove, a:{i})
        endfor
    endif
    
    " Get dictionary file path
    let dictPath = ''
    if !empty(a:db) && has_key(a:db, 'implData') && has_key(a:db['implData'], 'dictPath')
        let dictPath = a:db['implData']['dictPath']
    else
        " Try to get from configuration
        let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
        let sfileDir = expand('<sfile>:p:h:h')
        if isdirectory(sfileDir . '/dict')
            let pluginDir = sfileDir
        endif
        let dictDir = pluginDir . '/dict'
        
        if exists('g:zfvimim_default_dict_name') && !empty(g:zfvimim_default_dict_name)
            let defaultDictName = g:zfvimim_default_dict_name
            if defaultDictName !~ '\.txt$'
                let defaultDictName = defaultDictName . '.txt'
            endif
            let dictPath = dictDir . '/' . defaultDictName
        elseif exists('g:zfvimim_dict_path') && !empty(g:zfvimim_dict_path)
            let dictPath = expand(g:zfvimim_dict_path)
        else
            let dictPath = dictDir . '/default_pinyin.txt'
        endif
    endif
    
    if empty(dictPath) || !filereadable(dictPath)
        echom '[ZFVimIM] Error: Dictionary file not found: ' . dictPath
        return
    endif
    
    " Use Python to directly remove multiple words from file
    let pythonCmd = executable('python3') ? 'python3' : 'python'
    if !executable(pythonCmd)
        echom '[ZFVimIM] Error: Python not found. Cannot edit dictionary file directly.'
        return
    endif
    
    " Create a Python script to remove multiple words
    let tmpScript = ZFVimIM_cachePath() . '/direct_remove_words.py'
    let scriptLines = [
                \ '#!/usr/bin/env python3',
                \ '# -*- coding: utf-8 -*-',
                \ 'import sys',
                \ '',
                \ 'dictFile = sys.argv[1]',
                \ 'wordsToRemove = sys.argv[2:]',
                \ '',
                \ '# Read file line by line',
                \ 'modified = False',
                \ 'newLines = []',
                \ 'removedCount = {}',
                \ '',
                \ 'with open(dictFile, "r", encoding="utf-8") as f:',
                \ '    for line in f:',
                \ '        line = line.rstrip("\n")',
                \ '        if not line:',
                \ '            newLines.append("")',
                \ '            continue',
                \ '        ',
                \ '        # Handle escaped spaces: replace \  with placeholder',
                \ '        lineTmp = line.replace("\\ ", "_ZFVimIM_space_")',
                \ '        parts = lineTmp.split()',
                \ '        ',
                \ '        if len(parts) <= 1:',
                \ '            # Only key, no words, skip this line',
                \ '            continue',
                \ '        ',
                \ '        # Remove words if they exist',
                \ '        newParts = [parts[0]]  # Keep the key',
                \ '        foundAny = False',
                \ '        for w in parts[1:]:',
                \ '            # Restore spaces and compare',
                \ '            wRestored = w.replace("_ZFVimIM_space_", " ")',
                \ '            if wRestored not in wordsToRemove:',
                \ '                newParts.append(w)',
                \ '            else:',
                \ '                foundAny = True',
                \ '                modified = True',
                \ '                removedCount[wRestored] = removedCount.get(wRestored, 0) + 1',
                \ '        ',
                \ '        # If line still has words after removal, keep it',
                \ '        if len(newParts) > 1:',
                \ '            # Reconstruct line with escaped spaces',
                \ '            newLine = newParts[0]',
                \ '            for w in newParts[1:]:',
                \ '                newLine += " " + w.replace(" ", "\\ ")',
                \ '            newLines.append(newLine)',
                \ '        # If only key left, skip this line',
                \ '',
                \ '# Write back',
                \ 'if modified:',
                \ '    with open(dictFile, "w", encoding="utf-8") as f:',
                \ '        for line in newLines:',
                \ '            f.write(line + "\n")',
                \ '    # Print removed words count',
                \ '    result = []',
                \ '    for word in wordsToRemove:',
                \ '        count = removedCount.get(word, 0)',
                \ '        if count > 0:',
                \ '            result.append(word + "(" + str(count) + ")")',
                \ '        else:',
                \ '            result.append(word + "(0)")',
                \ '    print("OK:" + ":".join(result))',
                \ 'else:',
                \ '    print("NOT_FOUND")',
                \ ]
    let scriptContent = join(scriptLines, "\n") . "\n"
    
    " Write script file
    if type(scriptContent) == type([])
        call writefile(scriptContent, tmpScript)
    else
        call writefile(split(scriptContent, "\n", 1), tmpScript)
    endif
    
    " Build command with all words as arguments
    let cmd = pythonCmd . ' "' . tmpScript . '" "' . dictPath . '"'
    for word in wordsToRemove
        let cmd = cmd . ' "' . word . '"'
    endfor
    
    " Execute Python script
    let result = system(cmd)
    let result = substitute(result, '[\r\n]', '', 'g')
    
    " Clean up
    call delete(tmpScript)
    
    if result =~# '^OK:'
        " File modification time will automatically invalidate cache
        " Just clear in-memory search cache if database is loaded
        if exists('g:ZFVimIM_db') && !empty(g:ZFVimIM_db)
            for db in g:ZFVimIM_db
                if has_key(db, 'implData') && has_key(db['implData'], 'dictPath')
                    if db['implData']['dictPath'] ==# dictPath
                        call ZFVimIM_dbSearchCacheClear(db)
                        break
                    endif
                endif
            endfor
        endif
        
        " Parse result and show removed words
        let resultParts = split(result, ':')
        if len(resultParts) > 1
            let removedInfo = join(resultParts[1:], ':')
            echom '[ZFVimIM] Removed words: ' . removedInfo
        else
            echom '[ZFVimIM] Words removed from dictionary file'
        endif
    elseif result ==# 'NOT_FOUND'
        echom '[ZFVimIM] None of the words found in dictionary'
    else
        echom '[ZFVimIM] Error: ' . result
    endif
    
    if a:bang == '!'
        let g:ZFVimIM_dbEditApplyFlag -= 1
    endif
endfunction
function! IMReorder(bang, db, word, ...)
    if a:bang == '!'
        let g:ZFVimIM_dbEditApplyFlag += 1
    endif
    call ZFVimIM_wordReorder(a:db, a:word, get(a:, 1, ''))
    if a:bang == '!'
        let g:ZFVimIM_dbEditApplyFlag -= 1
    endif
endfunction
" Wrapper functions to parse arguments in format: key word (matching dictionary format)
function! s:IMAddWrapper(bang, ...)
    if a:0 < 2
        echom '[ZFVimIM] Error: Usage: IMAdd <key> <word>'
        return
    endif
    let key = a:1
    let word = join(a:000[1:], ' ')
    call IMAdd(a:bang, {}, key, word)
endfunction

function! s:IMRemoveWrapper(bang, ...)
    if a:0 < 1
        echom '[ZFVimIM] Error: Usage: IMRemove <word1> [word2] [word3] ...'
        echom '[ZFVimIM] Example: IMRemove 词1 词2 词3'
        return
    endif
    " Call IMRemove with first word and remaining words as additional arguments
    " Build function call dynamically
    let firstWord = a:1
    if a:0 == 1
        " Only one word
        call IMRemove(a:bang, {}, firstWord)
    else
        " Multiple words - need to call with all arguments
        " Use call() function to pass variable number of arguments
        let args = [a:bang, {}, firstWord]
        for i in range(2, a:0)
            call add(args, a:{i})
        endfor
        call call('IMRemove', args)
    endif
endfunction

command! -nargs=+ -bang IMAdd :call s:IMAddWrapper(<q-bang>, <f-args>)
command! -nargs=+ -bang IMRemove :call s:IMRemoveWrapper(<q-bang>, <f-args>)
command! -nargs=+ -bang IMReorder :call IMReorder(<q-bang>, {}, <f-args>)

let s:ZFVimIM_dbItemReorderThreshold = 1
function! s:dbItemReorderFunc(item1, item2)
    if (a:item2['count'] - a:item1['count']) - s:ZFVimIM_dbItemReorderThreshold > 0
        return 1
    elseif (a:item1['count'] - a:item2['count']) - s:ZFVimIM_dbItemReorderThreshold > 0
        return -1
    else
        return 0
    endif
endfunction
function! ZFVimIM_dbItemReorder(dbItem)
    call ZFVimIM_DEBUG_profileStart('ItemReorder')
    let tmp = []
    let i = 0
    let iEnd = len(a:dbItem['wordList'])
    while i < iEnd
        call add(tmp, {
                    \   'word' : a:dbItem['wordList'][i],
                    \   'count' : a:dbItem['countList'][i],
                    \ })
        let i += 1
    endwhile
    call sort(tmp, function('s:dbItemReorderFunc'))
    let a:dbItem['wordList'] = []
    let a:dbItem['countList'] = []
    for item in tmp
        call add(a:dbItem['wordList'], item['word'])
        call add(a:dbItem['countList'], item['count'])
    endfor
    call ZFVimIM_DEBUG_profileStop()
endfunction

" dbItemEncoded:
"   'a#啊,阿#123'
" dbItem:
"   {
"     'key' : 'a',
"     'wordList' : ['啊', '阿'],
"     'countList' : [123],
"   }
function! ZFVimIM_dbItemDecode(dbItemEncoded)
    let split = split(a:dbItemEncoded, g:ZFVimIM_KEY_S_MAIN)
    let wordList = split(split[1], g:ZFVimIM_KEY_S_SUB)
    for i in range(len(wordList))
        let wordList[i] = substitute(
                    \   substitute(wordList[i], g:ZFVimIM_KEY_SR_MAIN, g:ZFVimIM_KEY_S_MAIN, 'g'),
                    \   g:ZFVimIM_KEY_SR_SUB, g:ZFVimIM_KEY_S_SUB, 'g'
                    \ )
    endfor
    let countList = []
    for cnt in split(get(split, 2, ''), g:ZFVimIM_KEY_S_SUB)
        call add(countList, str2nr(cnt))
    endfor
    while len(countList) < len(wordList)
        call add(countList, 0)
    endwhile
    return {
                \   'key' : split[0],
                \   'wordList' : wordList,
                \   'countList' : countList,
                \ }
endfunction

function! ZFVimIM_dbItemEncode(dbItem)
    let dbItemEncoded = a:dbItem['key']
    let dbItemEncoded .= g:ZFVimIM_KEY_S_MAIN
    for i in range(len(a:dbItem['wordList']))
        if i != 0
            let dbItemEncoded .= g:ZFVimIM_KEY_S_SUB
        endif
        let dbItemEncoded .= substitute(
                    \   substitute(a:dbItem['wordList'][i], g:ZFVimIM_KEY_S_MAIN, g:ZFVimIM_KEY_SR_MAIN, 'g'),
                    \   g:ZFVimIM_KEY_S_SUB, g:ZFVimIM_KEY_SR_SUB, 'g'
                    \ )
    endfor
    let iEnd = len(a:dbItem['countList']) - 1
    while iEnd >= 0
        if a:dbItem['countList'][iEnd] > 0
            break
        endif
        let iEnd -= 1
    endwhile
    let i = 0
    while i <= iEnd
        if i == 0
            let dbItemEncoded .= g:ZFVimIM_KEY_S_MAIN
        else
            let dbItemEncoded .= g:ZFVimIM_KEY_S_SUB
        endif
        let dbItemEncoded .= a:dbItem['countList'][i]
        let i += 1
    endwhile
    return dbItemEncoded
endfunction

if !exists('*ZFVimIM_complete')
    function! ZFVimIM_complete(key, ...)
        return ZFVimIM_completeDefault(a:key, get(a:, 1, {}))
    endfunction
endif


" db: {
"   'dbSearchCache' : {
"     'c . start . pattern' : index,
"   },
"   'dbSearchCacheKeys' : [
"     'c . start . pattern',
"   ],
" }
function! ZFVimIM_dbSearch(db, c, pattern, start)
    let patternKey = a:c . a:start . a:pattern
    let index = get(a:db['dbSearchCache'], patternKey, -2)
    if index != -2
        return index
    endif
    " this may take long time for large db
    call ZFVimIM_DEBUG_profileStart('dbSearch')
    let index = match(get(a:db['dbMap'], a:c, []), a:pattern, a:start)
    call ZFVimIM_DEBUG_profileStop()

    if a:start == 0
        let a:db['dbSearchCache'][patternKey] = index
        call add(a:db['dbSearchCacheKeys'], patternKey)

        " limit cache size
        if len(a:db['dbSearchCacheKeys']) >= 300
            for patternKey in remove(a:db['dbSearchCacheKeys'], 0, 200)
                unlet a:db['dbSearchCache'][patternKey]
            endfor
        endif
    endif

    return index
endfunction

function! ZFVimIM_dbSearchCacheClear(db)
    let a:db['dbSearchCache'] = {}
    let a:db['dbSearchCacheKeys'] = []
endfunction

" Clear all cache files for all dictionaries
function! ZFVimIM_cacheClearAll()
    let cachePath = ZFVimIM_cachePath()
    if !isdirectory(cachePath)
        echo "キャッシュディレクトリが存在しません: " . cachePath
        return
    endif
    
    let cacheFiles = glob(cachePath . '/dbCache_*.vim', 0, 1)
    let deletedCount = 0
    for cacheFile in cacheFiles
        if delete(cacheFile) == 0
            let deletedCount = deletedCount + 1
        endif
    endfor
    
    if deletedCount > 0
        echo "キャッシュファイル " . deletedCount . " 個を削除しました"
    else
        echo "削除するキャッシュファイルが見つかりませんでした"
    endif
endfunction

" Clear cache and reload all dictionaries
function! ZFVimIM_cacheUpdate()
    " Clear all cache files
    call ZFVimIM_cacheClearAll()
    
    " Reload all dictionaries
    if exists('g:ZFVimIM_db') && !empty(g:ZFVimIM_db)
        let reloadedCount = 0
        for db in g:ZFVimIM_db
            if has_key(db, 'implData') && has_key(db['implData'], 'dictPath')
                let dictPath = db['implData']['dictPath']
                if filereadable(dictPath)
                    " Clear search cache
                    call ZFVimIM_dbSearchCacheClear(db)
                    " Reload dictionary (this will regenerate cache)
                    call ZFVimIM_dbLoad(db, dictPath)
                    let reloadedCount = reloadedCount + 1
                endif
            endif
        endfor
        
        if reloadedCount > 0
            echo "辞書 " . reloadedCount . " 個を再読み込みし、キャッシュを更新しました"
        else
            echo "再読み込みする辞書が見つかりませんでした。Vimを再起動してください。"
        endif
    else
        echo "辞書がまだ読み込まれていません。Vimを再起動するか、:ZFVimIMReload を実行してください。"
    endif
endfunction

" Clear cache for a specific dictionary file
function! ZFVimIM_cacheClearForFile(dictFile)
    let cacheFile = s:dbLoad_getCacheFile(a:dictFile)
    if filereadable(cacheFile)
        if delete(cacheFile) == 0
            return 1
        endif
    endif
    return 0
endfunction

" Regenerate cache for a specific dictionary file in background
function! ZFVimIM_cacheRegenerateForFile(dictFile)
    if !filereadable(a:dictFile)
        return
    endif
    
    " Find the database that uses this file
    let targetDb = {}
    if exists('g:ZFVimIM_db') && !empty(g:ZFVimIM_db)
        for db in g:ZFVimIM_db
            if has_key(db, 'implData') && has_key(db['implData'], 'dictPath')
                if db['implData']['dictPath'] ==# a:dictFile
                    let targetDb = db
                    break
                endif
            endif
        endfor
    endif
    
    " Clear the cache file
    call ZFVimIM_cacheClearForFile(a:dictFile)
    
    " Regenerate cache in background using timer
    if has('timers')
        " Use timer to regenerate cache asynchronously
        call timer_start(100, {-> s:cacheRegenerateAsync(a:dictFile, targetDb)})
    else
        " Fallback: regenerate synchronously
        if !empty(targetDb)
            call ZFVimIM_dbSearchCacheClear(targetDb)
            call ZFVimIM_dbLoad(targetDb, a:dictFile)
        endif
    endif
endfunction

" Async cache regeneration function
function! s:cacheRegenerateAsync(dictFile, db)
    try
        if !empty(a:db)
            " Clear search cache
            call ZFVimIM_dbSearchCacheClear(a:db)
            " Reload dictionary (this will regenerate cache)
            call ZFVimIM_dbLoad(a:db, a:dictFile)
        else
            " If database not found, just clear the cache
            " It will be regenerated on next load
            call ZFVimIM_cacheClearForFile(a:dictFile)
        endif
    catch
        " Silently fail if there's an error
    endtry
endfunction


" ============================================================
" Helper functions removed - only TXT format is supported now

function! s:dbLoad(db, dbFile, ...)
    call ZFVimIM_dbSearchCacheClear(a:db)

    " explicitly clear db content
    let a:db['dbMap'] = {}
    let a:db['dbEdit'] = []

    let dbMap = a:db['dbMap']
    
    " Try to load from cache first
    let cacheFile = s:dbLoad_getCacheFile(a:dbFile)
    if s:dbLoad_tryLoadFromCache(dbMap, a:dbFile, cacheFile)
        " Successfully loaded from cache
        call ZFVimIM_DEBUG_profileStart('dbLoadCountFile')
    else
        " Try to use Python script for faster loading if available
        if s:dbLoad_tryUsePythonScript(dbMap, a:dbFile, cacheFile, get(a:, 1, ''))
            " Successfully loaded using Python script
            call ZFVimIM_DEBUG_profileStart('dbLoadCountFile')
        else
            " Fallback to VimScript loading
            " Load from source file and create cache
            call ZFVimIM_DEBUG_profileStart('dbLoadFile')
            let lines = readfile(a:dbFile)
            call ZFVimIM_DEBUG_profileStop()
            if empty(lines)
                return
            endif

            call ZFVimIM_DEBUG_profileStart('dbLoad')
            " Load from TXT format (key word1 word2 ...)
            for line in lines
                let line = substitute(line, '^\s*\(.\{-}\)\s*$', '\1', '')
                " Skip empty lines and comments
                if empty(line) || line[0] ==# '#'
                    continue
                endif
                " Handle escaped spaces
                if match(line, '\\ ') >= 0
                    let wordListTmp = split(substitute(line, '\\ ', '_ZFVimIM_space_', 'g'))
                    if !empty(wordListTmp)
                        let key = remove(wordListTmp, 0)
                    endif
                    let wordList = []
                    for word in wordListTmp
                        call add(wordList, substitute(word, '_ZFVimIM_space_', ' ', 'g'))
                    endfor
                else
                    let wordList = split(line)
                    if !empty(wordList)
                        let key = remove(wordList, 0)
                    endif
                endif
                if !empty(wordList) && !empty(key)
                    if !exists('dbMap[key[0]]')
                        let dbMap[key[0]] = []
                    endif
                    call add(dbMap[key[0]], ZFVimIM_dbItemEncode({
                                \   'key' : key,
                                \   'wordList' : wordList,
                                \   'countList' : [],
                                \ }))
                endif
            endfor
            call ZFVimIM_DEBUG_profileStop()
            
            " Save to cache for next time
            call s:dbLoad_saveToCache(dbMap, cacheFile)
        endif
    endif

    let dbCountFile = get(a:, 1, '')
    if filereadable(dbCountFile)
        call ZFVimIM_DEBUG_profileStart('dbLoadCountFile')
        let lines = readfile(dbCountFile)
        call ZFVimIM_DEBUG_profileStop()

        call ZFVimIM_DEBUG_profileStart('dbLoadCount')
        for line in lines
            let countTextList = split(line)
            if len(countTextList) <= 1
                continue
            endif
            let key = countTextList[0]
            let index = match(get(dbMap, key[0], []), '^' . key . g:ZFVimIM_KEY_S_MAIN)
            if index < 0
                continue
            endif
            let dbItem = ZFVimIM_dbItemDecode(dbMap[key[0]][index])
            let wordListLen = len(dbItem['wordList'])
            for i in range(len(countTextList) - 1)
                if i >= wordListLen
                    break
                endif
                let dbItem['countList'][i] = str2nr(countTextList[i + 1])
            endfor
            call ZFVimIM_dbItemReorder(dbItem)
            let dbMap[key[0]][index] = ZFVimIM_dbItemEncode(dbItem)
        endfor
        call ZFVimIM_DEBUG_profileStop()
    endif
endfunction

" Get cache file path for a dictionary file
function! s:dbLoad_getCacheFile(dbFile)
    " Use MD5 hash of file path as cache file name to avoid conflicts
    " For simplicity, use a hash of the file path
    let fileHash = substitute(a:dbFile, '[^a-zA-Z0-9]', '_', 'g')
    " Limit hash length to avoid filename issues
    if len(fileHash) > 100
        let fileHash = strpart(fileHash, 0, 100)
    endif
    let cacheFile = ZFVimIM_cachePath() . '/dbCache_' . fileHash . '.vim'
    return cacheFile
endfunction

" Try to load dbMap from cache file
" Returns 1 if successful, 0 otherwise
function! s:dbLoad_tryLoadFromCache(dbMap, dbFile, cacheFile)
    " Check if cache file exists and is newer than source file
    if !filereadable(a:cacheFile) || !filereadable(a:dbFile)
        return 0
    endif
    
    " Check if cache is newer than source file
    let cacheMtime = getftime(a:cacheFile)
    let sourceMtime = getftime(a:dbFile)
    if cacheMtime < 0 || sourceMtime < 0 || cacheMtime < sourceMtime
        return 0
    endif
    
    " Try to load from cache file
    " Cache format: each line is a char prefix, followed by encoded items
    try
        call ZFVimIM_DEBUG_profileStart('dbLoadCache')
        let lines = readfile(a:cacheFile)
        if empty(lines)
            return 0
        endif
        
        " Parse cache file
        " Format: "CHAR|item1|item2|..."
        let currentChar = ''
        let currentItems = []
        for line in lines
            if line =~# '^[a-z]$'
                " New character prefix
                if !empty(currentChar)
                    let a:dbMap[currentChar] = currentItems
                endif
                let currentChar = line
                let currentItems = []
            elseif !empty(currentChar) && line =~# '^|'
                " Item for current character (starts with | to escape special chars)
                let item = strpart(line, 1)
                call add(currentItems, item)
            endif
        endfor
        " Don't forget the last character
        if !empty(currentChar)
            let a:dbMap[currentChar] = currentItems
        endif
        
        call ZFVimIM_DEBUG_profileStop()
        return 1
    catch
        " If anything fails, fall back to loading from source
        return 0
    endtry
endfunction

" Try to use Python script for faster loading
" Returns 1 if successful, 0 otherwise
function! s:dbLoad_tryUsePythonScript(dbMap, dbFile, cacheFile, dbCountFile)
    " Check if Python is available
    if !executable('python') && !executable('python3')
        return 0
    endif
    
    " Check if Python script exists
    let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
    let sfileDir = expand('<sfile>:p:h:h')
    if isdirectory(sfileDir . '/misc')
        let pluginDir = sfileDir
    else
        if !isdirectory(pluginDir . '/misc')
            let altPath = stdpath('config') . '/lazy/ZFVimIM'
            if isdirectory(altPath . '/misc')
                let pluginDir = altPath
            endif
        endif
    endif
    
    let scriptPath = pluginDir . '/misc/dbLoad.py'
    if !filereadable(scriptPath)
        return 0
    endif
    
    " Get cache path for Python script output
    let cachePath = ZFVimIM_cachePath()
    let cacheDir = fnamemodify(a:cacheFile, ':h')
    if !isdirectory(cacheDir)
        call mkdir(cacheDir, 'p')
    endif
    
    " Use a temporary cache path for Python script output
    let pythonCachePath = cachePath . '/dbLoadCache'
    
    " Determine Python command
    let pythonCmd = executable('python3') ? 'python3' : 'python'
    
    " Run Python script to generate cache files
    try
        let scriptPathAbs = CygpathFix_absPath(scriptPath)
        let dbFileAbs = CygpathFix_absPath(a:dbFile)
        let dbCountFileAbs = empty(a:dbCountFile) ? '' : CygpathFix_absPath(a:dbCountFile)
        let cachePathAbs = CygpathFix_absPath(pythonCachePath)
        
        " Build command with proper quoting for paths with spaces
        let cmd = pythonCmd . ' "' . scriptPathAbs . '" "' . dbFileAbs . '" "' . dbCountFileAbs . '" "' . cachePathAbs . '"'
        let result = system(cmd)
        
        if v:shell_error != 0
            return 0
        endif
        
        " Load from Python-generated cache files (one file per character)
        call ZFVimIM_DEBUG_profileStart('dbLoadPythonCache')
        for c_ in range(char2nr('a'), char2nr('z'))
            let c = nr2char(c_)
            let cachePartFile = pythonCachePath . '_' . c
            if filereadable(cachePartFile)
                let lines = readfile(cachePartFile)
                if !empty(lines)
                    if !has_key(a:dbMap, c)
                        let a:dbMap[c] = []
                    endif
                    call extend(a:dbMap[c], lines)
                endif
            endif
        endfor
        call ZFVimIM_DEBUG_profileStop()
        
        " Convert Python cache format to Vim cache format and save
        call s:dbLoad_saveToCache(a:dbMap, a:cacheFile)
        
        " Clean up Python cache files
        for c_ in range(char2nr('a'), char2nr('z'))
            let c = nr2char(c_)
            let cachePartFile = pythonCachePath . '_' . c
            if filereadable(cachePartFile)
                call delete(cachePartFile)
            endif
        endfor
        
        return 1
    catch
        " If Python script fails, fall back to VimScript loading
        return 0
    endtry
endfunction

" Save dbMap to cache file
function! s:dbLoad_saveToCache(dbMap, cacheFile)
    try
        let cacheDir = fnamemodify(a:cacheFile, ':h')
        if !isdirectory(cacheDir)
            call mkdir(cacheDir, 'p')
        endif
        
        call ZFVimIM_DEBUG_profileStart('dbSaveCache')
        let lines = []
        " Write cache file in format: "CHAR" followed by items prefixed with "|"
        for c in ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z']
            if has_key(a:dbMap, c) && !empty(a:dbMap[c])
                call add(lines, c)
                for item in a:dbMap[c]
                    " Prefix with | to escape and identify as item line
                    call add(lines, '|' . item)
                endfor
            endif
        endfor
        
        call writefile(lines, a:cacheFile)
        call ZFVimIM_DEBUG_profileStop()
    catch
        " Silently fail if cache saving doesn't work
    endtry
endfunction

function! s:dbSave(db, dbFile, ...)
    let dbCountFile = get(a:, 1, '')

    let dbMap = a:db['dbMap']
    
    " Save as TXT format (key word1 word2 ...)
    call ZFVimIM_DEBUG_profileStart('dbSave')
    let txtLines = []
    " Sort keys for consistent output
    let sortedKeys = []
    for c in keys(dbMap)
        for dbItemEncoded in dbMap[c]
            let dbItem = ZFVimIM_dbItemDecode(dbItemEncoded)
            call add(sortedKeys, dbItem['key'])
        endfor
    endfor
    call sort(sortedKeys)
    
    for key in sortedKeys
        " Find the item
        let found = 0
        for c in keys(dbMap)
            for dbItemEncoded in dbMap[c]
                let dbItem = ZFVimIM_dbItemDecode(dbItemEncoded)
                if dbItem['key'] ==# key
                    let found = 1
                    " Format: key word1 word2 ...
                    " Escape spaces in words
                    let wordParts = []
                    for word in dbItem['wordList']
                        " Escape spaces in words
                        let escapedWord = substitute(word, ' ', '\\ ', 'g')
                        call add(wordParts, escapedWord)
                    endfor
                    let line = key . ' ' . join(wordParts, ' ')
                    call add(txtLines, line)
                    break
                endif
            endfor
            if found
                break
            endif
        endfor
    endfor
    call ZFVimIM_DEBUG_profileStop()

    " Show progress for large dictionaries
    let totalEntries = len(txtLines)
    if totalEntries > 10000
        echom '[ZFVimIM] Preparing to save dictionary (' . totalEntries . ' entries)...'
        redraw
    endif

    call ZFVimIM_DEBUG_profileStart('dbSaveFile')
    
    " For very large files, use Python script for faster saving
    if totalEntries > 50000 && (executable('python') || executable('python3'))
        let pythonCmd = executable('python3') ? 'python3' : 'python'
        let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
        let sfileDir = expand('<sfile>:p:h:h')
        if isdirectory(sfileDir . '/misc')
            let pluginDir = sfileDir
        endif
        let dbFuncScript = pluginDir . '/misc/dbFunc.py'
        let cachePath = ZFVimIM_cachePath()
        
        if filereadable(dbFuncScript)
            " Use Python to save - write to temp file first, then use Python
            let tmpFile = cachePath . '/dbSaveTmp.txt'
            if writefile(txtLines, tmpFile) == 0
                " Use Python to move and optimize
                let cmd = pythonCmd . ' -c "'
                let cmd .= 'import shutil; '
                let cmd .= 'shutil.move(\"' . tmpFile . '\", \"' . a:dbFile . '\")'
                let cmd .= '"'
                let result = system(cmd)
                if v:shell_error == 0
                    echom '[ZFVimIM] Dictionary saved successfully: ' . totalEntries . ' entries (using Python)'
                    call ZFVimIM_DEBUG_profileStop()
                    return
                endif
            endif
        endif
    endif
    
    " Fallback to VimScript writefile
    if totalEntries > 10000
        echom '[ZFVimIM] Writing to file (this may take a while for large dictionaries)...'
        redraw
    endif
    
    if writefile(txtLines, a:dbFile) == 0
        echom '[ZFVimIM] Dictionary saved successfully: ' . totalEntries . ' entries'
    else
        echom '[ZFVimIM] Error: Failed to save dictionary file'
    endif
    call ZFVimIM_DEBUG_profileStop()
    
    " Save count file if needed
    if !empty(dbCountFile)
        let countLines = []
        call ZFVimIM_DEBUG_profileStart('dbSaveCount')
        for c in keys(dbMap)
            for dbItemEncoded in dbMap[c]
                let dbItem = ZFVimIM_dbItemDecode(dbItemEncoded)
                let countLine = dbItem['key']
                for cnt in dbItem['countList']
                    if cnt <= 0
                        break
                    endif
                    let countLine .= ' '
                    let countLine .= cnt
                endfor
                if countLine != dbItem['key']
                    call add(countLines, countLine)
                endif
            endfor
        endfor
        call ZFVimIM_DEBUG_profileStop()

        call ZFVimIM_DEBUG_profileStart('dbSaveCountFile')
        call writefile(countLines, dbCountFile)
        call ZFVimIM_DEBUG_profileStop()
    endif
endfunction

" ============================================================
function! s:dbEditWildKey(db, word, key, action)
    if empty(a:db)
        if g:ZFVimIM_dbIndex >= len(g:ZFVimIM_db)
            return
        endif
        let db = g:ZFVimIM_db[g:ZFVimIM_dbIndex]
    else
        let db = a:db
    endif
    if !get(db, 'editable', 1) || !empty(get(db, 'dbCallback', ''))
        return
    endif
    if !empty(a:key)
        call s:dbEdit(db, a:word, a:key, a:action)
        return
    endif
    if empty(a:word)
        return
    endif

    " Search for all keys containing this word
    " Optimized: decode items and check wordList directly instead of regex matching
    let keyToApply = []
    let dbMap = db['dbMap']
    let totalItems = 0
    for c in keys(dbMap)
        let totalItems += len(dbMap[c])
    endfor
    
    " For very large dictionaries, warn user and limit search
    let maxCheck = get(g:, 'ZFVimIM_wildKeySearchLimit', 50000)
    if totalItems > maxCheck
        echom '[ZFVimIM] Dictionary is very large (' . totalItems . ' entries). Searching may take time...'
        echom '[ZFVimIM] Tip: Specify key for instant removal: IMRemove ' . a:word . ' <key>'
    endif
    
    let checkedCount = 0
    for c in keys(dbMap)
        for dbItemEncoded in dbMap[c]
            let checkedCount += 1
            " Limit search to prevent hanging on very large dictionaries
            if checkedCount > maxCheck
                echom '[ZFVimIM] Warning: Search limit reached (' . maxCheck . ' entries).'
                echom '[ZFVimIM] Please specify key explicitly: IMRemove ' . a:word . ' <key>'
                if !empty(keyToApply)
                    echom '[ZFVimIM] Found ' . len(keyToApply) . ' key(s) so far. Continuing with those...'
                endif
                break
            endif
            
            let dbItem = ZFVimIM_dbItemDecode(dbItemEncoded)
            " Check if word exists in wordList
            let wordIndex = index(dbItem['wordList'], a:word)
            if wordIndex >= 0
                call add(keyToApply, dbItem['key'])
            endif
        endfor
        if checkedCount > maxCheck
            break
        endif
    endfor

    if empty(keyToApply)
        echom '[ZFVimIM] Word not found: ' . a:word
        if checkedCount >= maxCheck
            echom '[ZFVimIM] Note: Search was limited. Word may exist in unchecked entries.'
            echom '[ZFVimIM] Try: IMRemove ' . a:word . ' <key> (specify the key)'
        endif
        return
    endif

    echom '[ZFVimIM] Found word in ' . len(keyToApply) . ' key(s). Removing...'
    for key in keyToApply
        call s:dbEdit(db, a:word, key, a:action)
    endfor
    echom '[ZFVimIM] Removed word from ' . len(keyToApply) . ' key(s).'
endfunction

function! s:dbEdit(db, word, key, action)
    if empty(a:db)
        if g:ZFVimIM_dbIndex >= len(g:ZFVimIM_db)
            return
        endif
        let db = g:ZFVimIM_db[g:ZFVimIM_dbIndex]
    else
        let db = a:db
    endif
    if !get(db, 'editable', 1) || !empty(get(db, 'dbCallback', ''))
        return
    endif
    if empty(a:key) || empty(a:word)
        return
    endif

    let dbEditItem = {
                \   'action' : a:action,
                \   'key' : a:key,
                \   'word' : a:word,
                \ }

    if !exists("db['dbEdit']")
        let db['dbEdit'] = []
    endif
    call add(db['dbEdit'], dbEditItem)

    let dbEditLimit = get(g:, 'ZFVimIM_dbEditLimit', 500)
    if dbEditLimit > 0 && len(db['dbEdit']) > dbEditLimit
        call remove(db['dbEdit'], 0, len(db['dbEdit']) - dbEditLimit - 1)
    endif

    if g:ZFVimIM_dbEditApplyFlag == 0
        call s:dbEditApply(db, [dbEditItem])
        doautocmd User ZFVimIM_event_OnUpdateDb
    else
        let db['implData']['_dbLoadRequired'] = 1
    endif
endfunction

function! s:dbEditApply(db, dbEdit)
    call ZFVimIM_DEBUG_profileStart('dbEditApply')
    call s:dbEditMap(a:db, a:dbEdit)
    call ZFVimIM_DEBUG_profileStop()
endfunction

function! s:dbEditMap(db, dbEdit)
    let dbMap = a:db['dbMap']
    let dbEdit = a:dbEdit
    for e in dbEdit
        let key = e['key']
        let word = e['word']
        if e['action'] == 'add'
            if !exists('dbMap[key[0]]')
                let dbMap[key[0]] = []
            endif
            let index = ZFVimIM_dbSearch(a:db, key[0],
                        \ '^' . key . g:ZFVimIM_KEY_S_MAIN,
                        \ 0)
            if index >= 0
                let dbItem = ZFVimIM_dbItemDecode(dbMap[key[0]][index])
                let wordIndex = index(dbItem['wordList'], word)
                if wordIndex >= 0
                    let dbItem['countList'][wordIndex] += 1
                else
                    call add(dbItem['wordList'], word)
                    call add(dbItem['countList'], 1)
                endif
                call ZFVimIM_dbItemReorder(dbItem)
                let dbMap[key[0]][index] = ZFVimIM_dbItemEncode(dbItem)
            else
                call add(dbMap[key[0]], ZFVimIM_dbItemEncode({
                            \   'key' : key,
                            \   'wordList' : [word],
                            \   'countList' : [1],
                            \ }))
                call ZFVimIM_dbSearchCacheClear(a:db)
            endif
        elseif e['action'] == 'remove'
            let index = ZFVimIM_dbSearch(a:db, key[0],
                        \ '^' . key . g:ZFVimIM_KEY_S_MAIN,
                        \ 0)
            if index < 0
                echom '[ZFVimIM] Key not found: ' . key
                continue
            endif
            let dbItem = ZFVimIM_dbItemDecode(dbMap[key[0]][index])
            let wordIndex = index(dbItem['wordList'], word)
            if wordIndex < 0
                echom '[ZFVimIM] Word "' . word . '" not found in key "' . key . '"'
                echom '[ZFVimIM] Available words: ' . join(dbItem['wordList'], ', ')
                continue
            endif
            echom '[ZFVimIM] Removing word "' . word . '" from key "' . key . '"'
            call remove(dbItem['wordList'], wordIndex)
            call remove(dbItem['countList'], wordIndex)
            if empty(dbItem['wordList'])
                call remove(dbMap[key[0]], index)
                if empty(dbMap[key[0]])
                    call remove(dbMap, key[0])
                endif
                call ZFVimIM_dbSearchCacheClear(a:db)
                echom '[ZFVimIM] Key "' . key . '" removed (no words left)'
            else
                " Update the item in dbMap after removing word
                let dbMap[key[0]][index] = ZFVimIM_dbItemEncode(dbItem)
                echom '[ZFVimIM] Word removed. Remaining words: ' . join(dbItem['wordList'], ', ')
            endif
        elseif e['action'] == 'reorder'
            let index = ZFVimIM_dbSearch(a:db, key[0],
                        \ '^' . key . g:ZFVimIM_KEY_S_MAIN,
                        \ 0)
            if index < 0
                continue
            endif
            let dbItem = ZFVimIM_dbItemDecode(dbMap[key[0]][index])
            let wordIndex = index(dbItem['wordList'], word)
            if wordIndex < 0
                continue
            endif
            let dbItem['countList'][wordIndex] = 0
            let sum = 0
            for cnt in dbItem['countList']
                let sum += cnt
            endfor
            let dbItem['countList'][wordIndex] = float2nr(floor(sum / 3))
            call ZFVimIM_dbItemReorder(dbItem)
            let dbMap[key[0]][index] = ZFVimIM_dbItemEncode(dbItem)
        endif
    endfor
endfunction

" ============================================================
if 0 " test db
    let g:ZFVimIM_db = [{
                \   'dbId' : '999',
                \   'name' : 'test',
                \   'priority' : 100,
                \   'dbMap' : {
                \     'a' : [
                \       'a#啊,阿#3,2',
                \       'ai#爱,哀#2',
                \     ],
                \     'a' : [
                \       'ceshi#测试',
                \     ],
                \   },
                \   'dbEdit' : [
                \   ],
                \   'implData' : {
                \   },
                \ }]
endif

