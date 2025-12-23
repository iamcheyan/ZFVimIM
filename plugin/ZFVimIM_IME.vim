
" ============================================================
if !exists('g:ZFVimIM_autoAddWordLen')
    let g:ZFVimIM_autoAddWordLen=3*4
endif
" function(userWord)
" userWord: see ZFVimIM_complete
" return: 1 if need add word
if !exists('g:ZFVimIM_autoAddWordChecker')
    let g:ZFVimIM_autoAddWordChecker=[]
endif

if !exists('g:ZFVimIM_symbolMap')
    let g:ZFVimIM_symbolMap = {}
endif

" 退出插入模式时自动停止输入法
if !exists('g:ZFVimIME_autoStopOnInsertLeave')
    let g:ZFVimIME_autoStopOnInsertLeave = 1
endif

" ============================================================
" Get database directory path (in user config directory)
function! s:ZFVimIM_getDbDir()
    let dbDir = stdpath('config') . '/zfvimim_db'
    " Ensure directory exists
    if !isdirectory(dbDir)
        call mkdir(dbDir, 'p')
    endif
    return dbDir
endfunction

" Get database file path from YAML file path
" Database files are stored in ~/.config/nvim/zfvimim_db/
function! s:ZFVimIM_getDbPath(yamlPath)
    if empty(a:yamlPath)
        return ''
    endif
    
    " Get database directory
    let dbDir = s:ZFVimIM_getDbDir()
    
    " Get base filename from YAML path
    let yamlName = fnamemodify(a:yamlPath, ':t')
    let dbName = substitute(yamlName, '\.yaml$', '.db', '')
    if dbName ==# yamlName
        " No .yaml extension, add .db
        let dbName = dbName . '.db'
    endif
    
    return dbDir . '/' . dbName
endfunction

" Get YAML file path from database file path
" Try to find original YAML path from database name
function! s:ZFVimIM_getYamlPath(dbPath)
    if empty(a:dbPath)
        return ''
    endif
    
    " First, try to get from loaded dictionaries
    if exists('g:ZFVimIM_db')
        for db in g:ZFVimIM_db
            if has_key(db, 'implData') && has_key(db['implData'], 'dictPath')
                if db['implData']['dictPath'] ==# a:dbPath
                    " Found matching DB, return its YAML path
                    if has_key(db['implData'], 'yamlPath')
                        return db['implData']['yamlPath']
                    endif
                endif
            endif
        endfor
    endif
    
    " Fallback: try to find YAML file in dict directory
    let dbName = fnamemodify(a:dbPath, ':t')
    let yamlName = substitute(dbName, '\.db$', '.yaml', '')
    if yamlName ==# dbName
        let yamlName = yamlName . '.yaml'
    endif
    
    " Try plugin dict directory
    let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
    let sfileDir = expand('<sfile>:p:h:h')
    if isdirectory(sfileDir . '/dict')
        let pluginDir = sfileDir
    endif
    let dictDir = pluginDir . '/dict'
    let yamlPath = dictDir . '/' . yamlName
    
    " Check if file exists
    if filereadable(yamlPath)
        return yamlPath
    endif
    
    " Try with default_dict_name if set
    if exists('g:zfvimim_default_dict_name') && !empty(g:zfvimim_default_dict_name)
        let defaultDictName = g:zfvimim_default_dict_name
        if defaultDictName !~ '\.yaml$'
            let defaultDictName = defaultDictName . '.yaml'
        endif
        let yamlPath = dictDir . '/' . defaultDictName
        if filereadable(yamlPath)
            return yamlPath
        endif
    endif
    
    " Try zfvimim_dict_path if set
    if exists('g:zfvimim_dict_path') && !empty(g:zfvimim_dict_path)
        let yamlPath = expand(g:zfvimim_dict_path)
        if filereadable(yamlPath)
            return yamlPath
        endif
    endif
    
    " Last resort: return dict directory path
    return yamlPath
endfunction

" Auto load default dictionary if zfvimim_dict_path is set or use default
function! s:ZFVimIM_autoLoadDict()
    let dictPath = ''
    
    " Get plugin directory - use stdpath for reliability in LazyVim
    let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
    " Try <sfile> method first, fallback to stdpath
    let sfileDir = expand('<sfile>:p:h:h')
    if isdirectory(sfileDir . '/dict')
        let pluginDir = sfileDir
    endif
    let dictDir = pluginDir . '/dict'
    
    " Determine default dictionary name
    " Default dictionary is default.yaml
    " If zfvimim_default_dict_name is set, use it; otherwise use default.yaml
    if exists('g:zfvimim_default_dict_name') && !empty(g:zfvimim_default_dict_name)
        let defaultDictName = g:zfvimim_default_dict_name
        " Add .yaml extension if not present
        if defaultDictName !~ '\.yaml$'
            let defaultDictName = defaultDictName . '.yaml'
        endif
        
        " First, try to find in module directory
        if exists('*ZFVimIM_getModuleDictPath')
            let dictNameNoExt = substitute(defaultDictName, '\.yaml$', '', '')
            let moduleDictPath = ZFVimIM_getModuleDictPath(dictNameNoExt, dictNameNoExt)
            if !empty(moduleDictPath) && filereadable(moduleDictPath)
                let defaultDict = moduleDictPath
            else
                " Fallback to regular dict directory
                let defaultDict = dictDir . '/' . defaultDictName
            endif
        else
            " Fallback to regular dict directory
            let defaultDict = dictDir . '/' . defaultDictName
        endif
    else
        " Default dictionary: default.yaml
        let defaultDict = dictDir . '/default.yaml'
    endif
    
    " Check if zfvimim_dict_path is set
    if exists('g:zfvimim_dict_path') && !empty(g:zfvimim_dict_path)
        let customDictPath = expand(g:zfvimim_dict_path)
        " If custom dict path is set, check if file exists
        if filereadable(customDictPath)
            let dictPath = customDictPath
        else
            " Custom dict file doesn't exist, fallback to default
            if filereadable(defaultDict)
                let dictPath = defaultDict
            endif
        endif
    else
        " Use default dictionary if zfvimim_dict_path is not set
        if filereadable(defaultDict)
            let dictPath = defaultDict
        endif
    endif
    
    " Load dictionary if path is valid and file exists
    if !empty(dictPath) && filereadable(dictPath)
        " Convert to DB path if YAML is specified (actual file used for loading)
        " Always use .db file - convert .yaml to .db if needed
        let actualDbPath = dictPath
        if dictPath =~ '\.yaml$'
            let actualDbPath = s:ZFVimIM_getDbPath(dictPath)
            
            " Auto-generate .db file if it doesn't exist
            if !filereadable(actualDbPath)
                let importSuccess = s:ZFVimIM_importDb(dictPath, actualDbPath, 0)
                " If import was successful, the dictionary will be loaded below
                " No need to reload here as it's a new load
            endif
        endif
        
        if !exists('g:ZFVimIM_db')
            let g:ZFVimIM_db = []
        endif
        
        " Check if dictionary is already loaded
        let dictName = fnamemodify(dictPath, ':t:r')
        let alreadyLoaded = 0
        for db in g:ZFVimIM_db
            if get(db, 'name', '') ==# dictName
                let alreadyLoaded = 1
                break
            endif
        endfor
        
        if !alreadyLoaded
            let db = ZFVimIM_dbInit({
                        \   'name' : dictName,
                        \   'priority' : 100,
                        \ })
            " Show loading message if we just imported
            if exists('importSuccess') && importSuccess
                echom '[ZFVimIM] 正在加载词库: ' . fnamemodify(dictPath, ':t')
            endif
            call ZFVimIM_dbLoad(db, actualDbPath)
            if exists('importSuccess') && importSuccess
                echom '[ZFVimIM] ✅ 输入法已重新加载完成'
            endif
            " Store actual DB path in implData (not TXT path)
            if !has_key(db, 'implData')
                let db['implData'] = {}
            endif
            let db['implData']['dictPath'] = actualDbPath
            " Also store original YAML path for reference
            let db['implData']['yamlPath'] = dictPath
        else
            " Update dictPath for already loaded dictionary
            for db in g:ZFVimIM_db
                if get(db, 'name', '') ==# dictName
                    if !has_key(db, 'implData')
                        let db['implData'] = {}
                    endif
                    " Convert to DB path if YAML is specified
                    let actualDbPath = dictPath
                    if dictPath =~ '\.yaml$'
                        let actualDbPath = s:ZFVimIM_getDbPath(dictPath)
                        
                        " Auto-generate .db file if it doesn't exist
                        if !filereadable(actualDbPath)
                            let importSuccess = s:ZFVimIM_importDb(dictPath, actualDbPath, 0)
                            " If import was successful, reload the dictionary
                            if importSuccess && filereadable(actualDbPath)
                                " Find and reload the database
                                for db in g:ZFVimIM_db
                                    if get(db, 'name', '') ==# dictName
                                        call ZFVimIM_dbSearchCacheClear(db)
                                        call ZFVimIM_dbLoad(db, actualDbPath)
                                        echom '[ZFVimIM] ✅ 输入法已重新加载完成'
                                        break
                                    endif
                                endfor
                            endif
                        endif
                    endif
                    let db['implData']['dictPath'] = actualDbPath
                    let db['implData']['yamlPath'] = dictPath
                    break
                endif
            endfor
        endif
    endif
endfunction

" Auto import YAML to DB if DB file doesn't exist
" Returns 1 if successful, 0 otherwise
function! s:ZFVimIM_autoImportDb(yamlPath, dbPath)
    return s:ZFVimIM_importDb(a:yamlPath, a:dbPath, 0)
endfunction

" Import YAML to DB
" Returns 1 if successful, 0 otherwise
" force: if 1, re-import even if DB exists
function! s:ZFVimIM_importDb(yamlPath, dbPath, force)
    " Check if YAML file exists
    if !filereadable(a:yamlPath)
        return 0
    endif
    
    " Check if DB file already exists (unless force)
    if !a:force && filereadable(a:dbPath)
        return 0
    endif
    
    " Get Python command
    let pythonCmd = executable('python3') ? 'python3' : 'python'
    if !executable(pythonCmd)
        echom '[ZFVimIM] Python not found, cannot auto-import dictionary'
        return 0
    endif
    
    " Get script path
    let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
    let sfileDir = expand('<sfile>:p:h:h')
    if isdirectory(sfileDir . '/misc')
        let pluginDir = sfileDir
    endif
    let scriptPath = pluginDir . '/misc/import_txt_to_db.py'
    if !filereadable(scriptPath)
        echom '[ZFVimIM] Import script not found: ' . scriptPath
        return 0
    endif
    
    " Show importing message
    if a:force
        echom '[ZFVimIM] 正在重新导入词库: ' . fnamemodify(a:yamlPath, ':t')
    else
        echom '[ZFVimIM] 正在自动导入词库: ' . fnamemodify(a:yamlPath, ':t')
    endif
    
    " Run import script
    let cmd = pythonCmd . ' "' . scriptPath . '" "' . a:yamlPath . '" "' . a:dbPath . '"'
    let result = system(cmd)
    
    " Check if import was successful
    if v:shell_error == 0 && filereadable(a:dbPath)
        echom '[ZFVimIM] ✅ 词库导入成功: ' . fnamemodify(a:yamlPath, ':t')
        if a:force
            echom '[ZFVimIM] 正在重新加载输入法...'
        endif
        return 1
    else
        echom '[ZFVimIM] ❌ 词库导入失败: ' . fnamemodify(a:yamlPath, ':t')
        if !empty(result)
            echom '[ZFVimIM] 错误信息: ' . result
        endif
        return 0
    endif
endfunction

" Auto clear cache after dictionary initialization
function! s:ZFVimIM_autoClearCache()
    " Delay execution to ensure dictionary is fully loaded
    if has('timers')
        call timer_start(100, {-> s:doClearCache()})
    else
        " Fallback for Vim without timers
        call s:doClearCache()
    endif
endfunction

function! s:doClearCache()
    " Only clear cache, don't reload (avoid loop)
    if exists('*ZFVimIM_cacheClearAll')
        call ZFVimIM_cacheClearAll()
    endif
endfunction

augroup ZFVimIME_augroup
    autocmd!

    autocmd User ZFVimIM_event_OnDbInit call s:ZFVimIM_autoLoadDict()
    " Auto clear cache after dictionary initialization
    autocmd User ZFVimIM_event_OnDbInit call s:ZFVimIM_autoClearCache()

    autocmd User ZFVimIM_event_OnStart silent

    autocmd User ZFVimIM_event_OnStop silent

    autocmd User ZFVimIM_event_OnEnable silent

    autocmd User ZFVimIM_event_OnDisable silent

    " added word can be checked by g:ZFVimIM_event_OnAddWord : {
    "   'dbId' : 'add to which db',
    "   'key' : 'matched full key',
    "   'word' : 'matched word',
    " }
    autocmd User ZFVimIM_event_OnAddWord silent

    " current db can be accessed by g:ZFVimIM_db[g:ZFVimIM_dbIndex]
    autocmd User ZFVimIM_event_OnDbChange silent

    " called when update by ZFVimIME_keymap_update_i, typically by async update callback
    autocmd User ZFVimIM_event_OnUpdate silent

    " called when omni popup update, you may obtain current state by ZFVimIME_state()
    autocmd User ZFVimIM_event_OnUpdateOmni silent

    " called when choosed omni popup item, use `g:ZFVimIM_choosedWord` to obtain choosed word
    autocmd User ZFVimIM_event_OnCompleteDone silent
augroup END

function! ZFVimIME_init()
    if !exists('s:dbInitFlag')
        let s:dbInitFlag = 1
        doautocmd User ZFVimIM_event_OnDbInit
        doautocmd User ZFVimIM_event_OnDbChange
    endif
endfunction

function! ZFVimIME_initFlag()
    return get(s:, 'dbInitFlag', 0)
endfunction

" ============================================================
if get(g:, 'ZFVimIM_keymap', 1)
    nnoremap <expr><silent> ;; ZFVimIME_keymap_toggle_n()
    inoremap <expr><silent> ;; ZFVimIME_keymap_toggle_i()
    vnoremap <expr><silent> ;; ZFVimIME_keymap_toggle_v()

    nnoremap <expr><silent> ;: ZFVimIME_keymap_next_n()
    inoremap <expr><silent> ;: ZFVimIME_keymap_next_i()
    vnoremap <expr><silent> ;: ZFVimIME_keymap_next_v()

    nnoremap <expr><silent> ;, ZFVimIME_keymap_add_n()
    inoremap <expr><silent> ;, ZFVimIME_keymap_add_i()
    xnoremap <expr><silent> ;, ZFVimIME_keymap_add_v()

    nnoremap <expr><silent> ;. ZFVimIME_keymap_remove_n()
    inoremap <expr><silent> ;. ZFVimIME_keymap_remove_i()
    xnoremap <expr><silent> ;. ZFVimIME_keymap_remove_v()
endif

function! ZFVimIME_keymap_toggle_n()
    call ZFVimIME_toggle()
    call ZFVimIME_redraw()
    return ''
endfunction
function! ZFVimIME_keymap_toggle_i()
    call ZFVimIME_toggle()
    call ZFVimIME_redraw()
    return ''
endfunction
function! ZFVimIME_keymap_toggle_v()
    call ZFVimIME_toggle()
    call ZFVimIME_redraw()
    return ''
endfunction

function! ZFVimIME_keymap_next_n()
    call ZFVimIME_next()
    call ZFVimIME_redraw()
    return ''
endfunction
function! ZFVimIME_keymap_next_i()
    call ZFVimIME_next()
    call ZFVimIME_redraw()
    return ''
endfunction
function! ZFVimIME_keymap_next_v()
    call ZFVimIME_next()
    call ZFVimIME_redraw()
    return ''
endfunction

function! ZFVimIME_keymap_add_n()
    if !ZFVimIME_started()
        call ZFVimIME_start()
    endif
    call feedkeys(":IMAdd ", 'nt')
    return ''
endfunction
function! ZFVimIME_keymap_add_i()
    if !ZFVimIME_started()
        call ZFVimIME_start()
    endif
    call feedkeys("\<esc>:IMAdd ", 'nt')
    return ''
endfunction
function! ZFVimIME_keymap_add_v()
    if !ZFVimIME_started()
        call ZFVimIME_start()
    endif
    " In visual mode, use selected text as word
    call feedkeys("\<esc>\"ty:IMAdd \<c-r>t ", 'nt')
    return ''
endfunction

function! ZFVimIME_keymap_remove_n()
    if !ZFVimIME_started()
        call ZFVimIME_start()
    endif
    call feedkeys(":IMRemove ", 'nt')
    return ''
endfunction
function! ZFVimIME_keymap_remove_i()
    if !ZFVimIME_started()
        call ZFVimIME_start()
    endif
    call feedkeys("\<esc>:IMRemove ", 'nt')
    return ''
endfunction
function! ZFVimIME_keymap_remove_v()
    if !ZFVimIME_started()
        call ZFVimIME_start()
    endif
    " In visual mode, use selected text as word
    call feedkeys("\<esc>\"ty:IMRemove \<c-r>t\<cr>", 'nt')
    return ''
endfunction

if exists('*state')
    function! s:updateDisabled()
        return !ZFVimIME_started() || mode() != 'i' || match(state(), 'm') >= 0
    endfunction
else
    function! s:updateDisabled()
        return !ZFVimIME_started() || mode() != 'i'
    endfunction
endif
function! ZFVimIME_keymap_update_i()
    if s:updateDisabled()
        return ''
    endif
    if s:floatVisible()
        call s:floatClose()
    endif
    call s:resetAfterInsert()
    silent call feedkeys("\<c-r>=ZFVimIME_callOmni()\<cr>", 'nt')
    doautocmd User ZFVimIM_event_OnUpdate
    return ''
endfunction

if get(g:, 'ZFVimIME_fixCtrlC', 1)
    " <c-c> won't fire InsertLeave, we needs this to reset userWord detection
    inoremap <c-c> <esc>
endif

if !exists('*ZFVimIME_redraw')
    function! ZFVimIME_redraw()
        " redraw to ensure `b:keymap_name` updated
        " but redraw! would cause entire screen forced update
        " typically b:keymap_name used only in statusline, update it instead of redraw!
        if 0
            redraw!
        else
            if 0
                        \ || match(&statusline, '%k') >= 0
                        \ || match(&statusline, 'ZFVimIME_IMEStatusline') >= 0
                let &statusline = &statusline
            endif
            if 0
                        \ || match(&l:statusline, '%k') >= 0
                        \ || match(&l:statusline, 'ZFVimIME_IMEStatusline') >= 0
                let &l:statusline = &l:statusline
            endif
        endif
    endfunction
endif

function! ZFVimIME_started()
    return s:started
endfunction

function! ZFVimIME_enabled()
    return s:enabled
endfunction

function! ZFVimIME_toggle()
    if ZFVimIME_started()
        call ZFVimIME_stop()
    else
        call ZFVimIME_start()
    endif
endfunction

function! ZFVimIME_start()
    if s:started
        return
    endif
    let s:started = 1
    doautocmd User ZFVimIM_event_OnStart
    call s:IME_enableStateUpdate()
    redrawstatus
endfunction

function! ZFVimIME_stop()
    if !s:started
        return
    endif
    let s:started = 0
    call s:IME_enableStateUpdate()
    doautocmd User ZFVimIM_event_OnStop
    redrawstatus
endfunction

function! ZFVimIME_next()
    if !ZFVimIME_started()
        return ZFVimIME_start()
    endif
    call ZFVimIME_switchToIndex(g:ZFVimIM_dbIndex + 1)
endfunction

function! ZFVimIME_switchToIndex(dbIndex)
    if empty(g:ZFVimIM_db)
        let g:ZFVimIM_dbIndex = 0
        return
    endif
    let len = len(g:ZFVimIM_db)
    let dbIndex = (a:dbIndex % len)

    if !g:ZFVimIM_db[dbIndex]['switchable']
        " loop until found a switchable
        let dbIndexStart = dbIndex
        let dbIndex = ((dbIndex + 1) % len)
        while dbIndex != dbIndexStart && !g:ZFVimIM_db[dbIndex]['switchable']
            let dbIndex = ((dbIndex + 1) % len)
        endwhile
    endif

    if dbIndex == g:ZFVimIM_dbIndex || !g:ZFVimIM_db[dbIndex]['switchable']
        return
    endif
    let g:ZFVimIM_dbIndex = dbIndex
    let b:keymap_name = ZFVimIME_IMEName()
    doautocmd User ZFVimIM_event_OnDbChange
    redrawstatus
endfunction

function! ZFVimIME_state()
    return {
                \   'key' : s:keyboard,
                \   'list' : s:match_list,
                \   'page' : s:page,
                \   'startColumn' : s:start_column,
                \   'seamlessPos' : s:seamless_positions,
                \   'userWord' : s:userWord,
                \ }
endfunction

function! ZFVimIME_omnifunc(start, keyboard)
    return s:omnifunc(a:start, a:keyboard)
endfunction


" ============================================================
function! ZFVimIME_esc(...)
    if mode() != 'i' || !s:floatVisible()
        call s:symbolForward(get(a:, 1, '<esc>'))
        return ''
    endif
    let range = col('.') - s:start_column
    let key = repeat("\<bs>", range)
    call s:resetAfterInsert()
    silent call feedkeys(key, 'nt')
    return ''
endfunction

function! ZFVimIME_label(n, ...)
    if mode() != 'i' || !s:floatVisible()
        call s:symbolForward(get(a:, 1, a:n))
        return ''
    endif
    let curPage = s:curPage()
    let n = a:n < 1 ? 9 : a:n - 1
    if n >= len(curPage)
        return ''
    endif
    if get(curPage[n], 'hint', 0)
        return ''
    endif
    call s:chooseItem(curPage[n])
    return ''
endfunction

function! ZFVimIME_chooseFirst()
    if mode() != 'i' || empty(s:match_list)
        return ''
    endif
    call s:chooseItem(s:match_list[0])
    return ''
endfunction

function! ZFVimIME_chooseIndex(index)
    if mode() != 'i' || empty(s:match_list)
        return ''
    endif
    let idx = a:index
    if idx < 0
        let idx = len(s:match_list) - 1
    endif
    if idx < 0 || idx >= len(s:match_list)
        return ''
    endif
    call s:chooseItem(s:match_list[idx])
    return ''
endfunction

function! ZFVimIME_labelWithTail(n, tail)
    if mode() != 'i' || !s:floatVisible()
        return ZFVimIME_input(a:tail)
    endif
    let curPage = s:curPage()
    let n = a:n < 1 ? 9 : a:n - 1
    if n >= len(curPage)
        return ZFVimIME_input(a:tail)
    endif
    if get(curPage[n], 'hint', 0)
        return ZFVimIME_input(a:tail)
    endif
    let s:labelWithTailPending = {
                \ 'item' : curPage[n],
                \ 'tail' : a:tail,
                \ 'pos' : getpos('.'),
                \ 'start' : s:start_column,
                \ }
    if has('timers')
        call timer_start(0, function('s:labelWithTailApply'))
    else
        call s:labelWithTailApply(0)
    endif
    return ''
endfunction

