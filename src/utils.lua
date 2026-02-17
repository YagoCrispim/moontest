local function tern(cond, if_true, if_false)
  if cond then
    return if_true
  end
  return if_false
end


---@return MT_OSName
local function getOSName()
  local osname = ''

  local fh, _ = assert(io.popen("uname -o 2>/dev/null", "r"))
  if fh then
    osname = fh:read()
  end

  return string.lower(osname) or "windows"
end

return {
  tern = tern,
  getOSName = getOSName,
  string = {
    ---@param str string
    ---@param prefix string
    ---@return boolean
    startsWith = function(str, prefix)
      return str:sub(1, #prefix) == prefix
    end,

    ---@param str string
    ---@param suffix string
    ---@return boolean
    endsWith = function(str, suffix)
      return str:sub(- #suffix) == suffix
    end,

    ---@param str string
    ---@param substr string
    ---@return boolean
    includes = function(str, substr)
      local result = string.find(str, substr)
      return result ~= nil
    end
  }
}
