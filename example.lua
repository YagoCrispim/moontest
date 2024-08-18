local mt = require "moontest"

local function Person(name, age)
    local _name = name
    local _age = age

    return {
        set_data = function(_, data)
            _name = data.name
            _age = data.age
        end,

        get_data = function()
            --
            return {name = _name, age = _age}
        end
    }
end

-- test context
local tc = {person = nil}

mt.describe("Person", {
    -- before_all = function() print("Before all") end,
    -- after_all = function() print("After all") end,
    before_each = function()
        --
        tc.person = Person("John", 21)
    end,
    -- after_each = function() print("After each") end,
    --
    mt.it("should return name and age", function()
        local data = tc.person:get_data()
        return {data.name == "John", data.age == 21}
    end), --
    --
    mt.it("should set data", function()
        tc.person:set_data({name = "John 2", age = 200})
        local data = tc.person:get_data()
        return {data.name == "John 2", data.age == 200}
    end) -- 
})
