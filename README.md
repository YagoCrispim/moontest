# moontest

Single file test utility without dependencies

## Example

```lua
-- moontest_config.lua

return {
  test_suffix = '_test.lua',
  ignored_dirs = {
    -- 'dir_one',
    -- 'dir_two',
  },
  ignored_files = {
    'run_test.lua',
  }
}
```

```lua
-- test.lua

---@param name string
---@param age number
---@return Person
local function Person(name, age)
    ---@class Person
    ---@field set_data fun(_: Person, data: { name: string, age: number }): nil
    ---@field get_data fun(_: Person): { name: string, age: number }
    return {
        set_data = function(_, data)
            name = data.name
            age = data.age
        end,

        get_data = function()
            --
            return { name = name, age = age }
        end
    }
end

---@type Person
local person = nil

Describe("Example test - Person", {
    -- before_all = function() print("Before all") end,
    -- after_all = function() print("After all") end,
    before_each = function()
        person = Person("John", 21)
    end,
    -- after_each = function() print("After each") end,
    --
    It("should return name and age", function()
        local data = person:get_data()
        return { data.name == "John", data.age == 21 }
    end), --
    --
    It("should set data", function()
        person:set_data({ name = "John 2", age = 200 })
        local data = person:get_data()
        return { data.name == "John 2", data.age == 200 }
    end) --
})
```

## WIP docs
