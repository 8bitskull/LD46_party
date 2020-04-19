
local party_supplies = require "party_supplies.party_supplies"
local pathfinder = require "utilities.pathfinder"
local utilities = require "utilities.utilities"
local h = require "utilities.h"
local input = require "input.input"

local M = {}

M.click_distance_limit = 100 * 100
M.character_height = 58
M.need_spacing = 50
M.need_height = 150
M.need_threshold = 60

M.neediness_multiplier_min = 1
M.neediness_multiplier_max = 2
M.neediness_multiplier_max_guests = 50

function M.reset_variables()

    M.guests_spawned = 0
    M.guest_spawn_timer = 0
    M.guest_spawn_timer_max = 6
    M.guest_spawn_increment = 4

    M.guests = {}

end

function M.run_spawn(dt)

    M.guest_spawn_timer = M.guest_spawn_timer + dt

    if M.guest_spawn_timer >= M.guest_spawn_timer_max then

        M.spawn_guest()
        M.guests_spawned = M.guests_spawned + 1
        M.guest_spawn_timer = 0
        M.guest_spawn_timer_max = M.guest_spawn_timer_max + M.guest_spawn_increment
    end
end

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

    --need objects
    M.guests[guest].needs = {}

    --animation
    M.guests[guest].anim = h.IDLE

    --starting value
    M.guests[guest].booze = 75 + 25 * math.random()
    M.guests[guest].powder = 90 + 10 * math.random()
    M.guests[guest].dance = 60 + 40 * math.random()
    M.guests[guest].talk = 55 + 45 * math.random()

    local neediness_multiplier = M.neediness_multiplier_min + (M.neediness_multiplier_max - M.neediness_multiplier_min) * utilities.clamp(M.guests_spawned, M.guests_spawned, M.neediness_multiplier_max_guests) / M.neediness_multiplier_max_guests
    print("multiplier", neediness_multiplier)

    --rate per minute
    M.guests[guest].booze_rate = (10 + 10 * math.random()) * neediness_multiplier
    M.guests[guest].powder_rate = (10 + 10 * math.random()) * neediness_multiplier
    M.guests[guest].dance_rate = (20 + 10 * math.random()) * neediness_multiplier
    M.guests[guest].talk_rate = (5 + 5 * math.random()) * neediness_multiplier
    M.guests[guest].neediness_rate = 1

    M.guests[guest].booze_rate = M.guests[guest].booze_rate / 60
    M.guests[guest].powder_rate = M.guests[guest].powder_rate / 60
    M.guests[guest].dance_rate = M.guests[guest].dance_rate / 60
    M.guests[guest].talk_rate = M.guests[guest].talk_rate / 60
    M.guests[guest].neediness_rate = M.guests[guest].neediness_rate / 60

    M.guests[guest].leaving = false

    return guest
end

function M.num_needs(object)

    local n = 0
    for need, info in pairs(M.guests[object].needs) do
        n = n +1
    end
    return n
end

function M.arrange_needs(object)

    --   o
    --  o-o
    -- o-o-o
    --o-o-o-o
    local num = M.num_needs(object)
    local start_x = -((num-1) * M.need_spacing)*0.5
    local position = nil
    local i = 0
    for id, need in pairs(M.guests[object].needs) do
        i=i+1
        position = go.get_position(need)
        position.x = start_x + (i-1) * M.need_spacing
        go.set_position(position, need)
    end
end

function M.create_need(object, need_id)

    if M.guests[object] == nil or M.guests[object].needs[need_id] then
        return
    end

    local factory_component = msg.url(object)
    factory_component.fragment = "guest_need"

    local need = factory.create(factory_component, vmath.vector3(0,M.need_height,0), nil, nil, 0.01)

    go.animate(need, "scale", go.PLAYBACK_ONCE_FORWARD, 0.25, go.EASING_OUTBOUNCE, 1)

    msg.post(need, "play_animation", {id = party_supplies.icon_ids[need_id]})
    go.set_parent(need, object)

    M.guests[object].needs[need_id] = need

    M.arrange_needs(object)
end

function M.remove_all_needs(object)

    for id, need in pairs(M.guests[object].needs) do

        go.delete(need)
    end

    M.guests[object].needs = nil
end

function M.remove_need(object, need_id)

    if M.guests[object] == nil or M.guests[object].needs[need_id] == nil then
        return
    end

    go.delete(M.guests[object].needs[need_id])
    M.guests[object].needs[need_id] = nil

    M.arrange_needs(object)
end

