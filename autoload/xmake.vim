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
try
    for i in a:t['sourcefiles']
        let n = bufnr(i)
        if n > 0|let nrs[n] = 1|endif
    endfo
    for i in a:t['headerfiles']
        let n = bufnr(i)
        if n > 0|let nrs[n] = 1|endif
    endfo
catch
endt
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
fun! s:checkRunning()
    if job#running(s:job)
        echom 'a xmake task is running'
        return 0
    else
        return 1
    endif
endf
" If loaded the xmake's configuration
fun! s:checkXConfig()
    if exists('g:xmproj')
        return 1
    else
        echom 'not load xmake configuration'
        return 0
    endif
endf
" Building by xmake
fun! xmake#buildrun(run)
    if !s:checkXConfig() | return | endif
    if !s:checkRunning() | return | endif
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
                    echo 'targetfile unkown'
                else
                    call s:runsh(bin)
                endif
            endif
        endif
    endf
    cexpr ''
    " startup the xmake
    let s:job = job#start(['xmake build', s:target], {
                \ 'onout': funcref('job#cb_add2qf'),
                \ 'onerr': funcref('job#cb_add2qf'),
                \ 'onexit': funcref('OnQuit')})
endf
" Run xmake in the background
fun! xmake#xmake(args)
    if !s:checkRunning() | return | endif
    cexpr ''
    let opts = { 'onout': funcref('job#cb_add2qf') }
    if a:args =~ '^\s*config'
        let opts.onexit = {job, code -> xmake#load()}
    endif
    let s:job = job#start('xmake ' . a:args, opts)
endf

fun! s:onLoaded(...)
    echohl Define
    echom "Loaded xmake's configuration successfully"
    set title
    let config = g:xmproj.config
    let &titlestring = join([g:xmproj['name'], config.mode, config.arch], ' - ')
    redraw
    echohl
endf

let s:path = expand('<sfile>:p:h')
fun! xmake#load()
    let cache = []
    fun! LoadXCfg(job, code) closure
        try
            let m = split(join(cache, ''), '[\r\n]')[0]
            let g:xmproj = eval(m)
            call s:onLoaded()
        catch
            echohl WarningMsg
            cexpr m | copen
            echom "Loaded xmake's configuration unsuccessfully"
            echohl
        endt
    endf
    call job#start(['xmake lua', s:path . '/spy.lua', 'config'], {
                \ 'onout': {job, d->add(cache, d)},
                \ 'onexit': funcref('LoadXCfg')})
endf
