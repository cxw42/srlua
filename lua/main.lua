-- main.lua: Bootstrapper for Swiss.  Runs once the payload has been extracted.
-- Copyright (c) 2018 Chris White.  CC-BY-SA 3.0.

-- atexit2, swiss, print_r, lfs are already in the global space
local zip = require('brimworks.zip')
local util = require('util')
local winreg = require 'winreg'

--error('test error at the top')   -- for debugging

print('Running in ' .. (swiss.gui and 'GUI' or 'console') .. ' mode')
print('Payload is',swiss.payload_fullname,'in dir',swiss.payload_dir)

atexit2( function()
    print('Removing extracted payload', swiss.payload_fullname)
    os.remove(swiss.payload_fullname)
    --error('test error')   -- for debugging
end )

local ok, errmsg

-- Extract the payload to a temporary directory ----------------------
local M_tempdir
ok, M_tempdir = pcall(swiss.make_temp_dir)
if ok then
    print('Created temp dir', M_tempdir)
else
    error('Could not create temp dir:', M_tempdir)
end

atexit2( function ()
    util.rimraf(M_tempdir, true)
end)

util.unzip_all(M_tempdir, swiss.payload_fullname, true)

-- Don't need an atexit2() call to remove the extracted files, because the
-- rimraf() above will take care of it.

-- Find a Lua file in the extracted payload to run -------------------
local M_lua_filenames = {}

local function save_filename(fn, is_dir) --, unused_addrs, verbose
    if is_dir then return end
    if fn:find("%.[Ll][Uu][Aa]$") then
        table.insert(M_lua_filenames, fn)
    end
end --save_filename()

util.traverse_dir(M_tempdir, save_filename, {verbose=true})

table.sort(M_lua_filenames)
print_r{["Found filenames"]=M_lua_filenames}

-- Run the Lua file from the payload ---------------------------------
-- Note: cwd is still the directory under which the EXE was run.

-- Add the temp dir to the package path
if package.path and package.path:len()>0 then
    package.path = util.chompdelim(package.path, ';') .. ';'
end
package.path = package.path ..  M_tempdir .. '?.lua'
print('PATH', package.path)

-- run the file
if #M_lua_filenames > 0 then
    dofile(M_lua_filenames[1])
end

-- ========================================================================
-- DEBUG
--print('EXE core size', string.format('%d %x',swiss.exe_core_size, swiss.exe_core_size))
--util.make_payload_runner('extracted-exe.bin', 'test2.zip')
--print('Made extracted-exe.bin')
--
--if swiss.gui then
--    local gui = require 'gui'
--    print('Window',gui.window())
--    print('Wizard',gui.wizard())
--end
--print('Press enter to continue')
--io.read()

swiss.register_program{answer = 42}

-- vi: set ts=4 sts=4 sw=4 et ai fo-=ro ff=unix: --
