
fun! s:CheckXMake()
    let dir = g:Proj.dir
    let f = dir . '/xmake.lua'
    if filereadable(f)
        call xmake#load()
    endif
endf

au User AfterProjLoaded call <SID>CheckXMake()
