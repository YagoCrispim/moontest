# moontest

Lightweight, single-file testing utility for Lua.
It provides a simple and expressive API for defining test suites, test cases, and setup hooks without external dependencies or complex configuration.

## Example

```lua
local function Person(name, age)
    return {
        set_data = function(_, data)
            name = data.name
            age = data.age
        end,
        get_data = function()
            return { name = name, age = age }
        end
    }
end

Describe("Example test - Person", function(mt)
    local person = {}

    mt.beforeEach(function()
        person = Person("John", 21)
    end)

    mt.it("should return name and age", function()
        local data = person:get_data()
        mt.eq(data.name, "John")
        mt.eq(data.age, 21)
    end)

    mt.it("should set data", function()
        person:set_data({ name = "John 2", age = 200 })
        local data = person:get_data()
        mt.eq(data.name, "John 2")
        mt.eq(data.age, 2000)
    end)
end)
```

## Optional Configuration File

- All configuration fields are optional. If no configuration file is provided, default settings will be used.
- You can customize test discovery behavior by creating a `moontest.lua` file:

```lua
-- moontest.lua
-- default values
return {
  -- Optional: file suffix used to identify test files
  testSuffix = '_test.lua',

  -- Optional: directories to ignore during test discovery
  ignoredDirs = {
    'ignored_dir_one',
    'ignored_dir_two',
  },

  -- Optional: specific files to ignore
  ignoredFiles = {
    'run_test.lua',
  }
}
```

## Running Tests

- The runner will automatically discover and execute test files according to the configuration rules.
- Execute the test runner from the command line:

```bash
lua src/moontest.lua
```
