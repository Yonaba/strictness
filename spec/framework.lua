-- ==============================================
-- Custom test framework for specification tests
-- Copyright (c) 2013 Roland Y., MIT License
-- ==============================================

local COUNT = 0
local PASSED = 0

-- Custom assertions
local assert = function(cond, msg)
  COUNT = COUNT + 1
  if not cond then
    error(msg, 3)
  end
end

-- Single test output decorator
local function output(msg, depth)
  depth = (depth or 0) + 1
  PASSED = PASSED + 1
  msg = ('%s%s'):format(('  '):rep(depth or 1),msg)
  print(msg .. ('%s[OK]'):format(('.'):rep(76-#msg-1)))
end

-- ====================
-- Assertion functions
-- ====================

-- Test passing when v is nil
local function assert_nil(msg, v, level)
  assert(v==nil, ('Test failed, expected "%s" to be nil')
    :format(tostring(v)))
  output(msg, level)
end

-- Test passing when v is not nil
local function assert_not_nil(msg, v, level)
  assert(v~=nil, ('Test failed, expected "%s" not to be nil')
    :format(tostring(v)))
  output(msg, level)
end

-- Test passing when v is true
local function assert_true(msg, v, level)
  assert(v==true, ('Test failed, expected "%s" to be true')
    :format(tostring(v)))
  output(msg, level)
end

-- Test passing when v is false
local function assert_false(msg, v, level)
  assert(v==false, ('Test failed, expected "%s" to be false')
    :format(tostring(v)))
  output(msg, level)
end

-- Test passing when a == b
local function assert_equal(msg, a, b, level)
  assert(a == b, ('Test failed, expected "%s" to be equal to "%s"')
    :format(tostring(a), tostring(b)))
  output(msg, level)
end

-- Test passing when a ~= b
local function assert_not_equal(msg, a, b, level)
  assert(a ~= b, ('Test failed, expected "%s" not to be equal to "%s"')
    :format(tostring(a), tostring(b)))
  output(msg, level)
end

-- Test passing if the call f() produces an error
local function assert_error(msg, f, level)
  assert(not pcall(f), 'Expected to create an error')
  output(msg, level)
end

-- Test passing if the call f() does not produce an error
local function assert_not_error(msg, f, level)
  assert(pcall(f), 'Expected not to create an error')
  output(msg, level)
end

-- Prints tests results
local function print_stats()
  print(('='):rep(79))
  print(('Total %d tests : %d passed and %s failed')
    :format(COUNT, PASSED, COUNT-PASSED))
end

-- Returns framework
return {
  assert_equal = assert_equal,
  assert_not_equal = assert_not_equal,
  assert_error = assert_error,
  assert_not_error = assert_not_error,
  assert_nil = assert_nil,
  assert_not_nil = assert_not_nil,
  assert_true = assert_true,
  assert_false = assert_false,
  print_stats = print_stats,
}