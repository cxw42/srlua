-- gui.lua: GUI framework for Swiss
-- Copyright (c) 2018 Chris White.  CC-BY-SA 3.0.

-- atexit2, print_r, lfs, checks are already in the global space

local fl = require 'fltk4lua'
local original_print = _G.print
local window
local browser

local function start_gui()
    original_print('Starting GUI')
    window = fl.Window( 640, 480, InvokedAs)
    if not window then error('Could not create window') end

--    local box = fl.Box{ 20, 40, 300, 100, "Hello World!",
--      box = "FL_UP_BOX", labelfont = "FL_HELVETICA_BOLD_ITALIC",
--      labelsize = 36, labeltype = "FL_SHADOW_LABEL"
--    }
--    if not box then error('Could not create box') end

--    Fl_Text_Buffer *buff = new Fl_Text_Buffer();
--     Fl_Text_Display *disp = new Fl_Text_Display(20, 20, 640-40, 480-40, "Display");
--     disp->buffer(buff);
--     win->resizable(*disp);
--     win->show();
--     buff->text("line 0\nline 1\nline 2\n"
--                "line 3\nline 4\nline 5\n"
--                "line 6\nline 7\nline 8\n"
--                "line 9\nline 10\nline 11\n"
--                "line 12\nline 13\nline 14\n"
--                "line 15\nline 16\nline 17\n"
--                "line 18\nline 19\nline 20\n"
--                "line 21\nline 22\nline 23\n");

--    local scroller = fl.Scroll{20, 20, 640-40, 480-40, '', type = fl.BOTH}
--
--    local box = fl.Box{
--        0,0,800,600, "Hello, world!\nLine 2"
--                }
--
--    scroller:end_group()

    browser = fl.Browser{20, 20, 640-40, 480-40, type='FL_MULTI_BROWSER'}
    browser:add('foo')
    browser:add('bar')

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
    browser:add(s)
    --fl.check()
end

return { start = start_gui, output = output, original_print = original_print }

-- vi: set ts=4 sts=4 sw=4 et ai fo-=ro ff=unix: --
