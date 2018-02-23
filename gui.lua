-- gui.lua: GUI framework for Swiss
-- Copyright (c) 2018 Chris White.  CC-BY-SA 3.0.

-- atexit2, print_r, lfs, checks are already in the global space

local fl = require 'fltk4lua'
local original_print = _G.print
local window = nil
local browser = nil

local function start_gui()
    original_print('Starting GUI', InvokedAs)
    window = fl.Window( 640, 480, InvokedAs)
    if not window then error('Could not create window') end
    do  -- window elements

        -- TODO create a wizard here, and make the browser the first child
        -- of the wizard.
        do
            -- The console output
            browser = fl.Browser{20, 20, 640-40, 480-100}
                                    --type='FL_MULTI_BROWSER'
            if not browser then error('Could not create browser') end
        end

        -- A divider
        local box = fl.Box{ 20, 440, 640-40, 2, "", box = "FL_UP_BOX" }
        if not box then error('Could not create box') end

        -- Buttons
        -- TODO
        local button = fl.Button{ 640-100, 440+10, 40, 20, "Button" }
        if not box then error('Could not create button') end

        window:end_group()
    end

    window:show()
    --original_print 'GUI running'
    fl.check()
end

local function sprintf(...)
    --original_print('sprintf>', ...)
    local args=table.pack(...)
    local retval = ''
    if args.n == 0 then
        return ''
    end

    retval = tostring(args[1])
    for idx=2,args.n do
        retval = retval .. '\t' .. tostring(args[idx])
    end

    return retval
end --sprintf

local function output(...)
    if not window then start_gui() end

    local s = sprintf(...)
    --original_print('>',s)    --DEBUG
    -- Split at \n's because the browser doesn't handle them automatically
    for line in string.gmatch(s, '([^\n]*)') do
        browser:add(line)
    end
    browser.bottomline = browser.nitems
    fl.check()
end

return { start = start_gui, output = output, original_print = original_print }

-- vi: set ts=4 sts=4 sw=4 et ai fo-=ro ff=unix: --
