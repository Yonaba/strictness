-- ================================================================
-- "strictness" tracks declaration and assignment of globals in Lua
-- Copyright (c) 2013 Roland Y., MIT License
-- v0.1.0 - compatible Lua 5.1, 5.2
-- ================================================================

local setmetatable = setmetatable
local getmetatable = getmetatable
local type = type
local assert = assert
local rawget = rawget
local rawset = rawset
local unpack = unpack
local error = error

-- ===================
-- Private helpers
-- ===================

-- Register for declared globals, defined as a table
-- with weak values.
local declared_globals = setmetatable({},{__mode = 'v'})

-- The global env _G metatable
local _G_mt

-- A custom error function
local function err(msg)  return error(msg, 3) end

-- Custom argument type assertion helper
local function assert_type(var, expected_type, argn)
  local var_type = type(var)
  assert(var_type == expected_type,
    ('Bad argument #%d to global (%s expected, got %s')
      :format(argn or 1, expected_type, var_type))
end

-- Checks in the register if the given global was declared
local function is_declared(varname)
  return declared_globals[varname]
end

-- ==========================
-- Module exported functions
-- ==========================

-- Allows the declaration of the global variable "varname"
function global(varname)
  assert_type(varname, 'string')
  declared_globals[varname] = true
end

-- Allows the given function to write globals
function globalize(f)
  assert_type(f, 'function')
  return function(...)
    local old_index, old_newindex = _G_mt.__index, _G_mt.__newindex
    _G_mt.__index, _G_mt.__newindex = nil, nil
    local results = {f(...)}
    _G_mt.__index, _G_mt.__newindex = old_index, old_newindex
    return unpack(results)
  end
end

-- ==========================
-- Locking the global env _G
-- ==========================

do
  
  -- Preserves a possible existing metatable for _G 
  _G_mt = getmetatable(_G)
  if not _G_mt then
    _G_mt = {}
    setmetatable(_G,_G_mt)
  end

  -- Locks accessing of undeclared globals
  _G_mt.__index = function(env, varname)
    if not is_declared(varname) then
      err(('Attempt to read undeclared global variable "%s"')
        :format(varname))
    end
    return rawget(env, varname)
  end

  -- Locks assignment of undeclared globals  
  _G_mt.__newindex = function(env, varname, value)
    if not is_declared(varname) then
      err(('Attempt to assign undeclared global variable "%s"')
        :format(varname))
    end
    rawset(env, varname, value)
  end

end