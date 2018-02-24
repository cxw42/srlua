-- atexit2.lua: atexit with some extras.  Also defines assert2().
-- Copyright (c) Chris White 2018.  CC-BY 3.0.

local exit_handlers = {}

--- Register #h as an exit handler
function atexit2(h)  -- GLOBAL
    exit_handlers[#exit_handlers + 1] = h
end

--- As assert(), but you can add text to the error message.
--- If its second argument is falsy, call error(), and include #reason
--- in the message.  Otherwise, return all arguments except #reason.
function assert2(reason, ...)
    local arg = table.pack(...)
    local ok = arg[1]

    if not ok then
        -- empty rather than 'nil'
        if not reason then reason = '' end

        local errmsg = tostring(reason)

        if errmsg:len() > 0 and arg.n >= 2 then
            errmsg = errmsg .. ': '
        end
        if arg.n > 1 then       -- what was called gave us an error object
            errmsg = errmsg .. tostring(arg[2])
        end

        if errmsg:len() == 0 then       -- just in case
            errmsg = 'assertion failed!'
        end

        error(errmsg, 2)    -- 2 => show the caller's file and line number
    end

    return ...  -- not the reason
end --assert2()

--- Run the exit handlers.  Always succeeds.
--- @return An empty string on success, or error messages on failure.
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

return {
    atexit2 = atexit2,  -- in addition to the global
    assert2 = assert2,  -- in addition to the global
    do_exit = do_exit
}

-- vi: set ts=4 sts=4 sw=4 et ai fo-=ro ff=unix: --
