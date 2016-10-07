-- xFences mod by xyz
-- most code is taken from xPanes

local REPLACE_DEFAULT_FENCES = false

local function rshift(x, by)
  return math.floor(x / 2 ^ by)
end

local function merge(lhs, rhs)
    local merged_table = {}
    for _, v in ipairs(lhs) do
        table.insert(merged_table, v)
    end
    for _, v in ipairs(rhs) do
        table.insert(merged_table, v)
    end
    return merged_table
end

local directions = {
    {x = 1, y = 0, z = 0},
    {x = 0, y = 0, z = 1},
    {x = -1, y = 0, z = 0},
    {x = 0, y = 0, z = -1},
}

local function update_fence(pos)
    if minetest.env:get_node(pos).name:find("xfences:fence") == nil then
        return
    end
    local sum = 0
    for i = 1, 4 do
        local node = minetest.env:get_node({x = pos.x + directions[i].x, y = pos.y + directions[i].y, z = pos.z + directions[i].z})
        if minetest.registered_nodes[node.name].walkable ~= false then
            sum = sum + 2 ^ (i - 1)
        end
    end
    minetest.env:add_node(pos, {name = "xfences:fence_"..sum})
end

local function update_nearby(pos)
    for i = 1,4 do
        update_fence({x = pos.x + directions[i].x, y = pos.y + directions[i].y, z = pos.z + directions[i].z})
    end
end

local blocks = {
    {{0, 0.25, -0.06, 0.5, 0.4, 0.06}, {0, -0.15, -0.06, 0.5, 0, 0.06}},
    {{-0.06, 0.25, 0, 0.06, 0.4, 0.5}, {-0.06, -0.15, 0, 0.06, 0, 0.5}},
    {{-0.5, 0.25, -0.06, 0, 0.4, 0.06}, {-0.5, -0.15, -0.06, 0, 0, 0.06}},
    {{-0.06, 0.25, -0.5, 0.06, 0.4, 0}, {-0.06, -0.15, -0.5, 0.06, 0, 0}}
}

local limiters = {
    {{0, 1.0, -0.1, 0.5, 1.0, -0.0999}, {0, 1.0, 0.0999, 0.5, 1.0, 0.1}},
    {{-0.1, 1.0, 0, -0.0999, 1.0, 0.5}, {0.0999, 1.0, 0, 0.1, 1.0, 0.5}},
    {{-0.5, 1.0, -0.1, 0, 1.0, -0.0999}, {-0.5, 1.0, 0.0999, 0, 1.0, 0.1}},
    {{-0.1, 1.0, -0.5, -0.0999, 1.0, 0}, {0.0999, 1.0, -0.5, 0.1, 1.0, 0}},
}

local base = {-0.1, -0.5, -0.1, 0.1, 0.5, 0.1}

for i = 0, 15 do
    local take = {base}
    local take_with_limits = {base}
    for j = 1, 4 do
        if rshift(i, j - 1) % 2 == 1 then
            take = merge(take, blocks[j])
            take_with_limits = merge(take_with_limits, merge(blocks[j], limiters[j]))
        end
    end

    local texture = "default_wood.png"
    minetest.register_node("xfences:fence_"..i, {
        drawtype = "nodebox",
        tiles = {texture},
        paramtype = "light",
        groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
        drop = "xfences:fence",
        node_box = {
            type = "fixed",
            fixed = take_with_limits
        },
        selection_box = {
            type = "fixed",
            fixed = take
        },
        sounds = default.node_sound_wood_defaults(),
    })
end

minetest.register_node("xfences:fence", {
    description = "Wooden Fence",
    tiles = {"xfences_space.png"},
    inventory_image = "default_fence_overlay.png^default_wood.png^default_fence_overlay.png^[makealpha:255,126,126",
    wield_image = "default_fence_overlay.png^default_wood.png^default_fence_overlay.png^[makealpha:255,126,126",
    node_placement_prediction = "",
    on_construct = update_fence
})

minetest.register_on_placenode(update_nearby)
minetest.register_on_dignode(update_nearby)

minetest.register_craft({
	output = 'xfences:fence 2',
	recipe = {
		{'default:stick', 'default:stick', 'default:stick'},
        {'default:stick', 'default:stick', 'default:stick'}
	}
})

if REPLACE_DEFAULT_FENCES then
    minetest.register_abm({
        nodenames = {"default:fence_wood"},
        interval = 0.1,
        chance = 1,
        action = function(pos)
            minetest.env:add_node(pos, {name = "xfences:fence"})
        end
    })
    minetest.register_alias("default:fence_wood", "xfences:fence")
end
