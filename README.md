strictness
===========

[![Build Status](https://travis-ci.org/Yonaba/strictness.png)](https://travis-ci.org/Yonaba/strictness)

In Lua, one must use the `local` statement to create a local variable. On the other hand, global variables do not need assignment, Lua being [global by default](http://www.lua.org/pil/1.2.html). <br>

*strictness* is yet another pure Lua module (compatible with Lua 5.1 and 5.2) which stands for tracking global variables declaration and assignments in your code.<br>

With *strictness*, one is forced to declare globals using a new function, `global`. As such, it helps having a better control on the scope of  variables and therefore minimizes the global environment namespace pollution.

*strictness* is compatible with Lua [5.1](http://www.lua.org/versions.html#5.1) and Lua [5.2](http://www.lua.org/versions.html#5.2).

##Installation

####Git

    git clone git://github.com/Yonaba/strictness

####Download

* See [releases](https://github.com/Yonaba/strictness/releases)

####LuaRocks

    luarocks install strictness
    
####MoonRocks

    moonrocks install strictness

or 

    luarocks install --server=http://rocks.moonscript.org/manifests/Yonaba strictness


##Usage

Place the file [strictness.lua](strictness.lua) in your project and call it with [require](http://pgl.yoyo.org/luai/i/require).

    require "strictness"

## Documentation

See [tutorial.md](docs/tutorial.md).

##Tests

This project includes a custom test framework and specifications tests. To run these tests, run the following from the project root folder:

    lua specs/tests.lua

##Alternative implementations

Feel free to check those alternate implementations, from with *strictness* takes some inspiration:

* [strict.lua](http://rtfc.googlecode.com/svn-history/r2/trunk/lua-5.1/etc/strict.lua), which is included in the official Lua distribution
* [pl.strict](https://github.com/stevedonovan/Penlight/blob/master/lua/pl/strict.lua), which is part of [S. Donovan](https://github.com/stevedonovan)'s [Penlight](https://github.com/stevedonovan/Penlight).

  
##License
This work is under [MIT-LICENSE](http://www.opensource.org/licenses/mit-license.php)<br/>
Copyright (c) 2013 Roland Yonaba

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/Yonaba/strictness/trend.png)](https://bitdeli.com/free "Bitdeli Badge")