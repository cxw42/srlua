-- gui.lua: GUI framework for Swiss
-- Copyright (c) 2018 Chris White.  CC-BY-SA 3.0.

-- atexit2, print_r, lfs, checks, swiss are already in the global space

local fl = require 'fltk4lua'
local original_print = _G.print
local window

local function start_gui()
    original_print('Starting GUI')
    window = fl.Window( 640, 480, swiss.invoked_as );
    if not window then error('Could not create window') end

    local box = fl.Box{ 20, 40, 300, 100, "Hello World!",
      box = "FL_UP_BOX", labelfont = "FL_HELVETICA_BOLD_ITALIC",
      labelsize = 36, labeltype = "FL_SHADOW_LABEL"
    }
    if not box then error('Could not create box') end

    window:end_group()

    window:show()
    original_print 'GUI running'
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
    local s = sprintf(...)
    -- TODO output to the text_display
    -- TODO damage the text_display
    original_print('>',s)    --DEBUG
    --fl.check()
end

return { start = start_gui, output = output, original_print = original_print }

-- vi: set ts=4 sts=4 sw=4 et ai fo-=ro ff=unix: --
