
call job#cb#init()

if has('nvim')
else
fun! s:iconv(data)
    return iconv(a:data, 'gbk', 'utf-8')
endf
" 启动一个job
fun! job#start(cmd, opt)
    let opts = { 'out_mode': 'raw', 'err_mode': 'raw' }
    if has_key(a:opt, 'onout')
        let OUTCB = a:opt['onout']
        let opts['out_cb'] = {job, out->OUTCB(job, s:iconv(out))}
    endif
    if has_key(a:opt, 'onerr')
        let ERRCB = a:opt['onerr']
        let opts['err_cb'] = {job, out->ERRCB(job, s:iconv(out))}
    endif
    if has_key(a:opt, 'onexit')
        let EXITCB = a:opt['onexit']
        let opts.close_cb = {ch->
            \ call({job->EXITCB(job,job_info(job)['exitval'])}, [ch_getjob(ch)])}
    endif
    return job_start(a:cmd, opts)
endf
" job是否正在运行
fun! job#running(job)
    try
        return job_status(a:job) == 'run'
    catch
        return 0
    endt
endf
endif
