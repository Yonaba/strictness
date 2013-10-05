package = "strictness"
version = "0.1.0-1"
source = {
   url = "https://github.com/Yonaba/strictness/archive/strictness-0.1.0-1.tar.gz",
   dir = "strictness-strictness-0.1.0-1"
}
description = {
   summary = "Tracks declaration and assignment of globals in Lua",
   detailed = [[
    Strictness is yet another pure Lua module (compatible with Lua 5.1 and 5.2) 
    which stands for tracking global variables declaration and assignments in your code.
    It enforces to declare globals using a new statement, before assignment. As such, it
    helps having a better control on the scope of variables and therefore minimizes the 
    global environment namespace pollution.
   ]],
   homepage = "http://yonaba.github.com/strictness",
   license = "MIT <http://www.opensource.org/licenses/mit-license.php>"
}
dependencies = {
   "lua >= 5.1, <= 5.2"
}
build = {
  type = "builtin",
  modules = {
    ["strictness"] = "strictness.lua"
  },
  copy_directories = {"specs", "docs"}
}