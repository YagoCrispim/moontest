local test_hooks = {before_each = function() end, after_each = function() end}

local reserved_methods = {
    before_all = 1,
    before_each = 1,
    after_each = 1,
    after_all = 1
}

---@param name string
---@param body Moontest_Hooks | table<Moontest_It>
local function describe(name, body)
    print('Running ' .. name .. ' tests')

    if body.before_all then body.before_all() end
    if body.before_each then test_hooks.before_each = body.before_each end
    if body.after_each then test_hooks.after_each = body.after_each end

    for k, test_case in pairs(body) do
        if not reserved_methods[k] then test_case(test_hooks) end
    end

    if body.after_all then body.after_all() end

    test_hooks.before_each = function() end
    test_hooks.after_each = function() end
end

---@class Moontest_It
---@param name string
---@param test fun(): boolean[]
---@return fun(hooks: table): nil
local function it(name, test)
    return function(hooks)
        hooks.before_each()
        local result = test()

        if not result then
            print('\t[FAILED]: None assertion list found')

            hooks.after_each()
            return false
        end

        if #result == 0 then
            print('\t[FAILED]: None assertion found for: "' .. name .. '"')
            hooks.after_each()
            return false
        end

        local stop = false

        for i, v in ipairs(result) do
            if v == false then
                print('\t[FAILED]: ' .. name .. ': >> Assertion ' .. i .. ' failed')
                stop = true
                break
            end
        end

        if stop then

            hooks.after_each()
            return
        end

        print('\tpassed: ' .. name)
        hooks.after_each()
    end
end

return {describe = describe, it = it}

--[[
  TYPES
]]
---@class Moontest_Hooks
---@field before_each function
---@field after_each function
---@field before_all function
---@field after_all function
