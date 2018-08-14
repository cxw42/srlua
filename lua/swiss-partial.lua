-- swiss-partial.lua: Parts of package `swiss` that are defined in Lua
-- rather than in C.
-- For safety, do not assume that any packages are in the global namespace.
-- Returns a table; all values from the table are copied into the `swiss` pkg.
-- Copyright (c) 2018 Chris White

--- Register a program in the "Add/Remove Programs" list
--- TODO implement
local print_r = require 'print_r'
local winreg = require 'winreg'
local raii = require 'raii'
local scoped, pcall = raii.scoped, raii.pcall

local register_program = raii(function(opts)
    print("Hello from not-yet-implemented swiss.register_program!")
    print_r(opts)

    -- test from winreg.chm, with raii added
    local hkey = scoped(assert(winreg.openkey[[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion]]))

    local skey = scoped(assert(hkey:openkey([[Explorer\Shell Folders]])))
    for name in skey:enumvalue() do
        print("\nname: " .. name
           .. "\npath: " .. skey:getvalue(name))
    end

end) --register_program

return {
    register_program = register_program
}

-- vi: set ts=4 sts=4 sw=4 et ai fo-=ro ff=unix: --
