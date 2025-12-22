" ============================================================
" ZFVimIM 模块加载系统
" ============================================================

if exists('g:loaded_ZFVimIM_modules')
    finish
endif
let g:loaded_ZFVimIM_modules = 1

" 获取插件目录
function! s:ZFVimIM_getPluginDir()
    let pluginDir = stdpath('data') . '/lazy/ZFVimIM'
    let sfileDir = expand('<sfile>:p:h:h')
    if isdirectory(sfileDir . '/plugin')
        let pluginDir = sfileDir
    endif
    return pluginDir
endfunction

" 加载模块
function! s:ZFVimIM_loadModule(moduleName)
    let pluginDir = s:ZFVimIM_getPluginDir()
    let moduleDir = pluginDir . '/modules/' . a:moduleName
    
    " 检查模块目录是否存在
    if !isdirectory(moduleDir)
        return 0
    endif
    
    " 检查模块是否已启用（通过配置）
    let settings = exists('g:ZFVimIM_settings') ? g:ZFVimIM_settings : []
    let enabled = 0
    
    if type(settings) == type([])
        let enabled = index(settings, a:moduleName) >= 0
    elseif type(settings) == type({})
        let enabled = has_key(settings, a:moduleName)
    elseif type(settings) == type('')
        let enabled = settings ==# a:moduleName || match(settings, '\<' . a:moduleName . '\>') >= 0
    endif
    
    if !enabled
        return 0
    endif
    
    " 加载模块的 Vim 脚本文件
    let vimFile = moduleDir . '/ZFVimIM_' . a:moduleName . '.vim'
    if filereadable(vimFile)
        execute 'source ' . fnameescape(vimFile)
        return 1
    endif
    
    " 如果没有找到标准命名的文件，尝试加载所有 .vim 文件
    let vimFiles = glob(moduleDir . '/*.vim', 0, 1)
    if !empty(vimFiles)
        for vimFile in vimFiles
            execute 'source ' . fnameescape(vimFile)
        endfor
        return 1
    endif
    
    return 0
endfunction

" 获取模块词库路径
" 统一从 dict/ 目录查找词库文件
function! ZFVimIM_getModuleDictPath(moduleName, dictName)
    let pluginDir = s:ZFVimIM_getPluginDir()
    let dictDir = pluginDir . '/dict'
    
    " 统一从 dict/ 目录查找词库文件
    let dictName = a:dictName
    if dictName !~ '\.yaml$'
        let dictName = dictName . '.yaml'
    endif
    
    " 从 dict/ 目录查找
    let dictPath = dictDir . '/' . dictName
    if filereadable(dictPath)
        return dictPath
    endif
    
    return ''
endfunction

" 自动加载所有启用的模块
function! s:ZFVimIM_autoLoadModules()
    let pluginDir = s:ZFVimIM_getPluginDir()
    let modulesDir = pluginDir . '/modules'
    
    " 检查模块目录是否存在
    if !isdirectory(modulesDir)
        return
    endif
    
    " 遍历所有模块目录
    let moduleDirs = glob(modulesDir . '/*', 0, 1)
    for moduleDir in moduleDirs
        if !isdirectory(moduleDir)
            continue
        endif
        
        let moduleName = fnamemodify(moduleDir, ':t')
        
        " 加载模块
        call s:ZFVimIM_loadModule(moduleName)
    endfor
endfunction

" 在插件启动时自动加载模块
call s:ZFVimIM_autoLoadModules()

" 提供手动加载模块的命令
command! -nargs=1 ZFVimIMLoadModule call s:ZFVimIM_loadModule(<q-args>)

