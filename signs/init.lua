-- Font: 04.jp.org

-- load characters map
local chars_file = io.open(minetest.get_modpath("signs").."/characters", "r")
local charmap = {}
local charwidth = {}
local max_chars = 16
if not chars_file then
    print("[signs] E: character map file not found")
else
    while true do
        local char = chars_file:read("*l")
        if char == nil then
            break
        end
        local img = chars_file:read("*l")
        local width = chars_file:read("*n")
        chars_file:read("*l")
        charmap[char] = img
        charwidth[img] = width
    end
end

print(dump(charmap))

local metas = {"line1", "line2", "line3", "line4", "line5", "line6", "line7"}
local signs = {
    ["2"] = {nodebox = {0.4, -0.15, -0.45, 0.498, 0.45, 0.45}, delta = {x = 0.399, y = 0, z = 0}, yaw = math.pi / -2},
    ["3"] = {nodebox = {-0.498, -0.15, -0.45, -0.4, 0.45, 0.45}, delta = {x = -0.399, y = 0, z = 0}, yaw = math.pi / 2},
    ["4"] = {nodebox = {-0.45, -0.15, 0.4, 0.45, 0.45, 0.498}, delta = {x = 0, y = 0, z = 0.399}, yaw = 0},
    ["5"] = {nodebox = {-0.45, -0.15, -0.498, 0.45, 0.45, -0.4}, delta = {x = 0, y = 0, z = -0.399}, yaw = math.pi},
}

for param2 in pairs(signs) do
    local definition = signs[param2]
    minetest.register_node("signs:sign_"..param2, {
        drawtype = "nodebox",
        drop = "signs:sign",
        tiles = {"default_wood.png"},
        node_box = {type = "fixed", fixed = definition.nodebox},
        selection_box = {type = "fixed", fixed = definition.nodebox},
        sunlight_propagates = true,
        paramtype = "light",
        walkable = false,

        on_construct = function(pos)
            local meta = minetest.env:get_meta(pos)
            meta:set_string("formspec", "size[7,8]"..
                "field[1,0;6,3;line1;;${line1}]"..
                "field[1,1;6,3;line2;;${line2}]"..
                "field[1,2;6,3;line3;;${line3}]"..
                "field[1,3;6,3;line4;;${line4}]"..
                "field[1,4;6,3;line5;;${line5}]"..
                "field[1,5;6,3;line6;;${line6}]"..
                "field[1,6;6,3;line7;;${line7}]")
        end,
        on_receive_fields = function(pos, formname, fields, sender)
            local meta = minetest.env:get_meta(pos)
            local text = {}
            for i = 1, #metas do
                table.insert(text, fields[metas[i]])
                meta:set_string(metas[i], fields[metas[i]])
            end
            local object = minetest.env:get_objects_inside_radius(pos, 0.5)[1]
            object:set_properties({textures={generate_texture(text)}})
        end,
    })
end

minetest.register_node("signs:sign", {
    description = "Sign",
    inventory_image = "default_sign_wall.png",
    wield_image = "default_sign_wall.png",
    stack_max = 1,
    node_placement_prediction = "",

    on_place = function(itemstack, placer, pointed_thing)
        local above = pointed_thing.above
        local under = pointed_thing.under
        local dir = {x = under.x - above.x, 
                     y = under.y - above.y, 
                     z = under.z - above.z}

        local wdir = minetest.dir_to_wallmounted(dir)

        if wdir < 2 then
            --top/bottom not implemented =(
            minetest.env:add_item(above, "signs:sign")
        else
            minetest.env:add_node(above, {name="signs:sign_"..wdir})

            local text = minetest.env:add_entity({x = above.x + signs[wdir..""].delta.x, 
                                                  y = above.y + signs[wdir..""].delta.y,
                                                  z = above.z + signs[wdir..""].delta.z}, "signs:text")
            text:setyaw(signs[wdir..""].yaw)
        end

        return ItemStack("")
    end,
})

minetest.register_entity("signs:text", {
    collisionbox = { 0, 0, 0, 0, 0, 0 },
    visual = "upright_sprite",
    textures = {},

    on_activate = function(self)
        local meta = minetest.env:get_meta(self.object:getpos())
        local text = {}
        for i = 1, #metas do
            table.insert(text, meta:get_string(metas[i]))
        end
        self.object:set_properties({textures={generate_texture(text)}})
    end
})

local table_width = 110
local table_padding = 8

generate_texture = function(lines)
    local texture = "[combine:"..table_width.."x"..table_width
    local ypos = 12
    for i = 1, #lines do
        texture = texture..generate_line(lines[i], ypos)
        ypos = ypos + 8
    end
    return texture
end

generate_line = function(s, ypos)
    local i = 1
    local parsed = {}
    local width = 0
    local chars = 0
    while chars < max_chars and i <= #s do
        local file = nil
        if charmap[s:sub(i, i)] ~= nil then
            file = charmap[s:sub(i, i)]
            i = i + 1
        elseif i < #s and charmap[s:sub(i, i + 1)] ~= nil then
            file = charmap[s:sub(i, i + 1)]
            i = i + 2
        else
            print("[signs] W: unknown symbol in '"..s.."' at "..i.." (probably "..s:sub(i, i)..")")
            i = i + 1
        end
        if file ~= nil then
            width = width + charwidth[file] + 1
            table.insert(parsed, file)
            chars = chars + 1
        end
    end
    width = width - 1

    print("width("..s..") = "..width)

    local texture = ""
    local xpos = math.floor((table_width - 2 * table_padding - width) / 2 + table_padding)
    for i = 1, #parsed do
        texture = texture..":"..xpos..","..ypos.."="..parsed[i]..".png"
        xpos = xpos + charwidth[parsed[i]] + 1
    end
    return texture
end
