-- util.lua: Utilities for swiss
-- Copyright (c) Chris White 2018

raii = require 'raii'
local scoped, pcall = raii.scoped, raii.pcall

--- Strip trailing delimiter, which causes lfs.attributes() to fail
local function chompdelim(fn)
    if string.sub(fn, -1) == [[/]] or string.sub(fn, -1) == [[\]] then
        fn = string.sub(fn, 1, -2)
    end
    return fn
end --chompdelim()

--- rm -rf #dirname
local function rimraf(dirname, verbose)
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

--- Do what glue.c does: make a new EXE that has the given payload
local make_payload_runner = raii(function(dest_filename, payload_filename)

    -- Arg checks
    checks('string', 'string')
    if dest_filename:len() <= 0 then error('Need a dest_filename') end
    if payload_filename:len() <= 0 then error('Need a payload_filename') end

    local exefd, payloadfd, outfd, errmsg, dat, _

    exefd = scoped(assert(io.open(swiss.exe_fullname, 'rb')))
    payloadfd = scoped(assert(io.open(payload_filename, 'rb')))
    outfd = scoped(assert(io.open(dest_filename, 'wb')))

    dat = assert(exefd:read(swiss.exe_core_size), 'Could not read the EXE')

    assert(outfd:write(dat))

    dat = assert(payloadfd:read('a'), 'Could not read the payload')
    local payload_len = dat:len()

    assert(outfd:write(dat))

    outfd:write(swiss.make_glue_record(swiss.exe_core_size, payload_len))
end) --make_payload_runner()

return {
    chompdelim = chompdelim,
    rimraf = rimraf,
    make_payload_runner = make_payload_runner
}

-- vi: set ts=4 sts=4 sw=4 et ai fo-=ro ff=unix: --
