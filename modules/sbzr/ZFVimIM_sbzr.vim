if exists('g:loaded_ZFVimIM_sbzr')
    finish
endif
let g:loaded_ZFVimIM_sbzr = 1

let s:sbzr_labels = ['', 'a', 'e', 'u', 'i', 'o']
let s:sbzr_label_map = {'a': 2, 'e': 3, 'u': 4, 'i': 5, 'o': 6}
let s:sbzr_active = 0
let s:sbzr_prev_labelList_set = 0
let s:sbzr_prev_pumheight_set = 0
let s:sbzr_prev_candidateLimit_set = 0
let s:sbzr_prev_matchLimit_set = 0
let s:sbzr_prev_mode_set = 0
let s:sbzr_prev_labelList = []
let s:sbzr_prev_pumheight = 0
let s:sbzr_prev_candidateLimit = 0
let s:sbzr_prev_matchLimit = 0
let s:sbzr_prev_mode = 0
let s:sbzr_auto_commit = 0
let s:sbzr_seen_freq = {}
let s:sbzr_seen_counter = 0

function! s:settingsValue()
    if exists('g:ZFVimIM_settings')
        return g:ZFVimIM_settings
    endif
    if exists('g:ZFVimIM_setting')
        return g:ZFVimIM_setting
    endif
    return []
endfunction

function! s:sbzr_enabled()
    let setting = s:settingsValue()
    if type(setting) == type([])
        return index(setting, 'sbzr') >= 0
    elseif type(setting) == type({})
        return has_key(setting, 'sbzr')
    elseif type(setting) == type('')
        if empty(setting)
            return 0
        endif
        return setting ==# 'sbzr' || match(setting, '\<sbzr\>') >= 0
    endif
    return 0
endfunction

function! s:apply_sbzr_settings()
    if s:sbzr_enabled()
        if !s:sbzr_active
            if exists('g:ZFVimIM_labelList')
                let s:sbzr_prev_labelList = g:ZFVimIM_labelList
                let s:sbzr_prev_labelList_set = 1
            else
                let s:sbzr_prev_labelList_set = 0
            endif
            if exists('g:ZFVimIM_pumheight')
                let s:sbzr_prev_pumheight = g:ZFVimIM_pumheight
                let s:sbzr_prev_pumheight_set = 1
            else
                let s:sbzr_prev_pumheight_set = 0
            endif
            if exists('g:ZFVimIM_candidateLimit')
                let s:sbzr_prev_candidateLimit = g:ZFVimIM_candidateLimit
                let s:sbzr_prev_candidateLimit_set = 1
            else
                let s:sbzr_prev_candidateLimit_set = 0
            endif
            if exists('g:ZFVimIM_matchLimit')
                let s:sbzr_prev_matchLimit = g:ZFVimIM_matchLimit
                let s:sbzr_prev_matchLimit_set = 1
            else
                let s:sbzr_prev_matchLimit = 2000
                let s:sbzr_prev_matchLimit_set = 0
            endif
            if exists('g:ZFVimIM_sbzr_mode')
                let s:sbzr_prev_mode = g:ZFVimIM_sbzr_mode
                let s:sbzr_prev_mode_set = 1
            else
                let s:sbzr_prev_mode_set = 0
            endif
        endif
        let g:ZFVimIM_labelList = copy(s:sbzr_labels)
        let g:ZFVimIM_pumheight = len(s:sbzr_labels)
        " 不限制候选词总数，允许翻页（pumheight 限制显示数量为6）
        " candidateLimit 设为 0 表示不限制，这样翻页功能才能正常工作
        let g:ZFVimIM_candidateLimit = 0
        " matchLimit 设为负数表示精确匹配的数量限制，设为 -2000 允许匹配更多候选词
        " 这样翻页时才能获取所有候选词
        let g:ZFVimIM_matchLimit = 0 - abs(s:sbzr_prev_matchLimit)
        " 设置 freeScroll 模式，允许自由滚动和翻页
        let g:ZFVimIM_freeScroll = 1
        let g:ZFVimIM_sbzr_mode = 1
        let s:sbzr_active = 1
    else
        if s:sbzr_active
            if s:sbzr_prev_labelList_set
                let g:ZFVimIM_labelList = s:sbzr_prev_labelList
            elseif exists('g:ZFVimIM_labelList')
                unlet g:ZFVimIM_labelList
            endif
            if s:sbzr_prev_pumheight_set
                let g:ZFVimIM_pumheight = s:sbzr_prev_pumheight
            elseif exists('g:ZFVimIM_pumheight')
                unlet g:ZFVimIM_pumheight
            endif
            if s:sbzr_prev_candidateLimit_set
                let g:ZFVimIM_candidateLimit = s:sbzr_prev_candidateLimit
            elseif exists('g:ZFVimIM_candidateLimit')
                unlet g:ZFVimIM_candidateLimit
            endif
            if s:sbzr_prev_matchLimit_set
                let g:ZFVimIM_matchLimit = s:sbzr_prev_matchLimit
            elseif exists('g:ZFVimIM_matchLimit')
                unlet g:ZFVimIM_matchLimit
            endif
            if s:sbzr_prev_mode_set
                let g:ZFVimIM_sbzr_mode = s:sbzr_prev_mode
            elseif exists('g:ZFVimIM_sbzr_mode')
                unlet g:ZFVimIM_sbzr_mode
            endif
            " 恢复 freeScroll 设置（如果之前存在）
            if exists('g:ZFVimIM_freeScroll')
                unlet g:ZFVimIM_freeScroll
            endif
            let s:sbzr_active = 0
        endif
    endif
