" =============================================================================
" Filename:     autoload/xmake.vim
" Author:       luzhlon
" Function:     xmake's integeration
" Depends:      job.vim
" Last Change:  2017/7/20
" =============================================================================

let s:job = 0       " subprocess of xmake
let s:run = 0       " run this command after building successfully
let s:target = ''   " target to build, build ALL if empty
" Get the bufnr about a target's sourcefiles and headerfiles
fun! s:targetbufs(t)
    let nrs = {}
    for i in a:t['sourcefiles'] + a:t['headerfiles']
        let n = bufnr(i)
        if n > 0 && getbufvar(n, '&mod') | let nrs[n] = 1 | endif
    endfo
    return nrs
endf
" Get the bufnrs to save
fun! s:buf2save()
    if empty(s:target)
        " Save all target's file
        let nrs = {}
        for tf in values(g:xmproj['targets'])
            call extend(nrs, s:targetbufs(tf))
        endfo
    else
        " Save s:target's file
        let nrs = s:targetbufs(g:xmproj['targets'][s:target])
    endif
    return keys(nrs)
endf
" Save the file before building
fun! s:savafiles()
    let n = bufnr('%')      " save current bufnr
    let bufnrs = s:buf2save()
    for nr in bufnrs        " traverse project's files, and save them
        exe nr . 'bufdo!' 'up'
    endfo
    " switch to original buffer
    exe 'b!' n
endf
" Run shell command
fun! s:runsh(cmd)
    let p = a:cmd
    if type(p) == v:t_list
        let p = join(p)
    elseif has('unix') && p !~ '^\/'
    " Absolute path
        let p = './' . p
    endif
    try
        return qrun#exec(p)
    catch /E117/
        if has('win32')
            exe '!start' p
        else
            exe '!./' . p
        endif
    endt
endf
" If exists a xmake subprocess
fun! s:isRunning()
    if job#running(s:job)
        echom 'a xmake task is running'
        return 1
    endif
    return 0
endf
" If loaded the xmake's configuration
fun! s:notLoaded()
    if exists('g:xmproj')
        return 0
    endif
    echo 'No xmake-project loaded'
    return 1
endf
" Building by xmake
fun! xmake#buildrun(...)
    if s:notLoaded() | return | endif
    if s:isRunning() | return | endif
    call s:savafiles()          " save files about the target to build
    let run = a:0 && a:1
    let bin = get(g:xmproj.targets, s:target, '')
    let color = $COLORTERM
    fun! OnQuit(job, code) closure
        let $COLORTERM = color
        if a:code               " open the quickfix if any errors
            echohl Error | echo 'build failure' | echohl
            copen
        else
            echohl MoreMsg | echo 'build success' bin | echohl
            if run
                call s:runsh(empty(bin) ? ['xmake', 'run']: bin)
            endif
        endif
    endf
    cexpr ''
    let $COLORTERM = 'nocolor'
    " startup the xmake
    let cmd = empty(s:target) ? 'xmake': ['xmake', 'build', s:target]
    if has_key(g:xmproj, 'compiler')
        exe 'compiler' g:xmproj['compiler']
    endif
    let s:job = job#start(cmd, {
                    \ 'onout': funcref('job#cb_add2qf'),
                    \ 'onerr': funcref('job#cb_add2qf'),
                    \ 'onexit': funcref('OnQuit')})
endf
" Interpret XMake command
fun! xmake#xmake(...)
    let argv = filter(copy(a:000), {i,v->v!=''})
    let argc = len(argv)
    if !argc                            " building all targets without running
        let s:target = ''
        call xmake#buildrun()
    elseif argv[0] == 'run' || argv[0] == 'r'   " building && running
        if argc > 1 | let s:target = argv[1] | endif
        call xmake#buildrun(1)
    elseif argv[0] == 'build'               " building specific target
        if argc > 1 | let s:target = argv[1] | endif
        call xmake#buildrun()
    else                                " else xmake's commands
        if s:isRunning() | return | endif
        cexpr ''
        let opts = { 'onout': funcref('job#cb_add2qf') }
        if argv[0] == 'config' || argv[0] == 'f'
            let opts.onexit = {job, code -> code ? execute('copen'): xmake#load()}
        endif
        let s:job = job#start(['xmake'] + argv, opts)
    endif
endf

fun! s:onload(...)
    " Check the fields
    for t in values(g:xmproj['targets'])
        if empty(t.headerfiles)
            let t.headerfiles = []
        endif
        if empty(t.sourcefiles)
            let t.sourcefiles = []
        endif
    endfo
    " Change UI
    echohl MoreMsg
    echom "XMake-Project loaded successfully"
    echohl
    set title
    let config = g:xmproj.config
    let &titlestring = join([g:xmproj['name'], config.mode, config.arch], ' - ')
    redraw
    " Find compiler
    let cc = get(g:xmproj.config, 'cc', '')
    let cxx = get(g:xmproj.config, 'cxx', '')
    let compiler = ''
    if !empty(cxx)
        let compiler = cxx
    elseif !empty(cc)
        let compiler = cc
    endif
    if !empty(compiler)
        let t = {'cl.exe': 'msvc', 'gcc': 'gcc'}
        let g:xmproj.compiler = t[compiler]
    endif
endf

au User XMakeLoaded call <SID>onload()

let s:path = expand('<sfile>:p:h')
fun! xmake#load()
    let cache = []
    let tf = tempname()
    fun! LoadXCfg(job, code) closure
        let err = []
        if a:code
            call add(err, 'xmake returned ' . a:code)
        endif
        let l = ''
        try
            let l = readfile(tf)
            let g:xmproj = json_decode(l[0])
            do User XMakeLoaded
        catch
            let g:_xmake = {}
            let g:_xmake.tmpfile = tf
            let g:_xmake.output = l
            cexpr ''
            call add(err, "XMake-Project loaded unsuccessfully:")
            cadde err | cadde cache | copen
        endt
    endf
    let cmdline = ['xmake', 'lua', s:path . '/spy.lua', '-o', tf, 'project']
    call job#start(cmdline, {'onout': {d->add(cache, d)}, 'onexit': funcref('LoadXCfg') })
endf
