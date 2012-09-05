mesecon:register_on_signal_change(function(pos, node)
    if string.find(node.name, "xdoors2:door_bottom_") then
        xdoors2_transform(pos, node)
    end
end)

mesecon:register_effector("xdoors2:door_bottom_1")
mesecon:register_effector("xdoors2:door_bottom_2")
