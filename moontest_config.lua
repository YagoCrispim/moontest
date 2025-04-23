return {
  test_suffix = '_test.lua',
  ignored_dirs = {
    'ignored_dir_one',
    'ignored_dir_two',
  },
  ignored_files = {
    'run_test.lua',
  },
  prerun = function()
    local mt = require 'moontest'
    Describe = mt.describe
    It = mt.it
  end,
}
