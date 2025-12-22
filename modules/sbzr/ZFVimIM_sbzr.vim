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
