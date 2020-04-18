-- Put functions in this file to use them in several other scripts.
-- To get access to the functions, you need to put:
-- require "my_directory.my_file"
-- in any script using the functions.


local M = {}

M.pi = math.pi
M.rad_to_deg = 180 / M.pi
M.deg_to_rad = M.pi / 180

function M.angle(x1, y1, x2, y2)
    return math.atan2(y2 - y1, x2 - x1) * M.rad_to_deg
end

function M.angle_rad(x1, y1, x2, y2)
    return math.atan2(y2 - y1, x2 - x1)
end

function M.draw_line(from, to)
    if not from or not to then
        return
    end
	-- msg.post("@render:", "draw_line", { start_point = from, end_point = to, color = vmath.vector4(1,1,1,0.25) })
end

function M.clamp(var,min,max)

    if var < min then
        var = min
    end

    if var > max then
        var = max
    end

    return var
end

return M