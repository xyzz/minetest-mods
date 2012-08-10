-- xDoors² mod by xyz

-- remove default doors (or left/right version) and drop new doors
local REMOVE_OTHER_DOORS = false

local door_bottom = {-0.5, -0.5, -0.5, 0.5, 0.5, -0.4}
local door_top = {
    {-0.5, -0.5, -0.5, -0.3, 0.5, -0.4},
    {0.3, -0.5, -0.5, 0.5, 0.5, -0.4},
    {-0.3, 0.3, -0.5, 0.3, 0.5, -0.4},
    {-0.3, -0.5, -0.5, 0.3, -0.4, -0.4},
    {-0.05, -0.4, -0.5, 0.05, 0.3, -0.4},
    {-0.3, -0.1, -0.5, -0.05, 0, -0.4},
    {0.05, -0.1, -0.5, 0.3, 0, -0.4}
}

local is_top = function(name)
    return name:sub(14, 14) == "t"
end

local xdoors2_transform = function(pos, node)
    if is_top(node.name) then
        pos = {x = pos.x, y = pos.y - 1, z = pos.z}
    end
    local t = 3 - node.name:sub(-1)
    local p2 = 0
    if t == 2 then
        p2 = (node.param2 + 1) % 4
    else
        p2 = (node.param2 + 3) % 4
    end
    minetest.env:add_node(pos, {name = "xdoors2:door_bottom_"..t, param2 = p2})
    minetest.env:add_node({x = pos.x, y = pos.y + 1, z = pos.z}, {name = "xdoors2:door_top_"..t, param2 = p2})
end

local xdoors2_destruct = function(pos, oldnode)
    if is_top(oldnode.name) then
        pos = {x = pos.x, y = pos.y - 1, z = pos.z}
    end
    minetest.env:remove_node(pos)
    minetest.env:remove_node({x = pos.x, y = pos.y + 1, z = pos.z})
end

for i = 1, 2 do
    minetest.register_node("xdoors2:door_top_"..i, {
        tile_images = {"xdoors2_side.png", "xdoors2_side.png", "xdoors2_top.png", "xdoors2_bottom.png", "xdoors2_top_"..(3 - i)..".png", "xdoors2_top_"..i..".png"},
        paramtype = "light",
        paramtype2 = "facedir",
        drawtype = "nodebox",
        drop = "xdoors2:door",
        groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
        node_box = {
            type = "fixed",
            fixed = door_top
        },
        selection_box = {
            type = "fixed",
            fixed = door_bottom
        },
        on_punch = xdoors2_transform,
        after_dig_node = xdoors2_destruct
    })
    minetest.register_node("xdoors2:door_bottom_"..i, {
        tile_images = {"xdoors2_side.png", "xdoors2_side.png", "xdoors2_top.png", "xdoors2_bottom.png", "xdoors2_bottom_"..(3 - i)..".png", "xdoors2_bottom_"..i..".png"},
        paramtype = "light",
        paramtype2 = "facedir",
        drawtype = "nodebox",
        drop = "xdoors2:door",
        groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
        node_box = {
            type = "fixed",
            fixed = door_bottom
        },
        selection_box = {
            type = "fixed",
            fixed = door_bottom
        },
        on_punch = xdoors2_transform,
        after_dig_node = xdoors2_destruct
    })
end

local delta = {
    {x = -1, z = 0},
    {x = 0, z = 1},
    {x = 1, z = 0},
    {x = 0, z = -1}
}

minetest.register_node("xdoors2:door", {
    description = "Wooden Door",
    node_placement_prediction = "",
    inventory_image = 'xdoors2_door.png',
    wield_image = 'xdoors2_door.png',
    stack_max = 1,
    on_place = function(itemstack, placer, pointed_thing)
        local above = pointed_thing.above

        -- there should be 2 empty nodes
        if minetest.env:get_node({x = above.x, y = above.y + 1, z = above.z}).name ~= "air" then
            return itemstack
        end
        
        local fdir = 0
        local placer_pos = placer:getpos()
        if placer_pos then
            dir = {
                x = above.x - placer_pos.x,
                y = above.y - placer_pos.y,
                z = above.z - placer_pos.z
            }
            fdir = minetest.dir_to_facedir(dir)
        end

        local t = 1
        local another_door = minetest.env:get_node({x = above.x + delta[fdir + 1].x, y = above.y, z = above.z + delta[fdir + 1].z})
        if (another_door.name:sub(-1) == "1" and another_door.param2 == fdir)
            or (another_door.name:sub(-1) == "2" and another_door.param2 == (fdir + 1) % 4) then
            t = 2
        end

        minetest.env:add_node(above, {name = "xdoors2:door_bottom_"..t, param2 = fdir})
        minetest.env:add_node({x = above.x, y = above.y + 1, z = above.z}, {name = "xdoors2:door_top_"..t, param2 = fdir})
        return ItemStack("")
    end
})

minetest.register_craft({
	output = 'xdoors2:door',
	recipe = {
		{ 'default:wood', 'default:wood', '' },
		{ 'default:wood', 'default:wood', '' },
		{ 'default:wood', 'default:wood', '' },
	},
})

if REMOVE_OTHER_DOORS then
    minetest.register_abm({
        nodenames = {"doors:door_wood_a_c", "doors:door_wood_b_c", "doors:door_wood_a_o", "doors:door_wood_b_o",
                     "doors:door_wood_right_a_c", "doors:door_wood_right_b_c", "doors:door_wood_right_a_o", "doors:door_wood_right_b_o",
                     "doors:door_wood_left_a_c", "doors:door_wood_left_b_c", "doors:door_wood_left_a_o", "doors:door_wood_left_b_o",
                     "xdoors:door_1_1", "xdoors:door_1_2", "xdoors:door_2_1", "xdoors:door_2_2",
                     "xdoors:door_3_1", "xdoors:door_3_2", "xdoors:door_4_1", "xdoors:door_4_2"},
        interval = 0.1,
        chance = 1,
        action = function(pos, node)
            minetest.env:remove_node(pos)
            if node.name:find("_b") ~= nil or node.name:find("xdoors:door") ~= nil then
                minetest.env:add_item(pos, "xdoors2:door")
            end
        end
    })
    minetest.register_alias("doors:door_wood_right", "xdoors2:door")
    minetest.register_alias("doors:door_wood_left", "xdoors2:door")
    minetest.register_alias("doors:door_wood", "xdoors2:door")
end