endfunction

function! ZFVimIM_sbzr_key(key)
    if !s:sbzr_enabled()
        return ZFVimIME_input(a:key)
    endif
    let state = ZFVimIME_state()
    let candidates = get(state, 'list', [])
    
    " 检查当前 keyboard 长度（通过获取当前行的输入）
    let cursor_positions = getpos('.')
    let current_line = getline(cursor_positions[1])
    let start_column = cursor_positions[2]
    let seamless_column = 1
    let use_state = 0
    let state = ZFVimIME_state()
    let seamless_pos = get(state, 'seamlessPos', [])
    if len(seamless_pos) >= 4
                \&& seamless_pos[0] == cursor_positions[0]
                \&& seamless_pos[1] == cursor_positions[1]
                \&& seamless_pos[3] == cursor_positions[3]
        let candidate_column = seamless_pos[2]
        let len_to_cursor = cursor_positions[2] - candidate_column
        if len_to_cursor >= 0
            let snip = strpart(current_line, candidate_column - 1, len_to_cursor)
            if empty(snip)
                let seamless_column = candidate_column
                let use_state = 1
            else
                let valid = 1
                for c in split(snip, '\zs')
                    if c !~# '^[a-z]$'
                        let valid = 0
                        break
                    endif
                endfor
                if valid
                    let seamless_column = candidate_column
                    let use_state = 1
                endif
            endif
        endif
    endif
    if seamless_column <= 0 || !use_state
        " 如果无法获取，尝试从当前行计算
        let seamless_column = start_column
        while seamless_column > 1 && current_line[(seamless_column-1) - 1] =~# '^[a-z]$'
            let seamless_column -= 1
        endwhile
    endif
    let keyboard_len = start_column - seamless_column
    
    " 如果 3 码唯一匹配，继续输入时自动上屏并追加新字符
    if keyboard_len == 3
        let curKey = get(state, 'key', '')
        if len(curKey) == keyboard_len && len(candidates) == 1 && !get(candidates[0], 'hint', 0)
            return ZFVimIME_labelWithTail(1, a:key)
        endif
    endif

    " 如果输入第5个字符，且前4个字符有候选词，需要特殊处理
    if keyboard_len == 4
        " 获取前4个字符的编码
        let prefixKey = strpart(current_line, seamless_column - 1, 4)
        " 先检查完整的5个字符是否有匹配
        let fullKey = prefixKey . a:key
        let fullCandidates = ZFVimIM_complete(fullKey, {
                    \ 'match': -2000,
                    \ 'sentence': 0,
                    \ 'crossDb': 0,
                    \ 'predict': 0,
                    \ })
        
        " 如果完整的5个字符有匹配，正常输入，不自动上屏
        if !empty(fullCandidates)
            " 正常输入第5个字符，让系统处理完整的5个字符匹配
            return ZFVimIME_input(a:key)
        endif
        
        " 如果完整的5个字符没有匹配，才考虑自动上屏
        let prefixCandidates = ZFVimIM_complete(prefixKey, {
                    \ 'match': -2000,
                    \ 'sentence': 0,
                    \ 'crossDb': 0,
                    \ 'predict': 0,
                    \ })
        
        " 如果第5个字符是标签键，且前4个字符有候选词，让标签键用于选择候选词
        if has_key(s:sbzr_label_map, a:key) && !empty(prefixCandidates)
            " 直接使用标签键选择前4个字符的候选词
            let pageSize = len(get(g:, 'ZFVimIM_labelList', s:sbzr_labels))
            if pageSize <= 0
                let pageSize = len(s:sbzr_labels)
            endif
            let labelPos = s:sbzr_label_map[a:key]
            let candidateIdx = labelPos - 1  " 转换为0-based索引
            if candidateIdx < len(prefixCandidates)
                " 选择对应的候选词
                return ZFVimIME_label(labelPos)
            endif
        endif
        
        " 如果第5个字符不是标签键，且前4个字符有候选词，自动上屏第一个候选词，然后继续输入第5个字符
        if !has_key(s:sbzr_label_map, a:key) && !empty(prefixCandidates)
            " 选择第一个候选词并追加第5个字符
            return ZFVimIME_labelWithTail(1, a:key)
        endif
    endif
    
    if has_key(s:sbzr_label_map, a:key)
        if !empty(candidates)
            let pageSize = len(get(g:, 'ZFVimIM_labelList', s:sbzr_labels))
            if pageSize <= 0
                let pageSize = len(s:sbzr_labels)
            endif
            let pageIndex = max([0, get(state, 'page', 0)])
            let startIdx = pageIndex * pageSize
            let labelPos = s:sbzr_label_map[a:key]
            let candidateIdx = startIdx + (labelPos - 1)
            if startIdx < len(candidates) && candidateIdx < len(candidates) && (labelPos - 1) < pageSize
                return ZFVimIME_label(labelPos)
            endif
        endif
        return ZFVimIME_input(a:key)
    endif
    return ZFVimIME_input(a:key)
