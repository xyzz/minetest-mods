-- Drop mod allows to make nodes drop things in better way
-- Example:
--[[
minetest.register_node("drop:example", {
    ...
    drop = {
        -- how many items will be dropped to player inventory maximum? it depends on order! 
        max_items = 1,
        items = {{
            -- what item player will get?
            -- use table here
            items = {'node "drop:example"', 'craft "drop:example2"'},
            -- what tool player should use? (start with ~ to make mod search substring, for example "~hoe" will match default:hoe_wood, experimental:ohoe and so on)
            -- you should use table here
            tools = {"~pick", "~axe"},
            -- just some integer: how much nodes of that type should player dig to get this one item
            rarity = 5
        }, {
            ...
        }, {
            ...
            you can define any amount of tables, but their order is really important!
        }}
    }
})
]]

math.randomseed(os.time())

minetest.register_on_dignode(function(pos, oldnode, digger)
    local drop = minetest.registered_nodes[oldnode.name].drop
    if drop == nil or drop.items == nil then
        -- nothing to do
        return
    end

    local got_items = 0
    for _, item in ipairs(drop.items) do
        local rarity = item.rarity
        if rarity == nil then
            rarity = 1
        end
        local tools = item.tools
        local good_tool = false
        local player_tool = digger:get_wielded_item().name
        print(player_tool)
        if tools ~= nil then
            for _, tool in ipairs(tools) do
                if tool:sub(1, 1) == '~' then
                    good_tool = player_tool:find(tool:sub(2)) ~= nil
                else
                    good_tool = player_tool == tool
                end
                print(good_tool)
                if good_tool then
                    break
                end
            end
        else
            good_tool = true
        end
        if good_tool and math.random(rarity) == 1 then
            got_items = got_items + 1

            for _, add_item in ipairs(item.items) do
                digger:add_to_inventory(add_item)
            end

            if drop.max_items ~= nil and got_items == drop.max_items then
                break
            end
        end
    end
end)
