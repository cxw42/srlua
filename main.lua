-- main.lua: Bootstrapper for Swiss
-- Copyright (c) 2018 Chris White.  CC-BY-SA 3.0.

local S = require 'swiss'
local lfs = require 'lfs'

print('Payload is',S.payload_fullname,'in dir',S.payload_dir)

local ok, errmsg = pcall(S.make_temp_dir)
if ok then
    print('Created temp dir',errmsg)
    lfs.rmdir(errmsg)
else
    print('Could not create temp dir:', errmsg)
end

os.remove(S.payload_fullname)
-- vi: set ts=4 sts=4 sw=4 et ai fo-=ro ff=unix: --
