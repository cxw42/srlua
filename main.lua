-- main.lua: Bootstrapper for Swiss
-- Copyright (c) 2018 Chris White.  CC-BY-SA 3.0.

-- atexit2, swiss, print_r, lfs are already in the global space
local zip = require('brimworks.zip')

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

-- Strip trailing delimiter, which causes lfs.attributes() to fail
function chompdelim(fn)
    if string.sub(fn, -1) == [[/]] or string.sub(fn, -1) == [[\]] then
        fn = string.sub(fn, 1, -2)
    end
    return fn
end

function rimraf(dirname, verbose)
    local attrs

    dirname = chompdelim(dirname)

    -- Sanity check: rimraf(filename) just removes that file
    attrs, errmsg = lfs.attributes(dirname)
    if not attrs then
        error('Could not access ' .. dirname .. ': ' .. errmsg)
    end

    if attrs.mode ~= 'directory' then
        if verbose then print('Removing',attrs.mode,dirname) end
        ok, errmsg = os.remove(dirname)
        if not ok then error('Could not delete ' .. dirname .. ': ' .. errmsg) end
        return
    end

    if verbose then print('Removing extracted files in',dirname) end

    for fn in lfs.dir(dirname) do
        if fn ~= '.' and fn ~= '..' then
            if verbose then print('Processing',fn) end

            -- Need absolute path names since we're not doing chdir
            fn = dirname .. '/' .. fn
            attrs, errmsg = lfs.attributes(fn)
            if not attrs then
                error('Could not access ' .. fn .. ': ' .. errmsg)
            end

            if verbose then print('Cleanup', attrs.mode, fn) end
            if attrs.mode == 'directory' then
                rimraf(fn, verbose)
            else
                ok, errmsg = os.remove(fn)
                if not ok then error('Could not delete ' .. fn .. ': ' .. errmsg) end
            end
        end
    end --foreach file

    if verbose then print('Removing directory', dirname) end
    ok, errmsg = lfs.rmdir(dirname)
    if not ok then error('Could not remove ' .. dirname .. ': ' .. errmsg) end
end -- rimraf()

atexit2( function ()
    rimraf(G_tempdir, true)
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
    local destname = chompdelim(G_tempdir .. stat.name)
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

-- DEBUG
--print('Press enter to continue')
--io.read()

-- vi: set ts=4 sts=4 sw=4 et ai fo-=ro ff=unix: --
