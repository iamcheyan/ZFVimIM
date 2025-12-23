# ZFVimIM SBZR 模块完整文档

本文档包含 SBZR（声笔自然）输入模式模块的所有文件内容。

---

## 目录

1. [README.md](#readmemd)
2. [config.lua](#configlua)
3. [ZFVimIM_sbzr.vim](#zfvimim_sbzrvim)

---

## README.md

```markdown
# SBZR 模块

声笔自然（SBZR）输入模式模块。

## 功能特性

- 输入4码后，可以使用 `a/e/u/i/o` 快速选择第2-6个候选词
- 候选词标签：`['', 'a', 'e', 'u', 'i', 'o']`（第1个无标签，第2-6个对应 a/e/u/i/o）
- 每页显示6个候选词，提高选择效率
- 翻页功能：
  - `,` 键：向上翻页
  - `.` 键：向下翻页
  - `←` 键：向上翻页
  - `→` 键：向下翻页
  - 支持浏览所有候选词，不受6个显示限制

## 启用方式

在配置文件中设置：

```lua
vim.g.ZFVimIM_settings = { 'sbzr' }
vim.g.zfvimim_default_dict_name = "sbzr"
```

或者使用模块自带的配置文件：

```lua
-- 加载模块配置
dofile(vim.fn.stdpath('data') .. '/lazy/ZFVimIM/modules/sbzr/config.lua')
```

## 文件说明

- `ZFVimIM_sbzr.vim` - SBZR 模块核心代码
- `config.lua` - 模块配置文件
- 词库文件：`dict/sbzr.yaml`（统一存放在 dict/ 目录）

## 禁用模块

删除或重命名 `modules/sbzr/` 目录，或从配置中移除 `'sbzr'` 设置即可禁用。
```

---

## config.lua

```lua
--- ZFVimIM SBZR 模块配置文件
---
--- 此文件位于 modules 目录中，用于配置 SBZR（声笔自然）模块
---
--- SBZR 模式特性：
--- - 输入4码后，可以使用 a/e/u/i/o 快速选择第2-6个候选词
--- - 候选词标签：['', 'a', 'e', 'u', 'i', 'o']（第1个无标签，第2-6个对应 a/e/u/i/o）
--- - 自动限制候选词数量为6个，提高选择效率
---
--- 使用方法：
--- 1. 在主配置文件中启用 SBZR 模块：
---    vim.g.ZFVimIM_settings = { 'sbzr' }
---    vim.g.zfvimim_default_dict_name = "sbzr"
---
--- 2. 或者直接加载此配置文件：
---    dofile(vim.fn.stdpath('data') .. '/lazy/ZFVimIM/modules/sbzr/config.lua')

-- ============================================================
-- SBZR 模块配置
-- ============================================================

-- 启用 SBZR 模式
vim.g.ZFVimIM_settings = { 'sbzr' }

-- 设置词库名称（统一从 dict/ 目录查找）
vim.g.zfvimim_default_dict_name = "sbzr"
```

---

## ZFVimIM_sbzr.vim

```vim
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
    
    " 检查当前 keyboard 长度（通过获取当前行的输入）
    let cursor_positions = getpos('.')
    let current_line = getline(cursor_positions[1])
    let start_column = cursor_positions[2]
    let seamless_column = 1
    " 尝试获取 seamless_column
    if exists('*s:getSeamless')
        let seamless_column = s:getSeamless(cursor_positions)
    endif
    if seamless_column <= 0
        " 如果无法获取，尝试从当前行计算
        let seamless_column = start_column
        while seamless_column > 1 && current_line[(seamless_column-1) - 1] =~# '^[a-z]$'
            let seamless_column -= 1
        endwhile
    endif
    let keyboard_len = start_column - seamless_column
    
    " 如果输入第5个字符，且前4个字符有候选词，需要特殊处理
    if keyboard_len == 4
        " 获取前4个字符的编码
        let prefixKey = strpart(current_line, seamless_column - 1, 4)
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
                let selectedCandidate = prefixCandidates[candidateIdx]
                " 删除前4个字符，插入选中的候选词
                return repeat("\<bs>", 4) . selectedCandidate['word'] . "\<c-r>=ZFVimIME_callOmni()\<cr>"
            endif
        endif
        
        " 如果第5个字符不是标签键，且前4个字符有候选词，自动上屏第一个候选词
        if !has_key(s:sbzr_label_map, a:key) && !empty(prefixCandidates)
            let firstCandidate = prefixCandidates[0]
            " 删除前4个字符，插入候选词，然后输入第5个字符
            return repeat("\<bs>", 4) . firstCandidate['word'] . a:key . "\<c-r>=ZFVimIME_callOmni()\<cr>"
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
```

---

## 模块说明

### 核心功能

1. **标签键选择**：使用 `a/e/u/i/o` 选择第2-6个候选词
2. **4码自动上屏**：输入4个编码后，输入第5个字符时自动上屏第一个候选词
3. **标签键优先**：当第5个字符是标签键时，用于选择前4个编码的候选词
4. **翻页功能**：支持使用 `,`、`.`、`←`、`→` 翻页

### 断词自动拼规则

- **4个编码**：不触发断词自动拼，等待第5个编码
- **1-2个编码 + 标签键**：如果标签键对应的候选词存在，不触发断词自动拼
- **其他情况**：当没有匹配时，触发断词自动拼（前缀首选 + 后缀首选）

### 自造词组合匹配规则

SBZR 模块支持自动组合最近输入的两个词，生成新的组合词候选。当输入4个编码时，系统会检查是否符合组合规则。

#### 组合条件

- 输入编码长度必须为 4 个字符（`keyLen == 4`）
- 需要存在 `prev_commit`（倒数第二次上屏的词）和 `last_commit`（倒数第一次上屏的词）
- 总字数必须 >= 3

#### 编码规则

根据总字数和编码模式，使用不同的组合规则：

1. **三字组合**（前一个词是2个字，后一个词是1个字）
   - 规则：前两个字的声母 + 第三个字的全部编码
   - 示例：`woqu` (我去) + `wj` (顽) → `wqwj` (我去顽)
     - `w`(我) + `q`(去) + `wj`(顽) = `wqwj`

2. **四字组合**（前一个词是2个字，后一个词也是2个字）
   - 规则：每个字的声母（4个声母）
   - 示例：`Jntm` (今天) + `hvjw` (回家) → `Jthj` (今天回家)
     - `J`(今) + `t`(天) + `h`(回) + `j`(家) = `Jthj`

3. **多字组合**（总字数 >= 3，任意长度）
   - 规则：前三个字的声母 + 最后一个字的声母（固定4码）
   - 示例：
     - `wgxd` (我共享) + `gzni` (给你) → `wgxn` (我共享给你)
       - `w`(我) + `g`(共) + `x`(享) + `n`(你) = `wgxn`
     - `wosi` (我是) + `whtm` (王浩天) → `wswt` (我是王浩天)
       - `w`(我) + `s`(是) + `w`(王) + `t`(天) = `wswt`
     - `xngh` (性能更好) + `xsji` (新手机) → `xngj` (性能更好新手机)
       - `x`(性) + `n`(能) + `g`(更) + `j`(机) = `xngj`

#### 编码模式判断

系统会自动判断每个词的编码模式：

- **每个字1个编码**：如果编码长度 == 字数
  - 例如：`xngh` (性能更好) = 4个字，4个编码 → 每个字1个编码
- **每个字2个编码**：如果编码长度 != 字数
  - 例如：`xsji` (新手机) = 3个字，4个编码 → 前两个字各1个编码，第三个字2个编码

#### 组合词显示

- 组合词会显示为 `词~` 的形式（带 `~` 标记）
- 标记为临时词（`temp: 1`）
- 用户选择后，会自动添加到词库中

#### 优先级

- 组合候选词会添加到结果列表的最前面（最高优先级）
- 在 SBZR 模式下，即使已有其他匹配结果，也会检查并添加组合候选词

---
