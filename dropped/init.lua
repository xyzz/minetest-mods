math.randomseed(os.time())

local function drop_inventory(player, name)
    local items = player:inventory_get_list(name)
    local pos = player:getpos()
    for _, item in ipairs(items) do
        if item ~= "" then
            minetest.env:add_item({x = pos.x + math.random() * 2 - 1, y = pos.y, z = pos.z + math.random() * 2 - 1}, item)
        end
    end
    player:inventory_set_list(name, {})
end

minetest.register_on_dieplayer(function(player)
    drop_inventory(player, "main")
    drop_inventory(player, "craft")
    -- this is quite buggy and can lead to duplicating things
    --drop_inventory(player, "craftresult")
end)
