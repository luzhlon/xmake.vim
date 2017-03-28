" =============================================================================
" Filename:     plugin/xmake.vim
" Author:       luzhlon
" Function:     xmake integeration
" Depends:      proc.vim
" Last Change:  2017/3/22
" =============================================================================
"解释XMake命令
fun! s:XMake(...)
    if !a:0                     "构建但不运行
        call xmake#buildrun(0)
    elseif a:1 == 'run'         "构建&&运行
        if a:0 > 1 | let s:target = a:2 | endif
        call xmake#buildrun(1)
    elseif a:1 == 'build'       "构建目标
        if a:0 > 1 | let s:target = a:2 | endif
        call xmake#buildrun(0)
    else                        "运行其它xmake命令
        call xmake#xmake(a:000)
    endif
endf
"命令的参数补全
fun! s:compXMake(a, c, p)
    let l = split(a:c, '\s\+')
    if len(l) > 1 | if 'run' == l[1] || 'build' == l[1]
        return filter(keys(g:xcfg['targets']), {-> v:val =~ a:a})
    endif | endif
    return filter(['run', 'config', 'create', 'build',
                 \ 'clean', 'global', 'package'],
                 \ {-> v:val =~ a:a})
endf
com! -complete=customlist,<SID>compXMake -nargs=*
            \ XMake call <SID>XMake(<q-args>)
fun! s:compTarget(a, c, p)
    return filter(keys(g:xcfg['targets']), {-> v:val =~ a:a})
endf

let s:path = expand('<sfile>:p:h')

fun! s:XMGen()
    exe 'py3file' s:path . '/xmgen.py'
endf

com! XMLoad call xmake#load()
com! XMGen  call <SID>XMGen()

let s:xmakefile = 'xmake.lua'
if filereadable(s:xmakefile)
    au! VimEnter * XMLoad
endif

au! BufWritePost xmake.lua XMLoad
