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
        let g:ZFVimIM_candidateLimit = len(s:sbzr_labels)
        let g:ZFVimIM_matchLimit = 0 - abs(s:sbzr_prev_matchLimit)
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
            let s:sbzr_active = 0
        endif
    endif
endfunction

function! ZFVimIM_sbzr_key(key)
    if !s:sbzr_enabled()
        return ZFVimIME_input(a:key)
    endif
    let state = ZFVimIME_state()
    let keyLen = len(get(state, 'key', ''))
    if keyLen == 4 && !empty(get(state, 'list', []))
        if has_key(s:sbzr_label_map, a:key)
            return ZFVimIME_label(s:sbzr_label_map[a:key])
        endif
        return ZFVimIME_labelWithTail(1, a:key)
    endif
    return ZFVimIME_input(a:key)
endfunction

function! s:apply_sbzr_keymaps()
    if !s:sbzr_enabled()
        return
    endif
    for key in split('abcdefghijklmnopqrstuvwxyz', '\zs')
        execute 'lnoremap <buffer><expr><silent> ' . key . ' ZFVimIM_sbzr_key("' . key . '")'
    endfor
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
