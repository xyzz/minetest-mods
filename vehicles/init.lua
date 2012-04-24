-- Vehicles mod by xyz
--

-- speed: blocks per step
local speed = 0.25

-- how often will vehicles' pos be updated
local stepsize = 0.05

local eps = 0.1

local cart = {
    physical = true,
    collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}, -- TODO: make better collisionbox
    visual = "cube",
    textures = {"vehicles_cart_top.png", "vehicles_cart_side.png", "vehicles_cart_side.png", "vehicles_cart_side.png", "vehicles_cart_side.png", "vehicles_cart_side.png"},
    attached_to = false,
    time = 0.0,
    vec = {x = 0, z = 0},
    health = 3,
    moving = false,
    stopnow = false
}

local round = function(num)
    return math.floor(num + 0.5)
end

local sign = function(num)
    if math.abs(num) < eps then
        return 0
    end

    if num > 0 then
        return 1
    else
        return -1
    end
end

-- rotate vector by 90 degrees
local rotated = function(v)
    return {x = -v.z, z = v.x}
end

-- make set from list
local Set = function (list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

-- TODO: use .walkable property
local air_equivalent = Set{"air", "default:torch", "water"}

-- is there air/something airlike on {pos}
local is_air = function(pos)
    return air_equivalent[minetest.env:get_node(pos).name]
end

local rail_equivalent = Set{"default:rail"}

-- is there something raillike on {pos}?
local is_rail = function(pos)
    if rail_equivalent[minetest.env:get_node(pos).name] then
        return true
    else
        return false
    end
end

-- returns vector length
local length = function(v)
    return math.sqrt(v.x*v.x+v.y*v.y+v.z*v.z)
end

-- returns resized vector
local resize = function(v, l)
    local len = length(v)
    return {x = v.x / len * l, y = v.y / len * l, z = v.z / len * l}
end

-- moves point P on vector V
local move = function(p, v)
    return {x = p.x + v.x, y = p.y + v.y, z = p.z + v.z}
end

-- is float a == float b
local eq = function(a, b)
    return math.abs(a - b) < eps
end

-- returns distance between a and b
local dist = function(a, b)
    return math.sqrt((a.x-b.x)*(a.x-b.x) + (a.z-b.z)*(a.z-b.z))
end

function cart:on_step(dtime)
    --self.object:setacceleration({x = 0, y = -10, z = 0})
    if self.attached_to == false then
        return
    end

    self.time = self.time + dtime
    if self.time >= stepsize then
        self.time = 0
    end

    -- first state: cart is moving
    if self.moving ~= false and self.time == 0 then
        local pos_f = self.object:getpos()
        if self.moving ~= false then
            if eq(pos_f.x, self.moving.x) and eq(pos_f.y, self.moving.y) and eq(pos_f.z, self.moving.z) then
                self.moving = false
                self.object:setacceleration({x = 0, y = -10, z = 0})
                if self.stopnow then
                    self.stopnow = false
                    self.attached_to = false
                end
            else
                local needed = {x = self.moving.x - pos_f.x,
                                y = self.moving.y - pos_f.y,
                                z = self.moving.z - pos_f.z}
                needed = resize(needed, math.min(length(needed), speed))
                self.object:setpos(move(pos_f, needed))
                -- move player that attached to this cart; FIXME
                local player = minetest.env:get_player_by_name(self.attached_to)
                local cur_pos = self.object:getpos()
                player:setpos({x = cur_pos.x, y = cur_pos.y - 0.5, z = cur_pos.z})
            end

            return
        end
    end

    -- second state: cart just need to check whether to move next self.time==0
    if self.moving == false then
        --print("position: "..pos_f.x.." "..pos_f.y.." "..pos_f.z)
        local pos_f = self.object:getpos()
        local pos = {x = round(pos_f.x), y = round(pos_f.y), z = round(pos_f.z)}

        -- if cart is not on rails now, don't move it
        local node_below = minetest.env:get_node(pos)
        if node_below.name ~= "default:rail" then
            self.attached_to = false
            return
        end

        local v = {x = self.vec.x, z = self.vec.z}
        local pos_next = {x = pos.x, y = pos.y, z = pos.z}
        local node_next
        --print("vector: "..v.x.." "..v.z)

        local our_direction = true
        local on_different_y = false
        local on_different_y_vec = false

        for i = 1, 4 do
            for dy = -1, 1 do
                pos_next.x = pos.x + v.x
                pos_next.z = pos.z + v.z
                pos_next.y = pos.y + dy

                --print("position: "..pos.x.." "..pos.z.." at: ("..pos_next.x.."; "..pos_next.z.."): ".." v is "..v.x.." "..dy.." "..v.z)
                if is_rail(pos_next) and (v.x ~= -self.vec.x or v.z ~= -self.vec.z) then
                    if dy ~= 0 then
                        if on_different_y == false and
                            (dy == 1 and is_air({x = pos.x, y = pos.y + 1, z = pos.z})) or
                            (dy == -1 and is_air({x = pos_next.x, y = pos_next.y + 1, z = pos_next.z})) then
                                on_different_y = {x = pos_next.x, y = pos_next.y, z = pos_next.z}
                                on_different_y_vec = {x = v.x, z = v.z}
                        end
                    end
                    --print(minetest.env:get_node({x = pos_next.x, y = pos_next.y + 1, z = pos_next.z}).name)
                    if (dy == 0) or our_direction then
                        if dy ~= 0 then
                            self.object:setacceleration({x = 0, y = 0, z = 0})
                        end
                        self.moving = pos_next
                        self.vec = v
                        return
                    end
                end
            end

            -- rotate our vector
            v = rotated(v)
            our_direction = false
        end

        if on_different_y ~= false then
            --print("moving between Y")
            self.moving = on_different_y
            self.vec = on_different_y_vec
            self.object:setacceleration({x = 0, y = 0, z = 0})
            return
        end

        -- if not moved - stop
        self.attached_to = false
    end
end

function cart:on_rightclick(clicker)
    if self.attached_to == false then
        self.attached_to = clicker:get_player_name()
        local playerpos = clicker:getpos()
        local selfpos = self.object:getpos()
        local best = 1e15
        -- find initial moving direction by searching through 4 nearby possibly positions
        self.vec = {x = 1, z = 0}
        for dx = -1,1 do
            for dz = -1,1 do
                if (dx * dz == 0) and (dx ~= 0 or dz ~= 0) then
                    local dst = dist(playerpos, {x = selfpos.x + dx, z = selfpos.z + dz})
                    if dst < best
                        and (is_rail({x = selfpos.x - dx, y = selfpos.y, z = selfpos.z - dz})
                        or is_rail({x = selfpos.x - dx, y = selfpos.y + 1, z = selfpos.z - dz})
                        or is_rail({x = selfpos.x - dx, y = selfpos.y - 1, z = selfpos.z - dz})) then
                            best = dst
                            self.vec = {x = -dx, z = -dz}
                    end
                end
            end
        end
    else
        self.stopnow = true
    end
end

function cart:on_punch(hitter)
    self.health = self.health - 1
    if self.health <= 0 then
        self.object:remove()
        hitter:get_inventory():add_item("main", "vehicles:cart 1")
        return ""
    end
end

function cart:on_activate(staticdata)
    self.object:setacceleration({x = 0, y = -10, z = 0})
end

minetest.register_entity("vehicles:cart", cart)

minetest.register_craftitem("vehicles:cart", {
    inventory_image = "vehicles_cart_inventory.png",
    on_drop = function(itemstack, dropper, pos)
        minetest.env:add_entity({x = round(pos.x), y = round(pos.y), z = round(pos.z)}, "vehicles:cart")
        --return true
    end
})

minetest.register_craft({
    output = '"vehicles:cart" 1',
    recipe = {
        {'default:steel_ingot', '', 'default:steel_ingot'},
        {'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'}
    }
})
