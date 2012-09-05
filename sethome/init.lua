-- Some variables you can change

-- How often (in seconds) homes file saves
local save_delta = 10
-- How often (in seconds) player can teleport
-- Set it to 0 to disable
local cooldown = 0
-- Max distance player can teleport, otherwise he will see error messsage
-- Set it to 0 to disable
local max_distance = 0
----------------------------------

local homes_file = minetest.get_modpath('sethome')..'/homes'
--local homes_file = minetest.get_worldpath() .. "/homes"
local homepos = {}
local last_moved = {}

local function loadhomes()
    local input = io.open(homes_file, "r")
    if input then
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
    else
        homepos = {}
    end
end

loadhomes()

local function get_time()
    return os.time()
end

local function distance(a, b)
    return math.sqrt(math.pow(a.x-b.x, 2) + math.pow(a.y-b.y, 2) + math.pow(a.z-b.z, 2))
end

local function round(num, idp)
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

local changed = false

minetest.register_privilege("home", "Can use /home and /sethome commands")

minetest.register_chatcommand("home", {
    privs = {home=true},
    description = "Teleport you to your home point",
    func = function(name, param)
        local player = minetest.env:get_player_by_name(name)
        if player == nil then
            -- just a check to prevent server death
            return false
        end
        if homepos[name] then
            local time = get_time()
            if cooldown ~= 0 and last_moved[name] ~= nil and time - last_moved[name] < cooldown then
                minetest.chat_send_player(name, "You can teleport only once in "..cooldown.." seconds. Wait another "..round(cooldown - (time - last_moved[name]), 3).." secs...")
                return true
            end
            local pos = player:getpos()
            local dst = distance(pos, homepos[name])
            if max_distance ~= 0 and distance(pos, homepos[name]) > max_distance then
                minetest.chat_send_player(name, "You are too far away from your home. You must be "..round(dst - max_distance, 3).." meters closer to teleport to your home.")
                return true
            end
            last_moved[name] = time
            player:setpos(homepos[name])
            minetest.chat_send_player(name, "Teleported to home!")
        else
            minetest.chat_send_player(name, "You don't have a home now! Set it using /sethome.")
        end
    end,
})

minetest.register_chatcommand("sethome", {
    privs = {home=true},
    description = "Set your home point",
    func = function(name, param)
        local player = minetest.env:get_player_by_name(name)
        local pos = player:getpos()
        homepos[name] = pos
        minetest.chat_send_player(name, "Home set!")
        changed = true
    end,
})

local delta = 0
minetest.register_globalstep(function(dtime)
    delta = delta + dtime
    -- save it every <save_delta> seconds
    if delta > save_delta then
        delta = delta - save_delta
        if changed then
            local output = io.open(homes_file, "w")
            for i, v in pairs(homepos) do
                output:write(v.x.." "..v.y.." "..v.z.." "..i.."\n")
            end
            io.close(output)
            changed = false
        end
    end
end)
