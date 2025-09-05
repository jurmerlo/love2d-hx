local love_api = require('luaLibs.love-api.love_api')
local json = require('luaLibs.json')
local function generate_json()
  local api = json.encode(love_api)
  api = api:gsub('"default":', '"defaultValue":') -- replace "default" with "defaultValue" because "default" is a reserved keyword in Haxe.
  api = api:gsub('"\'restart\'"', '"restart"') -- replace 'restart' with restart to fix the output.
  local file = io.open('love_api.json', 'w')
  if file then
    print('Generating love_api.json')
    file:write(api)
    file:close()
  end
end


generate_json()
