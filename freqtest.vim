set rtp+=.
runtime plugin/ZFVimIM_DEBUG.vim
runtime plugin/ZFVimIM_API.vim
runtime plugin/ZFVimIM_complete.vim
runtime plugin/ZFVimIM_IME.vim
call ZFVimIME_init()
echo execute('scriptnames')
let sid = matchstr(execute('scriptnames'), '\n\s*\zs\d\+\ze: .*ZFVimIM_IME.vim')
echo 'sid=' . sid
qa
