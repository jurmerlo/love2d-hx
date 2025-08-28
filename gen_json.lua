local love_api = require("luaLibs.love-api.love_api")
local json = require("luaLibs.json_lua.json")

local function generate_json()
    local json_data = json.encode(love_api)
    json_data = json_data:gsub("\"default\":", "\"defaultValue\":") -- replace "default" with "defaultValue"
    local file = io.open("data/love_api.json", "w")
    if file then
        file:write(json_data)
        file:close()
    end
end

generate_json()