function M.tint_need(object, need_id,amount)

    local col = vmath.vector4(1,0,0,amount*0.5)
    local sprite_fragment = msg.url(M.guests[object].needs[need_id])
    sprite_fragment.fragment = "sprite"
    go.set(sprite_fragment, "blend", col)
end

function M.tick_guest_needs(dt)

    local label_component
    for object, info in pairs(M.guests) do
        
        if not info.leaving then    
            info.booze = info.booze - info.booze_rate * dt
            
            info.powder = info.powder - info.powder_rate * dt
            
            if party_supplies.sound_system then
                info.dance = info.dance + info.dance_rate * 10 * dt
            else
                info.dance = info.dance - info.dance_rate * dt
            end
            
            info.talk = info.talk - info.talk_rate * dt

            info.booze_rate = info.booze_rate  + info.neediness_rate * dt
            info.powder = info.powder  + info.neediness_rate * dt
            info.dance = info.dance  + info.neediness_rate * dt
            info.talk_rate = info.talk_rate  + info.neediness_rate * dt

            info.booze = utilities.clamp(info.booze, 0, 100)
            info.powder = utilities.clamp(info.powder, 0, 100)
            info.dance = utilities.clamp(info.dance, 0, 100)
            info.talk = utilities.clamp(info.talk, 0, 100)

            if info.booze < M.need_threshold then
                M.create_need(object, h.COCKTAIL)
                M.tint_need(object, h.COCKTAIL, 1-(info.booze/M.need_threshold))
            else
                M.remove_need(object, h.COCKTAIL)
            end

            if info.dance < M.need_threshold then
                M.create_need(object, h.MUSIC)
                M.tint_need(object, h.MUSIC, 1-(info.dance/M.need_threshold))
            else
                M.remove_need(object, h.MUSIC)
            end

            if info.powder < M.need_threshold then
                M.create_need(object, h.POWDER)
                M.tint_need(object, h.POWDER, 1-(info.powder/M.need_threshold))
            else
                M.remove_need(object, h.POWDER)
            end

            if info.talk < M.need_threshold then
                M.create_need(object, h.TALK)
                M.tint_need(object, h.TALK, 1-(info.talk/M.need_threshold))
            else
                M.remove_need(object, h.TALK)
            end

            label_component = msg.url(object)
            label_component.fragment = "booze"
            label.set_text(label_component, "Booze: " .. utilities.round(info.booze,1))
            label.set_text(label_component, "")
            label_component.fragment = "powder"
            label.set_text(label_component, "Powder: " .. utilities.round(info.powder,1))
            label.set_text(label_component, "")
            label_component.fragment = "dance"
            label.set_text(label_component, "Dance: " .. utilities.round(info.dance,1))
            label.set_text(label_component, "")
            label_component.fragment = "talk"
            label.set_text(label_component, "Talk: " .. utilities.round(info.talk,1))
            label.set_text(label_component, "")
        end
    end
end

function M.get_num_guests()

    local n = 0
    for object, info in pairs(M.guests) do
        n = n + 1
    end
    return n
end

function M.play_sleep_particles(object)

    local fx = msg.url(object)
    fx.fragment = "sleep_particles"
    particlefx.play(fx)
end

function M.check_for_leaving()

    for object, info in pairs(M.guests) do

        if info.talk <= 0 or info.dance <= 0 or info.booze <= 0 or info.powder <= 0 then
            if not info.leaving then
                M.play_sleep_particles(object)
                M.remove_all_needs(object)
                pathfinder.walk_to(object, nil, vmath.vector3(pathfinder.offscreen_right_x, pathfinder.downstairs_y, pathfinder.outdoors_z), true)
            else
                if not pathfinder.is_walk_in_progress(object) then
                    go.delete(object)
                    M.delete_guest(object)
                end
            end
            info.leaving = true
        end
    end
end

function M.check_guest_clicks()

    if input.check(h.TOUCH).pressed then

        local adj = vmath.vector3(0,M.character_height * 0.5,0)
        local closest = nil
        local distance = nil
        local clicked_object = nil
        local position = nil
        for object, info in pairs(M.guests) do

            position = go.get_position(object)
            distance = vmath.length_sqr(position+adj-input.mouse_location)

            if distance < M.click_distance_limit and (closest == nil or distance < closest) and pathfinder.get_location(position) ~= h.OUTSIDE and not info.leaving then
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
        elseif party_supplies.sound_system then
            anim = h.DANCE
        end
        if anim ~= info.anim then
            msg.post(sprite_fragment, "play_animation", {id = anim})
        end
        info.anim = anim
    end
end

function M.delete_guest(object)

    -- M.remove_all_needs(object)

    M.guests[object] = nil
end

return M