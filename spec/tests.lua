#!/usr/bin/env lua
-- ==============================================
-- Specification test suite for strictness
-- Uses custom test framework (see framework.lua)
-- ==============================================

-- Test framework
local test = require 'spec.framework'

-- Detect Lua 5.2
local _LUA52 = _VERSION:match('Lua 5.2')

-- Creating data for tests
-- Lua reserved keywords
local reserved = {
  'and', 'else', 'false', 'if', 'nil', 'repeat', 'until', 'true',
  'break', 'elseif', 'for', 'in', 'not', 'return', 'do', 'end',
  'function', 'local', 'or', 'then', 'while'
}; if _LUA52 then reserved[#reserved+1] = 'goto' end

-- Some non-valid identifiers
local wrong_identifiers = {'5_a', '.e_a', 'a,r', 'e+*z', '$b'}

-- Decorators for section headers
local function decorate(str)
  local line = ('='):rep(79)
  return ('\n%s\n%s\n%s'):format(line, str, line)
end

-- Get local via debug library
local function getlocal(var, level)
  local i = 1
  while true do
    local n = debug.getlocal(level,i)
    i = i+1
    if not n then break end
    if n == var then return n end
  end
end

-- Tests if arrays t1 and t2 are the same
local function same(t1, t2)
  if #t1 ~= #t2 then return false end
  for k,v in ipairs(t1) do
    if t2[k]~=v then return false end
  end
  return true
end

-- ===============
-- Running tests
-- ===============

local strictness = require 'strictness'

print(decorate('Requiring strictness:'))
test.assert_equal('returns a local table', getlocal('strictness', 2), 'strictness')
test.assert_equal('this table contains a function named "strict"', type(strictness.strict), 'function')
test.assert_equal('this table contains a function named "unstrict"', type(strictness.unstrict), 'function')
test.assert_equal('this table contains a function named "is_strict"', type(strictness.is_strict), 'function')
test.assert_equal('this table contains a function named "strictf"', type(strictness.strictf), 'function')
test.assert_equal('this table contains a function named "unstrictf"', type(strictness.unstrictf), 'function')
test.assert_equal('this table contains a function named "run_strict"', type(strictness.run_strict), 'function')
test.assert_equal('this table contains a function named "run_unstrict"', type(strictness.run_unstrict), 'function')

print(decorate('strictness.strict(t):'))
local t = {}
test.assert_true('makes a table strict', strictness.is_strict(strictness.strict(t)))
test.assert_error('expects its first argument to be a table', function() strictness.strict(1) end)
test.assert_true('if no argument was passed, it returns a strict empty table', strictness.is_strict(strictness.strict()))
test.assert_error('errs if the passed in table is already strict', function() strictness.strict(t) end)

print(decorate('strictness.is_strict():'))
local t = strictness.strict()
test.assert_true('tests if a given table is strict', strictness.is_strict(t))
test.assert_false('returns false if the table is not strict', strictness.is_strict {})
test.assert_error('expects its first argument to be a table', function() strictness.is_strict(1) end)

print(decorate('strictness.unstrict():'))
local t = strictness.strict()
local u = strictness.unstrict(t)
local v = strictness.unstrict({})
local w = strictness.strict(setmetatable({},{}))
test.assert_false('converts a strict table to a normal one', strictness.is_strict(u))
test.assert_false('leaves the given table untouched if not strict', strictness.is_strict(v))
test.assert_error('expects its first argument to be a table', function() strictness.unstrict(1) end)
test.assert_not_error('in case the original table had a metatable, it is restored', function() local mt = {}; local t = setmetatable(t,mt); strictness.strict(t); strictness.unstrict(t); assert(getmetatable(t) == mt) end)
test.assert_not_error('in case the original table had not a metatable, this is also resoected', function() local t = {} ; strictness.strict(t); strictness.unstrict(t); assert(getmetatable(t) == nil) end)

print(decorate('A strict table:'))
local t = strictness.strict()
local u = strictness.strict({}, 'x','y','z')
local mt = {
  __tostring = function(t) return t.name end,
  __index = function(t,k) return 0 end,
  __newindex = function(t,k,v) rawset(t, k, v) end,
}
local v = strictness.strict(setmetatable({name = 'v'},mt))
local w = strictness.strict {a = true, b = false, c = 'a'}
local y = strictness.strict({y = {}})
local function global_err()
  local _ENV = strictness.strict(_G)
  assert(strictness.is_strict(_ENV)); x = 5
end
local function global_no_err()
  local _ENV = _G
  assert(strictness.is_strict(_ENV))
  x = nil; x = 5; assert(x == 5); x = nil; assert(x == nil)
end
local function global_no_err2()
  local _ENV = strictness.unstrict( _G)
  assert(not strictness.is_strict(_ENV))
  assert(x ==nil); x = 5; assert(x == 5)
end
test.assert_error('create errors when trying to access to undefined keys',function() return t.k end)
test.assert_error('create errors when trying to assign value to undefined keys',function() t.x = 5 end)
test.assert_not_error('new fields have to be defined explictely, assigning "nil"',function() t.x = nil end)
test.assert_nil('as such, the new field will take the value "nil"',t.x)
test.assert_not_error('this new field can now be indexed without creating error',function() return t.x end)
test.assert_not_error('it can also be assigned any other value from now on',function() t.x = 5 end)
test.assert_equal('and re-indexed without any problem',t.x,5)
test.assert_not_error('fields already existing in a table made strict are preserved', function() assert(w.a == true and w.b == false and w.c == 'a') end)
test.assert_not_error('and those fields can be reassigned new values, included nil', function() w.a, w.b, w.c = 1, w.c, nil; assert(w.a == 1 and w.b == 'a' and w.c == nil) end)
test.assert_true('a strict table can also be declared with allowed keys, passed as vararg', (u.x == nil and u.y == nil and u.z == nil))
test.assert_not_error('if a table made strict had a metatable, it is preserved',function() assert(tostring(v) == 'v'); v.z = 5; assert(v.x == 0 and v.z == 5) end)
test.assert_error('strict rules can apply to environments', global_err)
test.assert_not_error('therefore, global variables must be declared with value nil before use', global_no_err)
test.assert_not_error('those environments can restored back to normal', global_no_err2)
test.assert_not_error('strict rules does not apply on sub tables', function() y.y.k = 5 end)
test.assert_error('those subtables must be made strict explicitely', function() strictness.strict(y.y); y.y.a = 5 end)

print(decorate('Allowed fields in strict tables cannot be reserved keywords:'))
for _,kword in ipairs(reserved) do
	print('testing', kword)
  test.assert_error(('like "%s"'):format(kword), function() strictness.strict(nil, kword) end)
end

print(decorate('Allowed fields in strict tables should be valid Lua identifiers:'))
for _,kword in ipairs(wrong_identifiers) do
  test.assert_error(('variable name like "%s" is not valid'):format(kword), function() strictness.strict(nil, kword)end)
end

print(decorate('strictness.strictf:'))
local _ENV = _G
local function f(...) return ... end
local strictf = strictness.strictf(f)
local function f2() _ENV.var = 5 end
local strictf2 = strictness.strictf(f2)
test.assert_true('returns a strict function', type(strictness.strictf(function() end)) == 'function')
test.assert_error('it expects its first argument to be a function', function() strictness.strictf(1) end)
test.assert_not_error('or something callable', function() strictness.strictf(setmetatable({},{__call = true})) end)
test.assert_not_equal('the strict function returned is different from the original one', strictf, f)
test.assert_equal('but yields the exact same result',strictf(2),f(2))
test.assert_true('or results', same ({strictf(1,2,3)}, {f(1,2,3)}))
test.assert_error('A strict function cannot write undefined variables in its environment', strictf2)
test.assert_error('no matter what this environment is strict', function() _ENV = strictness.strictf(_ENV); strictf2() end)
test.assert_error('or non strict', function() _ENV = strictness.unstrict(_ENV); strictf2() end)

print(decorate('strictness.unstrictf:'))
local _ENV = strictness.unstrict(_G)
local function f(...) return ... end
local unstrictf = strictness.unstrictf(f)
local function f2(var, value) _ENV[var] = value end
local unstrictf2 = strictness.unstrictf(f2)
test.assert_true('returns a non strict function', type(strictness.unstrictf(function() end)) == 'function')
test.assert_error('it expects its first argument to be a function', function() strictness.unstrictf(1) end)
test.assert_not_error('or something callable', function() strictness.unstrictf(setmetatable({},{__call = true})) end)
test.assert_not_equal('the non strict function returned is different from the original one', unstrictf, f)
test.assert_equal('but yields the exact same result',unstrictf(2),f(2))
test.assert_true('or results', same ({unstrictf(1,2,3)}, {f(1,2,3)}))
test.assert_not_error('A non strict function can write undefined variables in its environment', function() unstrictf2('var1',5); assert(var1 == 5) end)
test.assert_not_error('no matter what this environment is strict', function() _ENV = strictness.strict(_ENV); unstrictf2('var2','a'); assert(var2 == 'a') end)
test.assert_not_error('or non strict', function() _ENV = strictness.unstrict(_ENV); unstrictf2('var3',false); assert(var3 == false) end)

print(decorate('strictness.run_strict():'))
local function f(var, value) _ENV[var] = value end
test.assert_error('returns the result of the call f(...) in strict mode', function() strictness.run_strict(f,'varname',true) end)
test.assert_error('it expects its first argument to be a function', function() strictness.run_strict(1) end)

print(decorate('strictness.run_unstrict():'))
local function f(var, value) _ENV[var] = value end
test.assert_not_error('returns the result of the call f(...) in non strict mode', function() strictness.run_unstrict(f,'varname',true); assert(varname == true) end)
test.assert_error('it expects its first argument to be a function', function() strictness.run_unstrict(1) end)

strictness.unstrict(_G)
test.print_stats()