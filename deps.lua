---@class DepsFile
return {
  scripts = {
    test = {
      desc = 'Run project tests',
      cb = function()
        require 'src.moontest'
      end
    },
    bundle = {
      desc = 'Bundle',
      cb = function()
        ---@type any
        local chunk = loadfile('./libs/_dev/luabundler/bundler.lua')
        arg[1] = '.'
        arg[2] = 'src/moontest.lua'
        arg[3] = 'out.lua'
        chunk()
      end
    },
  },
  dev_dependencies = {
    luabundler = "https://github.com/YagoCrispim/luabundler.git"
  }
}
