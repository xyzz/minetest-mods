--[[
	This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

-- this mod is based on http://minetest.net/forum/viewtopic.php?id=1590
timber_nodenames={"default:jungletree", "default:papyrus", "default:cactus", "default:tree"}

minetest.register_on_dignode(function(pos, node)
	for _, name in ipairs(timber_nodenames) do
		if node.name==name then
			local np={x=pos.x, y=pos.y+1, z=pos.z}
			while minetest.env:get_node(np).name==name do
				minetest.env:remove_node(np)
				for _, item in ipairs(minetest.get_node_drops(name)) do
					local tp = {x = np.x + math.random() - 0.5, y = np.y, z = np.z + math.random() - 0.5}
					minetest.env:add_item(tp, item)
				end
				np={x=np.x, y=np.y+1, z=np.z}
			end
			break
		end
	end
end)
