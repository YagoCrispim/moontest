local u = require 'src.utils'
local fs = require 'src.fs'

---@class Moontest
local Moontest = {
    ignoredDirs = {},
    ignoredFiles = {},
    testSuffix = '_test.lua',
    config = {},
    currentScope = nil,
    testsStack = {}
}
local currentFilePath = ''
_G.Moontest = true

-------------

local function pushScope()
    ---@type Moontest_Scope
    local scope = {
        testName = '',
        tests = {},
        failure = false,
        hooks = {
            afterAll = {},
            afterEach = {},
            beforeAll = {},
            beforeEach = {},
        }
    }
    table.insert(Moontest.testsStack, scope)
end

local function popScope()
    table.remove(Moontest.testsStack, #Moontest.testsStack)
end

local function loadConfig()
    local success, configFile = pcall(
        function()
            ---@return Moontest_Config
            return require('moontest')
        end)

    if not success then
        return
    end

    for k, v in pairs(configFile) do
        if v then
            Moontest.config[k] = v
        end
    end
end

local function getTests(dir)
    local tests = {}

    local function collect(pathDir)
        local files = fs.ls(pathDir)

        for _, file in ipairs(files) do
            if file ~= "." and file ~= ".." then
                local path = pathDir

                if not pathDir:match("/$") and not file:match("^/") then
                    path = path .. "/"
                end

                path = path .. file

                if path:match(" ") then
                    error("Path cannot contain spaces: " .. path)
                end

                local attr = fs.attributes(path)

                if attr.mode == "directory" then
                    collect(path)
                elseif
                    u.string.includes(string.lower(attr.mode), 'file') and
                    file:match(Moontest.testSuffix .. "$")
                then
                    local is_ignored = false

                    for i = 1, #Moontest.ignoredDirs do
                        if u.string.includes(path, Moontest.ignoredDirs[i]) then
                            is_ignored = true
                            break
                        end
                    end

                    for i = 1, #Moontest.ignoredFiles do
                        if u.string.includes(path, Moontest.ignoredFiles[i]) then
                            is_ignored = true
                            break
                        end
                    end

                    if not is_ignored then
                        table.insert(tests, path)
                    end
                end
            end
        end
    end
    collect(dir)

    return tests
end

---@param expected any
---@param received any
local function eq(expected, received)
    if expected ~= received then
        Moontest.currentScope.failure = true
        print('\t[FAILED]: ' .. Moontest.currentScope.testName .. ' -- ' .. currentFilePath .. '\n' ..
            '\t  + Expected: ' .. expected .. '\n' ..
            '\t  - Received: ' .. received)
    end
end

---@param name string
---@param test fun(): nil
local function it(name, test)
    table.insert(Moontest.currentScope.tests, function()
        Moontest.currentScope.testName = name
        test()
        if Moontest.currentScope.failure == false then
            print('\tsuccess: ' .. name)
        end
    end)
end

---@param name string
---@param cb function
function Describe(name, cb)
    pushScope()

    Moontest.currentScope = Moontest.testsStack[#Moontest.testsStack]
    local scope = Moontest.currentScope --[[ @as Moontest_Scope ]]

    ---@type Moontest_DescribeContext
    local mt = {
        it = it,
        eq = eq,
        ---@param hcb function
        beforeAll = function(hcb)
            table.insert(scope.hooks.beforeAll, hcb)
        end,
        ---@param hcb function
        beforeEach = function(hcb)
            table.insert(scope.hooks.beforeEach, hcb)
        end,
        ---@param hcb function
        afterAll = function(hcb)
            table.insert(scope.hooks.afterAll, hcb)
        end,
        ---@param hcb function
        afterEach = function(hcb)
            table.insert(scope.hooks.afterEach, hcb)
        end,
    }

    print(name)
    cb(mt)

    for i = 1, #scope.hooks.beforeAll do
        scope.hooks.beforeAll[i]()
    end

    for _, testCase in pairs(scope.tests) do
        for i = 1, #scope.hooks.beforeEach do
            scope.hooks.beforeEach[i]()
        end

        testCase()

        for i = 1, #scope.hooks.afterEach do
            scope.hooks.afterEach[i]()
        end
    end

    for i = 1, #scope.hooks.afterAll do
        scope.hooks.afterAll[i]()
    end

    popScope()
end

loadConfig()

local testFiles = getTests(fs.cwd)

for i = 1, #testFiles do
    currentFilePath = testFiles[i]
    dofile(testFiles[i])
end

--
---@alias Fn fun(): nil
--
---@class Moontest
---@field testSuffix string
---@field ignoredDirs string[]
---@field ignoredFiles string[]
---@field config Moontest_Config
---@field testsStack Moontest_Scope[]
---@field currentScope? Moontest_Scope
--
---@class Moontest_Config
---@field testSuffix? string
---@field ignoredDirs? string[]
---@field ignoredFiles? string[]
--
---@class Moontest_Scope
---@field testName string
---@field tests function[]
---@field hooks Moontest_Hooks
---@field failure boolean
--
---@class Moontest_Hooks
---@field beforeAll function[]
---@field beforeEach function[]
---@field afterEach function[]
---@field afterAll function[]
--
---@class Moontest_DescribeContext
---@field it function
---@field eq fun(expected: any, received: any): nil
---@field beforeAll fun(hookCb: function): nil
---@field beforeEach fun(hookCb: function): nil
---@field afterEach fun(hookCb: function): nil
---@field afterAll fun(hookCb: function): nil
