# moontest

Single file test utility for testing

## Example

```lua
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

Describe("Example test - Person", function(mt)
    mt.beforeEach(function()
        person = Person("John", 21)
    end)

    It("should return name and age", function()
        local data = person:get_data()
        mt.eq(data.name, "John")
        mt.eq(data.age, 21)
    end)

    It("should set data", function()
        person:set_data({ name = "John 2", age = 200 })
        local data = person:get_data()
        mt.eq(data.name, "John 2")
        mt.eq(data.age, 2000)
    end)
end)
```

## Config file - optional

```lua
-- default values
return {
  -- optional
  test_suffix = '_test.lua',
  -- optional
  ignored_dirs = {
    'ignored_dir_one',
    'ignored_dir_two',
  },
  -- optional
  ignored_files = {
    'run_test.lua',
  }
}
```

## Execution

```bash
lua src/moontest.lua
```