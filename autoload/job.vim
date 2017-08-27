" =============================================================================
" Filename:     plugin/job.vim
" Author:       luzhlon
" Function:     Job utils on vim8 and neovim
" Last Change:  2017/4/23
" =============================================================================

if has('win32')
fun! s:iconv(data)
    return iconv(a:data, 'gbk', 'utf-8')
endf
else
fun! s:iconv(data)
    return a:data
endf
endif

if has('nvim')
fun! job#start(cmd, opt)
    let opts = {}
    if has_key(a:opt, 'onout')
        let OUTCB = a:opt['onout']
        if type(OUTCB)==1|let OUTCB = funcref(OUTCB)|endif
        let opts.on_stdout = {i, d, e->
                    \ map(copy(d), {i,v->OUTCB(i, s:iconv(v))})}
    endif
    if has_key(a:opt, 'onerr')
        let ERRCB = a:opt['onerr']
        if type(ERRCB)==1|let ERRCB = funcref(ERRCB)|endif
        let opts.on_stderr = {i, d, e->
                    \ map(copy(d), {i,v->ERRCB(i, s:iconv(v))})}
    endif
    if has_key(a:opt, 'onexit')
        let EXITCB = a:opt['onexit']
        let opts.on_exit = {i, d, e->EXITCB(i, d)}
    endif
    return jobstart(a:cmd, opts)
endf
" If job start successfully
fun! job#success(job)
    return a:job > 0
endf
" If job is running
fun! job#running(job)
    try|return jobpid(a:job) > 0
    catch|return 0|endt
endf
else            " For vim8.0+
fun! s:checkdead(job, cb, tid)
    if job_status(a:job) == 'dead'
        call timer_stop(a:tid)
        call a:cb(a:job, job_info(a:job)['exitval'])
    endif
endf
fun! s:onexit(cb, ch)
    let job = ch_getjob(a:ch)
    call assert_true(job_status(job) == 'dead', 'ASSERT')
    call a:cb(job, job_info(job)['exitval'])
endf
" Start a new job
fun! job#start(cmd, opt)
    let opts = { 'out_mode': 'raw', 'err_mode': 'raw' }
    if has_key(a:opt, 'onout')
        let OUTCB = a:opt['onout']
        if type(OUTCB)==1|let OUTCB = funcref(OUTCB)|endif
        let opts.out_cb = {job, out->OUTCB(job, s:iconv(out))}
    endif
    if has_key(a:opt, 'onerr')
        let ERRCB = a:opt['onerr']
        if type(ERRCB)==1|let ERRCB = funcref(ERRCB)|endif
        let opts.err_cb = {job, out->ERRCB(job, s:iconv(out))}
    endif
    if has_key(a:opt, 'onexit')
        let EXITCB = a:opt['onexit']
        let opts.close_cb = funcref('s:onexit', [function(EXITCB)])
    endif
    return job_start(a:cmd, opts)
endf
" If job start successfully
fun! job#success(job)
    return job_status(a:job) != 'fail'
endf
" If job is running
fun! job#running(job)
    try
        return job_status(a:job) == 'run'
    catch
        return 0
    endt
endf
endif

fun! job#cb_add2qf(job, d)
    cadde a:d
endf
fun! job#cb_add2qfb(job, d)
    cadde a:d
    cbottom
endf
