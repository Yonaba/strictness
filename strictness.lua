-- ==========================================
-- "strictness", a strict mode for Lua
-- Copyright (c) 2014 Roland Y., MIT License
-- v0.2.0 - compatible Lua 5.1, 5.2
-- ==========================================

local _LUA52 = _VERSION:match('Lua 5.2')
local setmetatable, getmetatable = setmetatable, getmetatable
local pairs, ipairs = pairs, ipairs
local rawget, rawget = rawget, rawget
local unpack = _LUA52 and table.unpack or unpack
local tostring, select, error = tostring, select, error
local getfenv = getfenv

----------------------------- Private definitions -----------------------------

if _LUA52 then
  -- Provide a replacement for getfenv in Lua 5.2, using the debug library
  -- Taken from: http://lua-users.org/lists/lua-l/2010-06/msg00313.html
  -- Slightly modified to handle f being nil and return _ENV if f is global.
  getfenv = function(f)
      f = (type(f) == 'function' and f or debug.getinfo((f or 0) + 1, 'f').func)
      local name, val
      local up = 0
      repeat
          up = up + 1
          name, val = debug.getupvalue(f, up)
      until name == '_ENV' or name == nil
      return val~=nil and val or _ENV
  end
end

-- Lua reserved keywords
local is_reserved_keyword = {
  ['and']      = true, ['break'] = true, ['do']    = true, ['else']   = true, 
  ['elseif']   = true, ['end']   = true, ['false'] = true, ['for']    = true,
  ['function'] = true, ['if']    = true, ['in']    = true, ['local']  = true,
  ['nil']      = true, ['not']   = true, ['or']    = true, ['repeat'] = true, 
  ['return']   = true, ['then']  = true, ['true']  = true, ['until']  = true,
  ['while']    = true,
}; if _LUA52 then is_reserved_keyword['goto'] = true end

-- Throws an error if cond
local function complain_if(cond, msg, level) 
  return cond and error(msg, level or 3)
end

-- Checks if iden match an valid Lua identifier syntax
local function is_identifier(iden)
  return tostring(iden):match('^[%a_]+[%w_]*$') and not is_reserved_keyword[iden]
end

-- Checks if all elements of vararg are valid Lua identifiers
local function validate_identifiers(...)
  local arg, varnames= {...}, {}
  for i, iden in ipairs(arg) do
    complain_if(not is_identifier(iden),
      ('varname #%d "<%s>" is not a valid Lua identifier.')
        :format(i, tostring(iden)),4)
  varnames[iden] = true
  end
  return varnames
end

-- add true keys in register all keys in t
local function add_allowed_keys(t,register)
  for key in pairs(t) do 
    if is_identifier(key) then register[key] = true end
  end
  return register
end
------------------------------- Module functions ------------------------------

-- Makes a given table strict
local function make_table_strict(t, ...)
  t = t or {}
  local mt = getmetatable(t) or {}
  complain_if(mt.__strict, 
    ('<%s> was already made strict.')
      :format(tostring(t)),3)
    
  local varnames = v
  mt.__allowed = add_allowed_keys(t, validate_identifiers(...))
  mt.__predefined_index = mt.__index
  mt.__predefined_newindex = mt.__newindex
  
  mt.__index = function(tbl, key)
    if not mt.__allowed[key] then
      if mt.__predefined_index then
        local expected_result = mt.__predefined_index(tbl, key)
        if expected_result then return expected_result end
      end
      complain_if(true,
        ('Attempt to access undeclared variable "%s" in <%s>.')
          :format(key, tostring(tbl)),3)
    end
    return rawget(tbl, key)
 end
  
  mt.__newindex = function(tbl, key, val)
    if mt.__predefined_newindex then
      mt.__predefined_newindex(tbl, key, val)
      if rawget(tbl, key) ~= nil then return end
    end
    if not mt.__allowed[key] then
      if val == nil then 
        mt.__allowed[key] = true
        return
      end
      complain_if(not mt.__allowed[key],
        ('Attempt to assign value to an undeclared variable "%s" in <%s>.')
          :format(key,tostring(tbl)),3)
      mt.__allowed[key] = true
    end
    rawset(tbl, key, val)
  end
  
  mt.__strict = true
  return setmetatable(t, mt)
  
end

-- Checks if a given table was made strict.
local function is_table_strict(t)
  return not not (getmetatable(t) and getmetatable(t).__strict)
end

-- Makes a given table unstrict
local function make_table_unstrict(t)
  if is_table_strict(t) then
    local mt = getmetatable(t)
    mt.__index, mt.__newindex = mt.__predefined_index, mt.__predefined_newindex
    mt.__strict, mt.__allowed = nil, nil
    mt.__predefined_index, mt.__predefined_newindex = nil, nil
  end
  return t
end

-- Makes a given function strict
-- Will run in strict mode whether or not its env is strict.
local function make_function_strict(f)
  return function(...)
    local ENV = getfenv(f)
    local was_strict = is_table_strict(ENV)
    if not was_strict then make_table_strict(ENV) end
    local results = {f(...)}
    if not was_strict then make_table_unstrict(ENV) end
    return unpack(results)
  end
end

-- Makes a given function sloppy
-- Will override strict rules of its env
local function make_function_sloppy(f)
  return function(...)
    local ENV = getfenv(f)
    local was_strict = is_table_strict(ENV)
    make_table_unstrict(ENV)
    local results = {f(...)}
    if was_strict then make_table_strict(ENV) end
    return unpack(results)
  end
end

-- Returns the result of function call in strict mode in its env
local function run_strict(f,...)
  return make_function_strict(f)(...)
end

-- Returns the result of function call in sloppy mode in its env
local function run_sloppy(f,...)
  return make_function_sloppy(f)(...)
end

return {
  strict      = make_table_strict,
  sloppy      = make_table_unstrict,
  is_strict   = is_table_strict,  
  sloppyf     = make_function_sloppy,
  strictf     = make_function_strict,
  run_strictf = run_strict,
  run_sloppyf = run_sloppy,
}