-- util.lua: Utilities for swiss
-- Copyright (c) Chris White 2018

raii = require 'raii'
local scoped, pcall = raii.scoped, raii.pcall

--- Strip trailing delimiter.  E.g., lfs.attributes() can't handle them on
--- filenames.  Default delimiter is either '/' or '\\'.
--- @input str {string} The fil
local function chompdelim(str, delim)
    checks('string','?string')
    local has_delim, delim_len
    if not delim then
        delim_len = 1
        has_delim = ( str:sub(-1) == [[/]] or str:sub(-1) == [[\]] )
    else
        delim_len = delim:len()
        has_delim = ( str:sub(-delim_len) == delim )
    end
    if has_delim then
        str = str:sub(1, -(delim_len+1))
    end
    return str
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

--- Unzip file #file_idx from open brimworks.zip #zipfile into #dest_dir.
--- @input zipfile {brimworks.zip}
--- @input file_idx {number} Must be a valid index in #zipfile
--- @input dest_dir {string} Must end with a terminator ('/' or '\\')
local unzip_file = raii(function(zipfile, file_idx, dest_dir, verbose)
    local srcfd = scoped(assert(zipfile:open(file_idx)))

    local stat = zipfile:stat(file_idx)
    local size = stat.size
    local destname = chompdelim(dest_dir .. stat.name)
    if verbose then print('Extracting ' .. stat.name) end

    if size==0 then     -- directory
        if verbose then print('Creating dir ' .. destname) end
        lfs.mkdir(destname)

    else                -- file
        if verbose then print('Extracting file ' .. destname) end
        local outfd = scoped(assert(io.open(destname, 'wb')))
        local dat = assert(srcfd:read(size))
        assert(outfd:write(dat))
    end
    -- raii closes srcfd and outfd
end) --unzip_file

--- Unzip everything in ZIP file #zip_filename into #dest_dir
local unzip_all = raii(function(dest_dir, zip_filename, verbose)
    checks('string','string', '?boolean')
    local zip = require('brimworks.zip')

    dest_dir = chompdelim(dest_dir) .. '/'  -- regularize

    local zipfile = scoped(assert(zip.open(zip_filename)))
    print_r({zipfile=zipfile})
    if verbose then print('Extracting ZIP '..zip_filename) end

    for file_idx=1,#zipfile do
        unzip_file(zipfile, file_idx, dest_dir, verbose)
    end --foreach file in the ZIP

end) --unzip_all()

return {
    chompdelim = chompdelim,
    rimraf = rimraf,
    make_payload_runner = make_payload_runner,
    unzip_all = unzip_all,
}

-- vi: set ts=4 sts=4 sw=4 et ai fo-=ro ff=unix: --
