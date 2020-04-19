
local pathfinder = require "utilities.pathfinder"
local utilities = require "utilities.utilities"
local h = require "utilities.h"
local input = require "input.input"

local M = {}

M.click_distance_limit = 100 * 100
M.character_height = 58

M.guests = {}

function M.spawn_guest()

    local guest = factory.create("guest_factory#guest")

    M.guests[guest] = {}

    --spawn position
    local side_x = pathfinder.offscreen_right_x
	if math.random() > 0.5 then 
		side_x = pathfinder.offscreen_left_x 
    end
    local position = vmath.vector3(side_x, pathfinder.downstairs_y, pathfinder.outdoors_z)
    go.set_position(position, guest)
    M.guests[guest].previous_position = position

    --walk speed
    M.guests[guest].walk_speed = pathfinder.walk_speed * utilities.rand_between(0.9,1.1,false)

    --colour
    local col = math.random()
    local sprite = msg.url(guest)
    local color = nil
    sprite.fragment = "sprite"
	if col > 0.66 then
		color = vmath.vector4(0.5 + math.random()*0.5,math.random()*0.5,math.random()*0.5,1)
	elseif col > 0.33 then
		color = vmath.vector4(math.random()*0.5,0.5 + math.random()*0.5,math.random()*0.5,1)
	else
		color = vmath.vector4(math.random()*0.5,math.random()*0.5,0.5 + math.random()*0.5,1)
    end
    go.set(sprite, "blend", color)
    M.guests[guest].color = color

    --animation
    M.guests[guest].anim = h.IDLE

    --starting value
    M.guests[guest].booze = 75 + 25 * math.random()
    M.guests[guest].powder = 90 + 10 * math.random()
    M.guests[guest].dance = 50 + 50 * math.random()
    M.guests[guest].talk = 50 + 50 * math.random()

    --rate per minute
    M.guests[guest].booze_rate = 10 + 10 * math.random()
    M.guests[guest].powder_rate = 10 + 10 * math.random()
    M.guests[guest].dance_rate = 10 + 10 * math.random()
    M.guests[guest].talk_rate = 10 + 10 * math.random()

    M.guests[guest].booze_rate = M.guests[guest].booze_rate / 60
    M.guests[guest].powder_rate = M.guests[guest].powder_rate / 60
    M.guests[guest].dance_rate = M.guests[guest].dance_rate / 60
    M.guests[guest].talk_rate = M.guests[guest].talk_rate / 60

    return guest
end

function M.tick_guest_needs(dt)

    local label_component
    for object, info in pairs(M.guests) do
        info.booze = info.booze - info.booze_rate * dt
        info.powder = info.powder - info.powder_rate * dt
        info.dance = info.dance - info.dance_rate * dt
        info.talk = info.talk - info.talk_rate * dt

        label_component = msg.url(object)
        label_component.fragment = "booze"
        label.set_text(label_component, "Booze: " .. utilities.round(info.booze,1))
        label_component.fragment = "powder"
        label.set_text(label_component, "Powder: " .. utilities.round(info.powder,1))
        label_component.fragment = "dance"
        label.set_text(label_component, "Dance: " .. utilities.round(info.dance,1))
        label_component.fragment = "talk"
        label.set_text(label_component, "Talk: " .. utilities.round(info.talk,1))
    end
end

function M.check_guest_clicks()

    if input.check(h.TOUCH).pressed then

        local adj = vmath.vector3(0,M.character_height * 0.5,0)
        local closest = nil
        local distance = nil
        local clicked_object = nil
        for object, info in pairs(M.guests) do

            distance = vmath.length_sqr(go.get_position(object)+adj-input.mouse_location)

            if distance < M.click_distance_limit and (closest == nil or distance < closest) then
                closest = distance
                clicked_object = object
            end
        end
        return clicked_object
    end
end

function M.assign_random_position(guest)

    pathfinder.walk_to(guest, go.get_position(), pathfinder.random_position(), false, M.guests[guest].walk_speed)
end

function M.manage_anim()
    local position = nil
    local sprite_fragment = nil
    local anim = h.IDLE
    for object, info in pairs(M.guests) do

        sprite_fragment = msg.url(object)
        sprite_fragment.fragment = "sprite"
        position = go.get_position(object)
        sprite.set_hflip(sprite_fragment, position.x > info.previous_position.x)
        info.previous_position = position

        anim = h.IDLE
        if pathfinder.is_walk_in_progress(object) then
            anim = h.WALK
        end
        if anim ~= info.anim then
            msg.post(sprite_fragment, "play_animation", {id = anim})
        end
        info.anim = anim
    end
end

function M.delete_guest(object)
    M.guests[object] = nil
end

return M