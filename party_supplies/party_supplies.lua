
local h = require "utilities.h"

local M = {}

M.positions = {}
M.positions[h.COCKTAIL] = vmath.vector3(210, 82, 0.1)
M.positions[h.BOTTLE] = vmath.vector3(1081, 82, 0.1)
M.positions[h.MUSIC] = vmath.vector3(541, 317, 0.1)
M.positions[h.PHONE] = vmath.vector3(801, 317, 0.1)
M.positions[h.POWDER] = vmath.vector3(801, 82, 0.1)

M.locations = {}
M.locations[h.COCKTAIL] = h.DOWNSTAIRS
M.locations[h.BOTTLE] = h.DOWNSTAIRS
M.locations[h.MUSIC] = h.UPSTAIRS
M.locations[h.PHONE] = h.UPSTAIRS
M.locations[h.POWDER] = h.DOWNSTAIRS

M.icon_ids = {}
M.icon_ids[h.COCKTAIL] = hash("symbol_cocktail")
M.icon_ids[h.BOTTLE] = hash("symbol_bottle")
M.icon_ids[h.MUSIC] = hash("symbol_music")
M.icon_ids[h.TALK] = hash("symbol_talk")
M.icon_ids[h.PHONE] = hash("symbol_phone")
M.icon_ids[h.POWDER] = hash("symbol_powder")

M.action_times = {}
M.action_times[h.COCKTAIL] = 1
M.action_times[h.BOTTLE] = 2
M.action_times[h.MUSIC] = 1
M.action_times[h.TALK] = 2
M.action_times[h.PHONE] = 1
M.action_times[h.POWDER] = 1

M.action_sounds = {}
M.action_sounds[h.PHONE] = "player#phone"
M.action_sounds[h.BOTTLE] = "player#bottle"
M.action_sounds[h.COCKTAIL] = "player#cocktail"
M.action_sounds[h.TALK] = "player#talk"
M.action_sounds[h.POWDER] = "player#powder"

M.inventory_nodes = {}
M.inventory_nodes[h.COCKTAIL] = "inventory_cocktail_symbol"
M.inventory_nodes[h.POWDER] = "inventory_powder_symbol"

M.inventory_numbers = {}
M.inventory_numbers[h.COCKTAIL] = "inventory_cocktail"
M.inventory_numbers[h.POWDER] = "inventory_powder"

function M.set_variables()

    M.cocktails = 1
    M.drink_materials = 1
    M.drink_materials_max = 6
    M.powder = 3
    M.powder_delivery_amount = 3
    M.powder_requested = false
    M.powder_delivered = false
    M.sound_system = false
    M.sound_level = 0
    M.cops = nil

    sound.set_group_gain(hash("master"), 0.5)
end
M.set_variables()

function M.make_cocktail()

    M.cocktails = M.cocktails + 1
    msg.post("ui", "wobble_node", {node = M.inventory_numbers[h.COCKTAIL]})

    M.drink_materials = M.drink_materials - 1
    if M.drink_materials <= 0 then
        msg.post("ui", "show_button", {id = h.BOTTLE})
        msg.post("ui", "highlight_node", {node = "bottle"})
        msg.post("ui", "hide_button", {id = h.COCKTAIL})
    end
end

function M.replenish_drink_stocks()

    if M.drink_materials <= 0 then
        msg.post("ui", "hide_button", {id = h.BOTTLE})
        msg.post("ui", "show_button", {id = h.COCKTAIL})
    end

    M.drink_materials = M.drink_materials_max
end

function M.switch_music()

    M.sound_system = not M.sound_system

    if M.sound_system then
        sound.set_group_gain(hash("master"), 1)
        if not M.cops then
            M.cops = factory.create("player#cops")
        end
    else
        sound.set_group_gain(hash("master"), 0.5)
    end
end

function M.request_powder()

    M.powder_requested = true
    msg.post("ui", "hide_button", {id = h.PHONE})
    factory.create("player#powder_delivery")
end

function M.deliver_powder()

    M.powder_delivered = true
    msg.post("ui", "show_button", {id = h.POWDER})
end

function M.collect_powder()

    M.powder_requested = false
    M.powder_delivered = false
    M.powder = M.powder + M.powder_delivery_amount
    msg.post("ui", "hide_button", {id = h.POWDER})
    msg.post("ui", "show_button", {id = h.PHONE})
    msg.post("ui", "wobble_node", {node = M.inventory_numbers[h.POWDER]})
end

return M