endfunction

" SBZR 翻页处理函数
" 翻页函数内部已经检查了是否有候选词窗口，如果没有会正常输入字符
function! ZFVimIM_sbzr_pageUp(key)
    if !s:sbzr_enabled()
        return ZFVimIME_pageUp(a:key)
    endif
    " 直接调用翻页函数，让它自己处理是否有候选词窗口的情况
    return ZFVimIME_pageUp(a:key)
endfunction

function! ZFVimIM_sbzr_pageDown(key)
    if !s:sbzr_enabled()
        return ZFVimIME_pageDown(a:key)
    endif
    " 直接调用翻页函数，让它自己处理是否有候选词窗口的情况
    return ZFVimIME_pageDown(a:key)
endfunction

function! s:apply_sbzr_keymaps()
    if !s:sbzr_enabled()
        return
    endif
    " 映射字母键
    for key in split('abcdefghijklmnopqrstuvwxyz', '\zs')
        execute 'lnoremap <buffer><expr><silent> ' . key . ' ZFVimIM_sbzr_key("' . key . '")'
    endfor
    " 映射翻页键：, 和 .
    execute 'lnoremap <buffer><expr><silent> , ZFVimIM_sbzr_pageUp(",")'
    execute 'lnoremap <buffer><expr><silent> . ZFVimIM_sbzr_pageDown(".")'
    " 映射左右箭头键
    execute 'lnoremap <buffer><expr><silent> <Left> ZFVimIM_sbzr_pageUp("<Left>")'
    execute 'lnoremap <buffer><expr><silent> <Right> ZFVimIM_sbzr_pageDown("<Right>")'
endfunction

function! s:autoCommitSingleCandidate()
    return
endfunction

call s:apply_sbzr_settings()

augroup ZFVimIM_sbzr_augroup
    autocmd!
    autocmd User ZFVimIM_event_OnStart call s:apply_sbzr_settings()
    autocmd User ZFVimIM_event_OnEnable call s:apply_sbzr_settings() | call s:apply_sbzr_keymaps()
augroup END

