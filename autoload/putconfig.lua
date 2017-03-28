--将一个表以python字典的格式打印出来，含有数字项的将被识别为列表
local function dump2py(t)
    local print = printf
    if type(t) == 'table' then
        if t[1] then
            print('[') dump2py(t[1])
            for i = 2, #t do
                print(', ') dump2py(t[i])
            end print(']')
        else
            print("{")
            local iter,_s,_v = pairs(t)
            local k,v = iter(_s, _v)
            _v = k if _v ~= nil then
                dump2py(k) print(':') dump2py(v)
                while true do
                    k,v = iter(_s, _v)
                    _v = k if _v == nil then break end
                    -- for in do --
                    print(',')
                    dump2py(k) print(':') dump2py(v)
                    -- for end --
                end
            end
            print("}")
        end
        return
    end
    local tt = type(t)
    if tt == 'string' then
        t = t:gsub('\\', '\\\\'):gsub('\n', '\\n'):gsub('\t', '\\t')
        print('"' .. t .. '"')
    elseif tt == 'number' then
        print('' .. t)
    elseif tt == 'number' then
        print(t and 'true' or 'false')
    elseif tt == 'nil' then
        print('null')
    end
end

function main()
    import "core.project.project"
    import "core.project.config"
    -- trace
    config.load()
    project.load('xmake.lua')
    os.cd(project.directory())

    local xconfig = {
        config = {
            arch = config:arch(),
            plat = config:plat(),
            mode = config:mode()
        },
        project = project.name(),
        targets = {}
    }

    for tname, target in pairs(project.targets()) do
        local tcfg = {}
        try { function ()
            tcfg.name        = target:name()
            tcfg.targetkind  = target:targetkind() or ''
            tcfg.sourcefiles = target:sourcefiles() or {}
            tcfg.headerfiles = target:headerfiles() or {}
            tcfg.targetfile  = target:targetfile() or '' end,
        catch { function(err)
            print(err)
        end}}

        xconfig.targets[tname] = tcfg
    end

    dump2py(xconfig)
end