function! s:labelWithTailApply(...)
    if !exists('s:labelWithTailPending')
        return
    endif
    let pending = s:labelWithTailPending
    unlet s:labelWithTailPending
    let item = pending['item']
    let tail = pending['tail']
    let cursor_positions = pending['pos']
    let line = getline(cursor_positions[1])
    let startCol = pending['start']
    let endCol = cursor_positions[2] - 1
    if startCol < 1
        let startCol = 1
    endif
    if endCol < startCol - 1
        let endCol = startCol - 1
    endif
    let prefix = strpart(line, 0, startCol - 1)
    let suffix = strpart(line, endCol)
    let insertText = item['word'] . tail
    let s:confirmFlag = 1
    call s:didChoose(item)
    call setline(cursor_positions[1], prefix . insertText . suffix)
    let newCol = startCol + strlen(insertText)
    call setpos('.', [cursor_positions[0], cursor_positions[1], newCol, cursor_positions[3]])
    let s:pending_left_len = 0
    call s:resetAfterInsert()
    let s:seamless_positions = [cursor_positions[0], cursor_positions[1], startCol + strlen(item['word']), cursor_positions[3]]
    call s:updateCandidates()
endfunction

function! ZFVimIME_pageUp(key, ...)
    if mode() != 'i' || !s:floatVisible()
        call s:symbolForward(get(a:, 1, a:key))
        return ''
    endif
    let s:pageup_pagedown = -1
    " Use feedkeys to defer the update to avoid "Not allowed to change text" error
    silent call feedkeys("\<c-r>=ZFVimIME_updatePage()\<cr>", 'nt')
    return ''
endfunction
function! ZFVimIME_pageDown(key, ...)
    if mode() != 'i' || !s:floatVisible()
        call s:symbolForward(get(a:, 1, a:key))
        return ''
    endif
    let s:pageup_pagedown = 1
    " Use feedkeys to defer the update to avoid "Not allowed to change text" error
    silent call feedkeys("\<c-r>=ZFVimIME_updatePage()\<cr>", 'nt')
    return ''
endfunction
function! ZFVimIME_updatePage()
    " This function is called via feedkeys to defer updateCandidates execution
    if mode() == 'i' && s:floatVisible()
        call s:updateCandidatesDebounced()
    endif
    return ''
endfunction

function! ZFVimIME_updateCandidatesNow()
    if mode() == 'i'
        call s:updateCandidates()
    endif
    return ''
endfunction

function! ZFVimIME_tabNext(...)
    if mode() != 'i' || !s:floatVisible()
        " If popup is not visible, insert tab normally
        call s:symbolForward(get(a:, 1, "\<tab>"))
        return ''
    endif
    if get(g:, 'ZFVimIM_sbzr_mode', 0)
        return ZFVimIME_chooseIndex(1)
    endif
    call s:floatMove(1)
    return ''
endfunction

function! ZFVimIME_tabPrev(...)
    if mode() != 'i' || !s:floatVisible()
        " If popup is not visible, do nothing (Shift+Tab in terminal may not work)
        return ''
    endif
    if get(g:, 'ZFVimIM_sbzr_mode', 0)
        return ZFVimIME_chooseIndex(-1)
    endif
    call s:floatMove(-1)
    return ''
endfunction

function! ZFVimIME_popupNext(key, ...)
    if mode() != 'i' || !s:floatVisible()
        call s:symbolForward(get(a:, 1, a:key))
        return ''
    endif
    call s:floatMove(1)
    return ''
endfunction

function! ZFVimIME_popupPrev(key, ...)
    if mode() != 'i' || !s:floatVisible()
        call s:symbolForward(get(a:, 1, a:key))
        return ''
    endif
    call s:floatMove(-1)
    return ''
endfunction

" note, this func must invoked as `<c-r>=`
" to ensure `<c-y>` actually transformed popup word
function! ZFVimIME_choose_fix(offset)
    let words = split(strpart(getline('.'), (s:start_column - 1), col('.') - s:start_column), '\ze')
    return repeat("\<bs>", len(words) - a:offset)
endfunction
function! ZFVimIME_chooseL(key, ...)
    if mode() != 'i' || !s:floatVisible()
        call s:symbolForward(get(a:, 1, a:key))
        return ''
    endif
    if s:float_index < len(s:float_items)
        call s:chooseItem(s:float_items[s:float_index])
    endif
    return ''
endfunction
function! ZFVimIME_chooseR(key, ...)
    if mode() != 'i' || !s:floatVisible()
        call s:symbolForward(get(a:, 1, a:key))
        return ''
    endif
    if s:float_index < len(s:float_items)
        call s:chooseItem(s:float_items[s:float_index])
    endif
    return ''
endfunction

function! ZFVimIME_space(...)
    if mode() != 'i' || !s:floatVisible()
        call s:symbolForward(get(a:, 1, '<space>'))
        return ''
    endif
    if s:float_index < len(s:float_items)
        call s:chooseItem(s:float_items[s:float_index])
    endif
    return ''
endfunction

function! ZFVimIME_enter(...)
    if mode() != 'i'
        call s:symbolForward(get(a:, 1, '<cr>'))
        return ''
    endif
    if s:floatVisible()
        call s:floatClose()
        let key = ''
    else
        if s:enter_to_confirm
            let s:enter_to_confirm = 0
            let key = ''
        else
            let key = "\<cr>"
        endif
    endif
    let s:seamless_positions = getpos('.')
    call s:resetAfterInsert()
    silent call feedkeys(key, 'nt')
    return ''
endfunction

function! ZFVimIME_backspace(...)
    if mode() != 'i'
        call s:symbolForward(get(a:, 1, '<bs>'))
        return ''
    endif
    let key = "\<bs>"
    if s:candidateVisible()
        let key .= "\<c-r>=ZFVimIME_callOmni()\<cr>"
    endif
    if !empty(s:seamless_positions)
        let line = getline('.')
        if !empty(line)
            let bsLen = len(substitute(line, '^.*\(.\)$', '\1', ''))
        else
            let bsLen = 1
        endif
        let pos = getpos('.')[2]
        if pos > bsLen
            let pos -= bsLen
        endif
        if pos < s:seamless_positions[2]
            let s:seamless_positions[2] = pos
        endif
    endif
    silent call feedkeys(key, 'nt')
    return ''
endfunction

function! ZFVimIME_delete(...)
    if mode() != 'i'
        call s:symbolForward(get(a:, 1, '<del>'))
        return ''
    endif
    let key = "\<del>"
    if s:candidateVisible()
        let key .= "\<c-r>=ZFVimIME_callOmni()\<cr>"
    endif
    silent call feedkeys(key, 'nt')
    return ''
endfunction

function! ZFVimIME_input(key, ...)
    if mode() != 'i'
        call s:symbolForward(get(a:, 1, a:key))
        return ''
    endif
    return a:key . "\<c-r>=ZFVimIME_callOmni()\<cr>"
endfunction

let s:symbolState = {}
function! s:symbol(key)
    if mode() != 'i'
        return a:key
    endif
    let T_symbol = get(g:ZFVimIM_symbolMap, a:key, [])
    if type(T_symbol) == type(function('type'))
        return T_symbol(a:key)
    elseif empty(T_symbol)
        return a:key
    elseif len(T_symbol) == 1
        if T_symbol[0] == ''
            return a:key
        else
            return T_symbol[0]
        endif
    endif
    let s:symbolState[a:key] = (get(s:symbolState, a:key, -1) + 1) % len(T_symbol)
    return T_symbol[s:symbolState[a:key]]
endfunction

function! s:symbolForward(key)
    let key = s:symbol(a:key)
    " (<[a-z]+>)
    execute 'silent call feedkeys("' . substitute(key, '\(<[a-z]\+>\)', '\\\1', 'g') . '", "nt")'
endfunction

function! ZFVimIME_symbol(key, ...)
    call s:symbolForward(get(a:, 1, a:key))
    return ''
endfunction

function! ZFVimIME_callOmni()
    let s:keyboard = (s:pageup_pagedown == 0) ? '' : s:keyboard
    if s:hasLeftChar()
        call s:updateCandidatesDebounced()
    else
        call s:floatClose()
    endif
    return ''
endfunction

function! ZFVimIME_fixOmni()
    return ''
endfunction

augroup ZFVimIME_impl_toggle_augroup
    autocmd!
    autocmd User ZFVimIM_event_OnStart call s:IMEEventStart()
    autocmd User ZFVimIM_event_OnStop call s:IMEEventStop()
augroup END
function! s:IMEEventStart()
    augroup ZFVimIME_impl_augroup
        autocmd!
        autocmd InsertEnter * call s:OnInsertEnter()
        autocmd InsertLeave * call s:OnInsertLeave()
        autocmd CursorMovedI * call s:OnCursorMovedI()
        if exists('##CompleteDone')
            autocmd CompleteDone * call s:OnCompleteDone()
        endif
    augroup END
endfunction
function! s:IMEEventStop()
    augroup ZFVimIME_impl_augroup
        autocmd!
    augroup END
endfunction

function! s:init()
    let s:started = 0
    let s:enabled = 0
    let s:seamless_positions = []
    let s:start_column = 1
    let s:all_keys = '^[0-9a-z]$'
    let s:input_keys = '^[a-z]$'
    let s:sbzr_seen_freq = {}
    let s:sbzr_seen_counter = 0
    let s:last_commit = {}
    let s:prev_commit = {}
    let s:prev_prev_commit = {}  " 记录倒数第三个词，用于三字组合
endfunction

function! ZFVimIME_IMEName()
    if ZFVimIME_started() && g:ZFVimIM_dbIndex < len(g:ZFVimIM_db)
        return g:ZFVimIM_db[g:ZFVimIM_dbIndex]['name']
    else
        return ''
    endif
endfunction

function! ZFVimIME_IMEStatusline()
    let name = ZFVimIME_IMEName()
    if empty(name)
        return ''
    else
        return get(g:, 'ZFVimIME_IMEStatus_tagL', ' <') . name . get(g:, 'ZFVimIME_IMEStatus_tagR', '> ')
    endif
endfunction

function! s:fixIMState()
    if mode() == 'i'
        " :h i_CTRL-^
        silent call feedkeys(nr2char(30), 'nt')
        if &iminsert != ZFVimIME_started()
            silent call feedkeys(nr2char(30), 'nt')
        endif
    endif
endfunction

function! s:IME_start()
    let &iminsert = 1
    call ZFVimIME_init()

    call s:vimrcSave()
    call s:vimrcSetup()
    call s:setupKeymap()
    let b:keymap_name = ZFVimIME_IMEName()

    let s:seamless_positions = getpos('.')
    call s:fixIMState()

    let s:enabled = 1
    let b:ZFVimIME_enabled = 1
    doautocmd User ZFVimIM_event_OnEnable
endfunction

function! s:IME_stop()
    let &iminsert = 0
    lmapclear
    call s:vimrcRestore()
    call s:resetState()
    call s:fixIMState()

    let s:enabled = 0
    if exists('b:ZFVimIME_enabled')
        unlet b:ZFVimIME_enabled
    endif
    doautocmd User ZFVimIM_event_OnDisable
endfunction

function! s:IME_enableStateUpdate(...)
    if get(g:, 'ZFVimIME_enableOnInsertOnly', 1)
        let desired = get(a:, 1, -1)
        if desired == 0
            let enabled = 0
        elseif desired == 1
            let enabled = s:started
        else
            let enabled = (s:started && match(mode(), 'i') >= 0)
        endif
    else
        let enabled = s:started
    endif
    if enabled != s:enabled
        if enabled
            call s:IME_start()
        else
            call s:IME_stop()
        endif
    endif
endfunction

augroup ZFVimIME_impl_enabledStateUpdate_augroup
    autocmd!
    autocmd InsertEnter * call s:IME_enableStateUpdate(1)
    autocmd InsertLeave * call s:IME_enableStateUpdate(0)
    autocmd InsertLeave * if g:ZFVimIME_autoStopOnInsertLeave && ZFVimIME_started() | call ZFVimIME_stop() | endif
augroup END

function! s:IME_syncBuffer_delay(...)
    if !get(g:, 'ZFVimIME_syncBuffer', 1)
        return
    endif
    if get(b:, 'ZFVimIME_enabled', 0) != s:enabled
                \ || &iminsert != s:enabled
        if s:enabled
            call s:IME_stop()
            call s:IME_start()
        else
            call s:IME_start()
            call s:IME_stop()
        endif
    endif
    let b:keymap_name = ZFVimIME_IMEName()
    call ZFVimIME_redraw()
endfunction
function! s:IME_syncBuffer(...)
    if !get(g:, 'ZFVimIME_syncBuffer', 1)
        return
    endif
    if get(b:, 'ZFVimIME_enabled', 0) != s:enabled
                \ || &iminsert != s:enabled
        if has('timers')
            call timer_start(get(a:, 1, 0), function('s:IME_syncBuffer_delay'))
        else
            call s:IME_syncBuffer_delay()
        endif
    endif
endfunction
augroup ZFVimIME_impl_syncBuffer_augroup
    autocmd!
    " sometimes `iminsert` would be changed by vim, reason unknown
    " try to check later to ensure state valid
    if has('timers')
        if exists('##OptionSet')
            autocmd BufEnter,CmdwinEnter * call s:IME_syncBuffer()
            autocmd OptionSet iminsert call s:IME_syncBuffer()
        else
            autocmd BufEnter,CmdwinEnter * call s:IME_syncBuffer()
                        \| call s:IME_syncBuffer(200)
        endif
    else
        autocmd BufEnter,CmdwinEnter * call s:IME_syncBuffer()
    endif
augroup END

function! s:vimrcSave()
    let s:saved_omnifunc    = &omnifunc
    let s:saved_completeopt = &completeopt
    let s:saved_shortmess   = &shortmess
    let s:saved_pumheight   = &pumheight
    let s:saved_pumwidth    = &pumwidth
endfunction

function! s:getLabelList()
    let labelList = get(g:, 'ZFVimIM_labelList', [])
    if type(labelList) == type([])
        return labelList
    elseif type(labelList) == type('')
        if empty(labelList)
            return []
        endif
        return split(labelList, '\zs')
    endif
    return []
endfunction

function! s:defaultPumheight()
    if exists('g:ZFVimIM_pumheight')
        return g:ZFVimIM_pumheight
    endif
    let labelList = s:getLabelList()
    if !empty(labelList)
        return len(labelList)
    endif
    return 10
endfunction

function! s:applyCandidateLimit(list)
    let candidateLimit = get(g:, 'ZFVimIM_candidateLimit', 0)
    if candidateLimit <= 0
        return a:list
    endif
    if len(a:list) > candidateLimit
        return a:list[0 : candidateLimit - 1]
    endif
    return a:list
endfunction

function! s:vimrcSetup()
    set omnifunc=ZFVimIME_omnifunc
    set completeopt=menuone
    try
        " some old vim does not have `c`
        silent! set shortmess+=c
    endtry
    execute 'set pumheight=' . s:defaultPumheight()
    set pumwidth=0
endfunction

function! s:vimrcRestore()
    let &omnifunc    = s:saved_omnifunc
    let &completeopt = s:saved_completeopt
    let &shortmess   = s:saved_shortmess
    let &pumheight   = s:saved_pumheight
    let &pumwidth    = s:saved_pumwidth
endfunction