function! s:ensure_label_list() abort
    if !exists('g:ZFVimIM_labelList') || empty(g:ZFVimIM_labelList)
        let g:ZFVimIM_labelList = copy(s:sbzr_labels)
    endif
endfunction

function! s:sbzr_updateCandidates() abort
    if !exists('*ZFVimIM_core_api')
        return
    endif
    call s:ensure_label_list()
    let defaultPumheight = ZFVimIM_core_api('default_pumheight')
    if &pumheight <= 0 || &pumheight < defaultPumheight
        execute 'set pumheight=' . defaultPumheight
    endif
    let pageSize = &pumheight
    let keyboard = ZFVimIM_core_api('get_keyboard')
    let lastKeyboard = ZFVimIM_core_api('get_last_keyboard')
    let matchList = ZFVimIM_core_api('get_match_list')
    let keyboardChanged = (keyboard !=# lastKeyboard)
    let needRefresh = keyboardChanged || empty(matchList)
    if needRefresh
        let matchLimit = get(g:, 'ZFVimIM_matchLimit', 0)
        if matchLimit == 0
            let matchLimit = -2000
        endif
        let resultList = ZFVimIM_complete(keyboard, {
                    \ 'match': matchLimit,
                    \ 'sentence': 0,
                    \ 'crossDb': 0,
                    \ 'predict': 0,
                    \ })
        let resultList = ZFVimIM_core_api('apply_candidate_limit', resultList)
        call ZFVimIM_core_api('set_full_result_list', resultList)
        call ZFVimIM_core_api('set_match_list', resultList)
        call ZFVimIM_core_api('set_loaded_result_count', len(resultList))
        call ZFVimIM_core_api('set_page', 0)
    elseif ZFVimIM_core_api('get_pageup_pagedown') != 0 && pageSize > 0
        let page = ZFVimIM_core_api('get_page')
        let delta = ZFVimIM_core_api('get_pageup_pagedown')
        let page += delta
        let currentList = ZFVimIM_core_api('get_match_list')
        if !empty(currentList)
            let maxPage = (len(currentList) - 1) / pageSize
            if page > maxPage
                let page = maxPage
            endif
        endif
        if page < 0
            let page = 0
        endif
        call ZFVimIM_core_api('set_page', page)
    endif
    call ZFVimIM_core_api('set_pageup_pagedown', 0)
    call ZFVimIM_core_api('set_has_full_results', 1)
    call ZFVimIM_core_api('set_last_keyboard', keyboard)
    let skipFew = get(g:, 'ZFVimIM_skipFloatWhenFew', 0)
    let matchList = ZFVimIM_core_api('get_match_list')
    if skipFew > 0 && len(matchList) <= skipFew
        call ZFVimIM_core_api('float_close')
        doautocmd User ZFVimIM_event_OnUpdateOmni_sbzr
        return
    endif
    if empty(matchList)
        let hintItems = s:sbzrHintItems(keyboard, &pumheight)
        if !empty(hintItems)
            call ZFVimIM_core_api('float_render', hintItems)
            doautocmd User ZFVimIM_event_OnUpdateOmni_sbzr
            return
        endif
    endif
    call ZFVimIM_core_api('float_render', ZFVimIM_core_api('cur_page'))
    doautocmd User ZFVimIM_event_OnUpdateOmni_sbzr
endfunction

function! s:sbzrHintItems(key, limit) abort
    if empty(a:key)
        return []
    endif
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
    let c = a:key[0]
    if !has_key(db['dbMap'], c)
        return []
    endif
    let bucket = db['dbMap'][c]
    let limit = a:limit > 0 ? a:limit : 6
    let ret = []
    let idx = ZFVimIM_dbSearch(db, c, '^' . a:key, 0)
    if idx < 0
        return []
    endif
    while idx < len(bucket) && len(ret) < limit
        let item = ZFVimIM_dbItemDecode(bucket[idx])
        let k = get(item, 'key', '')
        if k !~# '^' . a:key
            break
        endif
        if k !=# a:key
            let wordList = get(item, 'wordList', [])
            if !empty(wordList)
                let word = wordList[0]
                call add(ret, {
                            \ 'dbId' : get(db, 'dbId', 0),
                            \ 'len' : len(a:key),
                            \ 'word' : word,
                            \ 'displayWord' : word,
                            \ 'key' : k,
                            \ 'type' : 'match',
                            \ 'hint' : 1,
                            \ })
                break
            endif
        endif
        let idx += 1
    endwhile
    return ret
endfunction

function! s:hook_update_candidates_debounced() abort
    if !s:sbzr_enabled() || !exists('*ZFVimIM_core_api')
        return 0
    endif
    call ZFVimIM_core_api('call_update_candidates')
    return 1
endfunction

function! s:hook_update_candidates() abort
    if !s:sbzr_enabled()
        return 0
    endif
    call s:sbzr_updateCandidates()
    return 1
endfunction

function! s:hook_tab_move(direction) abort
    if !s:sbzr_enabled()
        return 0
    endif
    if a:direction > 0
        call ZFVimIME_chooseIndex(1)
    else
        call ZFVimIME_chooseIndex(-1)
    endif
    return 1
endfunction

function! s:hook_record_word_usage(key, word) abort
    if !s:sbzr_enabled()
        return
    endif
    let entry = a:key . "\t" . a:word
    let s:sbzr_seen_counter += 1
    let s:sbzr_seen_freq[entry] = s:sbzr_seen_counter
endfunction

function! s:hook_word_frequency_override(key, word) abort
    if !s:sbzr_enabled()
        return v:null
    endif
    let entry = a:key . "\t" . a:word
    let seen = get(s:sbzr_seen_freq, entry, 0)
    if seen > 0
        return 1000000 + seen
    endif
    return v:null
endfunction

function! s:sbzr_sortByFrequency(item1, item2) abort
    if !has_key(a:item1, 'freq')
        let a:item1['freq'] = ZFVimIM_getWordFrequency(get(a:item1, 'key', ''), get(a:item1, 'word', ''))
    endif
    if !has_key(a:item2, 'freq')
        let a:item2['freq'] = ZFVimIM_getWordFrequency(get(a:item2, 'key', ''), get(a:item2, 'word', ''))
    endif
    let freq1 = a:item1['freq']
    let freq2 = a:item2['freq']
    if freq1 > freq2
        return -1
    elseif freq1 < freq2
        return 1
    endif
    return 0
endfunction

function! s:hook_complete_add_candidates(ret, singleChars, multiChars, matchLimit) abort
    if !s:sbzr_enabled()
        return v:null
    endif
    let allCandidates = copy(a:singleChars) + copy(a:multiChars)
    if len(allCandidates) > 1
        call sort(allCandidates, function('s:sbzr_sortByFrequency'))
    endif
    let remainingLimit = a:matchLimit
    let wordIndex = 0
    while wordIndex < len(allCandidates) && remainingLimit > 0
        call add(a:ret, allCandidates[wordIndex])
        let wordIndex += 1
        let remainingLimit -= 1
    endwhile
    return remainingLimit
endfunction

function! s:hook_complete_sort_frequency_priority(ret) abort
    if !s:sbzr_enabled()
        return 0
    endif
    if len(a:ret) > 1
        call sort(a:ret, function('s:sbzr_sortByFrequency'))
    endif
    return 1
endfunction

function! s:hook_complete_force_combo(key, ret) abort
    if !s:sbzr_enabled()
        return 0
    endif
    return len(a:key) == 4
endfunction

function! s:register_hooks() abort
    if !exists('*ZFVimIM_registerHook')
        return
    endif
    call ZFVimIM_registerHook('update_candidates_debounced', function('s:hook_update_candidates_debounced'))
    call ZFVimIM_registerHook('update_candidates', function('s:hook_update_candidates'))
    call ZFVimIM_registerHook('tab_move', function('s:hook_tab_move'))
    call ZFVimIM_registerHook('record_word_usage', function('s:hook_record_word_usage'))
    call ZFVimIM_registerHook('word_frequency_override', function('s:hook_word_frequency_override'))
    call ZFVimIM_registerHook('complete_add_candidates', function('s:hook_complete_add_candidates'))
    call ZFVimIM_registerHook('complete_sort_frequency_priority', function('s:hook_complete_sort_frequency_priority'))
    call ZFVimIM_registerHook('complete_force_combo', function('s:hook_complete_force_combo'))
endfunction

call s:register_hooks()
