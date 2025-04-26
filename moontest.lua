---@class Moontest_Utils
local utils = {
    tern = function(cond, if_true, if_false)
        if cond then
            return if_true
        end
        return if_false
    end,

    string = {
        starts_with = function(str, prefix)
            return str:sub(1, #prefix) == prefix
        end,

        ends_with = function(str, suffix)
            return str:sub(- #suffix) == suffix
        end,

        includes = function(str, substr)
            local result = string.find(str, substr)
            return result ~= nil
        end
    }
}

---@class Moontest_Fs
local fs = {
    cwd = os.getenv("PWD"):gsub(' ', '') --[[ @as string ]],
    os_name = utils.tern(package.config:sub(1, 1) == '/', 'unix', 'windows') --[[ @as 'unix' | 'window' ]],
    separator = utils.tern(package.config:sub(1, 1) == '/', '/', '\\'),

    file_exists = function(_, path)
        local file = io.open(path, "r")
        if file then
            file:close()
            return true
        end
        return false
    end,

    ls = function(_, path)
        local files = {}
        for file in io.popen("ls " .. path):lines() do
            table.insert(files, file)
        end
        return files
    end,

    attributes = function(_, path)
        local cmd = 'stat -c %F ' .. '"' .. path .. '"'
        local mode = io.popen(cmd):read("*a")
        mode = mode:gsub("\n", "")
        return { mode = mode }
    end,

    join = function(self, paths)
        local res = ''

        for i = 1, #paths do
            res = res .. self.separator .. paths[i]
        end

        res = string.gsub(res, '//', '/')
        return res
    end,
}

---@class Moontest
local moontest = {
    configs = {
        ignored_dirs = {},
        ignored_files = {},
        prerun = function() end,
        postrun = function() end,
        test_suffix = '_test.lua',
    },

    load_config = function(self)
        local success, config_file = pcall(function() return require('moontest_config') end)

        if not success then
            return
        end

        for k, v in pairs(config_file --[[ @as Moontest_Config ]]) do
            -- if k == 'ignored_dirs' then
            --     for i = 1, #config_file.ignored_dirs do
            --         table.insert(
            --             self.configs.ignored_dirs,
            --             fs:join({ fs.cwd, config_file.ignored_dirs[i] })
            --         )
            --     end
            -- end

            if v then
                self.configs[k] = v
            end
        end
    end
}

local current_test_path = ''

---@param name string
---@param body table<string, Moontest_ReservedMethods | fun(): nil>
function Describe(name, body)
    ---@class Moontest_ReservedMethods
    local reserved_methods = {
        before_all = true,
        before_each = true,
        after_each = true,
        after_all = true
    }
    print(name)

    if body.before_all then body.before_all() end

    for k, test_case in pairs(body) do
        if not reserved_methods[k] then
            if body.before_each then body.before_each() end
            test_case()
            if body.after_each then body.after_each() end
        end
    end

    if body.after_all then body.after_all() end
end

---@param name string
---@param test fun(): boolean[]
---@return fun(hooks: table): nil
function It(name, test)
    return function()
        local result = test()

        if not result then
            print('\t[FAILED]: None assertion list found' .. '.' .. ' Test file: ' .. current_test_path)
            return false
        end

        if #result == 0 then
            print('\t[FAILED]: None assertion found for: "' .. name .. '"' .. '.' .. ' Test file: ' .. current_test_path)
            return false
        end

        local stop = false

        for i, v in ipairs(result) do
            if v == false then
                print('\t[FAILED]: ' ..
                    name .. ': >> Assertion ' .. i .. ' failed' .. '.' .. ' Test file: ' .. current_test_path)
                stop = true
                break
            end
        end

        if stop then
            return
        end

        print('\tpassed: ' .. name)
    end
end

return {
    run = function()
        local function get_tests(dir_path, test_list)
            local files = fs:ls(dir_path)

            for _, file in ipairs(files) do
                if file ~= "." and file ~= ".." then
                    local path = dir_path

                    if not dir_path:match("/$") and not file:match("^/") then
                        path = path .. "/"
                    end

                    path = path .. file

                    if path:match(" ") then
                        error("Path cannot contain spaces: " .. path)
                    end

                    local attr = fs:attributes(path)

                    if attr.mode == "directory" then
                        get_tests(path, test_list)
                    elseif
                        attr.mode:match("file") and
                        file:match(moontest.configs.test_suffix .. "$")
                    then
                        local is_ignored = false

                        for i = 1, #moontest.configs.ignored_dirs do
                            if utils.string.includes(path, moontest.configs.ignored_dirs[i]) then
                                is_ignored = true
                                break
                            end
                        end

                        for i = 1, #moontest.configs.ignored_files do
                            if utils.string.includes(path, moontest.configs.ignored_files[i]) then
                                is_ignored = true
                                break
                            end
                        end

                        if not is_ignored then
                            table.insert(test_list, path)
                        end
                    end
                end
            end
        end

        moontest:load_config()

        local test_files = {}
        get_tests(fs.cwd, test_files)

        if moontest.configs.prerun then
            moontest.configs.prerun()
        end

        local cwd_len = #fs.cwd

        for i = 1, #test_files do
            local test_path = test_files[i]
            current_test_path = '.' .. string.sub(test_path, cwd_len + 1, #test_path)
            dofile(test_files[i])
        end

        if moontest.configs.postrun then
            moontest.configs.postrun()
        end
    end,
}

--- TYPES
--
---@alias Fn fun(): nil
--
---@class Moontest
---@field configs Moontest_Config
---@field reserved_methods Moontest_ReservedMethods
---@field before_each function
---@field after_each function
---@field prerun function
---@field after_all function
---@field load_config fun(self: Moontest): nil
--
---@class Moontest_Config
---@field test_suffix? string
---@field ignored_dirs? string[]
---@field ignored_files? string[]
---@field prerun? Fn | nil
---@field postrun? Fn | nil
--
---@class Moontest_ReservedMethods
---@field before_all true
---@field before_each true
---@field after_each true
---@field after_all true
--
---@class Moontest_Fs
---@field cwd string
---@field os_name string
---@field separator '/' | '\'
---@field file_exists fun(_: Moontest_Fs, path: string): boolean
---@field ls fun(_: Moontest_Fs, path: string): string[]
---@field attributes fun(_: Moontest_Fs, path: string): { mode: string }
---@field join fun(_: Moontest_Fs, paths: string[]): string
--
---@class Moontest_Utils
---@field tern fun(cond: boolean, if_true: any, if_false?: any): any
---@field string Moontest_UtilsString
--
---@class Moontest_UtilsString
---@field starts_with fun(str: string, prefix: string): boolean
---@field ends_with fun(str: string, suffix: string): boolean
---@field includes fun(str: string, substr: string): boolean
