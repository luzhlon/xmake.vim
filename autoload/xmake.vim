" =============================================================================
" Filename:     autoload/xmake.vim
" Author:       luzhlon
" Function:     xmake integeration
" Depends:      proc.vim
" Last Change:  2017/3/22
" =============================================================================

let s:job = 0       "xmake进程的pid
let s:run = 0       "构建成功后运行
let s:target = ''   "要构建的目标，留空则为all

"获取binary的target文件
fun! s:getbin()
    if empty(s:target)
        for tf in values(g:xcfg['targets'])
            if tf['targetkind'] == 'binary'
                return tf['targetfile']
            endif
        endfo
        return ''
    else
        let tf = g:xcfg['targets'][s:target]
        return tf['targetkind'] == 'binary' ? tf['targetfile'] : ''
    endif
endf
"返回target所占用的buffer number
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
"返回要保存的buffer number
fun! s:buf2save()
    if empty(s:target)
        let nrs = {}
        for tf in values(g:xcfg['targets'])
            call extend(nrs, s:targetbufs(tf))
        endfo
    else
        let nrs = s:targetbufs(g:xcfg['targets'][s:target])
    endif
    return keys(nrs)
endf
"构建之前保存文件
fun! s:savafiles()
    let n = bufnr('%')      "保存当前的buffer号
    let bufnrs = s:buf2save()
    for nr in bufnrs        "遍历项目文件，并保存
        exe nr . 'bufdo!' 'up'
    endfo
    "切换到原来的buffer
    exe 'b!' n
endf
"运行shell命令
fun! s:runsh(...)
    let p = join(a:000)
    if has('win32')
        exe '!start' p
    else
        exe '!./' p
    endif
endf
"检查是否已经存在s:job
fun! s:ChkPid()
    if job#running(s:job)
        echom 'a xmake task is running'
        return 0
    else
        return 1
    endif
endf
"检查是否加载了xmake configuration
fun! s:ChkXCfg()
    if exists('g:xcfg')
        return 1
    else
        echom 'not load xmake configuration'
        return 0
    endif
endf
"调用xmake构建项目
fun! xmake#buildrun(run)
    if !s:ChkXCfg() | return | endif
    if !s:ChkPid() | return | endif
    "保存项目文件
    call s:savafiles()
    let run = a:run
    let bin = s:getbin()
    fun! OnQuit(job, code) closure
        if a:code    "如果出错则打开quickfix修正错误
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
    "启动xmake运行
    let s:job = job#start(['xmake build', s:target], {
                \ 'onout': funcref('job#cb_add2qf'),
                \ 'onerr': funcref('job#cb_add2qf'),
                \ 'onexit': funcref('OnQuit')})
endf
"后台运行xmake命令
fun! xmake#xmake(args)
    if !s:ChkPid() | return | endif
    cexpr ''
    let opts = { 'onout': funcref('job#cb_add2qf') }
    if a:args =~ '^\s*config'
        let opts.onexit = {job, code -> xmake#load()}
    endif
    let s:job = job#start('xmake ' . a:args, opts)
endf

fun! s:onLoaded(...)
    echo 'loaded xmake configuration'
    "设置窗口标题为项目名
    set title
    let config = g:xcfg.config
    let &titlestring = join([g:xcfg['project'], config.mode, config.arch], ' - ')
    redraw
endf

let s:path = expand('<sfile>:p:h')
fun! xmake#load()
    let cache = []
    fun! LoadXCfg(job, code) closure
        try
            let m = join(cache)
            let g:xcfg = eval(m)
            call s:onLoaded()
        catch
            call log#info(m)
            echo 'load xmake configuration failure'
        endt
    endf
    call job#start(['xmake lua', s:path . '/putconfig.lua'], {
                \ 'onout': {job, d->add(cache, d)},
                \ 'onexit': funcref('LoadXCfg')})
endf
