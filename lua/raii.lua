-- raii.lua
-- From http://lua-users.org/wiki/ResourceAcquisitionIsInitialization
-- I think this code is by John Belmonte.
-- Modified by Chris White in 2018 to test for metatable close() method.
-- Chris's changes to this file are licensed CC0.
-- The license for the original is unknown.

local M = {}

local frame_marker = {} -- unique value delimiting stack frames

local running = coroutine.running

--- Return the "close" member of #0, if there is one.
--- A separate function so you can use pcall.  E.g., `(42).foo` will
--- error() out if there is no metatable for numbers.
local function get_close(o)
  return o.close
end

-- Close current stack frame for RAII, releasing all objects.
-- @input e {optional} Error object
local function close_frame(stack, e)
  assert(#stack ~= 0, 'RAII stack empty')
  for i=#stack,1,-1 do  -- release in reverse order of acquire
    local v; v, stack[i] = stack[i], nil
    if v == frame_marker then
      break
    else
      -- note: assume finalizer never raises error
      local has_close = pcall(get_close, v)
      if has_close then
        v:close()
      elseif v then
        --print('Disposing value', debug.traceback())
        --print 'Value'
        --print_r(v)
        --print 'Metatable'
        --print_r(mt)
        v(e)
        --print('Successful')
      -- else v was falsy, so do nothing.
      end
    end -- v~=frame_marker
  end --foreach stack item
end --close_frame()

local function helper1(stack, ...) close_frame(stack); return ... end

-- Allow self to be used as a function modifier
-- to add RAII support to function.
function M.__call(self, f)
  return function(...)
    local stack, co = self, running()
    if co then  -- each coroutine gets its own stack
      stack = self[co]
      if not stack then
        stack = {}
        self[co] = stack
      end
    end
    stack[#stack+1] = frame_marker -- new frame
    return helper1(stack, f(...))
  end
end

-- Show variables in all stack frames.
function M.__tostring(self)
  local stack, co = self, running()
  if co then stack = stack[co] end
  local ss = {}
  local level = 0
  for i,val in ipairs(stack) do
    if val == frame_marker then
      level = level + 1
    else
      ss[#ss+1] = string.format('[%s][%d] %s', tostring(co), level, tostring(val))
    end
  end
  return table.concat(ss, '\n')
end

local function helper2(stack, level, ok, ...)
  local e; if not ok then e = select(1, ...) end
  while #stack > level do close_frame(stack, e) end
  return ...
end

-- Construct new RAII stack set.
function M.new()
  local self = setmetatable({}, M)

  -- Register new resource(s), preserving order of registration.
  function self.scoped(...)
    local stack, co = self, running()
    if co then stack = stack[co] end
    for n=1,select('#', ...) do
      stack[#stack+1] = select(n, ...)
    end
    return ...
  end

  -- a variant of pcall
  -- that ensures the RAII stack is unwound.
  function self.pcall(f, ...)
    local stack, co = self, running()
    if co then stack = stack[co] end
    local level = #stack
    return helper2(stack, level, pcall(f, ...))
  end

  -- Note: it's somewhat convenient having scoped and pcall be
  -- closures....  local scoped = raii.scoped

  return self
end

-- singleton.
local raii = M.new()

return raii
-- vi: set ts=2 sts=2 sw=2 et ai fo-=ro ff=unix: --
