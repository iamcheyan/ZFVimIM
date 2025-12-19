
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
    " If zfvimim_default_dict_name is set, use it; otherwise use default_pinyin
    if exists('g:zfvimim_default_dict_name') && !empty(g:zfvimim_default_dict_name)
        let defaultDictName = g:zfvimim_default_dict_name
        " Add .yaml extension if not present
        if defaultDictName !~ '\.\(yaml\|yml\|txt\)$'
            let defaultDictName = defaultDictName . '.yaml'
        endif
        let defaultDict = dictDir . '/' . defaultDictName
    else
        let defaultDict = dictDir . '/default_pinyin.yaml'
        " Fallback to .txt if .yaml doesn't exist
        if !filereadable(defaultDict)
            let defaultDict = dictDir . '/default_pinyin.txt'
        endif
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
            call ZFVimIM_dbLoad(db, dictPath)
            " Store dictPath in implData for saving after deletion
            if !has_key(db, 'implData')
                let db['implData'] = {}
            endif
            let db['implData']['dictPath'] = dictPath
        else
            " Update dictPath for already loaded dictionary
            for db in g:ZFVimIM_db
                if get(db, 'name', '') ==# dictName
                    if !has_key(db, 'implData')
                        let db['implData'] = {}
                    endif
                    let db['implData']['dictPath'] = dictPath
                    break
                endif
            endfor
        endif
    endif
endfunction

augroup ZFVimIME_augroup
    autocmd!

    autocmd User ZFVimIM_event_OnDbInit call s:ZFVimIM_autoLoadDict()

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
    call feedkeys(":IMAdd\<space>\<c-c>q:kA", 'nt')
    return ''
endfunction
function! ZFVimIME_keymap_add_i()
    if !ZFVimIME_started()
        call ZFVimIME_start()
    endif
    call feedkeys("\<esc>:IMAdd\<space>\<c-c>q:kA", 'nt')
    return ''
endfunction
function! ZFVimIME_keymap_add_v()
    if !ZFVimIME_started()
        call ZFVimIME_start()
    endif
    call feedkeys("\"ty:IMAdd\<space>\<c-r>t\<space>\<c-c>q:kA", 'nt')
    return ''
endfunction

function! ZFVimIME_keymap_remove_n()
    if !ZFVimIME_started()
        call ZFVimIME_start()
    endif
    call feedkeys(":IMRemove\<space>\<c-c>q:kA", 'nt')
    return ''
endfunction
function! ZFVimIME_keymap_remove_i()
    if !ZFVimIME_started()
        call ZFVimIME_start()
    endif
    call feedkeys("\<esc>:IMRemove\<space>\<c-c>q:kA", 'nt')
    return ''
endfunction
function! ZFVimIME_keymap_remove_v()
    if !ZFVimIME_started()
        call ZFVimIME_start()
    endif
    call feedkeys("\"tx:IMRemove\<space>\<c-r>t\<cr>", 'nt')
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
    call s:chooseItem(curPage[n])
    return ''
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
    call s:floatMove(1)
    return ''
endfunction

function! ZFVimIME_tabPrev(...)
    if mode() != 'i' || !s:floatVisible()
        " If popup is not visible, do nothing (Shift+Tab in terminal may not work)
        return ''
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
    if s:floatVisible()
        let key = "\<bs>\<c-r>=ZFVimIME_callOmni()\<cr>"
    else
        let key = "\<bs>"
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
    call s:resetAfterInsert()
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
        call s:updateCandidates()
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
    let cloudInitMode = get(g:, 'ZFVimIM_cloudInitMode', '')
    let g:ZFVimIM_cloudInitMode = 'preferSync'
    call ZFVimIME_init()
    let g:ZFVimIM_cloudInitMode = cloudInitMode

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

function! s:vimrcSetup()
    set omnifunc=ZFVimIME_omnifunc
    set completeopt=menuone
    try
        " some old vim does not have `c`
        silent! set shortmess+=c
    endtry
    set pumheight=10
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
    if len(a:key) != 2
        return a:list
    endif
    let filtered = []
    for item in a:list
        if len(get(item, 'key', '')) >= 2 && strpart(item['key'], 0, 2) ==# a:key
            call add(filtered, item)
        endif
    endfor
    return filtered
endfunction

function! s:curPage()
    if !empty(s:match_list) && &pumheight > 0
        if s:completeItemAvailable && get(g:, 'ZFVimIM_freeScroll', 0)
            execute 'let results = s:match_list[' . (s:page * &pumheight) . ':-1]'
            return results
        else
            execute 'let results = s:match_list[' . (s:page * &pumheight) . ':' . ((s:page+1) * &pumheight - 1) . ']'
            return results
        endif
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
let s:float_hl_inited = 0
let s:pending_left_len = 0

