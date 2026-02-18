local u = require 'src.utils'

---@class MT_FS
---@field cwd string
---@field osName MT_OSName
---@field separator string
local FS = {
  cwd = '',
  osName = 'linux',
  separator = '',
}
FS.osName = u.getOSName()
FS.cwd, _ = os.getenv("PWD"):gsub(' ', '')
FS.separator = u.tern(FS.osName == 'windows', '\\', '/')

---@param path string
---@return boolean
function FS.fileExists(path)
  local file = io.open(path, "r")
  if file then
    file:close()
    return true
  end
  return false
end

---@param path string
---@return string[]
function FS.ls(path)
  local files = {}
  for file in io.popen("ls " .. path):lines() do
    table.insert(files, file)
  end
  return files
end

---@param path string
---@return { mode: string }
function FS.attributes(path)
  local cmd = ''

  if FS.osName == 'darwin' then
    cmd = 'stat -f %HT ' .. '"' .. path .. '"'
  else
    cmd = 'stat -c %F ' .. '"' .. path .. '"'
  end

  local mode = io.popen(cmd):read("*a")
  mode = mode:gsub("\n", "")
  return { mode = mode }
end

---@param paths string
---@return string
function FS.join(paths)
  local res = ''

  for i = 1, #paths do
    res = res .. FS.separator .. paths[i]
  end

  res = string.gsub(res, '//', '/')
  return res
end

return FS
--
---@alias MT_OSName 'darwin' | 'linux' | 'windows'
