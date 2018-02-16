-- gui.lua: GUI framework for Swiss
-- Copyright (c) 2018 Chris White.  CC-BY-SA 3.0.

-- atexit2, print_r, lfs, checks are already in the global space

local function start_gui()
    print('Starting GUI')
end

return { start = start_gui }

-- vi: set ts=4 sts=4 sw=4 et ai fo-=ro ff=unix: --
