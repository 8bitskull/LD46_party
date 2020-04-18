-- Put functions in this file to use them in several other scripts.
-- To get access to the functions, you need to put:
-- require "my_directory.my_file"
-- in any script using the functions.

local h = require "utilities.h"
local input = require "input.input"

local M = {}

M.buttons = {}

---flipbook_default / flipbook_over / flipbook_down (hash, all default to current flipbook)
---
---doubleclick_time (0 default, 0.25 is reasonable)
---
---scale_default_amount / scale_default_time / scale_default_easing / scale_default_playback
---
---(same available for over, down, released)
function M.add_button(node, params, boop)

    if M.buttons[node] then
        print("BUTTONS: Warning - button id " .. node .. " already exists. Overwriting")
    end

    local button = {}
    button.node = node

    --flipbook
    local flipbook_default = params.flipbook_default or gui.get_flipbook(node)
    button.flipbook_default = params.flipbook_default or flipbook_default
    button.flipbook_over = params.flipbook_over or flipbook_default
    button.flipbook_down = params.flipbook_down or flipbook_default

    --scaling
    button.scaling_mode = nil

    button.scale_default_amount = params.scale_default_amount or 1
    button.scale_default_time = params.scale_default_time or 0.5
    button.scale_default_easing = params.scale_default_easing or gui.EASING_INOUTCUBIC
    button.scale_default_playback = params.scale_default_playback or gui.PLAYBACK_ONCE_FORWARD

    button.scale_over_amount = params.scale_over_amount or 0
    button.scale_over_time = params.scale_over_time or 0
    button.scale_over_easing = params.scale_over_easing or gui.EASING_OUTCUBIC
    button.scale_over_playback = params.scale_over_playback or gui.PLAYBACK_ONCE_FORWARD

    button.scale_down_amount = params.scale_down_amount or 0
    button.scale_down_time = params.scale_down_time or 0
    button.scale_down_easing = params.scale_down_easing or gui.EASING_OUTCUBIC
    button.scale_down_playback = params.scale_down_playback or gui.PLAYBACK_ONCE_FORWARD

    button.scale_released_amount = params.scale_released_amount or 0
    button.scale_released_time = params.scale_released_time or 0
    button.scale_released_easing = params.scale_released_easing or gui.EASING_OUTCUBIC
    button.scale_released_playback = params.scale_released_playback or gui.PLAYBACK_ONCE_FORWARD

    button.doubleclick_time = params.doubleclick_time or 0 --0.25 is reasonable
    button.last_released = 0

    M.buttons[node] = button

    pprint(M.buttons[node])
    return node
end

function M.complete_button_scaling(self, node)
    if M.buttons[node] then
        M.buttons[node].scaling_mode = nil
    end
end

function M.check_button(node)

    local button = M.buttons[node]
    if not button then
        print ("BUTTONS: Error - no button id " .. node)
        return
    end

    local over = false
    local down = false
    local released = false
    local last_released = button.last_released
    local doubleclick = false

    if gui.pick_node(node, input.mouse_location.x, input.mouse_location.y) then
        over = true
    end

    if over then
        down = input.check(h.TOUCH).value == 1
    end

    if button.down then
        released = input.check(h.TOUCH).value == 0
    end

    if released then
        last_released = socket.gettime()

        if last_released - button.last_released <= button.doubleclick_time then
            doubleclick = true
        end
    end

    --set flipbook and scaling
    if released then
        gui.play_flipbook(node, button.flipbook_default)
        if button.scale_released_time > 0 and button.scaling_mode ~= h.RELEASED then
            button.scaling_mode = h.RELEASED
            gui.animate(node, gui.PROP_SCALE, button.scale_released_amount, button.scale_released_easing, button.scale_released_time,0,M.complete_button_scaling,button.scale_released_playback)
        end
    elseif down then
        gui.play_flipbook(node, button.flipbook_down)
        if button.scale_down_time > 0 and button.scaling_mode ~= h.DOWN then
            button.scaling_mode = h.DOWN
            gui.animate(node, gui.PROP_SCALE, button.scale_down_amount, button.scale_down_easing, button.scale_down_time,0,M.complete_button_scaling,button.scale_down_playback)
        end
    elseif over then
        gui.play_flipbook(node, button.flipbook_over)
        if button.scale_over_time > 0 and button.scaling_mode == nil then
            button.scaling_mode = h.OVER
            gui.animate(node, gui.PROP_SCALE, button.scale_over_amount, button.scale_over_easing, button.scale_over_time,0,M.complete_button_scaling,button.scale_over_playback)
        end
    else
        gui.play_flipbook(node, button.flipbook_default)
        if button.scaling_mode ~= nil and button.scaling_mode ~= h.DEFAULT then
            button.scaling_mode = h.DEFAULT
            gui.animate(node, gui.PROP_SCALE, button.scale_default_amount, button.scale_default_easing, button.scale_default_time,0,M.complete_button_scaling,button.scale_default_playback)
        end
    end

    --store status
    button.over = over
    button.down = down
    button.released = released
    button.last_released = last_released

    return {over = over, down = down, released = released, doubleclick = doubleclick}
end

function M.remove_button(node)

end

function M.remove_all_buttons()

    M.buttons = {}
end

return M