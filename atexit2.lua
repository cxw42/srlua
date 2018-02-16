-- atexit2.lua: atexit with some extras
-- Copyright (c) Chris White 2018.  CC-BY 3.0.

local exit_handlers = {}

function atexit2(h)  -- GLOBAL
    exit_handlers[#exit_handlers + 1] = h
end

function do_exit()
    local errmsgs = ''
    for i=#exit_handlers, 1, -1 do
        --print('Calling exit handler',i)
        local ok, errmsg = pcall(exit_handlers[i])
        if not ok then
            --print('Error in handler', i, errmsg)
            errmsgs = errmsgs .. errmsg .. '\n'
        end
    end
    return errmsgs
end --do_exit()

-- TODO implement transactions

return { do_exit = do_exit }

-- vi: set ts=4 sts=4 sw=4 et ai fo-=ro ff=unix: --
