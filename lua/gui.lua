-- gui.lua: GUI framework for Swiss
-- Copyright (c) 2018 Chris White.  CC-BY-SA 3.0.

-- atexit2, print_r, lfs, checks are already in the global space

local fl = require 'fltk4lua'
local original_print = _G.print
local window = nil
local browser = nil
local wizard = nil

local function start_gui()
    original_print('Starting GUI', InvokedAs)
    do  -- window elements
        window = assert(fl.Window( 640, 480, InvokedAs))

        do  -- create a wizard
            local wx, wy, ww, wh = 20, 20, 640-40, 480-100
            wizard = assert(fl.Wizard(wx, wy, ww, wh))

            do  -- The console output as the first child of the wizard
                local g = fl.Group(wx, wy, ww, wh)
                browser = assert(fl.Browser{20, 20, 640-40, 480-100,
                                        type='FL_SELECT_BROWSER'})
                g:end_group()
            end

            do  -- Second page: currently a placeholder
                local g = fl.Group(wx, wy, ww, wh)

                local o = fl.Input( wx+20, wy+20, ww-40, wh-40, "Welcome" )
                o.type = "FL_MULTILINE_OUTPUT"
                o.labelsize = 20
                o.align = fl.ALIGN_TOP + fl.ALIGN_LEFT
                o.value = "This is the second page"

                g:end_group()
            end

            wizard:end_group()
        end

        -- A divider
        local box = fl.Box{ 20, 420, 640-40, 2, "", box = "FL_UP_BOX" }
        if not box then error('Could not create box') end

        -- Buttons
        local button

        -- Cancel
        button = assert(fl.Button{ 20, 435, 80, 30, "&Cancel" })
        function button:callback() window:hide() end

        -- Prev
        button = assert(fl.Button{ 640-200, 435, 80, 30, "@< &Previous" })
        function button:callback() wizard:prev() end

        -- Next
        button = assert(fl.Button{ 640-100, 435, 80, 30, "&Next @>" })
        function button:callback() wizard:next() end

    end
    window:end_group()

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
