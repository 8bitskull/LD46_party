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

function M.is_between(amount,min,max,equal_to_okay)

    if amount == nil or min == nil or max == nil then
        print("error: is_between function given nil value",amount,min,max)
        return false
    end

    if equal_to_okay then
        return amount >= min and amount <= max
    else
        return amount > min and amount < max
    end
end

function M.length(target_arr)
	if target_arr ~= nil then
		return table.getn(target_arr)
	else
		return 0
	end
end

function M.splice(t,i,len)
    -- t = table
    -- i = location in table
    -- len = number of elements to remove
	len = len or 1
    if (len > 0) then
        for r=0, len do
            if(r < len) then
                table.remove(t,i + r)
            end
        end
    end
    local count = 1
    local tempT = {}
    for i=1, #t do
        if t[i] then
            tempT[count] = t[i]
            count = count + 1
        end
    end
    t = tempT
end

function M.rand_between(min, max, int)
	if int then
		return round(math.random()*(max-min)+min)
	else
		return math.random()*(max-min)+min
	end
end

function M.round(num, num_decimal_places)
	local mult = 10^(num_decimal_places or 0)
	return math.floor(num * mult + 0.5) / mult
end

return M