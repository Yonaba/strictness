-- ==========================================
-- "strictness", a strict mode for Lua
-- Copyright (c) 2014 Roland Y., MIT License
-- v0.2.0 - compatible Lua 5.1, 5.2
-- ==========================================

local _LUA52 = _VERSION:match('5.2')
local setmetatable, getmetatable = setmetatable, getmetatable
local rawget, rawget = rawget, rawget
local unpack = _LUA52 and table.unpack or unpack
local tostring, select, error = tostring, select, error

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

-- Checks if all elements of vararg are valid Lua identifiers
local function validate_identifiers(...)
  local varnames = {...}
  for i, iden in ipairs(varnames) do
    local is_valid_iden = iden:match('^[%a_]+[%w_]*$') and 
                          not is_reserved_keyword[iden]
    complain_if(not is_valid_iden,
      ('varname #%d "<%s>" is not a valid Lua identifier.')
        :format(i, tostring(iden)),4)
  end
  return varnames
end

-- Swaps keys and values, overwrites values with v if provided
local function swap_key_and_values(t, v)
  local _t = {}
  for i, val in  ipairs(t) do _t[val] = i and v end
  return _t
end

-- Makes a given table strict
local function make_table_strict(t, ...)
  t = t or {}
  local mt = getmetatable(t) or {}
  complain_if(mt.__strict, 
    ('<%s> was already made strict.')
      :format(tostring(t)),3)
    
  local varnames = validate_identifiers(...)
  mt.__allowed = swap_key_and_values(varnames,true)
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
    mt.__index = mt.__predefined_index
    mt.__newindex = mt.__predefined_newindex
    mt.__strict = nil
    mt.__allowed = nil
    mt.__predefined_index = nil
    mt.__predefined_newindex = nil
  end
  return t
end

-- Makes a given function strict
-- Will run un strict mode whether or not env is strict.
local function make_function_strict(f, ENV)
  return function(...)
    local _ENV = ENV or (_LUA52 and _ENV or getfenv(1))
    local was_patched = is_table_strict(_ENV)
    if not was_patched then make_table_strict(_ENV) end
    local results = {f(...)}
    if not was_patched then make_table_unstrict(_ENV) end
    return unpack(results)
  end
end

-- Makes a given function sloppy
-- Will overrides strict rules of a given env
local function make_function_sloppy(f,ENV)
  return function(...)
    local _ENV = ENV or (_LUA52 and _ENV or getfenv(1))
    local was_patched = is_table_strict(_ENV)
    make_table_unstrict(_ENV)
    local results = {f(...)}
    if was_patched then make_table_strict(_ENV) end
    return unpack(results)
  end
end

-- Returns the result of function call in strict mode in an env
local function run_strict(f, env,...)
  return make_function_strict(f,env)(...)
end

-- Returns the result of function call in sloppy mode in an env
local function run_sloppy(f, env,...)
  return make_function_sloppy(f, env)(...)
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