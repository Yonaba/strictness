-- ================================================================
-- "strictness" tracks declaration and assignment of globals in Lua
-- Copyright (c) 2013 Roland Y., MIT License
-- v0.1.0 - compatible Lua 5.1, 5.2
-- ================================================================

local setmetatable = setmetatable
local getmetatable = getmetatable
local type = type
local rawget = rawget
local rawset = rawset
local unpack = unpack
local error = error
local getfenv = getfenv

-- ===================
-- Private helpers
-- ===================

-- Lua reserved keywords
local luaKeyword = {
  ['and'] = true,     ['break'] = true,   ['do'] = true,
  ['else'] = true,    ['elseif'] = true,  ['end'] = true ,
  ['false'] = true,   ['for'] = true,     ['function'] = true,
  ['if'] = true,      ['in'] = true,      ['local'] = true ,
  ['nil'] = true,     ['not'] = true ,    ['or'] = true,
  ['repeat'] = true,  ['return'] = true,  ['then'] = true ,
  ['true'] = true ,   ['until'] = true ,  ['while'] = true,
}

-- Register for declared globals, defined as a table
-- with weak values.
local declared_globals = setmetatable({},{__mode = 'v'})

-- The global env _G metatable
local _G_mt

-- A custom error function
local function err(msg, level)  return error(msg, level or 3) end

-- Custom assert with error level depth
local function assert(cond, msg, level)
  if not cond then
    return err(msg, level or 4)
  end
end

-- Custom argument type assertion helper
local function assert_type(var, expected_type, argn, level)
  local var_type = type(var)
  assert(var_type == expected_type,
    ('Bad argument #%d to global (%s expected, got %s)')
      :format(argn or 1, expected_type, var_type), level)
end

-- Checks in the register if the given global was declared
local function is_declared(varname)
  return declared_globals[varname]
end

-- Checks if the passed-in string can be a valid Lua identifier
local function is_valid_identifier(iden)
  return iden:match('^[%a_]+[%w_]*$') and not luaKeyword[iden]
end

-- ==========================
-- Module functions
-- ==========================

-- Allows the declaration of passed in varnames
local function declare_global(...)
  local vars = {...}
  assert(#vars > 0,
    'bad argument #1 to global (expected strings, got nil)')
  for i,varname in ipairs({...}) do
    assert_type(varname, 'string',i, 5)
    assert(is_valid_identifier(varname),
      ('bad argument #%d to global. "%s" is not a valid Lua identifier')
        :format(i, varname))
    declared_globals[varname] = true
  end
end

-- Allows the given function to write globals
local function declare_global_func(f)
  assert_type(f, 'function', nil, 5)
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

  -- Catches the current env
  local ENV = _VERSION:match('5.2') and _G or getfenv()
  
  -- Preserves a possible existing metatable for the current env
  _G_mt = getmetatable(ENV)
  if not _G_mt then
    _G_mt = {}
    setmetatable(ENV,_G_mt)
  end

  -- Locks access to undeclared globals
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
  
  rawset(ENV, 'global', declare_global)
  rawset(ENV, 'globalize', declare_global_func)

end