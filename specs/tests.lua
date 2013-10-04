-- ================================================================
-- test suite for strictness
-- Uses Telescope (https://github.com/norman/telescope)
-- ================================================================

-- ================================================================
-- Note :

-- As Telescope declares globals (assertion functions mostly), I 
-- had to track and declare those globals (in a hacky way) to 
-- enable strictness. See context 'Requiring strictness'.
-- ================================================================

-- Collects all keys in a given context
local function collect(t)
  local r = {}
  for k in pairs(t) do
    if not r[k] then r[k] = true end
  end
  return r
end

-- Returns diff keys
local function diff(n, o)
  local diff = {}
  for k in pairs(n) do
    if not o[k] then diff[#diff+1] = k end
  end
  return diff
end

-- Collects all existing keys in _G
local old_G = collect(_G)


context('Requiring strictness', function()

  test('Declaring test suite globals', function()
    
    local globs = diff(_G, old_G)
    require 'strictness'
    
    for _,var in ipairs(globs) do
      -- print('declaring', var)
      global (var)
    end
    
    assert_not_nil(global)
    assert_not_nil(globalize)
    
  end)

end)

context('Globals', function()

  test('Assigning value to undeclared global raises an error', function()
    
    local function setx() x = true end
    
    assert_error(setx)
    
  end)
  
  test('Assigning nil to undeclared global raises an error', function()
    
    local function setx() x = nil end
    
    assert_error(setx)
    
  end)  

  test('should be declared before assignment via global()', function()
    
    local function setx()
      global "x"
      x = true
    end
    
    assert_not_error(setx)
    assert_true(x)
    
  end)
  
  test('a newly assigned global takes the value nil by default', function()
    
    local function setn()
      global "n"
    end
    
    assert_not_error(setn)
    assert_nil(n)
    
  end)
  
  test('global accepts only strings', function()
    
    assert_false(pcall(global,{}))
    assert_false(pcall(global, 1))
    assert_false(pcall(global,nil))
    assert_false(pcall(global,false))
    assert_false(pcall(global,true))
    assert_false(pcall(global,function() end))
    assert_false(pcall(global, coroutine.create(function() end)))
    
  end)
  
  test('multiple globals can be declared with global()', function()
    
    local function declare_multiple()
      global ("xx", "yy", "zz")
    end
    
    assert_not_error(declare_multiple)
    assert_nil(xx)
    assert_nil(yy)
    assert_nil(zz)
    
    
    local function set_multiple()
      global ("aa", "bb", "cc")
      aa, bb, cc = 1, 2, 3
    end
    
    assert_not_error(set_multiple)
    assert_equal(aa, 1)
    assert_equal(bb, 2)
    assert_equal(cc, 3)
    
  end)
  
  test('global identifiers cannot be any of Lua reserved keywords', function()
    local reserved = {
      ['and'] = true,     ['break'] = true,   ['do'] = true,
      ['else'] = true,    ['elseif'] = true,  ['end'] = true ,
      ['false'] = true,   ['for'] = true,     ['function'] = true,
      ['if'] = true,      ['in'] = true,      ['local'] = true ,
      ['nil'] = true,     ['not'] = true ,    ['or'] = true,
      ['repeat'] = true,  ['return'] = true,  ['then'] = true ,
      ['true'] = true ,   ['until'] = true ,  ['while'] = true,
    }    
    
    for var in pairs(reserved) do
      assert_false(pcall(global,var))
    end
    
  end) 
  
  test('they should also respect Lua\'s identifiers lexical conventions', function()  
    
    assert_false(pcall(global,"5_a"))
    assert_false(pcall(global,".a"))
    assert_false(pcall(global,"e;z"))
    assert_false(pcall(global,"e+*z"))
    assert_false(pcall(global,"$b"))
    
  end) 
  
  test('a declared global can be assigned nil', function()
    
    local function setx()
      global "x"
      x = true
    end
    
    local function setnil() x = nil end
    setx()
    
    assert_not_error(setnil)
    assert_nil(x)
    
  end)
  
end)

context('Functions declaring globals', function()
  
  test('raises an error when called normally', function()
    
    local function set()
      global_one = "one"
      global_two = "two"
    end
    
    assert_error(set)
    
  end)
  
  test('globalizing such functions no longer raises an error', function()
    
    local function set()
      global_one = "one"
      global_two = "two"
    end
    
    local set_globalized = globalize(set)
    
    assert_error(set)
    assert_not_error(set_globalized)
    assert_equal(global_one, "one")
    assert_equal(global_two, "two")
    
  end)
  
  test('globalize() also works with functions returning multiple values', function()
    
    local add = globalize(function (...)
      sum = 0
      for _,v in ipairs({...}) do
        sum = sum + v
      end
      return sum * 2, sum * 3
    end)
    
    assert_not_error(add)
    assert_equal(sum, 0)
    
    local double, triple = add(1,2,3,4,5)
    
    assert_equal(sum, 15)
    assert_equal(double, 30)
    assert_equal(triple, 45)
    
  end)  
  
end)