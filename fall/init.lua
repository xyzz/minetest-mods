-- Fall mod by xyz

local falling = {}

function register_falling_item(name, falling_type)
   if falling_type ~= "bottom" and falling_type ~= "param2" then
        return
   end
   falling[name] = falling_type 
end

local function binary(x)
    local res = {}
    while x > 0 do
        table.insert(res, x % 2)
        x = math.floor(x / 2)
    end
    return res
end

local function unpack_dir(d)
    local b = binary(d)
    local res = {x = 0, y = 0, z = 0}
    if b[1] == 1 then
        res.x = 1
    elseif b[2] == 1 then
        res.x = -1
    end
    if b[3] == 1 then
        res.y = 1
    elseif b[4] == 1 then
        res.y = -1
    end
    if b[5] == 1 then
        res.z = 1
    elseif b[6] == 1 then
        res.z = -1
    end
    return res
end

local function drop_node(pos, node)
    minetest.env:remove_node(pos)
    minetest.env:add_item(pos, 'node "'..node.name..'" 1')
end

local dx = {0, 0, 0, 0, 1, -1}
local dy = {0, 0, 1, -1, 0, 0}
local dz = {1, -1, 0, 0, 0, 0}

minetest.register_on_dignode(function(pos, oldnode, digger)
    for i = 1, 6 do
        local new_pos = {x = pos.x + dx[i], y = pos.y + dy[i], z = pos.z + dz[i]}
        local node = minetest.env:get_node(new_pos)
        if falling[node.name] == "bottom" then 
            if dx[i] == 0 and dy[i] == 1 and dz[i] == 0 then
                drop_node(new_pos, node)
            end
        elseif falling[node.name] == "param2" then
            local vec = unpack_dir(node.param2)
            if (dx[i] + vec.x == 0) and (dy[i] + vec.y == 0) and (dz[i] + vec.z == 0) then
                drop_node(new_pos, node)
            end
        end
    end
end)

minetest.register_on_placenode(function(pos, newnode, placer)
    if falling[newnode.name] == "bottom" then
        local b_pos = {x = pos.x, y = pos.y - 1, z = pos.z}
        local b_node = minetest.env:get_node(b_pos)
        if minetest.registered_nodes[b_node.name].walkable == false then
            drop_node(pos, newnode)
        end
    elseif falling[newnode.name] == "param2" then
        local vec = unpack_dir(newnode.param2)
        if minetest.registered_nodes[minetest.env:get_node({x = pos.x + vec.x, y = pos.y + vec.y, z = pos.z + vec.z}).name].walkable == false then
            drop_node(pos, newnode)
        end
    end
end)
