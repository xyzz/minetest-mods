-- Copyright (c) 2012, xyz

-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
-- 
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
-- LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
-- OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
-- WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

-- Save privileges to file every 30 seconds
local SAVE_TIME = 30

local DEBUG = false

local function split(str, sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    str:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

-- splits a:b:c to {a, b, c}
local function parse_privilege(name)
    return split(name)
end

local function build_privilege(privs)
    return table.concat(privs, ":")
end

local function single_or_group(name)
    local c = name:sub(1, 1)
    if c == "@" or c == "~" then
        return name
    else
        return "~"..name
    end
end

privs = {
    privileges = {},
    groups = {},
    -- returns privilege, if not exists -- creates it (if create == true) or returns nil (otherwise)
    get = function(self, privilege, create) 
        if create == nil then
            create = false
        end
        
        local particles = parse_privilege(privilege)
        local current = self.privileges
        for i, particle in ipairs(particles) do
            if current[particle] == nil then
                if not create then
                    return nil
                else
                    current[particle] = {}
                end
            end
            current = current[particle]
        end
        return current
    end,
    safe_get = function(self, priv)
        local privilege = self:get(priv)
        if privilege == nil then
            if priv == nil then
                priv = "~nil~"
            end
            print("privs:safe_get() => privilege "..priv.." does not exists")
            return nil
        end
        return privilege
    end,
    -- registers default value for privilege "name" and group "group"
    register = function(self, priv, default, group)
        local privilege = self:get(priv, true)
        if group ~= nil then
            privilege["@"..group] = default
        else
            privilege["~"] = default
        end
    end,
    -- [re]loads privileges from file
    reload = function(self)
        local fin = io.open("privileges.data", "r")
        while true do
            local value = fin:read("*number")
            if value == nil then
                break
            end
            local priv = fin:read("*line"):sub(2)
            local priv_parsed = parse_privilege(priv)
            local entity = priv_parsed[#priv_parsed]
            table.remove(priv_parsed)
            priv = build_privilege(priv_parsed)
            privs:get(priv, true)
            if value == 0 then
                self:deny(priv, entity)
            elseif value == 1 then
                self:allow(priv, entity)
            end
        end
        fin:close()
    end,
    -- writes single privilege
    write = function(self, privilege, file, current)
        for priv, i in pairs(privilege) do
            local c = priv:sub(1, 1)
            if c == "@" or c == "~" then
                file:write((i and 1 or 0).." "..current..priv.."\n")
            else
                self:write(privilege[priv], file, current..priv..":")
            end
        end
    end,
    -- saves privileges to file
    save = function(self)
        local fout = io.open("privileges.data", "w")
        self:write(self.privileges, fout, "")
        fout:close()
    end,
    allow = function(self, priv, name)
        local privilege =  self:safe_get(priv)
        if privilege == nil then 
            return
        end
        name = single_or_group(name)
        privilege[name] = true
    end,
    reset = function(self, priv, name)
        local privilege =  self:safe_get(priv)
        if privilege == nil then 
            return
        end
        name = single_or_group(name)
        privilege[name] = nil
    end,
    deny = function(self, priv, name)
        local privilege =  self:safe_get(priv)
        if privilege == nil then 
            return
        end
        name = single_or_group(name)
        privilege[name] = false
    end,
    check = function(self, priv, name)
        if priv == "" then
            return false
        end
        local privilege =  self:safe_get(priv)
        if privilege == nil then 
            return
        end
        
        local current = privilege["~"..name]
        if current ~= nil then
            return current
        end
        local player_groups = self.groups[name]
        if player_groups ~= nil then
            for group in pairs(player_groups) do
                current = privilege["@"..group]
                if current ~= nil then
                    return current
                end
            end
        end
        current = privilege["~"]
        if current ~= nil then
            return current
        end
        local priv_new = parse_privilege(priv)
        table.remove(priv_new)
        return self:check(build_privilege(priv_new), name)
    end,
    get_player_groups = function(self, player)
        if self.groups[player] == nil then
            self.groups[player] = {}
        end
        return self.groups[player]
    end,
    join = function(self, player, group)
        local player_groups = self:get_player_groups(player)
        player_groups[group] = true
    end,
    part = function(self, player, group)
        local player_groups = self:get_player_groups(player)
        player_groups[group] = nil
    end
}

if arg[1] == "debug" then
    DEBUG = true
    dofile("debug.lua")
else
    -- minetest-specific code should go here
    local delta = 0
    minetest:register_globalstep(function(dtime)
        delta = delta + dtime
        if (delta > SAVE_TIME) then
            delta = 0
            privs:save()
        end
    end)
end
