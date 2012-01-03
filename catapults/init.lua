-- Catapults mod by xyz

-- How many seconds required to push one cannon ball
local catapult_speed = 5

minetest.register_node("catapults:catapult", {
    tile_inages = {"catapults_catapult.png"},
    inventory_image = minetest.inventorycube("catapults_catapult.png"),
    material = minetest.digprop_woodlike(1.5),
    param = "facedir_simple",
    metadata_name = "generic"
})

minetest.register_craftitem("catapults:cannon_ball", {
    image = "catapults_cannon_ball.png"
})

--[[
minetest.register_craft(
    output = 'craft "catapults:cannon_ball" 1',
    recipe = {

    }
)
]]

minetest.register_entity("catapults:cannon_ball_flying", {
    physical = true,
    collisionbox = {-0.2, -0.2, -0.2, 0.2, 0.2, 0.2},
    visual = "sprite",
    textures = {"catapults_cannon_ball.png"},
    on_step = function(self, dtime)
        local pos = self.object:getpos()
        local bcp = {x=pos.x, y=pos.y-0.7, z=pos.z}
        local bcn = minetest.env:get_node(bcp)
        if bcn.name ~= "air" then
            -- TODO: destroy something
            self.object:remove()
        end
    end
})

-- Returns timestamp
local function get_time()
    return os.time()
end

minetest.register_on_punchnode(function(pos, node, puncher)
    if node.name == "catapults:catapult" then
        local catapult_meta = minetest.env:get_meta(pos)
        local time_to_push = catapult_meta:get_string('time_to_push')
        if time_to_push == nil or time_to_push == '' then
            -- putin' some ball
            print('putin')
            catapult_meta:set_string('time_to_push', catapult_speed + get_time())
        elseif tonumber(time_to_push) < get_time() then
            print('Pushing')
            local ball = minetest.env:add_entity({x = pos.x, y = pos.y + 1, z = pos.z}, "catapults:cannon_ball_flying")
            ball:setacceleration({x = 0, y = -10, z = 0})
            -- TODO: velocity should depend on catapult rotation
            print(node.param2)
            ball:setvelocity({x = 50, y = 30, z = 0})
            catapult_meta:set_string('time_to_push', '')
        end
    end
end)

minetest.register_abm({
    nodenames = "catapults:catapult",
    interval = 1.0,
    chance = 1,
    action = function(pos, node)
        -- set loaded status
        local catapult_meta = minetest.env:get_meta(pos)
        local time_to_push = catapult_meta:get_string('time_to_push')
        print(get_time())
        print(time_to_push)
        local s = ''
        local time = get_time()
        if time_to_push == nil or time_to_push == "" then
            s = 'Click to load ball'
        elseif tonumber(time_to_push) <= time then
            s = 'Ready to shot!'
        else
            s = math.floor((1 - (tonumber(time_to_push) - time) / catapult_speed) * 100).."%"
        end
        catapult_meta:set_infotext(s)
    end
})
