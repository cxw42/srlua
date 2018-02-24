-- main.lua: Bootstrapper for Swiss
-- Copyright (c) 2018 Chris White.  CC-BY-SA 3.0.

-- atexit2, swiss, print_r, lfs are already in the global space
local zip = require('brimworks.zip')
local util = require('util')

--error('test error at the top')   -- for debugging

print('Running in ' .. (swiss.gui and 'GUI' or 'console') .. ' mode')
print('Payload is',swiss.payload_fullname,'in dir',swiss.payload_dir)

atexit2( function()
    print('Removing extracted payload', swiss.payload_fullname)
    os.remove(swiss.payload_fullname)
    --error('test error')   -- for debugging
end )

local ok, errmsg

local G_tempdir
ok, G_tempdir = pcall(swiss.make_temp_dir)
if ok then
    print('Created temp dir', G_tempdir)
else
    error('Could not create temp dir:', G_tempdir)
end

atexit2( function ()
    util.rimraf(G_tempdir, true)
end)

local G_z = nil -- the zip file that was the payload

G_z, errmsg = zip.open(swiss.payload_fullname)

if not G_z then
    error('Could not open payload ' .. swiss.payload_fullname .. ' as ZIP: ' ..
            errmsg)
end

atexit2(function()
    print('Closing zip file')
    G_z:close()
    G_z = nil
end)

local last_file_idx = #G_z
for file_idx=1,last_file_idx do
    local file, errmsg = G_z:open(file_idx)
    if errmsg then
        error('Could not open compressed file ' .. file .. ': ' .. errmsg)
    end

    local stat = G_z:stat(file_idx)
    local destname = util.chompdelim(G_tempdir .. stat.name)
    print('Extracting',stat.name)
    local size = stat.size
    if size==0 then
        print('Creating dir',destname)
        lfs.mkdir(destname)
    else
        print('Extracting file',destname)
        local dat = file:read(size)
        local outfd = io.open(destname, 'wb')
        if not outfd then error('Could not open ' .. destname .. ' for writing') end
        ok, errmsg = outfd:write(dat)
        if not ok then error('Could not write ' .. destname .. ': ' .. errmsg) end
        outfd:close()
    end

    file:close()
end

-- Don't need an atexit2() call to remove the extracted files, because the
-- rimraf() above will take care of it.

-- ========================================================================
-- DEBUG
--print('EXE core size', string.format('%d %x',swiss.exe_core_size, swiss.exe_core_size))
util.make_payload_runner('extracted-exe.bin', 'test2.zip')
print('Made extracted-exe.bin')
--print('Press enter to continue')
--io.read()

-- vi: set ts=4 sts=4 sw=4 et ai fo-=ro ff=unix: --
