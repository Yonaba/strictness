strictness tutorial
===================

### Requiring the module

Place the file [strictness.lua](http://github.com/Yonaba/strictness/blob/master/strictness.lua) in your project and call it with [require](http://pgl.yoyo.org/luai/i/require).

```lua
local strict = require "strictness"
````

From now on, it will no longer be possible to create/assign globals. The following code:

```lua
local strict = require "strictness"
a = 1
````

will create an error:


    lua: test.lua:2: Attempt to assign undeclared global variable "a"
    stack traceback:
	  [C]: in function 'error'
	  .\strictness.lua:40: in function 'err'
	  .\strictness.lua:118: in function <.\strictness.lua:116>
	  test.lua:2: in main chunk
	  [C]: ?
    Exit code: 1

### Creating global variables

With *strictness* enabled, global variables __must be declared first__ via a new function `strict.global`.

```lua
local strict = require "strictness"
strict.global "a"
a = 1
print(a) --> "1"
````

By default, a newly declared global takes the value `nil`.

```lua
strict.global "a"
print(a) --> "nil"
````

The function `strict.global` accepts multiple values, wich is convenient to declare multiple globals in a single line:

```lua
strict.global ("a", "b", "c")
print(a, b, c) --> "nil", "nil", "nil"
````

Note that `strict.global` will only accept strings representing valid Lua identifiers. All the following will raise an error:

```lua
strict.global ("else") --> "else" is a reserved keyword
strict.global ("1_a") --> "1_a" is not a valid Lua identifier
strict.global ({}) --> {} is not a string
````

### Functions creating globals

Some functions create globals when run. For instance, you might want to use [require](http://pgl.yoyo.org/luai/i/require)/[loadfile](http://pgl.yoyo.org/luai/i/loadfile)/[dofile](http://pgl.yoyo.org/luai/i/dofile) to call and execute some external code which is likely to create globals. In that case, if *strictness* is enabled, those functions will fail to execute when trying to assign those globals.

````lua
local strict = require 'strictness'
local function setGlobals()
  x, y, z = 1, 2, 3
end
setGlobals()
````

    lua: test.lua:4: Attempt to assign undeclared global variable "z"
    stack traceback:
	  [C]: in function 'error'
	  .\strictness.lua:40: in function 'err'
	  .\strictness.lua:118: in function <.\strictness.lua:116>
	  test.lua:4: in function 'setGlobals'
	  test.lua:6: in main chunk
	  [C]: ?
    Exit code: 1

To work around this issue, *strictness* provides another function named `strict.globalize`. When passing a function to `strict.globalize`, it returns a similar (wrapped) function which is free to write in the global environment.

````lua
local strict = require 'strictness'
local function setGlobals()
  x, y, z = 1, 2, 3
end

setGlobals = strict.globalize(setGlobals)
setGlobals() --> no error was raised
print(x) --> "1"
print(y) --> "2"
print(z) --> "3"
````

### The global env _G metatable

*strictness* works its magic by assigning a metatatable to the global environment `_G` implementing an `__index` and `__newindex` fields. <br>

In case `_G` already has a metatable, *strictness* will overwrite its `__index` and `__newindex` fields and leave all the other fields untouched.

```lua
local _GMT = {
  __tostring = function() return "I am _G!" end,
  __index = "_GMT index",
  __newindex = "_GMT newindex"
}
setmetatable(_G, _GMT)
print(_G) --> "I am _G!"
print(_GMT.__index, _GMT.__newindex) --> "_GMT index  _GMT newindex"

local strict = require 'strictness'
print(_G) --> "I am _G!" (__tostring was untouched)
print(_GMT.__index, _GMT.__newindex) --> "function: 0053B7D0	  function: 0053B9B0"
````
