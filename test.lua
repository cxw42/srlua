#!/usr/local/bin/lua

package.path=''
package.cpath=''
---- test srlua
local print_r = require('print_r')
print('print_r',print_r)
print('package.path',package.path)
print('package.cpath',package.cpath)
--print('Package before load')
--print_r(package)
local zip = require('brimworks.zip')
--print(zip)
print_r(zip)
--print('Package after load')
--print_r(package)
--
--print("hello from inside "..arg[0])
--print(#arg,...)
--print"bye!"
--
--print("hello again from inside "..arg[0])
--for i=0,#arg do
--  print(i,arg[i])
--end

--if #arg < 1 then
--    return
--end

local z = zip.open('test2.zip')
local last_file_idx = #z
for file_idx=1,last_file_idx do
    --local file = z:open(file_idx)
    --file:close()
    local stat = z:stat(file_idx)
    print('File idx',file_idx)
    print_r(stat)
end

z:close()

-- lfs example, from https://keplerproject.github.io/luafilesystem/examples.html
local lfs = require 'lfs'

function attrdir (path)
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local f = path..'/'..file
            print ("\t "..f)

            local attr = lfs.attributes (f)
            assert (type(attr) == "table")
            if attr.mode == "directory" then
                attrdir (f)
            else
                --[[
                for name, value in pairs(attr) do
                    print (name, value)
                end
                --]]
            end
        end
    end
end

attrdir "."


print_r(package.loaded)
print"bye now!"

-- vi: set ts=4 sts=4 sw=4 et ai: --