function! s:setupKeymap()
    let mapped = {}

    for c in split('abcdefghijklmnopqrstuvwxyz', '\zs')
        let mapped[c] = 1
        execute 'lnoremap <buffer><expr><silent> ' . c . ' ZFVimIME_input("' . escape(c, '"\') . '")'
    endfor

    for c in get(g:, 'ZFVimIM_key_pageUp', ['-', ','])
        if c !~ s:all_keys
            let mapped[c] = 1
            execute 'lnoremap <buffer><expr><silent> ' . c . ' ZFVimIME_pageUp("' . escape(c, '"\') . '")'
        endif
    endfor
    for c in get(g:, 'ZFVimIM_key_pageDown', ['=', '.'])
        if c !~ s:all_keys
            let mapped[c] = 1
            execute 'lnoremap <buffer><expr><silent> ' . c . ' ZFVimIME_pageDown("' . escape(c, '"\') . '")'
        endif
    endfor

    for c in get(g:, 'ZFVimIM_key_chooseL', ['['])
        if c !~ s:all_keys
            let mapped[c] = 1
            execute 'lnoremap <buffer><expr><silent> ' . c . ' ZFVimIME_chooseL("' . escape(c, '"\') . '")'
        endif
    endfor
    for c in get(g:, 'ZFVimIM_key_chooseR', [']'])
        if c !~ s:all_keys
            let mapped[c] = 1
            execute 'lnoremap <buffer><expr><silent> ' . c . ' ZFVimIME_chooseR("' . escape(c, '"\') . '")'
        endif
    endfor

    for n in range(10)
        let mapped['' . n] = 1
        execute 'lnoremap <buffer><expr><silent> ' . n . ' ZFVimIME_label(' . n . ')'
    endfor

    for c in get(g:, 'ZFVimIM_key_backspace', ['<bs>'])
        if c !~ s:all_keys
            let mapped[c] = 1
            execute 'lnoremap <buffer><expr><silent> ' . c . ' ZFVimIME_backspace("' . escape(c, '"\') . '")'
        endif
    endfor

    for c in get(g:, 'ZFVimIM_key_delete', ['<del>'])
        if c !~ s:all_keys
            let mapped[c] = 1
            execute 'lnoremap <buffer><expr><silent> ' . c . ' ZFVimIME_delete("' . escape(c, '"\') . '")'
        endif
    endfor

    for c in get(g:, 'ZFVimIM_key_esc', ['<esc>'])
        if c !~ s:all_keys
            let mapped[c] = 1
            execute 'lnoremap <buffer><expr><silent> ' . c . ' ZFVimIME_esc("' . escape(c, '"\') . '")'
        endif
    endfor

    for c in get(g:, 'ZFVimIM_key_enter', ['<cr>'])
        if c !~ s:all_keys
            let mapped[c] = 1
            execute 'lnoremap <buffer><expr><silent> ' . c . ' ZFVimIME_enter("' . escape(c, '"\') . '")'
        endif
    endfor

    for c in get(g:, 'ZFVimIM_key_space', ['<space>'])
        if c !~ s:all_keys
            let mapped[c] = 1
            execute 'lnoremap <buffer><expr><silent> ' . c . ' ZFVimIME_space("' . escape(c, '"\') . '")'
        endif
    endfor

    " Tab and Shift+Tab for candidate selection
    for c in get(g:, 'ZFVimIM_key_tabNext', ['<tab>'])
        if c !~ s:all_keys
            let mapped[c] = 1
            execute 'lnoremap <buffer><expr><silent> ' . c . ' ZFVimIME_tabNext("' . escape(c, '"\') . '")'
        endif
    endfor
    for c in get(g:, 'ZFVimIM_key_tabPrev', ['<s-tab>'])
        if c !~ s:all_keys
            let mapped[c] = 1
            execute 'lnoremap <buffer><expr><silent> ' . c . ' ZFVimIME_tabPrev("' . escape(c, '"\') . '")'
        endif
    endfor

    execute 'lnoremap <buffer><expr><silent> <down> ZFVimIME_popupNext("<down>")'
    execute 'lnoremap <buffer><expr><silent> <up> ZFVimIME_popupPrev("<up>")'
    execute 'lnoremap <buffer><expr><silent> <left> ZFVimIME_pageUp("<left>")'
    execute 'lnoremap <buffer><expr><silent> <right> ZFVimIME_pageDown("<right>")'

    " Delete word from dictionary (default: Ctrl+D)
    for c in get(g:, 'ZFVimIM_key_deleteWord', ['<c-d>'])
        if c !~ s:all_keys
            let mapped[c] = 1
            execute 'lnoremap <buffer><expr><silent> ' . c . ' ZFVimIME_removeCurrentWord()'
        endif
    endfor

    let candidates = get(g:, 'ZFVimIM_key_candidates', [])
    let iCandidate = 0
    while iCandidate < len(candidates)
        if type(candidates[iCandidate]) == type([])
            let cs = candidates[iCandidate]
        else
            let cs = [candidates[iCandidate]]
        endif
        for c in cs
            if c !~ s:all_keys
                let mapped[c] = 1
                execute 'lnoremap <buffer><expr><silent> ' . c . ' ZFVimIME_label(' . (iCandidate + 2) . ', "' . escape(c, '"\') . '")'
            endif
        endfor
        let iCandidate += 1
    endwhile

    for c in keys(g:ZFVimIM_symbolMap)
        if !exists("mapped[c]")
            execute 'lnoremap <buffer><expr><silent> ' . c . ' ZFVimIME_symbol("' . escape(c, '"\') . '")'
        endif
    endfor
endfunction

function! s:resetState()
    call s:resetAfterInsert()
    let s:keyboard = ''
    let s:userWord = []
    let s:confirmFlag = 0
    let s:hasInput = 0
endfunction

function! s:resetAfterInsert()
    let s:match_list = []
    let s:page = 0
    let s:pageup_pagedown = 0
    let s:enter_to_confirm = 0
    call s:floatClose()
endfunction

function! s:filterMatchListByPrefix(list, key)
    " Only filter for 2-char keys, skip for others to save time
    if len(a:key) != 2
        return a:list
    endif
    " Limit filtering to first 500 items for performance
    let maxFilter = len(a:list) > 500 ? 500 : len(a:list)
    let filtered = []
    for i in range(maxFilter)
        let item = a:list[i]
        if len(get(item, 'key', '')) >= 2 && strpart(item['key'], 0, 2) ==# a:key
            call add(filtered, item)
        endif
    endfor
    " Add remaining items without filtering (they're already sorted)
    if maxFilter < len(a:list)
        call extend(filtered, a:list[maxFilter :])
    endif
    return filtered
endfunction

" Remove duplicate candidates based on word (and optionally key)
" Keeps the first occurrence of each unique word
function! s:deduplicateCandidates(list)
    if empty(a:list)
        return []
    endif
    " Limit deduplication to first 1000 items for performance
    " Most duplicates are in the first few items anyway
    let maxDedup = len(a:list) > 1000 ? 1000 : len(a:list)
    let seen = {}
    let deduplicated = []
    for i in range(maxDedup)
        let item = a:list[i]
        " Use word as the unique identifier for deduplication
        " If same word appears with different keys, keep the first one
        let word = get(item, 'word', '')
        if !has_key(seen, word)
            let seen[word] = 1
            call add(deduplicated, item)
        endif
    endfor
    " Add remaining items without deduplication (they're less likely to have duplicates)
    if maxDedup < len(a:list)
        call extend(deduplicated, a:list[maxDedup :])
    endif
    return deduplicated
endfunction

function! s:curPage()
    if !empty(s:match_list) && &pumheight > 0
        " Always return only one page of candidates (pumheight items)
        execute 'let results = s:match_list[' . (s:page * &pumheight) . ':' . ((s:page+1) * &pumheight - 1) . ']'
        return results
    else
        return []
    endif
endfunction

let s:float_winid = -1
let s:float_bufnr = -1
let s:float_index = 0
let s:float_items = []
let s:float_ns = -1
let s:float_label_widths = []
let s:float_orig_key_ranges = []
let s:float_hl_inited = 0
let s:pending_left_len = 0

function! s:floatVisible()
    return s:float_winid > 0 && nvim_win_is_valid(s:float_winid)
endfunction

function! s:candidateVisible()
    return s:floatVisible()
endfunction

function! s:floatCloseNow(...)
    if s:floatVisible()
        call nvim_win_close(s:float_winid, v:true)
    endif
    let s:float_winid = -1
    let s:float_bufnr = -1
    let s:float_index = 0
    let s:float_items = []
    let s:float_label_widths = []
    let s:float_orig_key_ranges = []
endfunction

function! s:floatClose()
    if !s:floatVisible()
        return
    endif
    try
        call s:floatCloseNow()
    catch /^Vim\%((\a\+)\)\=:E5555/
        if exists('*timer_start')
            call timer_start(0, function('s:floatCloseNow'))
        endif
    endtry
endfunction

function! s:floatEnsure(lines)
    if s:float_ns < 0
        let s:float_ns = nvim_create_namespace('ZFVimIMFloat')
    endif
    if !s:float_hl_inited
        silent! highlight default link ZFVimIMFloatLabel PmenuSbar
        silent! highlight default link ZFVimIMFloatOrigKey Question
        " 设置选中候选的颜色为鲜亮的绿色
        " 如果要修改颜色，可以在这里修改下面的颜色代码：
        "   guibg=#00ff00 表示背景色（绿色），guifg=#000000 表示文字颜色（黑色）
        "   或者使用 ctermbg=2 ctermfg=0 用于终端版本
        silent! highlight default ZFVimIMFloatSelected guibg=#00ff00 guifg=#000000 ctermbg=2 ctermfg=0
        let s:float_hl_inited = 1
    endif
    if s:float_bufnr <= 0 || !nvim_buf_is_valid(s:float_bufnr)
        let s:float_bufnr = nvim_create_buf(v:false, v:true)
        call nvim_buf_set_option(s:float_bufnr, 'buftype', 'nofile')
        call nvim_buf_set_option(s:float_bufnr, 'bufhidden', 'wipe')
        call nvim_buf_set_option(s:float_bufnr, 'swapfile', v:false)
    endif
    let width = 1
    for line in a:lines
        let width = max([width, strdisplaywidth(line)])
    endfor
    let height = len(a:lines)
    if height <= 0
        call s:floatClose()
        return
    endif
    let config = {
                \ 'relative' : 'cursor',
                \ 'row' : 1,
                \ 'col' : 0,
                \ 'width' : width,
                \ 'height' : height,
                \ 'style' : 'minimal',
                \ 'focusable' : v:false,
                \ 'zindex' : 200,
                \ }
    if s:floatVisible()
        call nvim_win_set_config(s:float_winid, config)
        " 设置选中行的颜色（使用上面定义的鲜亮绿色）
        call nvim_win_set_option(s:float_winid, 'winhl', 'Normal:Pmenu,FloatBorder:Pmenu,CursorLine:ZFVimIMFloatSelected')
    else
        let s:float_winid = nvim_open_win(s:float_bufnr, v:false, config)
        " 设置选中行的颜色（使用上面定义的鲜亮绿色）
        call nvim_win_set_option(s:float_winid, 'winhl', 'Normal:Pmenu,FloatBorder:Pmenu,CursorLine:ZFVimIMFloatSelected')
    endif
endfunction

function! s:floatRender(list)
    if empty(a:list)
        call s:floatClose()
        return
    endif
    let labelList = s:getLabelList()
    let label = 1
    let lines = []
    let labelWidths = []
    let origRanges = []
    for item in a:list
        let isHint = get(item, 'hint', 0)
        if !empty(labelList)
            let labelstring = get(labelList, label - 1, '?')
        elseif get(g:, 'ZFVimIM_freeScroll', 0)
            let labelstring = printf('%2d', label == 10 ? 0 : label)
        else
            if label >= 1 && label <= 9
                let labelstring = label
            elseif label == 10
                let labelstring = '0'
            else
                let labelstring = '?'
            endif
        endif
        let left = strpart(s:keyboard, item['len'])
        let hasDisplay = get(g:, 'ZFVimIM_sbzr_mode', 0) && has_key(item, 'displayWord')
        if !empty(labelList)
            let labelcell = ' '
            if hasDisplay
                let wordPart = ' ' . item['displayWord']
            else
                let wordPart = ' ' . item['word'] . left
            endif
            let content = wordPart
            if !isHint && labelstring != ''
                let content .= labelstring
            endif
            let content .= ' '
        else
            let labelcell = ' ' . labelstring . ' '
            let wordPart = ' ' . item['word'] . left . ' '
            let content = wordPart
        endif
        let origRange = [-1, -1, -1]
        let origKey = get(item, 'key', '')
        if !empty(origKey)
            let origText = '[' . origKey . ']'
            let origStart = strlen(labelcell . content)
            let origEnd = origStart + strlen(origText)
            let content .= origText . ' '
            let origRange = [len(lines), origStart, origEnd]
        endif
        call add(labelWidths, strdisplaywidth(labelcell))
        call add(lines, labelcell . content)
        call add(origRanges, origRange)
        let label += 1
    endfor
    call s:floatEnsure(lines)
    call nvim_buf_set_option(s:float_bufnr, 'modifiable', v:true)
    call nvim_buf_set_lines(s:float_bufnr, 0, -1, v:true, lines)
    call nvim_buf_set_option(s:float_bufnr, 'modifiable', v:false)
    let s:float_items = a:list
    let s:float_label_widths = labelWidths
    let s:float_orig_key_ranges = origRanges
    if s:float_index >= len(lines)
        let s:float_index = 0
    endif
    call nvim_buf_clear_namespace(s:float_bufnr, s:float_ns, 0, -1)
    let i = 0
    while i < len(lines)
        let lw = s:float_label_widths[i]
        if i != s:float_index
            call nvim_buf_add_highlight(s:float_bufnr, s:float_ns, 'ZFVimIMFloatLabel', i, 0, lw)
        endif
        let i += 1
    endwhile
    for range in s:float_orig_key_ranges
        if range[0] >= 0 && range[1] >= 0
            call nvim_buf_add_highlight(s:float_bufnr, s:float_ns, 'ZFVimIMFloatOrigKey', range[0], range[1], range[2])
        endif
    endfor
    if s:float_index >= 0 && s:float_index < len(lines)
        " ウィンドウのCursorLineを設定して行全体の背景色を変更（深い色、行全体の幅）
        if s:floatVisible()
            call nvim_win_set_option(s:float_winid, 'cursorline', v:true)
            call nvim_win_set_cursor(s:float_winid, [s:float_index + 1, 0])
        endif
    endif
endfunction

function! s:floatMove(delta)
    if empty(s:float_items)
        return
    endif
    let s:float_index += a:delta
    if s:float_index < 0
        let s:float_index = len(s:float_items) - 1
    elseif s:float_index >= len(s:float_items)
        let s:float_index = 0
    endif
    call nvim_buf_clear_namespace(s:float_bufnr, s:float_ns, 0, -1)
    let i = 0
    let lineCount = len(s:float_label_widths)
    while i < lineCount
        let lw = s:float_label_widths[i]
        if i != s:float_index
            call nvim_buf_add_highlight(s:float_bufnr, s:float_ns, 'ZFVimIMFloatLabel', i, 0, lw)
        endif
        let i += 1
    endwhile
    for range in s:float_orig_key_ranges
        if range[0] >= 0 && range[1] >= 0
            call nvim_buf_add_highlight(s:float_bufnr, s:float_ns, 'ZFVimIMFloatOrigKey', range[0], range[1], range[2])
        endif
    endfor
    if s:float_index >= 0 && s:float_index < len(s:float_label_widths)
        " ウィンドウのCursorLineを設定して行全体の背景色を変更（深い色、行全体の幅）
        if s:floatVisible()
            call nvim_win_set_option(s:float_winid, 'cursorline', v:true)
            call nvim_win_set_cursor(s:float_winid, [s:float_index + 1, 0])
        endif
    endif
endfunction

function! s:chooseItem(item)
    let left = strpart(s:keyboard, a:item['len'])
    let bsCount = strchars(s:keyboard)
    let s:confirmFlag = 1
    call s:didChoose(a:item)
    
    " 確定された単語だけを挿入
    let replace = a:item['word']
    let key = repeat("\<bs>", bsCount) . replace
    
    " 残りの入力がある場合、続けてマッチングを行う
    if !empty(left)
        let s:pending_left_len = strchars(left)
        " 確定された単語を挿入後、残りの入力を処理
        " resetAfterInsert()を呼ばずに、状態だけをリセット
        let s:match_list = []
        let s:page = 0
        let s:pageup_pagedown = 0
        let s:enter_to_confirm = 0
        " 候補ボックスは閉じない（残りの入力でマッチングを続けるため）
        " 確定された単語と残りの入力を一度に挿入
        let key = key . left
        silent call feedkeys(key, 'nt')
        " feedkeysは非同期なので、タイマーを使ってupdateCandidates()を呼び出す
        " カーソル位置が更新された後にマッチングを続ける
        " タイマーの遅延を50msに設定して、feedkeysの処理が完了するまで待つ
        call timer_start(50, {-> s:continueMatchingAfterInsert()})
    else
        let s:pending_left_len = 0
        " 残りの入力がない場合、通常通りリセット
        call s:resetAfterInsert()
        call s:floatClose()
        silent call feedkeys(key, 'nt')
    endif
endfunction

function! s:continueMatchingAfterInsert()
    " 残りの入力でマッチングを続ける
    " updateKeyboardFromCursor()がカーソル位置からキーボード入力を取得する
    if s:pending_left_len > 0
        let pos = getpos('.')
        let pos[2] = max([1, pos[2] - s:pending_left_len])
        let s:seamless_positions = pos
        let s:pending_left_len = 0
    endif
    call s:updateCandidatesDebounced()
endfunction

function! s:getSeamless(cursor_positions)
    if empty(s:seamless_positions)
                \|| s:seamless_positions[0] != a:cursor_positions[0]
                \|| s:seamless_positions[1] != a:cursor_positions[1]
                \|| s:seamless_positions[3] != a:cursor_positions[3]
        return -1
    endif
    let current_line = getline(a:cursor_positions[1])
    let seamless_column = s:seamless_positions[2]
    let len = a:cursor_positions[2] - seamless_column
    let snip = strpart(current_line, seamless_column - 1, len)
    if len(snip) < 0
        let s:seamless_positions = []
        return -1
    endif
    for c in split(snip, '\zs')
        if c !~ s:input_keys
            return -1
        endif
    endfor
    return seamless_column
endfunction

function! s:hasLeftChar()
    let before = getline('.')[col('.')-2]
    if before =~ '\s' || empty(before)
        return 0
    elseif before =~# s:input_keys
        return 1
    endif
endfunction

function! s:updateKeyboardFromCursor()
    let cursor_positions = getpos('.')
    let start_column = cursor_positions[2]
    let current_line = getline(cursor_positions[1])
    let seamless_column = s:getSeamless(cursor_positions)
    if seamless_column <= 0
        let seamless_column = 1
    endif
    if start_column <= seamless_column
        return 0
    endif
    while start_column > seamless_column && current_line[(start_column-1) - 1] =~# s:input_keys
        let start_column -= 1
    endwhile
    let len = cursor_positions[2] - start_column
    if len <= 0
        return 0
    endif
    let keyboard = strpart(current_line, (start_column - 1), len)
    let s:keyboard = keyboard
    let s:start_column = start_column
    return 1
endfunction

" Debounce timer for updateCandidates
let s:updateCandidatesTimer = -1
" Result cache for fast lookup
let s:completeCache = {}
let s:completeCacheKeys = []
" Last keyboard state for detecting changes
let s:lastKeyboard = ''
" Lazy loading: track how many results we've loaded
let s:loadedResultCount = 0
let s:fullResultList = []
let s:hasFullResults = 0

function! s:updateCandidates()
    let s:enter_to_confirm = 1
    let s:hasInput = 1
    if !s:updateKeyboardFromCursor()
        call s:floatClose()
        let s:lastKeyboard = ''
        let s:loadedResultCount = 0
        let s:fullResultList = []
        return
    endif
    if get(g:, 'ZFVimIM_sbzr_mode', 0)
        call s:updateCandidates_sbzr()
        return
    endif
    
    " Check if keyboard actually changed (not just cached lookup)
    " This is critical: if keyboard changed, we MUST do a new search
    " even if there's a cache entry (which might be for a different/partial input)
    let keyboardActuallyChanged = (s:keyboard !=# s:lastKeyboard)
    
    " Update last keyboard state
    let s:lastKeyboard = s:keyboard
    
    " Ensure pumheight is set correctly
    let defaultPumheight = s:defaultPumheight()
    if &pumheight <= 0 || &pumheight < defaultPumheight
        execute 'set pumheight=' . defaultPumheight
    endif
    let pageSize = &pumheight
    
    " Check if keyboard changed (new search needed)
    " If keyboard actually changed, always do a new search (don't use cache)
    let keyboardChanged = 0
    if keyboardActuallyChanged || !has_key(s:completeCache, s:keyboard)
        let keyboardChanged = 1
        " Clear loaded state when keyboard changes
        let s:loadedResultCount = 0
        let s:fullResultList = []
    endif
    
    if keyboardChanged
        " New search: limit initial search to keep UI responsive
        let keyLen = len(s:keyboard)
        let initialLimit = pageSize * 2
        if initialLimit <= 0
            let initialLimit = 20
        endif
        let s:fullResultList = ZFVimIM_complete(s:keyboard, {'match': initialLimit})
        let s:fullResultList = s:filterMatchListByPrefix(s:fullResultList, s:keyboard)
        let s:fullResultList = s:deduplicateCandidates(s:fullResultList)
        let s:fullResultList = s:applyCandidateLimit(s:fullResultList)
        
        " Mark as partial; load more lazily when needed
        let s:hasFullResults = 0
        if get(g:, 'ZFVimIM_candidateLimit', 0) > 0
            let s:hasFullResults = 1
        endif
        
        " Cache full result list (but don't load all at once)
        " Also cache the hasFullResults flag
        let s:completeCache[s:keyboard] = s:fullResultList
        if !exists('s:completeCacheFull')
            let s:completeCacheFull = {}
        endif
        let s:completeCacheFull[s:keyboard] = s:hasFullResults
        call add(s:completeCacheKeys, s:keyboard)
        " Limit cache size to 200 entries
        if len(s:completeCacheKeys) > 200
            let removeCount = len(s:completeCacheKeys) - 200
            for i in range(removeCount)
                let oldKey = remove(s:completeCacheKeys, 0)
                if has_key(s:completeCache, oldKey)
                    call remove(s:completeCache, oldKey)
                endif
                if exists('s:completeCacheFull') && has_key(s:completeCacheFull, oldKey)
                    call remove(s:completeCacheFull, oldKey)
                endif
            endfor
        endif
        
        " Initially only load first page (10 items)
        let s:loadedResultCount = pageSize * 2  " Load 2 pages initially for smooth scrolling
        if s:loadedResultCount > len(s:fullResultList)
            let s:loadedResultCount = len(s:fullResultList)
        endif
        let s:match_list = s:fullResultList[0 : s:loadedResultCount - 1]
        let s:page = 0
        " hasFullResults is already set above based on whether we ran full search
    else
        " Same keyboard: use cached full result list
        let s:fullResultList = s:completeCache[s:keyboard]
        " Restore hasFullResults flag from cache
        if exists('s:completeCacheFull') && has_key(s:completeCacheFull, s:keyboard)
            let s:hasFullResults = s:completeCacheFull[s:keyboard]
        else
            " If flag not cached, assume partial (for backward compatibility)
            let s:hasFullResults = 0
        endif
        
        " Handle page navigation
        if s:pageup_pagedown != 0 && !empty(s:match_list) && pageSize > 0
        let s:page += s:pageup_pagedown
            let maxPage = (len(s:fullResultList) - 1) / pageSize
            if s:page > maxPage
                let s:page = maxPage
        endif
        if s:page < 0
            let s:page = 0
        endif
    else
        let s:page = 0
        endif
        
        " Check if we need to load more results for current page
        let neededCount = (s:page + 2) * pageSize  " Load 2 pages ahead
        
        " If we need more results than we have, do a full search
        if !s:hasFullResults && neededCount > len(s:fullResultList)
            " Do full search to get all results
            let s:fullResultList = ZFVimIM_complete(s:keyboard)
            let s:fullResultList = s:filterMatchListByPrefix(s:fullResultList, s:keyboard)
            let s:fullResultList = s:deduplicateCandidates(s:fullResultList)
            let s:fullResultList = s:applyCandidateLimit(s:fullResultList)
            " Update cache with full results
            let s:completeCache[s:keyboard] = s:fullResultList
            if !exists('s:completeCacheFull')
                let s:completeCacheFull = {}
            endif
            let s:completeCacheFull[s:keyboard] = 1
            let s:hasFullResults = 1
        endif
        
        if neededCount > s:loadedResultCount && neededCount <= len(s:fullResultList)
            " Load more results from cache
            let s:loadedResultCount = neededCount
            if s:loadedResultCount > len(s:fullResultList)
                let s:loadedResultCount = len(s:fullResultList)
            endif
            let s:match_list = s:fullResultList[0 : s:loadedResultCount - 1]
        elseif s:loadedResultCount == 0 || len(s:match_list) != s:loadedResultCount
            " Initialize or refresh match_list
            let s:loadedResultCount = pageSize * 2
            if s:loadedResultCount > len(s:fullResultList)
                let s:loadedResultCount = len(s:fullResultList)
            endif
            let s:match_list = s:fullResultList[0 : s:loadedResultCount - 1]
        endif
    endif
    let s:pageup_pagedown = 0
    " Debug: check if pumheight is limiting candidates
    let defaultPumheight = s:defaultPumheight()
    if &pumheight <= 0 || &pumheight < defaultPumheight
        execute 'set pumheight=' . defaultPumheight
    endif
    let skipFew = get(g:, 'ZFVimIM_skipFloatWhenFew', 0)
    if skipFew > 0 && len(s:match_list) <= skipFew
        call s:floatClose()
        doautocmd User ZFVimIM_event_OnUpdateOmni
        return
    endif
    " Use curPage() for rendering to support pagination
    " freeScroll mode still uses pagination, but allows scrolling through all candidates
    call s:floatRender(s:curPage())
    doautocmd User ZFVimIM_event_OnUpdateOmni
endfunction

function! s:updateCandidates_sbzr()
    " 确保 SBZR 模式的标签列表正确设置
    if get(g:, 'ZFVimIM_sbzr_mode', 0)
        if !exists('g:ZFVimIM_labelList') || empty(g:ZFVimIM_labelList)
            let g:ZFVimIM_labelList = ['', 'a', 'e', 'u', 'i', 'o']
        endif
    endif
    let defaultPumheight = s:defaultPumheight()
    if &pumheight <= 0 || &pumheight < defaultPumheight
        execute 'set pumheight=' . defaultPumheight
    endif
    let limit = &pumheight
    let pageSize = limit
    let keyboardChanged = (s:keyboard !=# s:lastKeyboard)
    let needRefresh = keyboardChanged || empty(s:match_list)
    if needRefresh
        let matchLimit = get(g:, 'ZFVimIM_matchLimit', 0)
        if matchLimit == 0
            let matchLimit = -2000
        endif
        let s:fullResultList = ZFVimIM_complete(s:keyboard, {
                    \ 'match': matchLimit,
                    \ 'sentence': 0,
                    \ 'crossDb': 0,
                    \ 'predict': 0,
                    \ })
        let s:fullResultList = s:applyCandidateLimit(s:fullResultList)
        let s:match_list = s:fullResultList
        let s:loadedResultCount = len(s:fullResultList)
        let s:page = 0
    elseif s:pageup_pagedown != 0 && !empty(s:match_list) && pageSize > 0
        let s:page += s:pageup_pagedown
        let maxPage = (len(s:match_list) - 1) / pageSize
        if s:page > maxPage
            let s:page = maxPage
        endif
        if s:page < 0
            let s:page = 0
        endif
    endif
    let s:pageup_pagedown = 0
    let s:hasFullResults = 1
    let s:lastKeyboard = s:keyboard

    let skipFew = get(g:, 'ZFVimIM_skipFloatWhenFew', 0)
    if skipFew > 0 && len(s:match_list) <= skipFew
        call s:floatClose()
        doautocmd User ZFVimIM_event_OnUpdateOmni_sbzr
        return
    endif
    " ============================================================
    " SBZR 自造词功能：当没有匹配的候选词时，显示断词自动拼的候选词
    " 这些候选词会显示为 "词~" 的形式，表示这是临时组合的词
    " 用户选择后会自动添加到词库中
    " ============================================================
    if empty(s:match_list)
        " 调用 s:sbzrHintItems 生成断词自动拼的候选词
        " 这些候选词会标记为 hint: 1，显示时会加上 ~ 标记
        let hintItems = s:sbzrHintItems(s:keyboard, &pumheight)
        if !empty(hintItems)
            " 显示带 ~ 标记的候选词
            call s:floatRender(hintItems)
            doautocmd User ZFVimIM_event_OnUpdateOmni_sbzr
            return
        endif
    endif
    call s:floatRender(s:curPage())
    doautocmd User ZFVimIM_event_OnUpdateOmni_sbzr
endfunction

" ============================================================
" SBZR 自造词功能：生成断词自动拼的候选词
" 
" 功能说明：
"   当用户输入编码但没有匹配的候选词时，此函数会查找以当前编码为前缀的
"   更长编码对应的词，作为"断词自动拼"的候选词显示给用户。
"   
"   例如：用户输入 "gk"，没有匹配，但词库中有 "gka" 对应 "高"，
"   则显示 "高~" 作为候选词。用户选择后，会将 "gk" -> "高" 添加到词库。
"
" 参数：
"   key: 当前输入的编码（例如 "gk"）
"   limit: 最多返回的候选词数量（默认6个）
"
" 返回值：
"   候选词列表，每个候选词包含：
"     - dbId: 数据库ID
"     - len: 编码长度（使用当前输入的编码长度）
"     - word: 词本身（例如 "高"）
"     - displayWord: 显示用的词（与 word 相同）
"     - key: 实际匹配的编码（例如 "gka"）
"     - type: 类型（'match'）
"     - hint: 1（标记为自造词，显示时会加上 ~）
"
" 工作流程：
"   1. 在当前数据库中查找以 key 为前缀的编码
"   2. 找到第一个匹配的更长编码（例如 "gk" -> "gka"）
"   3. 返回该编码对应的第一个词，标记为 hint: 1
"   4. 用户选择后，会调用 s:didChoose，然后调用 s:addWord 添加到词库
" ============================================================
function! s:sbzrHintItems(key, limit)
    if empty(a:key)
        return []
    endif
    " 检查数据库是否已加载
    if !exists('g:ZFVimIM_db') || empty(g:ZFVimIM_db)
        return []
    endif
    if g:ZFVimIM_dbIndex >= len(g:ZFVimIM_db)
        return []
    endif
    let db = g:ZFVimIM_db[g:ZFVimIM_dbIndex]
    if empty(db) || !has_key(db, 'dbMap')
        return []
    endif
    
    " 获取编码的第一个字符，用于查找对应的 bucket
    let c = a:key[0]
    if !has_key(db['dbMap'], c)
        return []
    endif
    let bucket = db['dbMap'][c]
    let limit = a:limit > 0 ? a:limit : 6
    let ret = []
    
    " 在当前 bucket 中查找以 key 为前缀的编码
    let idx = ZFVimIM_dbSearch(db, c, '^' . a:key, 0)
    if idx < 0
        return []
    endif
    
    " 遍历 bucket，找到第一个匹配的更长编码
    while idx < len(bucket) && len(ret) < limit
        let item = ZFVimIM_dbItemDecode(bucket[idx])
        let k = get(item, 'key', '')
        
        " 如果编码不再以 key 为前缀，停止搜索
        if k !~# '^' . a:key
            break
        endif
        
        " 只返回比当前编码更长的编码（例如 "gk" -> "gka"）
        " 这样用户输入 "gk" 时，会显示 "gka" 对应的词作为候选
        if k !=# a:key
            let wordList = get(item, 'wordList', [])
            if !empty(wordList)
                let word = wordList[0]
                " 创建候选词项，标记为 hint: 1
                " 这样在显示时会加上 ~ 标记，用户选择后会添加到词库
                " len: 使用当前输入的编码长度
                " word: 实际要上屏的词
                " displayWord: 显示用的词（与 word 相同）
                " key: 实际匹配的编码（例如 "gka"）
                " hint: 1 标记为自造词，显示时会加上 ~
                call add(ret, {
                            \ 'dbId' : get(db, 'dbId', 0),
                            \ 'len' : len(a:key),
                            \ 'word' : word,
                            \ 'displayWord' : word,
                            \ 'key' : k,
                            \ 'type' : 'match',
                            \ 'hint' : 1,
                            \ })
                break  " 只返回第一个匹配的词
            endif
        endif
        let idx += 1
    endwhile
    return ret
endfunction

" Debounced version of updateCandidates
function! s:updateCandidatesDebounced()
    if get(g:, 'ZFVimIM_sbzr_mode', 0)
        call s:updateCandidates()
        return
    endif
    " First, try to get current keyboard state (peek without updating)
    " Use updateKeyboardFromCursor logic but don't update s:keyboard yet
    let cursor_positions = getpos('.')
    let start_column = cursor_positions[2]
    let current_line = getline(cursor_positions[1])
    let seamless_column = s:getSeamless(cursor_positions)
    if seamless_column <= 0
        let seamless_column = 1
    endif
    if start_column <= seamless_column
        " No input, update immediately
        call s:updateCandidates()
        return
    endif
    while start_column > seamless_column && current_line[(start_column-1) - 1] =~# s:input_keys
        let start_column -= 1
    endwhile
    let len = cursor_positions[2] - start_column
    if len <= 0
        " No input, update immediately
        call s:updateCandidates()
        return
    endif
    let currentKeyboard = strpart(current_line, (start_column - 1), len)
    
    " For short input (1-2 chars) or when keyboard length/content changes, update immediately
    " This ensures first character is always matched and changes are responsive
    let keyboardLen = len(currentKeyboard)
    let lastKeyboardLen = len(s:lastKeyboard)
    
    " Immediate update conditions:
    " 1. Very short input (1-2 chars) - always immediate for responsiveness
    " 2. Keyboard length changed (user added/removed chars) - immediate to show new results
    " 3. Keyboard content changed (user typing) - immediate
    if keyboardLen <= 2 || keyboardLen != lastKeyboardLen || currentKeyboard !=# s:lastKeyboard
        " Cancel previous timer if exists
        if s:updateCandidatesTimer >= 0
            call timer_stop(s:updateCandidatesTimer)
            let s:updateCandidatesTimer = -1
        endif
        " Update immediately
        call s:updateCandidates()
        return
    endif
    
    " For longer input (3+ chars) with no change, use minimal debounce
    " Cancel previous timer if exists
    if s:updateCandidatesTimer >= 0
        call timer_stop(s:updateCandidatesTimer)
    endif
    " Schedule update with 10ms delay (minimal debounce for better responsiveness)
    let s:updateCandidatesTimer = timer_start(10, {-> s:updateCandidates()})
endfunction

function! s:omnifunc(start, keyboard)
    let s:enter_to_confirm = 1
    let s:hasInput = 1
    if a:start
        if !s:updateKeyboardFromCursor()
            return -3
        endif
        return s:start_column - 1
    else
        call s:updateCandidatesDebounced()
        return []
    endif
endfunction

function! s:popupMenuList(complete)
    if empty(a:complete) || type(a:complete) != type([])
        return []
    endif
    let labelList = s:getLabelList()
    let label = 1
    let popup_list = []
    for item in a:complete
        " :h complete-items
        let complete_items = {}
        " ============================================================
        " SBZR 自造词功能：检查是否为自造词（hint: 1）
        " 
        " hint: 1 表示这是断词自动拼生成的候选词，显示时不应该显示标签键
        " （因为用户需要通过标签键选择，而不是通过 hint 词）
        " ============================================================
        let isHint = get(item, 'hint', 0)
        
        if !empty(labelList)
            let labelstring = get(labelList, label - 1, '?')
        elseif get(g:, 'ZFVimIM_freeScroll', 0)
            let labelstring = printf('%2d', label == 10 ? 0 : label)
        else
            if label >= 1 && label <= 9
                let labelstring = label
            elseif label == 10
                let labelstring = '0'
            else
                let labelstring = '?'
            endif
        endif
        let left = strpart(s:keyboard, item['len'])
        
        " 检查是否有自定义显示词（displayWord）
        " 在 SBZR 模式下，如果候选词有 displayWord（例如 "高兴~"），
        " 会使用 displayWord 而不是 word + left
        let hasDisplay = get(g:, 'ZFVimIM_sbzr_mode', 0) && has_key(item, 'displayWord')
        
        if !empty(labelList)
            if hasDisplay
                " 使用 displayWord（例如 "高兴~"）
                " 注意：displayWord 可能已经包含了 ~ 标记（通过 ZFVimIM_recentComboCandidate）
                let wordText = item['displayWord']
            else
                let wordText = item['word'] . left
            endif
            " 如果是 hint 词（自造词），不显示标签键
            " 因为 hint 词是通过断词自动拼生成的，用户不应该通过标签键选择
            if !isHint && labelstring != ''
                let wordText .= labelstring
            endif
            let complete_items['abbr'] = wordText
            let complete_items['word'] = wordText
        else
            let complete_items['abbr'] = item['word']
            let complete_items['word'] = item['word']
        endif

        let complete_items['dup'] = 1
        if empty(labelList)
            let complete_items['word'] .= left
        endif
        if s:completeItemAvailable
            let complete_items['info'] = ZFVimIM_json_encode(item)
        endif
        call add(popup_list, complete_items)
        let label += 1
    endfor

    let &completeopt = 'menuone'
    let &pumheight = s:defaultPumheight()
    return popup_list
endfunction

function! s:OnInsertEnter()
    if get(g:, 'ZFJobTimerFallbackCursorMoving', 0) > 0
        return
    endif
    let s:seamless_positions = getpos('.')
    let s:enter_to_confirm = 0
endfunction
function! s:OnInsertLeave()
    if get(g:, 'ZFJobTimerFallbackCursorMoving', 0) > 0
        return
    endif
    call s:resetState()
    
    " Save all pending dictionaries in background
    call s:savePendingDicts()
endfunction

" Save all pending dictionaries asynchronously
function! s:savePendingDicts()
    if empty(s:pendingSaveDicts)
        return
    endif
    
    " Save each dictionary in background
    for dictPath in keys(s:pendingSaveDicts)
        let db = s:pendingSaveDicts[dictPath]
        if has('timers')
            " Use timer to save asynchronously (non-blocking)
            call timer_start(0, {-> s:asyncSaveDict(db, dictPath)})
        else
            " Fallback: save synchronously if timers not available
            try
                call ZFVimIM_dbSave(db, dictPath)
            catch
                " Silently ignore save errors
            endtry
        endif
    endfor
    
    " Clear pending saves
    let s:pendingSaveDicts = {}
    " Note: pendingAutoAddWords are cleared in asyncSaveDict after processing
endfunction

" Save all pending dictionaries synchronously (for VimLeavePre)
function! s:savePendingDictsSync()
    if empty(s:pendingSaveDicts)
        return
    endif
    
    " Save each dictionary synchronously (blocking, but necessary on exit)
    for dictPath in keys(s:pendingSaveDicts)
        let db = s:pendingSaveDicts[dictPath]
        try
            call s:asyncSaveDict(db, dictPath)
        catch
            " Silently ignore save errors on exit
        endtry
    endfor
    
    " Clear pending saves
    let s:pendingSaveDicts = {}
endfunction
function! s:OnCursorMovedI()
    if get(g:, 'ZFJobTimerFallbackCursorMoving', 0) > 0
        return
    endif
    if s:hasInput
        let s:hasInput = 0
    else
        let s:seamless_positions = getpos('.')
        let s:enter_to_confirm = 0
    endif
endfunction


" Track which databases need to be saved
if !exists('s:pendingSaveDicts')
    let s:pendingSaveDicts = {}
endif
" Track words added by auto-add feature (key: dictPath, value: list of {key, word})
if !exists('s:pendingAutoAddWords')
    let s:pendingAutoAddWords = {}
endif

function! s:addWord(dbId, key, word)
    let dbIndex = ZFVimIM_dbIndexForId(a:dbId)
    if dbIndex < 0
        return
    endif
    let db = g:ZFVimIM_db[dbIndex]
    call ZFVimIM_wordAdd(db, a:word, a:key)

    let g:ZFVimIM_event_OnAddWord = {
                \   'dbId' : a:dbId,
                \   'key' : a:key,
                \   'word' : a:word,
                \ }
    doautocmd User ZFVimIM_event_OnAddWord
    
    " Mark database for saving (don't save immediately)
    let dictPath = ''
    if has_key(db, 'implData') && has_key(db['implData'], 'dictPath')
        let dictPath = db['implData']['dictPath']
    else
        " Try to get from autoLoadDict logic
        let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
        let sfileDir = expand('<sfile>:p:h:h')
        if isdirectory(sfileDir . '/dict')
            let pluginDir = sfileDir
        endif
        let dictDir = pluginDir . '/dict'
        
        " Default dictionary is default.yaml
        if exists('g:zfvimim_default_dict_name') && !empty(g:zfvimim_default_dict_name)
            let defaultDictName = g:zfvimim_default_dict_name
            if defaultDictName !~ '\.yaml$'
                let defaultDictName = defaultDictName . '.yaml'
            endif
            let dictPath = dictDir . '/' . defaultDictName
        elseif exists('g:zfvimim_dict_path') && !empty(g:zfvimim_dict_path)
            let dictPath = expand(g:zfvimim_dict_path)
        else
            " Default dictionary: default.yaml
            let dictPath = dictDir . '/default.yaml'
        endif
    endif
    
    if !empty(dictPath)
        " Store dictPath in implData for future use
        if !has_key(db, 'implData')
            let db['implData'] = {}
        endif
        let db['implData']['dictPath'] = dictPath
        
        " Record the added word for database update
        if !has_key(s:pendingAutoAddWords, dictPath)
            let s:pendingAutoAddWords[dictPath] = []
        endif
        call add(s:pendingAutoAddWords[dictPath], {'key': a:key, 'word': a:word})
        
        " Mark this database for saving when leaving insert mode
        let s:pendingSaveDicts[dictPath] = db
    endif
endfunction

" Async save function to avoid blocking - now only updates database, not TXT
function! s:asyncSaveDict(db, dictPath)
    try
        " Get database file path (.db file)
        let dbPath = s:ZFVimIM_getDbPath(a:dictPath)
        " Note: db_add_word.py will create the database if it doesn't exist
        " So we don't need to check if it exists here
        
        " Get words to add from pending list
        let wordsToAdd = get(s:pendingAutoAddWords, a:dictPath, [])
        if empty(wordsToAdd)
            " No words to add, skip
            return
        endif
        
        " Use Python to add words to database
        let pythonCmd = executable('python3') ? 'python3' : 'python'
        if !executable(pythonCmd)
            return
        endif
        
        " Get script path
        let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
        let sfileDir = expand('<sfile>:p:h:h')
        if isdirectory(sfileDir . '/misc')
            let pluginDir = sfileDir
        endif
        let scriptPath = pluginDir . '/misc/db_add_word.py'
        if !filereadable(scriptPath)
            return
        endif
        
        " Add each word to database
        let addedCount = 0
        let failedCount = 0
        for wordItem in wordsToAdd
            let cmd = pythonCmd . ' "' . scriptPath . '" "' . dbPath . '" "' . wordItem['key'] . '" "' . wordItem['word'] . '"'
            let result = system(cmd)
            let result = substitute(result, '[\r\n]', '', 'g')
            if result ==# 'OK' || result ==# 'EXISTS'
                let addedCount += 1
            else
                let failedCount += 1
                " Log error for debugging (only if not silent)
                if !exists('g:ZFVimIM_silent_save') || !g:ZFVimIM_silent_save
                    echom '[ZFVimIM] Failed to add word: ' . wordItem['word'] . ' (' . result . ')'
                endif
            endif
        endfor
        
        " Clear pending words for this dict
        if has_key(s:pendingAutoAddWords, a:dictPath)
            call remove(s:pendingAutoAddWords, a:dictPath)
        endif
        
        " Clear cache and reload database if loaded
        if exists('g:ZFVimIM_db') && !empty(g:ZFVimIM_db)
            for db in g:ZFVimIM_db
                if has_key(db, 'implData')
                    let dbDictPath = get(db['implData'], 'dictPath', '')
                    if dbDictPath ==# a:dictPath
                        call ZFVimIM_dbSearchCacheClear(db)
                        " Reload database
                        call ZFVimIM_dbLoad(db, dbDictPath)
                        break
                    endif
                endif
            endfor
        endif
    catch
        " Silently ignore save errors
    endtry
endfunction

function! s:removeWord(dbId, key, word)
    " Remove word from dictionary
    let dbIndex = ZFVimIM_dbIndexForId(a:dbId)
    if dbIndex < 0
        return 0
    endif
    let db = g:ZFVimIM_db[dbIndex]
    
    " Get dictionary file path for saving
    let dictPath = ''
    if has_key(db, 'implData') && has_key(db['implData'], 'dictPath')
        let dictPath = db['implData']['dictPath']
    else
        " Try to get from autoLoadDict logic
        let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
        let sfileDir = expand('<sfile>:p:h:h')
        if isdirectory(sfileDir . '/dict')
            let pluginDir = sfileDir
        endif
        let dictDir = pluginDir . '/dict'
        
        " Default dictionary is default.yaml
        if exists('g:zfvimim_default_dict_name') && !empty(g:zfvimim_default_dict_name)
            let defaultDictName = g:zfvimim_default_dict_name
            if defaultDictName !~ '\.yaml$'
                let defaultDictName = defaultDictName . '.yaml'
            endif
            let dictPath = dictDir . '/' . defaultDictName
        elseif exists('g:zfvimim_dict_path') && !empty(g:zfvimim_dict_path)
            let dictPath = expand(g:zfvimim_dict_path)
        else
            " Default dictionary: default.yaml
                let dictPath = dictDir . '/default.yaml'
        endif
    endif
    
    " Remove the word
    call ZFVimIM_wordRemove(db, a:word, a:key)
    
    " Also remove from frequency tracking
    let freqKey = a:key . "\t" . a:word
    if has_key(s:word_frequency, freqKey)
        call remove(s:word_frequency, freqKey)
    endif
    
    " Mark database for saving (don't save immediately)
    if !empty(dictPath) && filereadable(dictPath)
            " Store dictPath in implData for future use
            if !has_key(db, 'implData')
                let db['implData'] = {}
            endif
            let db['implData']['dictPath'] = dictPath
        
        " Mark this database for saving when leaving insert mode
        let s:pendingSaveDicts[dictPath] = db
    endif
    
    return 1
endfunction

function! ZFVimIME_removeCurrentWord()
    " Remove the currently highlighted word in popup menu
    if mode() != 'i' || !s:floatVisible()
        return ''
    endif
    
    let item = {}
    if s:float_index >= 0 && s:float_index < len(s:float_items)
        let item = s:float_items[s:float_index]
    endif
    
    if !empty(item) && has_key(item, 'word')
        let word = item['word']
        
        " Protect single character words - do not allow deletion
        if strchars(word) == 1
            " Silently ignore - don't delete single character words
            return ''
        endif
        
        let key = get(item, 'key', '')
        let dbId = get(item, 'dbId', '')
        
        " Get database
        let db = {}
        let dictPath = ''
        if !empty(dbId) && exists('g:ZFVimIM_db') && !empty(g:ZFVimIM_db)
            let dbIndex = ZFVimIM_dbIndexForId(dbId)
            if dbIndex >= 0 && dbIndex < len(g:ZFVimIM_db)
                let db = g:ZFVimIM_db[dbIndex]
                if has_key(db, 'implData') && has_key(db['implData'], 'dictPath')
                    let dictPath = db['implData']['dictPath']
                endif
            endif
        endif
        
        " Remove from file using IMRemove
        call IMRemove('', {}, word)
        
        " Also remove from memory database if we have the key
        " Try to remove from all databases, not just current one
        let removedFromMemory = 0
        if exists('g:ZFVimIM_db') && !empty(g:ZFVimIM_db) && !empty(key)
            for dbItem in g:ZFVimIM_db
                try
                    " Try to remove from this database
                    call ZFVimIM_wordRemove(dbItem, word, key)
                    call ZFVimIM_dbSearchCacheClear(dbItem)
                    let removedFromMemory = 1
                catch
                    " Ignore errors, continue to next database
                endtry
            endfor
        endif
        
        " If we don't have key, try to remove from all databases without key
        if empty(key) && exists('g:ZFVimIM_db') && !empty(g:ZFVimIM_db)
            for dbItem in g:ZFVimIM_db
                try
                    " Try to remove without key (searches all keys)
                    call ZFVimIM_wordRemove(dbItem, word, '')
                    call ZFVimIM_dbSearchCacheClear(dbItem)
                    let removedFromMemory = 1
                catch
                    " Ignore errors
                endtry
            endfor
        endif
        
        " Clear cache and refresh candidates
        " If removed from memory successfully, no need to reload file
        " Use timer to defer update to avoid API errors
        if has('timers')
            call timer_start(100, {-> s:refreshAfterRemove(dictPath, db, removedFromMemory)})
        else
            " Fallback: try to refresh immediately
            try
                call s:refreshAfterRemove(dictPath, db, removedFromMemory)
            catch
                " Ignore errors
            endtry
        endif
    else
        echo "无法获取当前选中的词"
    endif
    
    return ''
endfunction

" Refresh candidates after removing a word
function! s:refreshAfterRemove(dictPath, db, removedFromMemory)
    try
        " Clear file cache if path is known
        if !empty(a:dictPath) && filereadable(a:dictPath)
            call ZFVimIM_cacheClearForFile(a:dictPath)
        endif
        
        " Clear search cache for ALL databases (not just current one)
        if exists('g:ZFVimIM_db') && !empty(g:ZFVimIM_db)
            for dbItem in g:ZFVimIM_db
                call ZFVimIM_dbSearchCacheClear(dbItem)
            endfor
        endif
        
        " Clear alias cache if exists (used for abbreviation matching)
        if exists('s:alias_cache')
            let s:alias_cache = {}
            let s:alias_cache_keys = []
        endif
        
        " Always reload dictionary file to ensure memory is in sync with file
        " Even if removed from memory, file was modified, so reload to be safe
        if !empty(a:dictPath) && filereadable(a:dictPath) && !empty(a:db)
            " Reload dictionary file (this updates dbMap in memory)
            " Use async reload to avoid blocking
            if has('timers')
                " Reload first, then update candidates after reload completes
                call timer_start(0, {-> s:asyncReloadDict(a:db, a:dictPath)})
            else
                " Synchronous reload
                call ZFVimIM_dbLoad(a:db, a:dictPath)
                " Update candidates after reload
                if mode() == 'i' && s:floatVisible()
                    " Clear existing match list to force regeneration
                    let s:match_list = []
                    let s:page = 0
                    let s:pageup_pagedown = 0
                    call s:updateCandidatesDebounced()
                endif
            endif
        else
            " If no file path, just refresh candidates from current memory state
            if mode() == 'i' && s:floatVisible()
                " Clear existing match list to force regeneration
                let s:match_list = []
                let s:page = 0
                let s:pageup_pagedown = 0
                " Force update candidates (this will regenerate from updated database)
                call s:updateCandidatesDebounced()
            endif
        endif
    catch
        " Ignore errors
    endtry
endfunction

" Async reload dictionary to avoid blocking
function! s:asyncReloadDict(db, dictPath)
    try
        " Reload dictionary file
        call ZFVimIM_dbLoad(a:db, a:dictPath)
        
        " Update candidates after reload completes
        " Use another timer to ensure reload is complete
        if has('timers')
            call timer_start(50, {-> s:updateCandidatesAfterReload()})
        else
            call s:updateCandidatesAfterReload()
        endif
    catch
        " Ignore errors
    endtry
endfunction

" Update candidates after dictionary reload
function! s:updateCandidatesAfterReload()
    try
        if mode() == 'i' && s:floatVisible()
            " Clear existing match list to force regeneration
            let s:match_list = []
            let s:page = 0
            let s:pageup_pagedown = 0
            " Force update candidates (this will regenerate from reloaded database)
            call s:updateCandidatesDebounced()
        endif
    catch
        " Ignore errors
    endtry
endfunction

let s:completeItemAvailable = (exists('v:completed_item') && ZFVimIM_json_available())
let s:confirmFlag = 0
function! s:OnCompleteDone()
    if !s:confirmFlag
        return
    endif
    let s:confirmFlag = 0
    if !s:completeItemAvailable
        return
    endif
    try
        let item = ZFVimIM_json_decode(v:completed_item['info'])
    catch
        let item = ''
    endtry
    if empty(item)
        let s:userWord = []
        return
    endif
    call s:didChoose(item)
endfunction

let s:userWord=[]
function! s:didChoose(item)
    let g:ZFVimIM_choosedWord = a:item
    doautocmd User ZFVimIM_event_OnCompleteDone
    unlet g:ZFVimIM_choosedWord

    let s:seamless_positions[2] = s:start_column + len(a:item['word'])

    " 记录词的使用频率，用于智能排序
    call s:recordWordUsage(a:item['key'], a:item['word'])
    
    " 更新最近提交的词记录（用于生成组合候选词）
    " 这会更新 s:prev_commit 和 s:last_commit
    call s:updateRecentCommit(a:item)
    
    " ============================================================
    " SBZR 自造词功能：处理临时词（标记为 temp: 1 的词）
    " 
    " 当用户选择了带 temp: 1 标记的词（例如通过 ZFVimIM_recentComboCandidate
    " 生成的组合词），会立即添加到词库中。
    " 
    " 例如：用户输入 "gkxk" 选择了 "高兴~"（temp: 1），
    " 这里会将 "gkxk" -> "高兴" 添加到词库。
    " ============================================================
    if get(a:item, 'temp', 0)
        " 将临时词添加到词库（会保存到数据库和 YAML 文件）
        call s:addWord(a:item['dbId'], a:item['key'], a:item['word'])
    endif

    " 处理句子类型的词（多个词组合）
    if a:item['type'] == 'sentence'
        for word in get(a:item, 'sentenceList', [])
            call s:addWord(a:item['dbId'], word['key'], word['word'])
            " Also record sentence word usage
            call s:recordWordUsage(word['key'], word['word'])
        endfor
        let s:userWord = []
        return
    endif

    " ============================================================
    " SBZR 自造词功能：记录用户选择的词，用于后续组合
    "
    " s:userWord 用于记录用户连续选择的词，当选择的词长度等于当前编码长度时，
    " 会调用 s:addWordFromUserWord 将多个词组合成词组添加到词库。
    "
    " 例如：用户输入 "gk" 选择 "高"，然后输入 "xk" 选择 "兴"，
    " 当输入 "gkxk" 时，s:addWordFromUserWord 会将 "gkxk" -> "高兴" 添加到词库。
    " ============================================================
    call add(s:userWord, a:item)

    " 当选择的词长度等于当前编码长度时，尝试组合成词组
    if a:item['len'] == len(s:keyboard)
        " 将多个词组合成词组添加到词库
        call s:addWordFromUserWord()
        let s:userWord = []
    endif
endfunction

function! s:updateRecentCommit(item)
    if empty(a:item) || !has_key(a:item, 'key') || !has_key(a:item, 'word')
        return
    endif
    let key = get(a:item, 'key', '')
    let word = get(a:item, 'word', '')
    if len(key) < 2 || empty(word)
        return
    endif
    let key2 = strpart(key, 0, 2)
    " 更新历史记录：prev_prev -> prev -> last
    " 确保每个记录都包含 key2（前2码）和 key（完整编码），用于两字和三字组合
    let s:prev_prev_commit = s:prev_commit
    let s:prev_commit = s:last_commit
    let s:last_commit = {'key2': key2, 'key': key, 'word': word}
    
    " 调试：显示历史记录更新
    if get(g:, 'ZFVimIM_debug', 0)
        echom '[DEBUG] Updated commit history:'
        echom '[DEBUG]   last_commit: key=' . key . ', word=' . word
        if !empty(s:prev_commit)
            echom '[DEBUG]   prev_commit: key=' . get(s:prev_commit, 'key', '') . ', word=' . get(s:prev_commit, 'word', '')
        endif
        if !empty(s:prev_prev_commit)
            echom '[DEBUG]   prev_prev_commit: key=' . get(s:prev_prev_commit, 'key', '') . ', word=' . get(s:prev_prev_commit, 'word', '')
        endif
    endif
endfunction
" ============================================================
" SBZR 自造词功能：将用户连续选择的多个词组合成词组添加到词库
"
" 功能说明：
"   当用户连续选择多个词（例如先选 "高"，再选 "兴"），
"   此函数会将它们组合成一个词组（例如 "高兴"）并添加到词库。
"
" 工作流程：
"   1. 遍历 s:userWord（用户连续选择的词列表）
"   2. 先将每个词单独添加到词库（记录使用频率）
"   3. 检查是否需要组合成词组：
"      - 如果有自定义检查器（g:ZFVimIM_autoAddWordChecker），使用检查器判断
"      - 否则，如果满足以下条件，则组合：
"        * 所有词来自同一个数据库
"        * 词的数量大于1
"        * 组合后的词长度不超过 g:ZFVimIM_autoAddWordLen（默认12个字符）
"   4. 如果需要组合，将组合词添加到词库
"
" 示例：
"   用户输入 "gk" 选择 "高"，然后输入 "xk" 选择 "兴"
"   s:userWord = [
"     {'key': 'gk', 'word': '高', 'dbId': 0},
"     {'key': 'xk', 'word': '兴', 'dbId': 0}
"   ]
"   此函数会：
"   1. 将 "gk" -> "高" 和 "xk" -> "兴" 添加到词库
"   2. 检查是否需要组合：满足条件
"   3. 将 "gkxk" -> "高兴" 添加到词库
"
" 相关变量：
"   s:userWord: 用户连续选择的词列表（在 s:didChoose 中更新）
"   g:ZFVimIM_autoAddWordLen: 组合词的最大长度（默认12个字符）
"   g:ZFVimIM_autoAddWordChecker: 自定义检查器函数列表
" ============================================================
function! s:addWordFromUserWord()
    if !empty(s:userWord)
        let sentenceKey = ''      " 组合后的编码（例如 "gkxk"）
        let sentenceWord = ''      " 组合后的词（例如 "高兴"）
        let hasOtherDb = 0         " 是否有来自不同数据库的词
        let dbIdPrev = ''          " 前一个词的数据库ID
        
        " 遍历用户选择的词列表
        for word in s:userWord
            " 先将每个词单独添加到词库（记录使用频率）
            call s:addWord(word['dbId'], word['key'], word['word'])

            " 检查是否有来自不同数据库的词
            if !hasOtherDb
                let hasOtherDb = (dbIdPrev != '' && dbIdPrev != word['dbId'])
                let dbIdPrev = word['dbId']
            endif
            
            " 组合编码和词
            let sentenceKey .= word['key']
            let sentenceWord .= word['word']
        endfor

        " 判断是否需要将组合词添加到词库
        let needAdd = 0
        if !empty(g:ZFVimIM_autoAddWordChecker)
            " 如果有自定义检查器，使用检查器判断
            let needAdd = 1
            for Checker in g:ZFVimIM_autoAddWordChecker
                if ZFVimIM_funcCallable(Checker)
                    let needAdd = ZFVimIM_funcCall(Checker, [s:userWord])
                    if !needAdd
                        break
                    endif
                endif
            endfor
        else
            " 默认规则：如果满足以下条件，则组合
            " 1. 所有词来自同一个数据库
            " 2. 词的数量大于1（至少2个词）
            " 3. 组合后的词长度不超过限制（默认12个字符）
            if !hasOtherDb
                        \ && len(s:userWord) > 1
                        \ && len(sentenceWord) <= g:ZFVimIM_autoAddWordLen
                let needAdd = 1
            endif
        endif
        
        " 如果需要组合，将组合词添加到词库
        if needAdd
            " 使用第一个词的数据库ID，组合编码和词添加到词库
            call s:addWord(s:userWord[0]['dbId'], sentenceKey, sentenceWord)
        endif
    endif
endfunction

call s:init()
call s:resetState()

" ============================================================
" Word frequency tracking for smart sorting
let s:word_frequency = {}
let s:freq_file_path = ''

function! s:initWordFrequency()
    " Initialize frequency file path
    if empty(s:freq_file_path)
        let s:freq_file_path = stdpath('data') . '/ZFVimIM_word_freq.txt'
        " Fallback to plugin directory if stdpath doesn't work
        if !isdirectory(stdpath('data'))
            let s:freq_file_path = expand('<sfile>:p:h:h') . '/word_freq.txt'
        endif
    endif
    
    " Load frequency data
    if filereadable(s:freq_file_path)
        for line in readfile(s:freq_file_path)
            let parts = split(line, "\t")
            if len(parts) >= 2
                let key = parts[0]
                let word = parts[1]
                let freq = len(parts) >= 3 ? str2nr(parts[2]) : 1
                let s:word_frequency[key . "\t" . word] = freq
            endif
        endfor
    endif
endfunction

function! s:recordWordUsage(key, word)
    " Record word usage (key + word as unique identifier)
    let key = a:key . "\t" . a:word
    if !has_key(s:word_frequency, key)
        let s:word_frequency[key] = 0
    endif
    let s:word_frequency[key] += 1
    if get(g:, 'ZFVimIM_sbzr_mode', 0)
        let s:sbzr_seen_counter += 1
        let s:sbzr_seen_freq[key] = s:sbzr_seen_counter
    endif
    
    " Save to file (limit frequency to prevent overflow)
    if s:word_frequency[key] > 1000
        let s:word_frequency[key] = 1000
    endif
    
    " Update frequency in database
    call s:updateWordFrequencyInDb(a:key, a:word, 1)
    
    " Auto-save frequency data (every 10 uses)
    if s:word_frequency[key] % 10 == 0
        call s:saveWordFrequency()
    endif
endfunction

function! s:updateWordFrequencyInDb(key, word, increment)
    " Update word frequency in database
    " Get database file path
    let dictPath = ''
    let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
    let sfileDir = expand('<sfile>:p:h:h')
    if isdirectory(sfileDir . '/dict')
        let pluginDir = sfileDir
    endif
    let dictDir = pluginDir . '/dict'
    
    if exists('g:zfvimim_default_dict_name') && !empty(g:zfvimim_default_dict_name)
        let defaultDictName = g:zfvimim_default_dict_name
        if defaultDictName !~ '\.yaml$'
            let defaultDictName = defaultDictName . '.yaml'
        endif
        let dictPath = dictDir . '/' . defaultDictName
    elseif exists('g:zfvimim_dict_path') && !empty(g:zfvimim_dict_path)
        let dictPath = expand(g:zfvimim_dict_path)
    else
        let dictPath = dictDir . '/default.yaml'
    endif
    
    if empty(dictPath)
        return
    endif
    
    " Get database file path (.db file)
    let dbPath = s:ZFVimIM_getDbPath(dictPath)
    if !filereadable(dbPath)
        return
    endif
    
    " Use Python to update frequency in database
    let pythonCmd = executable('python3') ? 'python3' : 'python'
    if !executable(pythonCmd)
        return
    endif
    
    " Get script path
    let scriptPath = pluginDir . '/misc/db_update_frequency.py'
    if !filereadable(scriptPath)
        return
    endif
    
    " Execute update (silently, don't show errors)
    try
        let scriptPathAbs = CygpathFix_absPath(scriptPath)
        let dbPathAbs = CygpathFix_absPath(dbPath)
        let cmd = pythonCmd . ' "' . scriptPathAbs . '" "' . dbPathAbs . '" "' . a:key . '" "' . a:word . '" ' . a:increment
        let result = system(cmd)
        " Update in-memory database if loaded
        if exists('g:ZFVimIM_db') && !empty(g:ZFVimIM_db)
            for db in g:ZFVimIM_db
                if has_key(db, 'implData')
                    let dbDictPath = get(db['implData'], 'dictPath', '')
                    if dbDictPath ==# dbPath
                        " Update frequency in memory
                        call ZFVimIM_wordReorder(db, a:word, a:key)
                        break
                    endif
                endif
            endfor
        endif
    catch /.*/
        " Silently ignore errors
    endtry
endfunction

function! s:saveWordFrequency()
    " Save frequency data to file
    if empty(s:freq_file_path)
        return
    endif
    
    let lines = []
    for key in keys(s:word_frequency)
        let freq = s:word_frequency[key]
        if freq > 0
            call add(lines, key . "\t" . freq)
        endif
    endfor
    
    " Sort by frequency (descending) and keep top 10000 entries
    call sort(lines, function('s:sortFreqDesc'))
    if len(lines) > 10000
        let lines = lines[0:9999]
    endif
    
    call writefile(lines, s:freq_file_path)
endfunction

function! s:sortFreqDesc(line1, line2)
    let parts1 = split(a:line1, "\t")
    let parts2 = split(a:line2, "\t")
    let freq1 = len(parts1) >= 3 ? str2nr(parts1[2]) : 0
    let freq2 = len(parts2) >= 3 ? str2nr(parts2[2]) : 0
    return freq2 - freq1
endfunction

function! s:getWordFrequency(key, word)
    " Get word frequency (0 if not found)
    let key = a:key . "\t" . a:word
    return get(s:word_frequency, key, 0)
endfunction

" Global function to get word frequency (for use in other files)
function! ZFVimIM_getWordFrequency(key, word)
    let key = a:key . "\t" . a:word
    if get(g:, 'ZFVimIM_sbzr_mode', 0)
        let seen = get(s:sbzr_seen_freq, key, 0)
        if seen > 0
            return 1000000 + seen
        endif
    endif
    return get(s:word_frequency, key, 0)
endfunction

" ============================================================
" SBZR 自造词功能：生成最近两个词或三个词的组合候选词
"
" 功能说明：
"   1. 两个单字组合（4个编码）：
"      当用户连续输入两个单字（每个单字2个编码，共4个编码）后，
"      此函数会生成一个组合候选词，将前两个字组合成一个词组。
"      例如：用户输入 "gk" 选择 "高"，然后输入 "xk" 选择 "兴"，
"      当输入 "gkxk" 时，会显示 "高兴~" 作为候选词。
"
"   2. 三个字组合（6个编码）：
"      当用户连续输入三个字后，会生成三字组合词。
"      编码规则：前两个字的声母 + 第三个字的全部编码
"      例如：
"        - 倒数第二次上屏：woqu (我去) -> 声母 w, q
"        - 倒数第一次上屏：wj (玩) -> 全部编码 wj
"        - 组合编码：wq + wj = wqwj
"        - 组合词：我去玩
"
" 参数：
"   key: 当前输入的编码（4个编码用于两字组合，6个编码用于三字组合）
"
" 返回值：
"   候选词项，包含：
"     - dbId: 数据库ID
"     - len: 编码长度（4或6）
"     - key: 组合编码
"     - word: 组合词
"     - displayWord: 显示用的词（带 ~ 标记）
"     - type: 类型（'match'）
"     - temp: 1（标记为临时词，选择后会添加到词库）
"
" 工作流程：
"   1. 检查输入是否为4个或6个编码
"   2. 对于4个编码：检查是否有前两个词的记录，组合前2码+后2码
"   3. 对于6个编码：检查是否有前三个词的记录，提取前两个字的声母+第三个字的全部编码
"   4. 生成组合词候选项，标记为 temp: 1
"   5. 用户选择后，s:didChoose 会检测到 temp: 1，调用 s:addWord 添加到词库
"
" 相关变量：
"   s:prev_prev_commit: 倒数第三个词（用于三字组合）
"   s:prev_commit: 前一个提交的词（通过 s:updateRecentCommit 更新）
"   s:last_commit: 最后一个提交的词（通过 s:updateRecentCommit 更新）
"   这些变量在 s:didChoose 中通过 s:updateRecentCommit 更新
" ============================================================
function! ZFVimIM_recentComboCandidate(key)
    let keyLen = len(a:key)
    
    " 调试：函数入口
    if get(g:, 'ZFVimIM_debug', 0)
        echom '[DEBUG] ZFVimIM_recentComboCandidate called: key=' . a:key . ', keyLen=' . keyLen
        echom '[DEBUG]   prev_commit exists: ' . (!empty(s:prev_commit))
        echom '[DEBUG]   last_commit exists: ' . (!empty(s:last_commit))
        if !empty(s:prev_commit)
            echom '[DEBUG]   prev_commit: key=' . get(s:prev_commit, 'key', '') . ', word=' . get(s:prev_commit, 'word', '')
        endif
        if !empty(s:last_commit)
            echom '[DEBUG]   last_commit: key=' . get(s:last_commit, 'key', '') . ', word=' . get(s:last_commit, 'word', '')
        endif
    endif
    
    " 处理多字组合（4个编码：前三个字的声母 + 最后一个字的声母）
    " 规则：前三个字的声母 + 最后一个字的声母
    " 例如：
    "   - wgxn = w(我) + g(共) + x(享) + n(你) = 我共享给你 (wgxd + gzni)
    "   - wswt = w(我) + s(是) + w(王) + t(天) = 我是王浩天 (wosi + whtm)
    "   - xngj = x(性) + n(能) + g(更) + j(机) = 性能更好新手机 (xngh + xsji)
    " 条件：prev_commit 和 last_commit 都存在
    if keyLen == 4 && !empty(s:prev_commit) && !empty(s:last_commit)
        let prevKey = get(s:prev_commit, 'key', '')
        let lastKey = get(s:last_commit, 'key', '')
        let prevWord = get(s:prev_commit, 'word', '')
        let lastWord = get(s:last_commit, 'word', '')
        
        " 计算总字数（使用 strchars 计算中文字符数）
        let totalWordLen = strchars(prevWord) + strchars(lastWord)
        
        " 如果总字数 >= 3，使用规则：前三个字的声母 + 最后一个字的声母
        " 无论总字数是多少（3字、4字、5字、10字...），都使用这个规则
        if totalWordLen >= 3
            let firstInitial = ''
            let secondInitial = ''
            let thirdInitial = ''
            let lastInitial = ''
            
            " 计算每个字的编码长度（用于定位声母）
            " 假设：编码长度 = 字数（每个字1个编码）或 编码长度 = 字数 * 2（每个字2个编码）
            let prevKeyLen = len(prevKey)
            let lastKeyLen = len(lastKey)
            " 使用 strchars() 计算中文字符数（而不是字节数）
            let prevWordLen = strchars(prevWord)
            let lastWordLen = strchars(lastWord)
            
            " 判断编码模式：如果编码长度等于字数，则每个字1个编码；否则每个字2个编码
            let prevCharsPerWord = (prevKeyLen == prevWordLen) ? 1 : 2
            let lastCharsPerWord = (lastKeyLen == lastWordLen) ? 1 : 2
            
            " 调试：编码模式
            if get(g:, 'ZFVimIM_debug', 0)
                echom '[DEBUG] Encoding mode:'
                echom '[DEBUG]   prevCharsPerWord=' . prevCharsPerWord . ' (keyLen=' . prevKeyLen . ', wordLen=' . prevWordLen . ')'
                echom '[DEBUG]   lastCharsPerWord=' . lastCharsPerWord . ' (keyLen=' . lastKeyLen . ', wordLen=' . lastWordLen . ')'
            endif
            
            " 提取前三个字的声母
            let charIndex = 0
            " 第一个字（在 prev_commit）
            if prevWordLen >= 1
                let firstInitial = strpart(prevKey, charIndex, 1)
                let charIndex += prevCharsPerWord
                if get(g:, 'ZFVimIM_debug', 0)
                    echom '[DEBUG]   firstInitial=' . firstInitial . ' (charIndex=' . (charIndex - prevCharsPerWord) . ')'
                endif
            endif
            
            " 第二个字
            if prevWordLen >= 2
                " 第二个字也在 prev_commit
                let secondInitial = strpart(prevKey, charIndex, 1)
                let charIndex += prevCharsPerWord
                if get(g:, 'ZFVimIM_debug', 0)
                    echom '[DEBUG]   secondInitial=' . secondInitial . ' (charIndex=' . (charIndex - prevCharsPerWord) . ')'
                endif
            elseif prevWordLen == 1 && lastWordLen >= 1
                " 第二个字在 last_commit
                let secondInitial = strpart(lastKey, 0, 1)
                if get(g:, 'ZFVimIM_debug', 0)
                    echom '[DEBUG]   secondInitial=' . secondInitial . ' (from last_commit[0])'
                endif
            endif
            
            " 第三个字
            if prevWordLen >= 3
                " 第三个字也在 prev_commit
                let thirdInitial = strpart(prevKey, charIndex, 1)
                if get(g:, 'ZFVimIM_debug', 0)
                    echom '[DEBUG]   thirdInitial=' . thirdInitial . ' (charIndex=' . charIndex . ')'
                endif
            elseif prevWordLen == 2 && lastWordLen >= 1
                " 第三个字在 last_commit
                let thirdInitial = strpart(lastKey, 0, 1)
                if get(g:, 'ZFVimIM_debug', 0)
                    echom '[DEBUG]   thirdInitial=' . thirdInitial . ' (from last_commit[0])'
                endif
            elseif prevWordLen == 1 && lastWordLen >= 2
                " 第三个字在 last_commit
                let thirdInitial = strpart(lastKey, lastCharsPerWord, 1)
                if get(g:, 'ZFVimIM_debug', 0)
                    echom '[DEBUG]   thirdInitial=' . thirdInitial . ' (from last_commit[' . lastCharsPerWord . '])'
                endif
            endif
            
            " 提取最后一个字的声母
            " 最后一个字在 last_commit 的最后一个字
            if lastWordLen >= 1
                " 计算最后一个字在 lastKey 中的位置
                if lastCharsPerWord == 1
                    " 每个字1个编码，最后一个字的位置是 len(lastKey) - 1
                    let lastCharPos = lastKeyLen - 1
                else
                    " 每个字2个编码，最后一个字的位置是 len(lastKey) - 2
                    let lastCharPos = lastKeyLen - 2
                endif
                let lastInitial = strpart(lastKey, lastCharPos, 1)
            endif
            
            " 组合编码：前三个字的声母 + 最后一个字的声母
            let comboKey = firstInitial . secondInitial . thirdInitial . lastInitial
            let matchedComboKey = ''
            
            " 调试：检查多字组合
            if get(g:, 'ZFVimIM_debug', 0)
                echom '[DEBUG] Multi-word combo:'
                echom '[DEBUG]   prev_commit: ' . prevKey . ' (' . prevWord . ', len=' . len(prevWord) . ')'
                echom '[DEBUG]   last_commit: ' . lastKey . ' (' . lastWord . ', len=' . len(lastWord) . ')'
                echom '[DEBUG]   totalWordLen: ' . totalWordLen
                echom '[DEBUG]   initials: ' . firstInitial . ' + ' . secondInitial . ' + ' . thirdInitial . ' + ' . lastInitial
                echom '[DEBUG]   comboKey: ' . comboKey . ', input key: ' . a:key
            endif
            
            " 检查是否匹配当前输入的4码
            if comboKey ==# a:key
                let matchedComboKey = comboKey
            else
                if get(g:, 'ZFVimIM_debug', 0)
                    echom '[DEBUG] ❌ No match: comboKey=' . comboKey . ' != input=' . a:key
                endif

                " 额外兼容：首字单字、末词双字的场景（如 你 + 去吗 -> nqma）
                if prevWordLen == 1 && lastWordLen == 2
                    let lastCharStart = lastKeyLen - lastCharsPerWord
                    let lastFullKey = strpart(lastKey, lastCharStart, lastCharsPerWord)
                    let comboKeyAlt = firstInitial . secondInitial . lastFullKey
                    if get(g:, 'ZFVimIM_debug', 0)
                        echom '[DEBUG] Alt comboKey (initials + last full key): ' . comboKeyAlt . ', input key: ' . a:key
                    endif
                    if comboKeyAlt ==# a:key
                        let matchedComboKey = comboKeyAlt
                    endif
                endif
            endif

            if !empty(matchedComboKey)
                " 检查数据库是否已加载
                if !exists('g:ZFVimIM_db') || empty(g:ZFVimIM_db) || g:ZFVimIM_dbIndex >= len(g:ZFVimIM_db)
                    if get(g:, 'ZFVimIM_debug', 0)
                        echom '[DEBUG] Database not loaded'
                    endif
                    return {}
                endif

                let dbId = get(g:ZFVimIM_db[g:ZFVimIM_dbIndex], 'dbId', 0)
                let word = prevWord . lastWord

                if get(g:, 'ZFVimIM_debug', 0)
                    if matchedComboKey ==# comboKey
                        echom '[DEBUG] ✅ Match! Returning combo candidate: ' . word . ' (' . matchedComboKey . ')'
                    else
                        echom '[DEBUG] ✅ Alt match! Returning combo candidate: ' . word . ' (' . matchedComboKey . ')'
                    endif
                endif

                return {
                    \ 'dbId': dbId,
                    \ 'key': matchedComboKey,
                    \ 'word': word,
                    \ 'displayWord': word . '~',
                    \ 'type': 'match',
                    \ 'temp': 1,
                    \ 'len': 4,
                    \ 'freq': 0,
                    \ }
            endif
        else
            if get(g:, 'ZFVimIM_debug', 0)
                echom '[DEBUG] Total word length < 3: ' . totalWordLen
            endif
        endif
    else
        if get(g:, 'ZFVimIM_debug', 0)
            echom '[DEBUG] Conditions not met: keyLen=' . keyLen . ', prev_empty=' . empty(s:prev_commit) . ', last_empty=' . empty(s:last_commit)
        endif
    endif
    
    " 处理三个字组合（4个编码：前两个字的声母各1个 + 第三个字的全部编码2个）
    " 例如：wqwj = w(我) + q(去) + wj(顽)
    " 条件：prev_commit 是两个字（编码长度 >= 4），last_commit 是一个字（编码长度 == 2）
    if keyLen == 4
        " 检查是否有前两个词的记录
        " 根据用户需求：
        "   - 倒数第二次上屏：woqu (我去) - 这是一个词（两个字）
        "   - 倒数第一次上屏：wj (玩) - 这是一个单字
        "   所以：prev_commit 是两个字（如 "woqu"），last_commit 是第三个字（如 "wj"）
        if empty(s:prev_commit) || empty(s:last_commit)
            return {}
        endif
        
        let prevKey = get(s:prev_commit, 'key', '')
        let lastKey = get(s:last_commit, 'key', '')
        
        " 调试：检查历史记录
        if get(g:, 'ZFVimIM_debug', 0)
            echom '[DEBUG] prev_commit key: ' . prevKey . ', word: ' . get(s:prev_commit, 'word', '')
            echom '[DEBUG] last_commit key: ' . lastKey . ', word: ' . get(s:last_commit, 'word', '')
            echom '[DEBUG] input key: ' . a:key
        endif
        
        let firstInitial = ''
        let secondInitial = ''
        
        " 如果 prev_commit 的编码长度 >= 4，可能是两个字，需要拆分
        " 假设每个字2个编码，前2个字符是第一个字，后2个字符是第二个字
        if len(prevKey) >= 4
            " 多字词（如 "woqu"）：拆分提取每个字的声母
            " 第一个字：前2个字符的第一个字符（声母）
            " 例如：woqu -> wo (我) -> 声母 w
            let firstInitial = strpart(prevKey, 0, 1)
            " 第二个字：第3-4个字符的第一个字符（声母），即索引2
            " 例如：woqu -> qu (去) -> 声母 q
            let secondInitial = strpart(prevKey, 2, 1)
        elseif len(prevKey) >= 2
            " prev_commit 是单字：第一个字的声母
            let firstInitial = strpart(prevKey, 0, 1)
            " 如果 prev_prev_commit 存在，它是第二个字
            if !empty(s:prev_prev_commit)
                let prevPrevKey = get(s:prev_prev_commit, 'key', '')
                if len(prevPrevKey) >= 2
                    let secondInitial = strpart(prevPrevKey, 0, 1)
                else
                    return {}
                endif
            else
                return {}
            endif
        else
            return {}
        endif
        
        " 第三个字的全部编码（last_commit）
        " 例如：last_commit['key'] = "wj"
        let thirdFullKey = lastKey
        
        " 组合编码：前两个字的声母 + 第三个字的全部编码
        " 例如：w + q + wj = wqwj
        let comboKey = firstInitial . secondInitial . thirdFullKey
        
        " 调试：检查组合编码
        if get(g:, 'ZFVimIM_debug', 0)
            echom '[DEBUG] firstInitial: ' . firstInitial . ', secondInitial: ' . secondInitial . ', thirdFullKey: ' . thirdFullKey
            echom '[DEBUG] comboKey: ' . comboKey . ', input key: ' . a:key
        endif
        
        " 检查是否匹配当前输入的4码
        if comboKey !=# a:key
            if get(g:, 'ZFVimIM_debug', 0)
                echom '[DEBUG] comboKey mismatch: ' . comboKey . ' != ' . a:key
            endif
            return {}
        endif
        
        " 检查数据库是否已加载
        if !exists('g:ZFVimIM_db') || empty(g:ZFVimIM_db) || g:ZFVimIM_dbIndex >= len(g:ZFVimIM_db)
            return {}
        endif
        
        let dbId = get(g:ZFVimIM_db[g:ZFVimIM_dbIndex], 'dbId', 0)
        " 组合词的词，生成三字组合词组
        " 如果 prev_commit 是多字词（如 "woqu"），需要拆分
        " 例如：prev_commit['word'] = "我去", last_commit['word'] = "玩"
        " word = "我去玩"
        let prevWord = get(s:prev_commit, 'word', '')
        let lastWord = get(s:last_commit, 'word', '')
        
        " 如果 prev_commit 是多字词，直接拼接；否则需要从 prev_prev_commit 获取第一个字
        if len(prevKey) >= 4 && len(prevWord) >= 2
            " prev_commit 是多字词，直接使用
            let word = prevWord . lastWord
        elseif !empty(s:prev_prev_commit)
            " prev_commit 是单字，需要从 prev_prev_commit 获取第一个字
            let prevPrevWord = get(s:prev_prev_commit, 'word', '')
            let word = prevPrevWord . prevWord . lastWord
        else
            return {}
        endif
        
        " 返回组合候选词项，标记为 temp: 1
        " len: 6个编码
        " key: 组合编码（例如 "wqwj"）
        " word: 组合词（例如 "我去玩"）
        " displayWord: 显示用的词，加上 ~ 标记
        " temp: 1 标记为临时词，选择后会添加到词库
        return {
                    \ 'dbId' : dbId,
                    \ 'len' : len(a:key),
                    \ 'key' : a:key,
                    \ 'word' : word,
                    \ 'displayWord' : word . '~',
                    \ 'type' : 'match',
                    \ 'temp' : 1,
                    \ }
    endif
    
    " 处理两个单字组合（4个编码）
    if keyLen == 4
        " 检查是否有前两个词的记录
        " s:prev_commit 和 s:last_commit 在 s:updateRecentCommit 中更新
        if empty(s:prev_commit) || empty(s:last_commit)
            return {}
        endif
        
        " 组合前两个词的前2码，检查是否匹配当前输入的4码
        " 例如：prev_commit['key2'] = "gk", last_commit['key2'] = "xk"
        " comboKey = "gkxk"，应该等于 a:key
        let comboKey = get(s:prev_commit, 'key2', '') . get(s:last_commit, 'key2', '')
        if comboKey !=# a:key
            return {}
        endif
        
        " 检查数据库是否已加载
        if !exists('g:ZFVimIM_db') || empty(g:ZFVimIM_db) || g:ZFVimIM_dbIndex >= len(g:ZFVimIM_db)
            return {}
        endif
        
        let dbId = get(g:ZFVimIM_db[g:ZFVimIM_dbIndex], 'dbId', 0)
        " 组合前两个词的词，生成组合词组
        " 例如：prev_commit['word'] = "高", last_commit['word'] = "兴"
        " word = "高兴"
        let word = get(s:prev_commit, 'word', '') . get(s:last_commit, 'word', '')
        
        " 返回组合候选词项，标记为 temp: 1
        " 这样在显示时会加上 ~ 标记（通过 displayWord），用户选择后会添加到词库
        " len: 4个编码
        " key: 组合编码（例如 "gkxk"）
        " word: 组合词（例如 "高兴"）
        " displayWord: 显示用的词，加上 ~ 标记
        " temp: 1 标记为临时词，选择后会添加到词库
        return {
                    \ 'dbId' : dbId,
                    \ 'len' : len(a:key),
                    \ 'key' : a:key,
                    \ 'word' : word,
                    \ 'displayWord' : word . '~',
                    \ 'type' : 'match',
                    \ 'temp' : 1,
                    \ }
    endif
    
    " 其他长度不支持
    return {}
endfunction

" Initialize word frequency on plugin load (after init)
call s:initWordFrequency()

" Save frequency on exit
augroup ZFVimIM_frequency
    autocmd!
    autocmd VimLeavePre * call s:saveWordFrequency()
    autocmd VimLeavePre * call s:cleanupDictionaryOnExit()
    " Also save pending dictionaries on exit
    autocmd VimLeavePre * call s:savePendingDictsSync()
augroup END

" Cleanup dictionary on exit
function! s:cleanupDictionaryOnExit()
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
        if defaultDictName !~ '\.yaml$'
            let defaultDictName = defaultDictName . '.yaml'
        endif
        let dictPath = dictDir . '/' . defaultDictName
    elseif exists('g:zfvimim_dict_path') && !empty(g:zfvimim_dict_path)
        let dictPath = expand(g:zfvimim_dict_path)
        " Ensure it's .yaml file for cleanup script
        if dictPath =~ '\.db$'
            let dictPath = s:ZFVimIM_getYamlPath(dictPath)
        endif
    else
        let dictPath = dictDir . '/default.yaml'
    endif
    
    if empty(dictPath) || !filereadable(dictPath)
        return
    endif
    
    " Get script path
    let scriptPath = pluginDir . '/misc/dbCleanup.py'
    if !filereadable(scriptPath)
        " Try sfileDir
        let scriptPath = sfileDir . '/misc/dbCleanup.py'
        if !filereadable(scriptPath)
            return
        endif
    endif
    
    " Get cache path
    let cachePath = ZFVimIM_cachePath()
    
    " Execute cleanup script (non-blocking, but wait a bit for it to start)
    let pythonCmd = executable('python3') ? 'python3' : 'python'
    if executable(pythonCmd)
        " Use timer to run asynchronously (non-blocking exit)
        if has('timers')
            " Run cleanup in background using timer
            call timer_start(0, {-> s:runCleanupScript(pythonCmd, scriptPath, dictPath, cachePath)})
        else
            " Fallback: run synchronously but quickly (script should be fast)
            try
                silent! call system('"' . pythonCmd . '" "' . scriptPath . '" "' . dictPath . '" "' . cachePath . '"')
            catch
                " Ignore errors
            endtry
        endif
    endif
endfunction

" Run cleanup script (called by timer)
function! s:runCleanupScript(pythonCmd, scriptPath, dictPath, cachePath)
    try
        " Run in background (non-blocking)
        if has('win32') || has('win64')
            " Windows: use start command
            silent! call system('start /b "' . a:pythonCmd . '" "' . a:scriptPath . '" "' . a:dictPath . '" "' . a:cachePath . '"')
        else
            " Unix: redirect output and run in background
            silent! call system('"' . a:pythonCmd . '" "' . a:scriptPath . '" "' . a:dictPath . '" "' . a:cachePath . '" > /dev/null 2>&1 &')
        endif
    catch
        " Ignore errors
    endtry
endfunction

" ============================================================
" Reload plugin function for development
" Define function only if it doesn't exist, to avoid redefinition errors during reload
if !exists('*ZFVimIM_reload')
function ZFVimIM_reload()
    " Stop IME if running
    if exists('*ZFVimIME_stop')
        call ZFVimIME_stop()
    endif
    
    " Clear autocommands
    try
        augroup! ZFVimIME_augroup
    catch
    endtry
    
    try
        augroup! ZFVimIME_impl_toggle_augroup
    catch
    endtry
    
    try
        augroup! ZFVimIME_impl_augroup
    catch
    endtry
    
    try
        augroup! ZFVimIME_impl_enabledStateUpdate_augroup
    catch
    endtry
    
    try
        augroup! ZFVimIME_impl_syncBuffer_augroup
    catch
    endtry
    
    try
        augroup! ZFVimIM_autoDisable_augroup
    catch
    endtry
    
    try
        augroup! ZFVimIM_event_OnUpdateDb_augroup
    catch
    endtry
    
    " Clear keymaps - both global and buffer-local
    if get(g:, 'ZFVimIM_keymap', 1)
        silent! nunmap ;;
        silent! iunmap ;;
        silent! vunmap ;;
        silent! xnoremap ;;
    endif
    
    " Clear all buffer-local keymaps that might have been created
    silent! lmapclear
    
    " Delete the command first to avoid redefinition errors
    if exists(':ZFVimIMReload')
        delcommand ZFVimIMReload
    endif
    
    " Reload plugin via Lazy
    " Use feedkeys to defer the reload, so this function can finish executing first
    " This avoids the "function in use" error when the plugin tries to redefine this function
    if exists(':Lazy') == 2
        " Defer the reload command to avoid redefinition errors
        call feedkeys(":Lazy reload ZFVimIM\<cr>", 'nt')
    else
        echo "Warning: Lazy plugin manager not found. Please restart Neovim to reload ZFVimIM."
    endif
endfunction
endif

" Create user command for reloading
" Reload plugin
command! -nargs=0 IMReload :call ZFVimIM_reload()

" Cache management commands - removed, use ZFVimIMClear instead
" if !exists(':ZFVimIMCacheClear')
"     command! ZFVimIMCacheClear :call ZFVimIM_cacheClearAll()
" endif
"
" if !exists(':ZFVimIMCacheUpdate')
"     command! ZFVimIMCacheUpdate :call ZFVimIM_cacheUpdate()
" endif

" Auto-regenerate cache when dictionary files are modified
augroup ZFVimIM_autoCacheUpdate_augroup
    autocmd!
    " Detect when dictionary files are saved
    autocmd BufWritePost *.yaml call s:ZFVimIM_autoCacheUpdate(expand('<afile>:p'))
augroup END

" Function to check if file is a dictionary file and regenerate cache
function! s:ZFVimIM_autoCacheUpdate(filePath)
    " Check if this file is a dictionary file used by ZFVimIM
    if !filereadable(a:filePath)
        return
    endif
    
    " Check if file is in a dictionary directory or matches known patterns
    let isDictFile = 0
    if exists('g:ZFVimIM_db') && !empty(g:ZFVimIM_db)
        for db in g:ZFVimIM_db
            if has_key(db, 'implData') && has_key(db['implData'], 'dictPath')
                if db['implData']['dictPath'] ==# a:filePath
                    let isDictFile = 1
                    break
                endif
            endif
        endfor
    endif
    
    " Also check if file is in common dictionary directories
    if !isDictFile
        let fileDir = fnamemodify(a:filePath, ':h')
        if fileDir =~# 'dict' || fileDir =~# 'zfvimim'
            let isDictFile = 1
        endif
    endif
    
    " Regenerate cache if it's a dictionary file
    if isDictFile
        " Regenerate cache in background
        call ZFVimIM_cacheRegenerateForFile(a:filePath)
    endif
endfunction

" ============================================================
" Cleanup dictionary manually
function! ZFVimIM_cleanupDictionary()
    " Check if Python is available
    if !executable('python') && !executable('python3')
        echom 'ZFVimIM: Python not found, cannot cleanup dictionary'
        return
    endif
    
    " Get current database
    if g:ZFVimIM_dbIndex >= len(g:ZFVimIM_db)
        echom 'ZFVimIM: No database loaded'
        return
    endif
    let db = g:ZFVimIM_db[g:ZFVimIM_dbIndex]
    
    " Get dictionary file path
    let dictPath = ''
    if has_key(db, 'implData') && has_key(db['implData'], 'dictPath')
        " Get path from database, but convert .db to .yaml for cleanup script
        let dictPath = db['implData']['dictPath']
        " Cleanup script only works with .yaml files, so convert .db to .yaml
        if dictPath =~ '\.db$'
            let dictPath = s:ZFVimIM_getYamlPath(dictPath)
        endif
    else
        " Try to get from autoLoadDict logic
        let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
        let sfileDir = expand('<sfile>:p:h:h')
        if isdirectory(sfileDir . '/dict')
            let pluginDir = sfileDir
        endif
        let dictDir = pluginDir . '/dict'
        
        " Default dictionary is default.yaml
        if exists('g:zfvimim_default_dict_name') && !empty(g:zfvimim_default_dict_name)
            let defaultDictName = g:zfvimim_default_dict_name
            if defaultDictName !~ '\.yaml$'
                let defaultDictName = defaultDictName . '.yaml'
            endif
            let dictPath = dictDir . '/' . defaultDictName
        elseif exists('g:zfvimim_dict_path') && !empty(g:zfvimim_dict_path)
            let dictPath = expand(g:zfvimim_dict_path)
            " Ensure it's .yaml file for cleanup script
            if dictPath =~ '\.db$'
                let dictPath = s:ZFVimIM_getYamlPath(dictPath)
            endif
        else
            " Default dictionary: default.yaml
                let dictPath = dictDir . '/default.yaml'
        endif
    endif
    
    " Skip if dictionary file doesn't exist or is not readable
    if empty(dictPath) || !filereadable(dictPath)
        echom 'ZFVimIM: Dictionary file not found: ' . dictPath
        return
    endif
    
    " Get script path
    let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
    let sfileDir = expand('<sfile>:p:h:h')
    if isdirectory(sfileDir . '/dict') && isdirectory(sfileDir . '/misc')
        let pluginDir = sfileDir
    else
        if !isdirectory(pluginDir . '/misc')
            let altPath = stdpath('config') . '/lazy/ZFVimIM'
            if isdirectory(altPath . '/misc')
                let pluginDir = altPath
            endif
        endif
    endif
    
    let scriptPath = pluginDir . '/misc/dbCleanup.py'
    if !filereadable(scriptPath)
        echom 'ZFVimIM: Cleanup script not found: ' . scriptPath
        return
    endif
    
    " Get cache path
    let cachePath = ZFVimIM_cachePath()
    
    " Determine Python command
    let pythonCmd = executable('python3') ? 'python3' : 'python'
    
    " Run cleanup script synchronously
    try
        let scriptPathAbs = CygpathFix_absPath(scriptPath)
        let dictPathAbs = CygpathFix_absPath(dictPath)
        let cachePathAbs = CygpathFix_absPath(cachePath)
        
        echom 'ZFVimIM: Cleaning up dictionary: ' . dictPathAbs
        let cmdList = [pythonCmd, scriptPathAbs, dictPathAbs, cachePathAbs]
        let result = system(join(cmdList, ' '))
        if v:shell_error == 0
            echom 'ZFVimIM: Dictionary cleanup completed successfully'
        else
            echom 'ZFVimIM: Cleanup failed: ' . result
        endif
    catch /.*/
        echom 'ZFVimIM: Error running cleanup: ' . v:exception
    endtry
endfunction

" Command to manually cleanup dictionary - removed, use ZFVimIMClear instead
" command! -nargs=0 ZFVimIMCleanup call ZFVimIM_cleanupDictionary()

" Combined command: cleanup dictionary + clear cache + reload
" This is the only cache management command now
function! ZFVimIM_refreshAll()
    echom '[ZFVimIM] 开始刷新：清理字典 + 清除缓存 + 重新加载...'
    
    " Step 1: Cleanup dictionary file (if cleanup script exists)
    let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
    let sfileDir = expand('<sfile>:p:h:h')
    if isdirectory(sfileDir . '/dict') && isdirectory(sfileDir . '/misc')
        let pluginDir = sfileDir
    else
        if !isdirectory(pluginDir . '/misc')
            let altPath = stdpath('config') . '/lazy/ZFVimIM'
            if isdirectory(altPath . '/misc')
                let pluginDir = altPath
            endif
        endif
    endif
    
    let cleanupScript = pluginDir . '/misc/dbCleanup.py'
    if filereadable(cleanupScript)
        " Get current database
        if g:ZFVimIM_dbIndex < len(g:ZFVimIM_db)
            let db = g:ZFVimIM_db[g:ZFVimIM_dbIndex]
            
            " Get dictionary file path
            let dictPath = ''
            if has_key(db, 'implData') && has_key(db['implData'], 'dictPath')
                let dictPath = db['implData']['dictPath']
                " Cleanup script only works with .yaml files
                if dictPath =~ '\.db$'
                    let dictPath = s:ZFVimIM_getYamlPath(dictPath)
                endif
            else
                " Try to get from autoLoadDict logic
                let dictDir = pluginDir . '/dict'
                if exists('g:zfvimim_default_dict_name') && !empty(g:zfvimim_default_dict_name)
                    let defaultDictName = g:zfvimim_default_dict_name
                    if defaultDictName !~ '\.yaml$'
                        let defaultDictName = defaultDictName . '.yaml'
                    endif
                    let dictPath = dictDir . '/' . defaultDictName
                elseif exists('g:zfvimim_dict_path') && !empty(g:zfvimim_dict_path)
                    let dictPath = expand(g:zfvimim_dict_path)
                    if dictPath =~ '\.db$'
                        let dictPath = s:ZFVimIM_getYamlPath(dictPath)
                    endif
                else
                    let dictPath = dictDir . '/default.yaml'
                endif
            endif
            
            if !empty(dictPath) && filereadable(dictPath)
                let pythonCmd = executable('python3') ? 'python3' : 'python'
                let cachePath = ZFVimIM_cachePath()
                
                try
                    let scriptPathAbs = CygpathFix_absPath(cleanupScript)
                    let dictPathAbs = CygpathFix_absPath(dictPath)
                    let cachePathAbs = CygpathFix_absPath(cachePath)
                    
                    echom '[ZFVimIM] 步骤 1/3: 清理字典文件...'
                    let cmdList = [pythonCmd, scriptPathAbs, dictPathAbs, cachePathAbs]
                    let result = system(join(cmdList, ' '))
                    if v:shell_error == 0
                        echom '[ZFVimIM] 字典文件清理完成'
                    else
                        echom '[ZFVimIM] 警告: 字典清理失败: ' . result
                    endif
                catch /.*/
                    echom '[ZFVimIM] 警告: 字典清理出错: ' . v:exception
                endtry
            endif
        endif
    else
        echom '[ZFVimIM] 跳过字典清理（清理脚本不存在）'
    endif
    
    " Step 2: Clear cache and reload dictionaries
    echom '[ZFVimIM] 步骤 2/3: 清除缓存文件...'
    call ZFVimIM_cacheClearAll()
    
    echom '[ZFVimIM] 步骤 3/3: 重新加载字典...'
    call ZFVimIM_cacheUpdate()
    
    echom '[ZFVimIM] 刷新完成！'
endfunction

" ============================================================
" Commands - All commands use IM prefix for consistency
" ============================================================

" Cache management - combines cleanup + clear + reload
command! -nargs=0 IMClear call ZFVimIM_refreshAll()

" Show dictionary information
command! -nargs=0 IMInfo call ZFVimIM_showInfo()

" Sync YAML file to database (only add new entries, don't delete)
command! -nargs=0 IMSync call ZFVimIM_syncTxtToDb()

" Initialize database from YAML file (force overwrite DB with YAML content)
command! -nargs=0 IMInit call ZFVimIM_importTxtToDb('')

" Backup: export DB to YAML (overwrite YAML with DB content)
command! -nargs=0 IMBackup call ZFVimIM_exportDbToTxt()

" Edit dictionary (open in new tab, edit and save to import)
command! -nargs=0 IMEdit call ZFVimIM_editDict()

" ============================================================
" Legacy commands removed - use IM* commands instead
" ============================================================

function! ZFVimIM_importTxtToDb(...)
    " Check if Python is available
    if !executable('python') && !executable('python3')
        echom '[ZFVimIM] Error: Python not found, cannot import TXT file'
        return
    endif
    
    " Get YAML file path (use argument if provided, otherwise use default)
    let yamlPath = ''
    let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
    let sfileDir = expand('<sfile>:p:h:h')
    if isdirectory(sfileDir . '/dict')
        let pluginDir = sfileDir
    endif
    let dictDir = pluginDir . '/dict'
    
    " If path argument provided, use it
    if a:0 > 0 && !empty(a:1)
        let yamlPath = expand(a:1)
        " Check if file exists
        if !filereadable(yamlPath)
            echom '[ZFVimIM] 错误: 指定的 YAML 文件不存在: ' . yamlPath
            return
        endif
    else
        " Use default logic
        if exists('g:zfvimim_default_dict_name') && !empty(g:zfvimim_default_dict_name)
            let defaultDictName = g:zfvimim_default_dict_name
            if defaultDictName !~ '\.yaml$'
                let defaultDictName = defaultDictName . '.yaml'
            endif
            let yamlPath = dictDir . '/' . defaultDictName
        elseif exists('g:zfvimim_dict_path') && !empty(g:zfvimim_dict_path)
            let yamlPath = expand(g:zfvimim_dict_path)
        else
            let yamlPath = dictDir . '/default.yaml'
        endif
    endif
    
    " Skip if TXT file doesn't exist
    if empty(yamlPath) || !filereadable(yamlPath)
        echom '[ZFVimIM] Error: YAML dictionary file not found: ' . yamlPath
        return
    endif
    
    " Get database file path (.db file)
    let dbPath = s:ZFVimIM_getDbPath(yamlPath)
    
    " Get script path
    let scriptPath = pluginDir . '/misc/import_txt_to_db.py'
    if !filereadable(scriptPath)
        echom '[ZFVimIM] Error: Import script not found: ' . scriptPath
        return
    endif
    
    " Determine Python command
    let pythonCmd = executable('python3') ? 'python3' : 'python'
    
    " Confirm before clearing database
    echom '[ZFVimIM] 警告: 此操作将清空数据库并重新导入！'
    echom '[ZFVimIM] YAML 文件: ' . yamlPath
    echom '[ZFVimIM] 数据库文件: ' . dbPath
    echom '[ZFVimIM] 正在执行导入...'
    
    " Run import script
    try
        let scriptPathAbs = CygpathFix_absPath(scriptPath)
        let yamlPathAbs = CygpathFix_absPath(yamlPath)
        let dbPathAbs = CygpathFix_absPath(dbPath)
        
        let cmdList = [pythonCmd, scriptPathAbs, yamlPathAbs, dbPathAbs]
        let result = system(join(cmdList, ' '))
        
        " Display result
        let lines = split(result, '\n')
        for line in lines
            if !empty(line)
                echom line
            endif
        endfor
        
        if v:shell_error == 0
            echom '[ZFVimIM] 导入完成！'
            " Optionally reload the database
            if exists('g:ZFVimIM_db') && len(g:ZFVimIM_db) > 0
                let db = g:ZFVimIM_db[g:ZFVimIM_dbIndex]
                if has_key(db, 'implData') && has_key(db['implData'], 'dictPath')
                    let dbPath = db['implData']['dictPath']
                    " Convert .yaml to .db if needed
                    if dbPath =~ '\.yaml$'
                        let dbPath = s:ZFVimIM_getDbPath(dbPath)
                    endif
                    if filereadable(dbPath)
                        echom '[ZFVimIM] 重新加载数据库...'
                        call ZFVimIM_dbLoad(db, dbPath)
                        echom '[ZFVimIM] 数据库已重新加载'
                    endif
                endif
            endif
        else
            echom '[ZFVimIM] 导入失败，请检查错误信息'
        endif
    catch /.*/
        echom '[ZFVimIM] Error: 导入过程出错: ' . v:exception
    endtry
endfunction

function! ZFVimIM_exportDbToTxt()
    " Check if Python is available
    if !executable('python') && !executable('python3')
        echom '[ZFVimIM] Error: Python not found, cannot backup dictionary'
        return
    endif
    
    " Get database file path
    let dbPath = ''
    let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
    let sfileDir = expand('<sfile>:p:h:h')
    if isdirectory(sfileDir . '/dict')
        let pluginDir = sfileDir
    endif
    let dictDir = pluginDir . '/dict'
    
    " Determine database file path
    if exists('g:zfvimim_default_dict_name') && !empty(g:zfvimim_default_dict_name)
        let defaultDictName = g:zfvimim_default_dict_name
        " Get YAML path first
        if defaultDictName !~ '\.yaml$'
            let defaultDictName = defaultDictName . '.yaml'
        endif
        let yamlPath = dictDir . '/' . defaultDictName
        let dbPath = s:ZFVimIM_getDbPath(yamlPath)
    elseif exists('g:zfvimim_dict_path') && !empty(g:zfvimim_dict_path)
        let dictPath = expand(g:zfvimim_dict_path)
        " Convert .yaml to .db
        if dictPath =~ '\.yaml$'
            let dbPath = s:ZFVimIM_getDbPath(dictPath)
        elseif dictPath =~ '\.db$'
            let dbPath = dictPath
        else
            " Assume it's a YAML file without extension
            let dbPath = s:ZFVimIM_getDbPath(dictPath . '.yaml')
        endif
    else
        let yamlPath = dictDir . '/default.yaml'
        let dbPath = s:ZFVimIM_getDbPath(yamlPath)
    endif
    
    " Skip if database file doesn't exist
    if empty(dbPath) || !filereadable(dbPath)
        echom '[ZFVimIM] Error: Database file not found: ' . dbPath
        return
    endif
    
    " Get YAML file path from database path
    let yamlPath = s:ZFVimIM_getYamlPath(dbPath)
    
    " Get script path
    let scriptPath = pluginDir . '/misc/db_export_to_txt.py'
    if !filereadable(scriptPath)
        echom '[ZFVimIM] Error: 备份脚本未找到: ' . scriptPath
        return
    endif
    
    " Determine Python command
    let pythonCmd = executable('python3') ? 'python3' : 'python'
    
    " Run export script
    try
        let scriptPathAbs = CygpathFix_absPath(scriptPath)
        let dbPathAbs = CygpathFix_absPath(dbPath)
        let yamlPathAbs = CygpathFix_absPath(yamlPath)
        
        echom '[ZFVimIM] 开始备份（从数据库导出到 YAML）...'
        echom '[ZFVimIM] 数据库: ' . dbPathAbs
        echom '[ZFVimIM] YAML 文件: ' . yamlPathAbs
        
        let cmdList = [pythonCmd, scriptPathAbs, dbPathAbs, yamlPathAbs]
        let result = system(join(cmdList, ' '))
        
        " Display result
        let lines = split(result, '\n')
        for line in lines
            if !empty(line)
                echom line
            endif
        endfor
        
        if v:shell_error == 0
            echom '[ZFVimIM] ✅ 备份完成！'
        else
            echom '[ZFVimIM] ❌ 备份失败，请检查错误信息'
        endif
    catch /.*/
        echom '[ZFVimIM] Error: 备份过程出错: ' . v:exception
    endtry
endfunction

function! ZFVimIM_syncTxtToDb()
    " Check if Python is available
    if !executable('python') && !executable('python3')
        echom 'ZFVimIM: Python not found, cannot sync dictionary'
        return
    endif
    
    " Get dictionary file path (TXT file)
    let yamlPath = ''
    let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
    let sfileDir = expand('<sfile>:p:h:h')
    if isdirectory(sfileDir . '/dict')
        let pluginDir = sfileDir
    endif
    let dictDir = pluginDir . '/dict'
    
    " Determine TXT file path
    if exists('g:zfvimim_default_dict_name') && !empty(g:zfvimim_default_dict_name)
        let defaultDictName = g:zfvimim_default_dict_name
        if defaultDictName !~ '\.yaml$'
            let defaultDictName = defaultDictName . '.yaml'
        endif
        let yamlPath = dictDir . '/' . defaultDictName
    elseif exists('g:zfvimim_dict_path') && !empty(g:zfvimim_dict_path)
        let yamlPath = expand(g:zfvimim_dict_path)
    else
        let yamlPath = dictDir . '/default.yaml'
    endif
    
    " Skip if TXT file doesn't exist
    if empty(yamlPath) || !filereadable(yamlPath)
        echom 'ZFVimIM: YAML dictionary file not found: ' . yamlPath
        return
    endif
    
    " Get script path
    let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
    let sfileDir = expand('<sfile>:p:h:h')
    if isdirectory(sfileDir . '/dict') && isdirectory(sfileDir . '/misc')
        let pluginDir = sfileDir
    else
        if !isdirectory(pluginDir . '/misc')
            let altPath = stdpath('config') . '/lazy/ZFVimIM'
            if isdirectory(altPath . '/misc')
                let pluginDir = altPath
            endif
        endif
    endif
    
    let scriptPath = pluginDir . '/misc/sync_txt_to_db.py'
    if !filereadable(scriptPath)
        echom 'ZFVimIM: Sync script not found: ' . scriptPath
        return
    endif
    
    " Determine database file path (.db)
    let dbPath = s:ZFVimIM_getDbPath(yamlPath)
    
    " Determine Python command
    let pythonCmd = executable('python3') ? 'python3' : 'python'
    
    " Run sync script synchronously
    try
        let scriptPathAbs = CygpathFix_absPath(scriptPath)
        let yamlPathAbs = CygpathFix_absPath(yamlPath)
        let dbPathAbs = CygpathFix_absPath(dbPath)
        
        echom 'ZFVimIM: Syncing TXT to database...'
        echom '  TXT: ' . yamlPathAbs
        echom '  DB:  ' . dbPathAbs
        
        let cmdList = [pythonCmd, scriptPathAbs, yamlPathAbs, dbPathAbs]
        let result = system(join(cmdList, ' '))
        
        " Show result
        let lines = split(result, '\n')
        for line in lines
            if !empty(line)
                echom line
            endif
        endfor
        
        if v:shell_error == 0
            echom 'ZFVimIM: Sync completed successfully'
            " Optionally reload the database
            if exists('g:ZFVimIM_db') && len(g:ZFVimIM_db) > 0
                let db = g:ZFVimIM_db[g:ZFVimIM_dbIndex]
                if has_key(db, 'implData') && has_key(db['implData'], 'dictPath')
                    let dbPath = db['implData']['dictPath']
                    " Convert .yaml to .db if needed
                    if dbPath =~ '\.yaml$'
                        let dbPath = s:ZFVimIM_getDbPath(dbPath)
                    endif
                    if filereadable(dbPath)
                        echom 'ZFVimIM: Reloading database...'
                        call ZFVimIM_dbLoad(db, dbPath)
                        echom 'ZFVimIM: Database reloaded'
                    endif
                endif
            endif
        else
            echom 'ZFVimIM: Sync failed'
        endif
    catch /.*/
        echom 'ZFVimIM: Error running sync: ' . v:exception
    endtry
endfunction

function! ZFVimIM_showInfo()
    echo "=========================================="
    echo "ZFVimIM 词库信息"
    echo "=========================================="
    
    " Try to initialize if not already done
    if !exists('s:dbInitFlag') || !s:dbInitFlag
        echo "正在初始化词库..."
        call ZFVimIME_init()
    endif
    
    " Check if database is initialized
    if !exists('g:ZFVimIM_db') || empty(g:ZFVimIM_db)
        echo "❌ 未加载任何词库"
        echo ""
        echo "配置信息:"
        if exists('g:zfvimim_dict_path') && !empty(g:zfvimim_dict_path)
            echo "  zfvimim_dict_path: " . g:zfvimim_dict_path
            if filereadable(g:zfvimim_dict_path)
                let mtime = getftime(g:zfvimim_dict_path)
                if mtime > 0
                    echo "    文件存在，最后修改: " . strftime('%Y-%m-%d %H:%M:%S', mtime)
                    let fileSize = getfsize(g:zfvimim_dict_path)
                    if fileSize > 0
                        if fileSize < 1024
                            echo "    文件大小: " . fileSize . " B"
                        elseif fileSize < 1024 * 1024
                            echo "    文件大小: " . (fileSize / 1024.0) . " KB"
                        else
                            echo "    文件大小: " . (fileSize / (1024.0 * 1024.0)) . " MB"
                        endif
                    endif
                else
                    echo "    文件存在"
                endif
            else
                echo "    ⚠️  文件不存在"
            endif
        endif
        if exists('g:zfvimim_default_dict_name') && !empty(g:zfvimim_default_dict_name)
            echo "  zfvimim_default_dict_name: " . g:zfvimim_default_dict_name
            " Try to find the dictionary file
            let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
            let sfileDir = expand('<sfile>:p:h:h')
            if isdirectory(sfileDir . '/dict')
                let pluginDir = sfileDir
            endif
            let dictDir = pluginDir . '/dict'
            let defaultDictName = g:zfvimim_default_dict_name
            if defaultDictName !~ '\.yaml$'
                let defaultDictName = defaultDictName . '.yaml'
            endif
            let defaultDict = dictDir . '/' . defaultDictName
            if filereadable(defaultDict)
                echo "    默认词库文件: " . defaultDict
                let mtime = getftime(defaultDict)
                if mtime > 0
                    echo "      最后修改: " . strftime('%Y-%m-%d %H:%M:%S', mtime)
                endif
            else
                echo "    ⚠️  默认词库文件不存在: " . defaultDict
            endif
        endif
        echo ""
        echo "提示: 如果词库应该已加载，请尝试:"
        echo "  1. 运行 :ZFVimIMReload 重新加载插件"
        echo "  2. 检查词库文件路径是否正确"
        echo "  3. 检查词库文件格式是否正确"
        return
    endif
    
    " Show current database index
    let currentIndex = get(g:, 'ZFVimIM_dbIndex', 0)
    let totalDbs = len(g:ZFVimIM_db)
    echo "当前词库索引: " . (currentIndex + 1) . " / " . totalDbs
    echo ""
    
    " Show each database
    let idx = 0
    for db in g:ZFVimIM_db
        let isCurrent = (idx == currentIndex)
        let marker = isCurrent ? "👉 " : "   "
        
        echo marker . "词库 #" . (idx + 1) . ": " . get(db, 'name', '(未命名)')
        
        " Show dictionary path (actual DB file being used)
        let dictPath = ''
        if has_key(db, 'implData') && has_key(db['implData'], 'dictPath')
            let dictPath = db['implData']['dictPath']
        endif
        
        " If path is TXT, convert to DB (show actual file being used)
        if !empty(dictPath) && dictPath =~ '\.yaml$'
            let dictPath = s:ZFVimIM_getDbPath(dictPath)
        endif
        
        if !empty(dictPath)
            echo "    路径: " . dictPath . " (SQLite数据库)"
            " Also show TXT path if available
            if has_key(db, 'implData') && has_key(db['implData'], 'yamlPath')
                let yamlPath = db['implData']['yamlPath']
                if !empty(yamlPath) && yamlPath =~ '\.yaml$'
                    echo "    TXT源文件: " . yamlPath
                endif
            endif
            if filereadable(dictPath)
                let mtime = getftime(dictPath)
                if mtime > 0
                    echo "    最后修改: " . strftime('%Y-%m-%d %H:%M:%S', mtime)
                endif
                let fileSize = getfsize(dictPath)
                if fileSize > 0
                    if fileSize < 1024
                        echo "    文件大小: " . fileSize . " B"
                    elseif fileSize < 1024 * 1024
                        echo "    文件大小: " . (fileSize / 1024.0) . " KB"
                    else
                        echo "    文件大小: " . (fileSize / (1024.0 * 1024.0)) . " MB"
                    endif
                endif
            else
                echo "    ⚠️  文件不存在"
            endif
        else
            echo "    路径: (未设置)"
        endif
        
        " Count entries in database
        let entryCount = 0
        if has_key(db, 'dbMap')
            for c in keys(db['dbMap'])
                let entryCount += len(db['dbMap'][c])
            endfor
        endif
        echo "    条目数量: " . entryCount
        
        " Show priority
        if has_key(db, 'priority')
            echo "    优先级: " . db['priority']
        endif
        
        " Show other info
        if has_key(db, 'dbId')
            echo "    数据库ID: " . db['dbId']
        endif
        
        echo ""
        let idx += 1
    endfor
    
    " Show configuration
    echo "配置信息:"
    if exists('g:zfvimim_dict_path') && !empty(g:zfvimim_dict_path)
        echo "  zfvimim_dict_path: " . g:zfvimim_dict_path
    endif
    if exists('g:zfvimim_default_dict_name') && !empty(g:zfvimim_default_dict_name)
        echo "  zfvimim_default_dict_name: " . g:zfvimim_default_dict_name
    endif
    if exists('g:ZFVimIM_matchLimit')
        echo "  ZFVimIM_matchLimit: " . g:ZFVimIM_matchLimit
    endif
    if exists('g:ZFVimIM_predictLimit')
        echo "  ZFVimIM_predictLimit: " . g:ZFVimIM_predictLimit
    endif
    if exists('g:ZFVimIM_crossDbLimit')
        echo "  ZFVimIM_crossDbLimit: " . g:ZFVimIM_crossDbLimit
    endif
    
    echo "=========================================="
    
    " 整理词库：去重、格式化、去掉不规范条目
    echo ""
    echo "=========================================="
    echo "正在整理词库..."
    echo "=========================================="
    
    " Check if Python is available
    if !executable('python') && !executable('python3')
        echo "❌ Python 未找到，无法整理词库"
        return
    endif
    
    " Get current dictionary YAML path
    let yamlPath = ''
    if exists('g:ZFVimIM_db') && len(g:ZFVimIM_db) > 0
        let db = g:ZFVimIM_db[g:ZFVimIM_dbIndex]
        if has_key(db, 'implData') && has_key(db['implData'], 'yamlPath')
            let yamlPath = db['implData']['yamlPath']
        endif
    endif
    
    " Fallback: try to get from default dict name
    if empty(yamlPath)
        let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
        let sfileDir = expand('<sfile>:p:h:h')
        if isdirectory(sfileDir . '/dict')
            let pluginDir = sfileDir
        endif
        let dictDir = pluginDir . '/dict'
        
        if exists('g:zfvimim_default_dict_name') && !empty(g:zfvimim_default_dict_name)
            let defaultDictName = g:zfvimim_default_dict_name
            if defaultDictName !~ '\.yaml$'
                let defaultDictName = defaultDictName . '.yaml'
            endif
            
            " First, try to find in module directory
            if exists('*ZFVimIM_getModuleDictPath')
                let dictNameNoExt = substitute(defaultDictName, '\.yaml$', '', '')
                let moduleDictPath = ZFVimIM_getModuleDictPath(dictNameNoExt, dictNameNoExt)
                if !empty(moduleDictPath) && filereadable(moduleDictPath)
                    let yamlPath = moduleDictPath
                else
                    " Fallback to regular dict directory
                    let yamlPath = dictDir . '/' . defaultDictName
                endif
            else
                " Fallback to regular dict directory
                let yamlPath = dictDir . '/' . defaultDictName
            endif
        elseif exists('g:zfvimim_dict_path') && !empty(g:zfvimim_dict_path)
            let yamlPath = expand(g:zfvimim_dict_path)
        else
            let yamlPath = dictDir . '/default.yaml'
        endif
    endif
    
    if empty(yamlPath) || !filereadable(yamlPath)
        echo "❌ 未找到词库 YAML 文件: " . yamlPath
        return
    endif
    
    " Get script path
    let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
    let sfileDir = expand('<sfile>:p:h:h')
    if isdirectory(sfileDir . '/misc')
        let pluginDir = sfileDir
    endif
    let scriptPath = pluginDir . '/misc/clean_dict.py'
    
    if !filereadable(scriptPath)
        echo "❌ 整理脚本未找到: " . scriptPath
        return
    endif
    
    " Determine Python command
    let pythonCmd = executable('python3') ? 'python3' : 'python'
    
    " Run clean script
    try
        let scriptPathAbs = CygpathFix_absPath(scriptPath)
        let yamlPathAbs = CygpathFix_absPath(yamlPath)
        
        echo "YAML 文件: " . yamlPathAbs
        echo "正在执行整理..."
        
        let cmdList = [pythonCmd, scriptPathAbs, yamlPathAbs]
        let result = system(join(cmdList, ' '))
        
        " Display result
        let lines = split(result, '\n')
        for line in lines
            if !empty(line)
                echo line
            endif
        endfor
        
        if v:shell_error == 0
            echo ""
            echo "✅ 词库整理完成！"
            echo ""
            echo "提示: 整理后的词库已保存到 YAML 文件"
            echo "      如需更新数据库，请运行: :IMInit"
        else
            echo ""
            echo "❌ 词库整理失败，请检查错误信息"
        endif
    catch /.*/
        echo "❌ 整理过程出错: " . v:exception
    endtry
    
endfunction

" ============================================================
" Batch add words function
" ============================================================
function! ZFVimIM_batchAddWords(...)
    " Get current dictionary path
    let dictPath = ''
    let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
    let sfileDir = expand('<sfile>:p:h:h')
    if isdirectory(sfileDir . '/dict')
        let pluginDir = sfileDir
    endif
    let dictDir = pluginDir . '/dict'
    
    " Determine dictionary path
    if exists('g:zfvimim_default_dict_name') && !empty(g:zfvimim_default_dict_name)
        let defaultDictName = g:zfvimim_default_dict_name
        if defaultDictName !~ '\.yaml$'
            let defaultDictName = defaultDictName . '.yaml'
        endif
        let dictPath = dictDir . '/' . defaultDictName
    elseif exists('g:zfvimim_dict_path') && !empty(g:zfvimim_dict_path)
        let dictPath = expand(g:zfvimim_dict_path)
    else
        let dictPath = dictDir . '/default.yaml'
    endif
    
    " Check if dictionary file exists
    if !filereadable(dictPath)
        echom '[ZFVimIM] 错误: 词库文件不存在: ' . dictPath
        return
    endif
    
    " Store dictionary path in buffer variable
    let b:zfvimim_dict_path = dictPath
    
    " Create a new tab for batch input
    tabnew
    setlocal buftype=acwrite
    setlocal bufhidden=wipe
    setlocal noswapfile
    setlocal filetype=zfvimim_batch
    setlocal syntax=zfvimim_batch
    
    " Set buffer name
    let bufname = '[ZFVimIM 批量添加] ' . fnamemodify(dictPath, ':t')
    silent! execute 'file ' . escape(bufname, ' ')
    
    " Add instructions
    call setline(1, '# ZFVimIM 批量添加编码')
    call setline(2, '# 格式: 编码<Tab>词组')
    call setline(3, '# 例如:')
    call setline(4, '# xnzg	新增')
    call setline(5, '# wxsh	我想说话')
    call setline(6, '#')
    call setline(7, '# 每次使用 :w 保存时会实时写入数据库并重新加载输入法')
    call setline(8, '# 使用 :q 关闭此标签页')
    call setline(9, '')
    
    " If arguments provided, add them as initial content
    if a:0 >= 2
        let key = a:1
        let word = join(a:000[1:], ' ')
        call setline(10, key . "\t" . word)
        " Move cursor to the entry line
        normal! 10G
    else
        " Move cursor to end
        normal! G
    endif
    
    " Set up autocommand to handle save
    augroup ZFVimIM_batchAdd
        autocmd!
        autocmd BufWriteCmd <buffer> call s:ZFVimIM_processBatchAdd()
    augroup END
    
    " Set up key mapping for quick save
    nnoremap <buffer> <silent> <C-s> :w<CR>
    inoremap <buffer> <silent> <C-s> <Esc>:w<CR>
    
    echom '[ZFVimIM] 批量添加模式已在新标签页打开，每次 :w 保存时会实时写入数据库并重新加载输入法'
endfunction

function! s:ZFVimIM_processBatchAdd()
    let dictPath = get(b:, 'zfvimim_dict_path', '')
    
    " If buffer variable is lost, try to get from buffer name or use default
    if empty(dictPath)
        " Try to extract from buffer name
        let bufname = bufname('%')
        if bufname =~# '\[ZFVimIM 批量添加\]'
            let dictName = substitute(bufname, '.*\[ZFVimIM 批量添加\]\s*', '', '')
            if !empty(dictName)
                let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
                let sfileDir = expand('<sfile>:p:h:h')
                if isdirectory(sfileDir . '/dict')
                    let pluginDir = sfileDir
                endif
                let dictDir = pluginDir . '/dict'
                let dictPath = dictDir . '/' . dictName
            endif
        endif
        
        " If still empty, use default dictionary
        if empty(dictPath)
            let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
            let sfileDir = expand('<sfile>:p:h:h')
            if isdirectory(sfileDir . '/dict')
                let pluginDir = sfileDir
            endif
            let dictDir = pluginDir . '/dict'
            
            if exists('g:zfvimim_default_dict_name') && !empty(g:zfvimim_default_dict_name)
                let defaultDictName = g:zfvimim_default_dict_name
                if defaultDictName !~ '\.yaml$'
                    let defaultDictName = defaultDictName . '.yaml'
                endif
                let dictPath = dictDir . '/' . defaultDictName
            elseif exists('g:zfvimim_dict_path') && !empty(g:zfvimim_dict_path)
                let dictPath = expand(g:zfvimim_dict_path)
            else
                let dictPath = dictDir . '/default.yaml'
            endif
        endif
    endif
    
    if empty(dictPath)
        echom '[ZFVimIM] 错误: 无法获取词库路径'
        setlocal nomodified
        return
    endif
    
    " Get all lines from buffer
    let lines = getline(1, '$')
    let entries = []
    
    " Parse lines
    for line in lines
        let line = substitute(line, '^\s*', '', '')
        let line = substitute(line, '\s*$', '', '')
        
        " Skip empty lines and comments
        if empty(line) || line[0] ==# '#'
            continue
        endif
        
        " Parse format: encoding<Tab>word or encoding word
        let parts = split(line, '\t')
        if len(parts) < 2
            " Try space as separator
            let parts = split(line, ' ')
            if len(parts) < 2
                continue
            endif
        endif
        
        let encoding = parts[0]
        let word = join(parts[1:], ' ')
        
        " Validate encoding (should be lowercase letters)
        if encoding !~# '^[a-z]\+$'
            continue
        endif
        
        " Validate word (should contain Chinese characters)
        if word !~# '[\u4e00-\u9fff]'
            continue
        endif
        
        call add(entries, {'encoding': encoding, 'word': word})
    endfor
    
    if empty(entries)
        echom '[ZFVimIM] 没有有效的条目，取消保存'
        setlocal nomodified
        return
    endif
    
    " Get YAML file path
    let yamlPath = dictPath
    if yamlPath =~ '\.db$'
        let yamlPath = s:ZFVimIM_getYamlPath(yamlPath)
    endif
    
    if !filereadable(yamlPath)
        echom '[ZFVimIM] 错误: YAML 文件不存在: ' . yamlPath
        setlocal nomodified
        return
    endif
    
    " Read existing entries from YAML
    let existingEntries = {}
    let yamlLines = readfile(yamlPath)
    for line in yamlLines
        let line = substitute(line, '^\s*', '', '')
        let line = substitute(line, '\s*$', '', '')
        if empty(line) || line[0] ==# '#'
            continue
        endif
        let parts = split(line, '\t')
        if len(parts) >= 2
            let encoding = parts[0]
            if !has_key(existingEntries, encoding)
                let existingEntries[encoding] = []
            endif
            call extend(existingEntries[encoding], parts[1:])
        endif
    endfor
    
    " Merge new entries (only add new words, avoid duplicates)
    let newEntries = []
    for entry in entries
        if !has_key(existingEntries, entry['encoding'])
            let existingEntries[entry['encoding']] = []
        endif
        " Check if word already exists
        if index(existingEntries[entry['encoding']], entry['word']) < 0
            call add(existingEntries[entry['encoding']], entry['word'])
            call add(newEntries, entry)
        endif
    endfor
    
    " Write back to YAML file
    let output = []
    for encoding in sort(keys(existingEntries))
        let words = existingEntries[encoding]
        if !empty(words)
            call add(output, encoding . "\t" . join(words, "\t"))
        endif
    endfor
    
    call writefile(output, yamlPath)
    
    if !empty(newEntries)
        echom '[ZFVimIM] 已保存 ' . len(newEntries) . ' 个新条目到 YAML: ' . fnamemodify(yamlPath, ':t')
        
        " Get database file path
        let dbPath = s:ZFVimIM_getDbPath(yamlPath)
        
        " Get Python command
        let pythonCmd = executable('python3') ? 'python3' : 'python'
        if !executable(pythonCmd)
            echom '[ZFVimIM] 错误: Python 未找到，无法同步到数据库'
            setlocal nomodified
            return
        endif
        
        " Get script path
        let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
        let sfileDir = expand('<sfile>:p:h:h')
        if isdirectory(sfileDir . '/misc')
            let pluginDir = sfileDir
        endif
        let scriptPath = pluginDir . '/misc/db_add_word.py'
        if !filereadable(scriptPath)
            echom '[ZFVimIM] 错误: 脚本文件不存在: ' . scriptPath
            setlocal nomodified
            return
        endif
        
        " Insert new entries to database
        echom '[ZFVimIM] 正在同步 ' . len(newEntries) . ' 个新条目到数据库...'
        let addedCount = 0
        let failedCount = 0
        
        for entry in newEntries
            let cmd = pythonCmd . ' "' . scriptPath . '" "' . dbPath . '" "' . entry['encoding'] . '" "' . entry['word'] . '"'
            let result = system(cmd)
            let result = substitute(result, '[\r\n]', '', 'g')
            if result ==# 'OK' || result ==# 'EXISTS'
                let addedCount += 1
            else
                let failedCount += 1
            endif
        endfor
        
        echom '[ZFVimIM] ✅ 已同步 ' . addedCount . ' 个条目到数据库'
        if failedCount > 0
            echom '[ZFVimIM] ⚠️  ' . failedCount . ' 个条目同步失败'
        endif
        
        " Reload dictionary after saving
        let dictName = fnamemodify(dbPath, ':t:r')
        if exists('g:ZFVimIM_db')
            for db in g:ZFVimIM_db
                if get(db, 'name', '') ==# dictName
                    call ZFVimIM_dbSearchCacheClear(db)
                    call ZFVimIM_dbLoad(db, dbPath)
                    echom '[ZFVimIM] ✅ 输入法已重新加载'
                    break
                endif
            endfor
        endif
    else
        echom '[ZFVimIM] 所有条目已存在于 YAML 文件中'
    endif
    
    " Keep buffer open, just mark as not modified
    setlocal nomodified
endfunction

" Edit dictionary - open in new tab, edit and save to import
function! ZFVimIM_editDict()
    " Get current dictionary path
    let dictPath = ''
    let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
    let sfileDir = expand('<sfile>:p:h:h')
    if isdirectory(sfileDir . '/dict')
        let pluginDir = sfileDir
    endif
    let dictDir = pluginDir . '/dict'
    
    " Determine dictionary path
    if exists('g:zfvimim_default_dict_name') && !empty(g:zfvimim_default_dict_name)
        let defaultDictName = g:zfvimim_default_dict_name
        if defaultDictName !~ '\.yaml$'
            let defaultDictName = defaultDictName . '.yaml'
        endif
        let dictPath = dictDir . '/' . defaultDictName
    elseif exists('g:zfvimim_dict_path') && !empty(g:zfvimim_dict_path)
        let dictPath = expand(g:zfvimim_dict_path)
    else
        let dictPath = dictDir . '/default.yaml'
    endif
    
    " Get database file path
    let dbPath = s:ZFVimIM_getDbPath(dictPath)
    if !filereadable(dbPath)
        echom '[ZFVimIM] 错误: 数据库文件不存在: ' . dbPath
        echom '[ZFVimIM] 请先运行 :IMInit 初始化词库'
        return
    endif
    
    " Store paths in buffer variable
    let b:zfvimim_dict_path = dictPath
    let b:zfvimim_db_path = dbPath
    
    " Create a new tab for editing
    tabnew
    setlocal buftype=acwrite
    setlocal bufhidden=wipe
    setlocal noswapfile
    setlocal filetype=zfvimim_edit
    setlocal syntax=zfvimim_edit
    
    " Set buffer name
    let bufname = '[ZFVimIM 词库编辑] ' . fnamemodify(dictPath, ':t')
    silent! execute 'file ' . escape(bufname, ' ')
    
    " Add instructions
    call setline(1, '# ZFVimIM 词库编辑')
    call setline(2, '# 格式: 编码 候选词1 候选词2 ...')
    call setline(3, '# 例如:')
    call setline(4, '# nihao 你好 你号')
    call setline(5, '# ceshi 测试 测时')
    call setline(6, '#')
    call setline(7, '# 删除行即可删除该编码的所有词')
    call setline(8, '# 每次使用 :w 保存时会即时导入到词库并重新加载输入法')
    call setline(9, '# 使用 :q 关闭此标签页')
    call setline(10, '')
    
    " Export database to text format
    let pythonCmd = executable('python3') ? 'python3' : 'python'
    if !executable(pythonCmd)
        echom '[ZFVimIM] 错误: Python 未找到，无法导出词库'
        return
    endif
    
    " Get script path
    let scriptPath = pluginDir . '/misc/db_export_for_edit.py'
    if !filereadable(scriptPath)
        echom '[ZFVimIM] 错误: 脚本文件不存在: ' . scriptPath
        return
    endif
    
    " Execute Python script to export database
    let scriptPathAbs = CygpathFix_absPath(scriptPath)
    let dbPathAbs = CygpathFix_absPath(dbPath)
    let cmd = pythonCmd . ' "' . scriptPathAbs . '" "' . dbPathAbs . '"'
    let result = system(cmd)
    
    if v:shell_error != 0
        echom '[ZFVimIM] 错误: 导出词库失败'
        if !empty(result)
            echom '[ZFVimIM] 错误信息: ' . result
        endif
        return
    endif
    
    " Parse result and add to buffer
    let lines = split(result, '\n')
    let lineNum = 11
    for line in lines
        if !empty(line)
            call setline(lineNum, line)
            let lineNum += 1
        endif
    endfor
    
    " Set up autocommand to handle save
    augroup ZFVimIM_editDict
        autocmd!
        autocmd BufWriteCmd <buffer> call s:ZFVimIM_processEditDict()
    augroup END
    
    " Set up key mapping for quick save
    nnoremap <buffer> <silent> <C-s> :w<CR>
    inoremap <buffer> <silent> <C-s> <Esc>:w<CR>
    
    " Move cursor to first data line
    normal! 11G
    
    echom '[ZFVimIM] 词库编辑模式已在新标签页打开，每次 :w 保存时会即时导入到词库并重新加载输入法'
endfunction

function! s:ZFVimIM_processEditDict()
    let dictPath = get(b:, 'zfvimim_dict_path', '')
    let dbPath = get(b:, 'zfvimim_db_path', '')
    
    " If buffer variables are lost, try to get from buffer name
    if empty(dictPath) || empty(dbPath)
        let bufname = bufname('%')
        if bufname =~# '\[ZFVimIM 词库编辑\]'
            let dictName = substitute(bufname, '.*\[ZFVimIM 词库编辑\]\s*', '', '')
            if !empty(dictName)
                let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
                let sfileDir = expand('<sfile>:p:h:h')
                if isdirectory(sfileDir . '/dict')
                    let pluginDir = sfileDir
                endif
                let dictDir = pluginDir . '/dict'
                let dictPath = dictDir . '/' . dictName
                let dbPath = s:ZFVimIM_getDbPath(dictPath)
            endif
        endif
        
        " If still empty, use default dictionary
        if empty(dictPath)
            let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
            let sfileDir = expand('<sfile>:p:h:h')
            if isdirectory(sfileDir . '/dict')
                let pluginDir = sfileDir
            endif
            let dictDir = pluginDir . '/dict'
            
            if exists('g:zfvimim_default_dict_name') && !empty(g:zfvimim_default_dict_name)
                let defaultDictName = g:zfvimim_default_dict_name
                if defaultDictName !~ '\.yaml$'
                    let defaultDictName = defaultDictName . '.yaml'
                endif
                let dictPath = dictDir . '/' . defaultDictName
            elseif exists('g:zfvimim_dict_path') && !empty(g:zfvimim_dict_path)
                let dictPath = expand(g:zfvimim_dict_path)
            else
                let dictPath = dictDir . '/default.yaml'
            endif
            let dbPath = s:ZFVimIM_getDbPath(dictPath)
        endif
    endif
    
    if empty(dictPath) || empty(dbPath)
        echom '[ZFVimIM] 错误: 无法获取词库路径'
        setlocal nomodified
        return
    endif
    
    " Get all lines from buffer (skip instructions)
    let lines = getline(11, '$')
    let entries = []
    
    " Parse lines
    for line in lines
        let line = substitute(line, '^\s*', '', '')
        let line = substitute(line, '\s*$', '', '')
        
        " Skip empty lines and comments
        if empty(line) || line[0] ==# '#'
            continue
        endif
        
        " Parse format: encoding word1 word2 ... (space separated)
        " Handle escaped spaces: replace \  with placeholder first
        let lineTmp = substitute(line, '\\ ', '_ZFVimIM_space_', 'g')
        let parts = split(lineTmp, ' ')
        if len(parts) < 2
            continue
        endif
        
        " Restore spaces in words
        let words = []
        for i in range(1, len(parts) - 1)
            call add(words, substitute(parts[i], '_ZFVimIM_space_', ' ', 'g'))
        endfor
        call add(words, substitute(parts[len(parts) - 1], '_ZFVimIM_space_', ' ', 'g'))
        
        let encoding = substitute(parts[0], '_ZFVimIM_space_', ' ', 'g')
        
        " Validate encoding (should be lowercase letters)
        if encoding !~# '^[a-z]\+$'
            continue
        endif
        
        " Validate words (should contain Chinese characters)
        let validWords = []
        for word in words
            if word =~# '[\u4e00-\u9fff]'
                call add(validWords, word)
            endif
        endfor
        
        if !empty(validWords)
            call add(entries, {'encoding': encoding, 'words': validWords})
        endif
    endfor
    
    if empty(entries)
        echom '[ZFVimIM] 没有有效的条目，取消保存'
        setlocal nomodified
        return
    endif
    
    " Write to temporary YAML file
    let yamlPath = dictPath
    let tmpYamlPath = yamlPath . '.tmp'
    
    let output = []
    for entry in entries
        " Escape spaces in words
        let escapedWords = []
        for word in entry['words']
            call add(escapedWords, substitute(word, ' ', '\\ ', 'g'))
        endfor
        call add(output, entry['encoding'] . ' ' . join(escapedWords, ' '))
    endfor
    
    call writefile(output, tmpYamlPath)
    
    echom '[ZFVimIM] 已保存 ' . len(entries) . ' 个条目到临时文件'
    
    " Import to database using import script
    let pythonCmd = executable('python3') ? 'python3' : 'python'
    if !executable(pythonCmd)
        echom '[ZFVimIM] 错误: Python 未找到，无法导入到数据库'
        setlocal nomodified
        return
    endif
    
    " Get script path
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
    let scriptPath = pluginDir . '/misc/import_txt_to_db.py'
    if !filereadable(scriptPath)
        echom '[ZFVimIM] 错误: 脚本文件不存在: ' . scriptPath
        setlocal nomodified
        return
    endif
    
    " Execute import script
    let scriptPathAbs = CygpathFix_absPath(scriptPath)
    let tmpYamlPathAbs = CygpathFix_absPath(tmpYamlPath)
    let dbPathAbs = CygpathFix_absPath(dbPath)
    let cmd = pythonCmd . ' "' . scriptPathAbs . '" "' . tmpYamlPathAbs . '" "' . dbPathAbs . '"'
    let result = system(cmd)
    
    " Clean up temporary file
    if filereadable(tmpYamlPath)
        call delete(tmpYamlPath)
    endif
    
    if v:shell_error == 0
        echom '[ZFVimIM] ✅ 已导入 ' . len(entries) . ' 个条目到数据库'
        
        " Reload dictionary
        let dictName = fnamemodify(dbPath, ':t:r')
        if exists('g:ZFVimIM_db')
            for db in g:ZFVimIM_db
                if get(db, 'name', '') ==# dictName
                    call ZFVimIM_dbSearchCacheClear(db)
                    call ZFVimIM_dbLoad(db, dbPath)
                    echom '[ZFVimIM] ✅ 输入法已重新加载'
                    break
                endif
            endfor
        endif
    else
        echom '[ZFVimIM] ❌ 导入失败'
        if !empty(result)
            echom '[ZFVimIM] 错误信息: ' . result
        endif
        setlocal nomodified
        return
    endif
    
    " Keep buffer open, just mark as not modified
    setlocal nomodified
endfunction

" Backup dictionary - export YAML and DB to specified directory or dict/ directory
function! ZFVimIM_backupDict(...)
    " Check if Python is available
    if !executable('python') && !executable('python3')
        echom '[ZFVimIM] 错误: Python 未找到，无法备份词库'
        return
    endif
    
    " Get backup directory (use argument if provided, otherwise use default)
    let backupDir = ''
    if a:0 > 0 && !empty(a:1)
        " User specified a path
        let backupDir = expand(a:1)
        " Ensure it's a directory
        if !isdirectory(backupDir)
            " Try to create it
            call mkdir(backupDir, 'p')
            if !isdirectory(backupDir)
                echom '[ZFVimIM] 错误: 无法创建备份目录: ' . backupDir
                return
            endif
        endif
    else
        " Use default dict directory
        let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
        let sfileDir = expand('<sfile>:p:h:h')
        if isdirectory(sfileDir . '/dict')
            let pluginDir = sfileDir
        endif
        let backupDir = pluginDir . '/dict'
    endif
    
    " Get database file path
    let dbPath = ''
    let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
    let sfileDir = expand('<sfile>:p:h:h')
    if isdirectory(sfileDir . '/dict')
        let pluginDir = sfileDir
    endif
    let dictDir = pluginDir . '/dict'
    
    " Determine database file path
    if exists('g:zfvimim_default_dict_name') && !empty(g:zfvimim_default_dict_name)
        let defaultDictName = g:zfvimim_default_dict_name
        " Get YAML path first
        if defaultDictName !~ '\.yaml$'
            let defaultDictName = defaultDictName . '.yaml'
        endif
        let yamlPath = dictDir . '/' . defaultDictName
        let dbPath = s:ZFVimIM_getDbPath(yamlPath)
    elseif exists('g:zfvimim_dict_path') && !empty(g:zfvimim_dict_path)
        let dictPath = expand(g:zfvimim_dict_path)
        " Convert .yaml to .db
        if dictPath =~ '\.yaml$'
            let dbPath = s:ZFVimIM_getDbPath(dictPath)
        elseif dictPath =~ '\.db$'
            let dbPath = dictPath
        else
            " Assume it's a YAML file without extension
            let dbPath = s:ZFVimIM_getDbPath(dictPath . '.yaml')
        endif
    else
        let yamlPath = dictDir . '/default.yaml'
        let dbPath = s:ZFVimIM_getDbPath(yamlPath)
    endif
    
    " Check if database file exists
    if empty(dbPath) || !filereadable(dbPath)
        echom '[ZFVimIM] 错误: 数据库文件不存在: ' . dbPath
        echom '[ZFVimIM] 请先运行 :IMInit 初始化词库'
        return
    endif
    
    " Get base name for backup files
    let dbName = fnamemodify(dbPath, ':t:r')
    
    " Generate timestamp for backup filename
    " Format: YYYYMMDD_HHMMSS
    let timestamp = strftime('%Y%m%d_%H%M%S')
    
    " Create backup filenames
    let backupYamlName = dbName . '_backup_' . timestamp . '.yaml'
    let backupDbName = dbName . '_backup_' . timestamp . '.db'
    let backupYamlPath = backupDir . '/' . backupYamlName
    let backupDbPath = backupDir . '/' . backupDbName
    
    " Get script path for export
    let scriptPath = pluginDir . '/misc/db_export_to_txt.py'
    if !filereadable(scriptPath)
        echom '[ZFVimIM] 错误: 导出脚本未找到: ' . scriptPath
        return
    endif
    
    " Determine Python command
    let pythonCmd = executable('python3') ? 'python3' : 'python'
    
    " Step 1: Copy DB file to backup location
    try
        echom '[ZFVimIM] 开始备份词库...'
        echom '[ZFVimIM] 数据库: ' . dbPath
        echom '[ZFVimIM] 备份目录: ' . backupDir
        
        " Copy DB file
        let dbPathAbs = CygpathFix_absPath(dbPath)
        let backupDbPathAbs = CygpathFix_absPath(backupDbPath)
        
        " Use system copy command
        if has('win32') || has('win64')
            let copyCmd = 'copy /Y "' . dbPathAbs . '" "' . backupDbPathAbs . '"'
        else
            let copyCmd = 'cp "' . dbPathAbs . '" "' . backupDbPathAbs . '"'
        endif
        
        let copyResult = system(copyCmd)
        if v:shell_error != 0
            echom '[ZFVimIM] ❌ 复制数据库文件失败'
            if !empty(copyResult)
                echom '[ZFVimIM] 错误信息: ' . copyResult
            endif
            return
        endif
        
        echom '[ZFVimIM] ✅ 数据库文件已备份: ' . backupDbName
        
        " Step 2: Export DB to YAML
        let scriptPathAbs = CygpathFix_absPath(scriptPath)
        let backupYamlPathAbs = CygpathFix_absPath(backupYamlPath)
        
        echom '[ZFVimIM] 正在导出 YAML 文件...'
        
        let cmdList = [pythonCmd, scriptPathAbs, backupDbPathAbs, backupYamlPathAbs]
        let result = system(join(cmdList, ' '))
        
        " Display result
        let lines = split(result, '\n')
        for line in lines
            if !empty(line)
                echom line
            endif
        endfor
        
        if v:shell_error == 0
            echom '[ZFVimIM] ✅ YAML 文件已备份: ' . backupYamlName
            echom '[ZFVimIM] ✅ 备份完成！'
            echom '[ZFVimIM] 备份位置: ' . backupDir
            echom '[ZFVimIM]   - DB: ' . backupDbName
            echom '[ZFVimIM]   - YAML: ' . backupYamlName
        else
            echom '[ZFVimIM] ❌ YAML 文件导出失败'
            " Remove DB backup if YAML export failed
            if filereadable(backupDbPath)
                call delete(backupDbPath)
            endif
        endif
    catch /.*/
        echom '[ZFVimIM] Error: 备份过程出错: ' . v:exception
        " Clean up on error
        if filereadable(backupDbPath)
            call delete(backupDbPath)
        endif
        if filereadable(backupYamlPath)
            call delete(backupYamlPath)
        endif
    endtry
endfunction

" Command to open batch add interface
