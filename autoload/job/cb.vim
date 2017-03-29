" 初始化callback库
fun! job#cb#init()
    if !exists('s:init')
        let s:init = 1
    endif
endf
"将数据添加到quickfix
fun! job#cb#add2qf(job, d)
    cadde a:d
endf
"将数据添加到quickfix，并滚动到最下面
fun! job#cb#add2qfb(job, d)
    cadde a:d
    cbottom
endf
