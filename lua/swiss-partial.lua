-- swiss-partial.lua: Parts of package `swiss` that are defined in Lua
-- rather than in C.
-- For safety, do not assume that any packages are in the global namespace.
-- Returns a table; all values from the table are copied into the `swiss` pkg.
-- Copyright (c) 2018 Chris White

--- Register a program in the "Add/Remove Programs" list
--- TODO implement
local function register_program(opts)
    local print_r = require 'print_r'
    print("Hello from not-yet-implemented swiss.register_program!")
    print_r(opts)
end --register_program

return {
    register_program = register_program
}

-- vi: set ts=4 sts=4 sw=4 et ai fo-=ro ff=unix: --
