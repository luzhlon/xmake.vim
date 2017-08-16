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
" Get the target's file path whoes kind is 'binary'
fun! s:getbin()
    if empty(s:target)
        for tf in values(g:xmproj['targets'])
            if tf['targetkind'] == 'binary'
                return tf['targetfile']
            endif
        endfo
        return ''
    else
        let tf = g:xmproj['targets'][s:target]
        return tf['targetkind'] == 'binary' ? tf['targetfile'] : ''
    endif
endf
" Get the bufnr about a target's sourcefiles and headerfiles
fun! s:targetbufs(t)
    let nrs = {}
    for i in a:t['sourcefiles'] + a:t['headerfiles']
        let n = bufnr(i)
        if n > 0 && getbufvar(n, 'mod') | let nrs[n] = 1 | endif
    endfo
    return nrs
endf
" Get the bufnrs to save
fun! s:buf2save()
    if empty(s:target)
        let nrs = {}
        for tf in values(g:xmproj['targets'])
            call extend(nrs, s:targetbufs(tf))
        endfo
    else
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
fun! s:runsh(...)
    let p = join(a:000)
    if has('win32')
        exe '!start' p
    else
        exe '!./' p
    endif
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
fun! xmake#buildrun(run)
    if s:notLoaded() | return | endif
    if s:isRunning() | return | endif
    call s:savafiles()          " save files about the target to build
    let run = a:run
    let bin = s:getbin()
    fun! OnQuit(job, code) closure
        if a:code               " open the quickfix if any errors
            echo 'build failure'
            copen
        else
            echo 'build success'
            if run
                if empty(bin)
                    echo 'Not a binary'
                else
                    call s:runsh(bin)
                endif
            endif
        endif
    endf
    cexpr ''
    " startup the xmake
    let s:job = job#start(['xmake', 'build', s:target], {
                    \ 'onout': funcref('job#cb_add2qf'),
                    \ 'onerr': funcref('job#cb_add2qf'),
                    \ 'onexit': funcref('OnQuit')})
endf
" Interpret XMake command
fun! xmake#xmake(...)
    if !a:0                             " building all targets without running
        let s:target = ''
        call xmake#buildrun(0)
    elseif a:1 == 'run' || a:1 == 'r'   " building && running
        if a:0 > 1 | let s:target = a:2 | endif
        call xmake#buildrun(1)
    elseif a:1 == 'build'               " building specific target
        if a:0 > 1 | let s:target = a:2 | endif
        call xmake#buildrun(0)
    else                                " else xmake's commands
        if s:isRunning() | return | endif
        cexpr ''
        let opts = { 'onout': funcref('job#cb_add2qf') }
        if a:1 == 'config' || a:1 == 'f'
            let opts.onexit = {job, code -> xmake#load()}
        endif
        let s:job = job#start(['xmake'] + a:000, opts)
    endif
endf

fun! s:onLoaded(...)
    " Check the fields
    for t in values(g:xmproj['targets'])
        if empty(t.headerfiles)
            let t.headerfiles = []
        endif
        if empty(t.sourcefiles)
            let t.sourcefiles = []
        endif
    endfo
    echohl Define
    echom "XMake-Project loaded successfully"
    echohl
    set title
    let config = g:xmproj.config
    let &titlestring = join([g:xmproj['name'], config.mode, config.arch], ' - ')
    redraw
endf

let s:path = expand('<sfile>:p:h')
fun! xmake#load()
    let cache = []
    fun! LoadXCfg(job, code) closure
        try
            let l = split(join(cache, ''), '[\r\n]\+')
            let g:xmproj = json_decode(l[0])
        catch
            cexpr ''
            cadde "XMake-Project loaded unsuccessfully:"
            " cadde v:errmsg
            cadde l | copen
            return
        endt
        call s:onLoaded()
    endf
    call job#start(['xmake lua', s:path . '/spy.lua', 'project'], {
                \ 'onout': {job, d->add(cache, d)},
                \ 'onexit': funcref('LoadXCfg')})
endf
