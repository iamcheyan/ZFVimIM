" Minimal stubs for removed cloud features
if exists('*ZFVimIM_cloudRegister')
  finish
endif

function! ZFVimIM_cloudRegister(...) abort
  return 0
endfunction
function! ZFVimIM_download(...) abort
  return 0
endfunction
function! ZFVimIM_upload(...) abort
  return 0
endfunction
function! ZFVimIM_cloudLog(...) abort
  return []
endfunction
function! ZFVimIM_cloudLogClear() abort
endfunction
function! ZFVimIM_cloudAsyncAvailable() abort
  return 0
endfunction
function! ZFVimIM_LocalDb(...) abort
  return 0
endfunction
