import 'core.project.project'
import 'core.project.config'
import 'core.base.option'

local function tojson(t)
    if type(t) == 'table' then
        local list = {}
        if t[1] then
            for i = 1, #t do
                list[i] = tojson(t[i])
            end
            return table.concat({'[', table.concat(list, ','), ']'})
        else
            for k, v in pairs(t) do
                table.insert(list, tojson(k) .. ':' .. tojson(v))
            end
            return table.concat({'{', table.concat(list, ','), '}'})
        end
    end
    local tt = type(t)
    if tt == 'string' then
        t = t:gsub('[\\\n\r\t"]', {
            ['\\'] = '\\\\', ['\n'] = '\\n',
            ['\t'] = '\\t', ['"'] = '\\"', ['\r'] = '\\r'
        })
        return '"' .. t .. '"'
    elseif tt == 'nil' then
        return 'null'
    else            -- number or boolean
        return tostring(t)
    end
end

local funcs = {
    config = function(args)
        config.load()
        project.load()
        -- os.cd(project.directory())
        -- project's configuration
        local xconfig = {
            config = {
                arch = config:arch(),
                plat = config:plat(),
                mode = config:mode()
            },
            -- project's name
            name = project.name() or '<unamed>',
            -- project's version
            version = project.version(),
            -- project's targets
            targets = {}
        }
        -- read the configuration of all targets
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
        -- output
        print(tojson(xconfig))
    end,
    getenv = function(args)
        print(os.getenv(args[2]))
    end
}

function main(...)
    local args = {...}
    local func = funcs[args[1]]
    if func then func(args) end
end