function! s:floatVisible()
    return s:float_winid > 0 && nvim_win_is_valid(s:float_winid)
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
    else
        let s:float_winid = nvim_open_win(s:float_bufnr, v:false, config)
        call nvim_win_set_option(s:float_winid, 'winhl', 'Normal:Pmenu,FloatBorder:Pmenu')
    endif
endfunction

function! s:floatRender(list)
    if empty(a:list)
        call s:floatClose()
        return
    endif
    let label = 1
    let lines = []
    let labelWidths = []
    for item in a:list
        if get(g:, 'ZFVimIM_freeScroll', 0)
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
        let labelcell = ' ' . labelstring . ' '
        let content = ' ' . item['word'] . left . ' '
        call add(labelWidths, strdisplaywidth(labelcell))
        call add(lines, labelcell . content)
        let label += 1
    endfor
    call s:floatEnsure(lines)
    call nvim_buf_set_option(s:float_bufnr, 'modifiable', v:true)
    call nvim_buf_set_lines(s:float_bufnr, 0, -1, v:true, lines)
    call nvim_buf_set_option(s:float_bufnr, 'modifiable', v:false)
    let s:float_items = a:list
    let s:float_label_widths = labelWidths
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
    call s:updateCandidates()
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

function! s:updateCandidates()
    let s:enter_to_confirm = 1
    let s:hasInput = 1
    if !s:updateKeyboardFromCursor()
        call s:floatClose()
        return
    endif
    if s:pageup_pagedown != 0 && !empty(s:match_list) && &pumheight > 0
        let length = len(s:match_list)
        let pageCount = (length-1) / &pumheight + 1
        let s:page += s:pageup_pagedown
        if s:page >= pageCount
            let s:page = pageCount - 1
        endif
        if s:page < 0
            let s:page = 0
        endif
    else
        let s:match_list = ZFVimIM_complete(s:keyboard)
        let s:match_list = s:filterMatchListByPrefix(s:match_list, s:keyboard)
        let s:page = 0
    endif
    let s:pageup_pagedown = 0
    call s:floatRender(s:curPage())
    doautocmd User ZFVimIM_event_OnUpdateOmni
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
        call s:updateCandidates()
        return []
    endif
endfunction

function! s:popupMenuList(complete)
    if empty(a:complete) || type(a:complete) != type([])
        return []
    endif
    let label = 1
    let popup_list = []
    for item in a:complete
        " :h complete-items
        let complete_items = {}
        if get(g:, 'ZFVimIM_freeScroll', 0)
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
        let complete_items['abbr'] = item['word']
        let complete_items['word'] = item['word']

        let complete_items['dup'] = 1
        let complete_items['word'] .= left
        if s:completeItemAvailable
            let complete_items['info'] = ZFVimIM_json_encode(item)
        endif
        call add(popup_list, complete_items)
        let label += 1
    endfor

    let &completeopt = 'menuone'
    let &pumheight = 10
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


