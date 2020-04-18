-- Put functions in this file to use them in several other scripts.
-- To get access to the functions, you need to put:
-- require "my_directory.my_file"
-- in any script using the functions.

local utilities = require "utilities.utilities"
local h = require "utilities.h"

local M = {}

M.walk_speed = 80
M.downstairs_y = -277
M.upstairs_y = -51
M.stairs_up_x = -300
M.stairs_down_x = -138
M.door_x = 86
M.indoors_z = 0.1
M.outdoors_z = 0.2
M.left_x = -540
M.right_x = 550
M.upstairs_right_x = 287
M.offscreen_left_x = -710
M.offscreen_right_x = 684

M.walks = {}

function M.get_location(position)

    if position == nil then
        print("PATHFINDER: Error, nil position in get location")
        return nil
    end

    if math.abs(position.z - M.outdoors_z) < math.abs(position.z - M.indoors_z) then
        return h.OUTSIDE
    elseif position.y == M.upstairs_y then
        return h.UPSTAIRS
    elseif position.y == M.downstairs_y then
        return h.DOWNSTAIRS
    else
        return h.STAIRS
    end
end

function M.set_z(location)

    if location == h.OUTSIDE then
        return M.outdoors_z
    else
        return M.indoors_z
    end
end

function M.random_position()

    local position = vmath.vector3()

    if math.random() > 0.5 then
        position.y = M.upstairs_y
        position.x = utilities.rand_between(M.left_x,M.upstairs_right_x)
    else
        position.y = M.downstairs_y
        position.x = utilities.rand_between(M.left_x,M.right_x)
    end

    position.z = M.indoors_z

    return position
end

function M.update_walk_cycle(self, object)

    if object == nil then
        print("PATHFINDER: Error - object is nil")
        return
    end

    if M.walks[object] == nil then
        object = msg.url(object).path

        if M.walks[object] == nil then
            print("PATHFINDER: Error - object does not exist in table")
            print(object, type(object))
            pprint(M.walks)
            return
        end
    end

    local walk = M.walks[object]

    local current_position = go.get_position(walk.object)
    local current_location = M.get_location(current_position)

    print("walk checkpoint", current_location, current_position)

    local target_position = walk.final_position

    --fix z
    current_position.z = M.set_z(current_location)
    go.set_position(current_position, walk.object)

    --check if walk is complete
    if vmath.length_sqr(current_position - target_position) < 10 and current_location == walk.final_location then

        --remove walk
        M.walks[object] = nil
        return
    end

    if walk.final_location == h.UPSTAIRS then

        if current_location == h.DOWNSTAIRS then
            --at stairs - move up
            if current_position.x == M.stairs_down_x then
                target_position = vmath.vector3(M.stairs_up_x, M.upstairs_y, current_position.z)
            else
                target_position = vmath.vector3(M.stairs_down_x, M.downstairs_y, current_position.z)
            end
        elseif current_location == h.STAIRS then
            target_position = vmath.vector3(M.stairs_up_x, M.upstairs_y, current_position.z)
        elseif current_location == h.OUTSIDE then
            --at door, come in
            if current_position.x == M.door_x then
                current_position.z = M.indoors_z
                go.set_position(current_position, walk.object)
                target_position = vmath.vector3(M.stairs_down_x, M.downstairs_y, current_position.z)
            else
                target_position = vmath.vector3(M.door_x, M.downstairs_y, current_position.z)
            end
        end

    elseif walk.final_location == h.DOWNSTAIRS then

        if current_location == h.UPSTAIRS then
            --at stairs - move down
            if current_position.x == M.stairs_up_x then
                target_position = vmath.vector3(M.stairs_down_x, M.downstairs_y, current_position.z)
            else
                target_position = vmath.vector3(M.stairs_up_x, M.upstairs_y, current_position.z)
            end
        elseif current_location == h.STAIRS then
            target_position = vmath.vector3(M.stairs_down_x, M.downstairs_y, current_position.z)
        elseif current_location == h.OUTSIDE then
            --at door, come in
            if current_position.x == M.door_x then
                current_position.z = M.indoors_z
                go.set_position(current_position, walk.object)
            else
                target_position = vmath.vector3(M.door_x, M.downstairs_y, current_position.z)
            end
        end

    elseif walk.final_location == h.OUTSIDE then

        if current_location == h.UPSTAIRS then
            --at stairs - move down
            if current_position.x == M.stairs_up_x then
                target_position = vmath.vector3(M.stairs_down_x, M.downstairs_y, current_position.z)
            else
                target_position = vmath.vector3(M.stairs_up_x, M.upstairs_y, current_position.z)
            end
        elseif current_location == h.STAIRS then
            target_position = vmath.vector3(M.stairs_down_x, M.downstairs_y, current_position.z)
        elseif current_location == h.DOWNSTAIRS then
            --at door, go out
            if current_position.x == M.door_x then
                current_position.z = M.outdoors_z
                go.set_position(current_position, walk.object)
            else
                target_position = vmath.vector3(M.door_x, M.downstairs_y, current_position.z)
            end
        end
    end

    local walk_time = vmath.length(target_position-go.get_position(walk.object)) / walk.walk_speed

    go.animate(walk.object, "position.x", go.PLAYBACK_ONCE_FORWARD, target_position.x, go.EASING_INOUTSINE, walk_time, 0, M.update_walk_cycle)
    go.animate(walk.object, "position.y", go.PLAYBACK_ONCE_FORWARD, target_position.y, go.EASING_INOUTSINE, walk_time)
end

function M.walk_to(object, from, to, allow_outside, walk_speed)

    walk_speed = walk_speed or M.walk_speed

    from = from or go.get_position(object)
   
    local current_location = M.get_location(from)

    local final_location = nil

    --check if our target is upstairs or downstairs
    if to.y >= M.upstairs_y then
        final_location = h.UPSTAIRS
        to.y = M.upstairs_y
        to.x = utilities.clamp(to.x, M.left_x, M.upstairs_right_x)
    else
        final_location = h.DOWNSTAIRS
        if allow_outside and (to.y < M.downstairs_y or to.x > M.right_x or to.x < M.left_x) then
            final_location = h.OUTSIDE
        elseif not allow_outside then
            to.x = utilities.clamp(to.x, M.left_x, M.right_x)
        end
        to.y = M.downstairs_y
    end

    M.walks[object] = {object = object, current_location = current_location, final_location = final_location, final_position = to, walk_speed = walk_speed}

    M.update_walk_cycle(self, object)
end

function M.get_walk_destination(object)

    if M.walks[object] then
        return M.walks[object].final_position
    else
        return go.get_position(object)
    end
end

function M.cancel_walk(object)

    M.walks[object] = nil
end

function M.is_walk_in_progress(object)
    return M.walks[object] ~= nil
end


return M