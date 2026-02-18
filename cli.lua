_G.__LOADED = {}
function _G.main()
if _G.__LOADED[_G.main] and _G.__LOADED[_G.main].called then
return _G.__LOADED[_G.main].M
end
_G.__LOADED[_G.main] = {called = true,M = (function()
_G.cliglobals()
local fs = _G.clifs()
local utils = _G.cliutils()
local deps_file_template =
"---@class DepsFile" .. "\n" ..
"return {" .. '\n' ..
"  scripts = {" .. '\n' ..
"    test = {" .. '\n' ..
"      desc = 'Run project tests'," .. '\n' ..
"      cb = function(add_dependencies_to_path)" .. '\n' ..
"        -- Optional call" .. '\n' ..
"        -- add_dependencies_to_path()" .. '\n' ..
"        error('Not implemented.')" .. '\n' ..
"      end" .. '\n' ..
"    }," .. '\n' ..
"  }," .. '\n' ..
"  dependencies = {" .. '\n' ..
"    -- example" .. '\n' ..
"    -- utils = 'git@github.com:YagoCrispim/lua_utils.git'" .. '\n' ..
"  }," .. '\n' ..
"  dev_dependencies = {}" .. '\n' ..
"}"
local add_deps_to_path
local instal_dependency
local cb_context
local cli = {
context = {
op = arg[1],
checked_deps = {},
config = {
dep_folder_name = 'libs',
}
},
}
cli.run = {
desc = 'Execute a command in deps.lua with given name',
cb = function()
local success, deps = pcall(function()
return require 'deps'
end)
if not success then
print('[ERROR]: deps.lua not found. run "lua cli.lua init" to create it.')
return
end
assert(deps, "'deps.lua' not found in current directory.")
local script_name = arg[2]
if not script_name then
print('Script not informed.')
print('Usage: lua cli.lua run <script_name>')
return
end
if not deps.scripts or not deps.scripts[script_name] then
print('[ERROR]: Script "' .. script_name .. '" not found.')
return
end
deps.scripts[script_name].cb(cb_context)
end
}
cli.install = {
desc = 'Install project dependencies',
cb = function(deps_param)
local deps = deps_param
if not deps_param then
local success, depsfile = pcall(function()
return require 'deps'
end)
if not success then
print('[ERROR]: deps.lua not found. run "lua cli.lua init" to create it.')
return
end
deps = depsfile
end
assert(deps, "'deps.lua' not found in current directory.")
if (deps.dependencies or deps.dev_dependencies) then
if not fs.exists(cli.context.config.dep_folder_name) then
os.execute('mkdir libs')
end
if deps.dependencies then
for name, dep in pairs(deps.dependencies) do
local install_path = fs.join({ '.', cli.context.config.dep_folder_name, name })
instal_dependency(name, dep, install_path)
end
end
if deps.dev_dependencies then
for name, dep in pairs(deps.dev_dependencies) do
local install_path = fs.join({ '.', cli.context.config.dep_folder_name, '_dev', name })
instal_dependency(name, dep, install_path)
end
end
end
end
}
cli.init = {
desc = "Initialize a project",
cb = function()
local cwd = fs.cwd
local deps_path = fs.join({ cwd, 'deps.lua' })
local ignore_path = fs.join({ cwd, '.gitignore' })
if not fs.exists(deps_path, true) then
local deps = io.open(deps_path, 'w')
deps:write(deps_file_template)
deps:close()
print('deps.lua created.')
else
print('deps.lua already exist.')
end
if not fs.exists(ignore_path, true) then
local gitIgnore = io.open(ignore_path, 'w')
gitIgnore:write('libs')
gitIgnore:close()
print('.gitignore created.')
else
print('.gitignore already exist')
end
end
}
function cli:get_op(op)
if not cli[op] then
print('CLI commands')
for _, v in pairs({ 'init', 'install', 'run' }) do
if type(v) ~= 'function' then
print('- ' .. v, cli[v].desc)
end
end
local success, deps = pcall(function()
return require 'deps'
end)
if not success then
return
end
if deps then
print('\nProject scripts')
for k, v in pairs(deps.scripts) do
if type(v) ~= 'function' then
print('- ' .. k, v.desc)
end
end
end
return
end
return cli[op]
end
instal_dependency = function(name, dep, install_path)
local function eval_script(content)
local eval = utils.tern(_VERSION == 'Lua 5.4', load, loadstring)
if content and content ~= "" then
local func, _ = eval(content)
if func then
return func()
end
else
return nil
end
end
local function for_each_dep(dep_path, skip_setup_call)
local path = fs.join({ dep_path, 'deps.lua' })
local setup_file = fs.join({ dep_path, 'setup.lua' })
if fs.exists(setup_file, true) then
os.execute('lua ' .. setup_file)
end
if skip_setup_call then
return
end
local deps_file = eval_script(path)
if deps_file then
cli.install.cb(deps_file)
end
end
if not fs.exists(install_path) then
cli.context.checked_deps[name] = true
if type(dep) == "string" then
print('\n--- Installing ' .. name .. ' into ' .. install_path .. ' ---')
os.execute('git clone --depth 1 ' .. dep .. ' ' .. install_path)
for_each_dep(install_path)
end
if type(dep) == "table" then
print('\n--- Installing ' .. name .. ' into ' .. install_path .. ' ---')
local branch = dep.branch or 'main'
local command = 'git clone --depth 1 --branch ' ..
branch .. ' ' .. dep.url .. ' ' .. fs.join({ install_path, name })
os.execute(command)
if dep.postInstall then
dep.postInstall(cb_context)
end
for_each_dep(install_path)
end
if type(dep) == "function" then
print('\n--- Running function for ' .. name)
dep(cb_context)
end
else
if not cli.context.checked_deps[name] then
print('The dependency "' .. name .. '" is already installed.')
cli.context.checked_deps[name] = true
for_each_dep(install_path)
end
end
end
local original_add_deps_to_path = utils.add_deps_to_path
add_deps_to_path = function()
original_add_deps_to_path(cli, fs)
end
utils.add_deps_to_path = add_deps_to_path
cb_context = {
fs = fs,
utils = utils,
}
local handler = cli:get_op(cli.context.op)
if handler then
handler.cb()
end
end)()
}
return _G.__LOADED[_G.main].M
end
function _G.cliutils()
if _G.__LOADED[_G.cliutils] and _G.__LOADED[_G.cliutils].called then
return _G.__LOADED[_G.cliutils].M
end
_G.__LOADED[_G.cliutils] = {called = true,M = (function()
local function tern(cond, if_true, if_false)
if cond then
return if_true
end
return if_false
end
local function add_deps_to_path(cli, fs)
local should_add_devdeps = false
local deps_dir = fs.ls(fs.join({ fs.cwd, cli.context.config.dep_folder_name }))
local deps_file = require('deps')
for _, dir_name in pairs(deps_dir) do
if dir_name == '_dev' then
should_add_devdeps = true
else
local src_dir = nil
if deps_file.dependencies[dir_name].src then
src_dir = dir_name
end
local package_path = fs.join({ fs.cwd, cli.context.config.dep_folder_name, dir_name, src_dir, '?.lua' })
package.path = package.path .. ';' .. package_path
end
end
if should_add_devdeps then
local dev_deps_dir = fs.ls(fs.join({ fs.cwd, cli.context.config.dep_folder_name, '_dev' }))
for _, dir_name in pairs(dev_deps_dir) do
local src_dir = nil
if deps_file.dev_dependencies[dir_name].src then
src_dir = dir_name
end
local package_path = fs.join({ fs.cwd, cli.context.config.dep_folder_name, '_dev', dir_name, src_dir, '?.lua' })
package.path = package.path .. ';' .. package_path
end
end
end
return {
tern = tern,
add_deps_to_path = add_deps_to_path,
}
end)()
}
return _G.__LOADED[_G.cliutils].M
end
function _G.clifs()
if _G.__LOADED[_G.clifs] and _G.__LOADED[_G.clifs].called then
return _G.__LOADED[_G.clifs].M
end
_G.__LOADED[_G.clifs] = {called = true,M = (function()
local utils = _G.cliutils()
local FS = {
cwd = os.getenv("PWD") or io.popen("cd"):read() --[[ @as string ]],
separator = utils.tern(package.config:sub(1, 1) == '/', '/', '\\') --[[ @as PathSeparator ]],
}
function FS.ls(path)
local files = {}
for file in io.popen("ls " .. path):lines() do
table.insert(files, file)
end
return files
end
function FS.join(paths)
local result = ''
for _, v in pairs(paths) do
if result == '' then
result = v
else
result = result .. FS.separator .. v
end
end
result = result:gsub('\n', '')
return result
end
function FS.exists(path, is_file)
local command = ''
local res_to_match = ''
local read_all_flag = ''
if OSNAME == OSNAMES.nix then
local arch_type = ' -d '
if is_file then arch_type = ' -f ' end
command = 'if [ ' .. arch_type .. '"' .. path .. '" ]; then echo "1"; else echo "0"; fi'
res_to_match = '1'
read_all_flag = '*a'
end
if OSNAME == OSNAMES.windows then
command = 'IF EXIST "' .. path .. '" echo 1 ELSE echo 0'
command = 'IF EXIST "' .. path .. '" (echo 1) ELSE (echo 0)'
res_to_match = '1'
read_all_flag = '*l'
end
local handle = io.popen(command)
if not handle then
error('Could not execute: ' .. command)
end
local result = handle:read(read_all_flag)
handle:close()
return result:match(res_to_match)
end
function FS.read_file(file_path)
if not FS.exists(file_path, true) then
return nil
end
local read_tool = ''
if OSNAME == 'windows' then
read_tool = 'type'
else
read_tool = 'cat'
end
local command = read_tool .. ' "' .. file_path .. '"'
local handle = io.popen(command)
if not handle then
error('Could not execute: ' .. command)
end
local result = handle:read("*a")
handle:close()
return result
end
return FS
end)()
}
return _G.__LOADED[_G.clifs].M
end
function _G.cliglobals()
if _G.__LOADED[_G.cliglobals] and _G.__LOADED[_G.cliglobals].called then
return _G.__LOADED[_G.cliglobals].M
end
_G.__LOADED[_G.cliglobals] = {called = true,M = (function()
OSNAMES = {
nix = 'nix',
windows = 'windows'
}
OSNAME = nil
local function load_osname()
if package.config:sub(1, 1) == '/' then
OSNAME = OSNAMES.nix
else
OSNAME = OSNAMES.windows
end
end
load_osname()
end)()
}
return _G.__LOADED[_G.cliglobals].M
end
return _G.main()