function! s:addWord(dbId, key, word)
    let dbIndex = ZFVimIM_dbIndexForId(a:dbId)
    if dbIndex < 0
        return
    endif
    call ZFVimIM_wordAdd(g:ZFVimIM_db[dbIndex], a:word, a:key)

    let g:ZFVimIM_event_OnAddWord = {
                \   'dbId' : a:dbId,
                \   'key' : a:key,
                \   'word' : a:word,
                \ }
    doautocmd User ZFVimIM_event_OnAddWord
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
        
        if exists('g:zfvimim_default_dict_name') && !empty(g:zfvimim_default_dict_name)
            let defaultDictName = g:zfvimim_default_dict_name
            if defaultDictName !~ '\.\(yaml\|yml\|txt\)$'
                let defaultDictName = defaultDictName . '.yaml'
            endif
            let dictPath = dictDir . '/' . defaultDictName
            " Fallback to .txt if .yaml doesn't exist
            if !filereadable(dictPath) && defaultDictName =~ '\.yaml$'
                let dictPath = dictDir . '/' . substitute(defaultDictName, '\.yaml$', '.txt', '')
            endif
        elseif exists('g:zfvimim_dict_path') && !empty(g:zfvimim_dict_path)
            let dictPath = expand(g:zfvimim_dict_path)
        else
            let dictPath = dictDir . '/default_pinyin.yaml'
            " Fallback to .txt if .yaml doesn't exist
            if !filereadable(dictPath)
                let dictPath = dictDir . '/default_pinyin.txt'
            endif
        endif
    endif
    
    " Remove the word
    call ZFVimIM_wordRemove(db, a:word, a:key)
    
    " Also remove from frequency tracking
    let freqKey = a:key . "\t" . a:word
    if has_key(s:word_frequency, freqKey)
        call remove(s:word_frequency, freqKey)
    endif
    
    " Save to file if path is valid and file exists
    if !empty(dictPath) && filereadable(dictPath)
        try
            call ZFVimIM_dbSave(db, dictPath)
            " Store dictPath in implData for future use
            if !has_key(db, 'implData')
                let db['implData'] = {}
            endif
            let db['implData']['dictPath'] = dictPath
        catch
            " Silently ignore save errors
        endtry
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
    
    if !empty(item) && has_key(item, 'key') && has_key(item, 'word') && has_key(item, 'dbId')
        let key = item['key']
        let word = item['word']
        let dbId = item['dbId']
        
        " Remove the word
        if s:removeWord(dbId, key, word)
            echo "已删除: " . word . " (" . key . ")"
            call s:updateCandidates()
        else
            echo "删除失败: " . word . " (" . key . ")"
        endif
    else
        echo "无法获取当前选中的词"
    endif
    
    return ''
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

    " Record word usage for frequency-based sorting
    call s:recordWordUsage(a:item['key'], a:item['word'])

    if a:item['type'] == 'sentence'
        for word in get(a:item, 'sentenceList', [])
            call s:addWord(a:item['dbId'], word['key'], word['word'])
            " Also record sentence word usage
            call s:recordWordUsage(word['key'], word['word'])
        endfor
        let s:userWord = []
        return
    endif

    call add(s:userWord, a:item)

    if a:item['len'] == len(s:keyboard)
        call s:addWordFromUserWord()
        let s:userWord = []
    endif
endfunction
function! s:addWordFromUserWord()
    if !empty(s:userWord)
        let sentenceKey = ''
        let sentenceWord = ''
        let hasOtherDb = 0
        let dbIdPrev = ''
        for word in s:userWord
            call s:addWord(word['dbId'], word['key'], word['word'])

            if !hasOtherDb
                let hasOtherDb = (dbIdPrev != '' && dbIdPrev != word['dbId'])
                let dbIdPrev = word['dbId']
            endif
            let sentenceKey .= word['key']
            let sentenceWord .= word['word']
        endfor

        let needAdd = 0
        if !empty(g:ZFVimIM_autoAddWordChecker)
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
            if !hasOtherDb
                        \ && len(s:userWord) > 1
                        \ && len(sentenceWord) <= g:ZFVimIM_autoAddWordLen
                let needAdd = 1
            endif
        endif
        if needAdd
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
    
    " Save to file (limit frequency to prevent overflow)
    if s:word_frequency[key] > 1000
        let s:word_frequency[key] = 1000
    endif
    
    " Auto-save frequency data (every 10 uses)
    if s:word_frequency[key] % 10 == 0
        call s:saveWordFrequency()
    endif
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
    return get(s:word_frequency, key, 0)
endfunction

" Initialize word frequency on plugin load (after init)
call s:initWordFrequency()

" Save frequency on exit
augroup ZFVimIM_frequency
    autocmd!
    autocmd VimLeavePre * call s:saveWordFrequency()
augroup END

" ============================================================
" Reload plugin function for development
function! ZFVimIM_reload()
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
        augroup! ZFVimIM_cloud_sync_augroup
    catch
    endtry
    
    try
        augroup! ZFVimIM_autoDisable_augroup
    catch
    endtry
    
    try
        augroup! ZFVimIM_cloud_async_augroup
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
    
    " Reload plugin via Lazy
    if exists(':Lazy') == 2
        Lazy reload ZFVimIM
    else
        echo "Warning: Lazy plugin manager not found. Please restart Neovim to reload ZFVimIM."
    endif
endfunction

" Create user command for reloading
if !exists(':ZFVimIMReload')
    command! ZFVimIMReload :call ZFVimIM_reload()
endif

" Create user command for cache management
if !exists(':ZFVimIMCacheClear')
    command! ZFVimIMCacheClear :call ZFVimIM_cacheClearAll()
endif

if !exists(':ZFVimIMCacheUpdate')
    command! ZFVimIMCacheUpdate :call ZFVimIM_cacheUpdate()
endif
