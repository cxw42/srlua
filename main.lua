-- main.lua: Bootstrapper for Swiss
-- Copyright (c) 2018 Chris White.  CC-BY-SA 3.0.

local S = require 'swiss'
--local lfs = require 'lfs'
local zip = require('brimworks.zip')

print('Payload is',S.payload_fullname,'in dir',S.payload_dir)

local ok, errmsg

local tempdir
ok, tempdir = pcall(S.make_temp_dir)
if ok then
    print('Created temp dir', tempdir)
else
    error('Could not create temp dir:', tempdir)
end

local z = nil -- the zip file that was the payload

local function cleanup()
    if z then z:close() end

    -- TODO remove the contents of S.payload_dir recursively
    for fn in lfs.dir(tempdir) do
        if fn ~= '.' and fn ~= '..' then 
            print('Cleanup',fn)
            os.remove(fn)
        end
    end

    lfs.rmdir(tempdir)

    os.remove(S.payload_fullname)
end

z, errmsg = zip.open(S.payload_fullname)

if not z then
    cleanup()
    error('Could not open payload ' .. S.payload_fullname .. ' as ZIP: ' ..
            errmsg)
end

local last_file_idx = #z
for file_idx=1,last_file_idx do
    local file, errmsg = z:open(file_idx)
    if errmsg then
        error('Could not open compressed file ' .. file .. ': ' .. errmsg)
    end

    local stat = z:stat(file_idx)
    local size = stat.size
    local destfn = S.payload_dir .. stat.name
    local dat = file:read()
    file:close()
    print('File idx',file_idx)
    print_r(stat)
end

cleanup()

-- vi: set ts=4 sts=4 sw=4 et ai fo-=ro ff=unix: --
