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
