-- Some variable(s) you can change

-- How often (in seconds) homes file saves
local save_delta = 10
----------------------------------

local homes_file = minetest.get_modpath('sethome')..'/homes'
local homepos = {}

local function loadhomes()
    local input = io.open(homes_file, "r")
    while true do
        local x = input:read("*n")
        if x == nil then
            break
        end
        local y = input:read("*n")
        local z = input:read("*n")
        local name = input:read("*l")
        homepos[name:sub(2)] = {x = x, y = y, z = z}
    end
    io.close(input)
end

loadhomes()

minetest.register_on_chat_message(function(name, message)
    if message == '/sethome' then
        local player = minetest.env:get_player_by_name(name)
        local pos = player:getpos()
        homepos[name] = pos
        minetest.chat_send_player(name, "Home set!")
        return true
    elseif message == "/home" then
        local player = minetest.env:get_player_by_name(name)
        if homepos[name] then
            player:setpos(homepos[name])
            minetest.chat_send_player(name, "Teleported to home!")
        else
            minetest.chat_send_player(name, "You don't have a home now! Set it using /sethome")
        end
        return true
    end
end)

local delta = 0
minetest.register_globalstep(function(dtime)
    delta = delta + dtime
    -- save it every <save_delta> seconds
    if delta > save_delta then
        delta = delta - save_delta
        local output = io.open(homes_file, "w")
        for i, v in pairs(homepos) do
            output:write(v.x.." "..v.y.." "..v.z.." "..i.."\n")
        end
        io.close(output)
    end
end)
