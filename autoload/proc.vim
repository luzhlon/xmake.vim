py3 from proc import Process, procs
py3 _procs = procs

let s:t2p = {} "timer id到pid的映射
let s:cbr = {} "pid到read callbacks的映射
let s:cbq = {} "pid到quit callbacks的映射
"事件调度函数
fun! s:dispatch(t)
    if !has_key(s:t2p,a:t)|return|endif
    let pid = s:t2p[a:t]
    py3 _pr = _procs[int(vim.eval('pid'))]
    let d = py3eval('_pr.read()')
    if empty(d) 
        if py3eval('_pr.ended')     "子进程已经结束
            call timer_stop(a:t)    "停止当前定时器
            if has_key(s:cbq, pid)
                let CB = s:cbq[pid]
                call CB(0+py3eval('str(_pr.returncode)'))
            endif
            try                     "删除回调函数的映射
                py3 del _procs[int(vim.eval('pid'))]
                unlet s:t2p[a:t]|unlet s:cbr[pid]
                unlet s:cbq[pid]|catch|endt
        endif
    else                            "传入读取的数据回调函数
        if has_key(s:cbr, pid)
            let CB = s:cbr[pid] | call CB(d)
        endif
    endif
endf
"创建一个后台运行的进程，并返回pid
fun! proc#new(cmd)
    let t = type(a:cmd)
    if t == v:t_string
        let cmd = a:cmd
    elseif t == v:t_list
        let cmd = join(a:cmd)
    else
        echom 'invaild command'
        return
    endif
    return py3eval('Process(vim.eval("cmd")).pid')
endf

"设置进程为pid的onread事件，并开始读取进程的标准输出
fun! proc#onread(pid, cb)
    if !a:pid
        echom 'invaild pid'
        return
    endif
    let tid = timer_start(10,
             \funcref('s:dispatch'),
             \{'repeat':-1})
    let s:t2p[tid] = a:pid
    let s:cbr[a:pid] = a:cb
endf
"设置进程为pid的onquit事件
fun! proc#onquit(pid, cb)
    let s:cbq[a:pid] = a:cb
endf
"启动一个子进程，并指定事件处理器
fun! proc#start(cmd, read, quit)
    let pid = proc#new(a:cmd)
    if !pid | return 0 | endif
    call proc#onquit(pid, a:quit)
    call proc#onread(pid, a:read)
    return pid
endf
