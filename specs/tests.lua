#!/usr/bin/env lua
-- ==============================================
-- Specification test suite for strictness
-- Uses custom test framework (see framework.lua)
-- ==============================================

-- Test framework
local test = require 'specs.framework'

-- Aliases
local loaded = package.loaded

-- Setting a fake metatable to _G, for the Environment context
local fake_mt = {
  __index = function() end,
  __newindex = function() end,
  __tostring = function() return "fake_mt" end,
}

-- Caching fake_mt field to track changes later
local old_fake_mt_index = fake_mt.__index
local old_fake_mt_newindex = fake_mt.__newindex
local old_fake_mt_a_field = fake_mt.a_field

setmetatable(_G, fake_mt)

-- Creating data for tests
-- Lua reserved keywords
local reserved = {
  'and', 'else', 'false', 'if', 'nil', 'repeat', 'until', 'true',
  'break', 'elseif', 'for', 'in', 'not', 'return', 'do', 'end',
  'function', 'local', 'or', 'then', 'while'
}

if _VERSION:match('5.2') then 
  reserved[#reserved+1] = 'goto'
end

-- Some non-valid identifiers
local wrong_identifiers = {'5_a', '.e_a', 'a,r', 'e+*z', '$b'}

-- Output decorators for section headers
local function decorate(str)
  local line = ('='):rep(79)
  return ('\n%s\n%s\n%s'):format(line, str, line)
end

local function getlocal(var, level)
	local i = 1
	while true do
		local n = debug.getlocal(level,i)
		i = i+1
		if not n then break end
		if n == var then return n end
	end
end

-- ===============
-- Running tests
-- ===============

local strictness = require 'strictness'

print(decorate('Requiring strictness:'))
test.assert_equal('returns a local table', getlocal('strictness', 2), 'strictness')
test.assert_equal('this table contains a function named "global"', type(strictness.global), 'function')
test.assert_equal('and another function named "globalize"', type(strictness.globalize), 'function')

print(decorate('Globals:'))
test.assert_error('An attempt to read an undeclared global raises an error', function() print(x) end)
test.assert_error('Assigning undeclared global raises an error', function() x = true end)
test.assert_error('Assigning nil to undeclared global raises an error', function() x = nil end)
test.assert_not_error('Should be declared before assignment via global()', function() strictness.global ("x"); x = true end)
test.assert_not_nil('declared global x successfully', x, 2)
test.assert_true('assigned global x successfully', x, 2)
test.assert_not_error('A newly assigned global takes the value nil by default', function() strictness.global ("n"); end)
test.assert_nil('declared n, n is nil', n, 2)
test.assert_not_error('A declared global can also be assigned nil', function() n = nil end)
test.assert_nil('n was assigned nil', n, 2)
test.assert_error('global() do not accept tables', function() strictness.global({}) end)
test.assert_error('global() do not accept numbers', function() strictness.global(1) end)
test.assert_error('global() do not accept nil', function() strictness.global(nil) end)
test.assert_error('global() do not accept boolean', function() strictness.global(true) end)
test.assert_error('global() do not accept functions', function() strictness.global(function() end) end)
test.assert_error('global() do not accept coroutine, userdata or threads', function() global(coroutine.create(function() end)) end)
test.assert_not_error('global() only accept strings', function() strictness.global("a") end)
test.assert_error('But not empty strings', function() strictness.global("") end)
test.assert_not_error('Multiple globals can be declared with global()', function() strictness.global("yy", "zz") end)
test.assert_nil('yy was declared, value is nil', yy, 2)
test.assert_nil('zz was declared, value is nil', zz, 2)

print('  Global varnames cannot be a Lua reserved keywords')
for _, varname in ipairs(reserved) do
  test.assert_error(('like %s'):format(varname), function() strictness.global(varname) end, 2)
end

print('  global() raises an error when identifiers are not valid')
for _, varname in ipairs(wrong_identifiers) do
  test.assert_error(('like %s'):format(varname), function() strictness.global(varname) end, 2)
end

print('  Varname "global" is not reserved')
test.assert_not_error('declared global "global"',function() strictness.global "global"; global = true end, 2)
test.assert_true('assigned var "global" a boolean value', global, 2)

print('  Varname "globalize" is not reserved')
test.assert_not_error('declared global "globalize"',function() strictness.global "globalize"; globalize = false end, 2)
test.assert_false('assigned var "globalize" a boolean value', globalize, 2)

print(decorate('Functions declaring globals:'))
test.assert_error('Raises error when called normally', function() one = "one" end)
test.assert_not_error('globalize() wraps these functions so that they can write globals', strictness.globalize(function() one = "one" end))
test.assert_equal('called a function which declared a global successfully', one, "one", 2)

print(decorate('Environment metatable:'))
test.assert_equal('Preserves a possible existing metatable for _G', getmetatable(_G), fake_mt)
test.assert_not_equal('Overwrites __index in the env table metatable, if defined', fake_mt.__index, old_fake_mt_index)
test.assert_not_equal('Overwrites __newindex in the env table metatable, if defined', fake_mt.__newindex, old_fake_mt_newindex)
test.assert_equal('Any other defined field is preserved in the env metatable', tostring(_G), "fake_mt")

print(decorate('Locked Environments:'))
test.assert_not_error('Let\'s unload strictness from package.loaded', function() package.loaded['strictness'] = nil end)
test.assert_not_error('Now we lock _G with a new metatable implemeting a __newindex field', function() setmetatable(_G,{__newindex = function() error() end}) end)
test.assert_error('We can no longer create globals', function() var = true end)
test.assert_nil('could not assign variable "var"', var, 2)
test.assert_not_error('Let\'s require strictness', function() strictness = require "strictness" end)
test.assert_not_error('We can now declare globals', function() strictness.global "var"; var = true end)
test.assert_true('successfully declared and assigned global "var" to true', var, 2)

test.print_stats()