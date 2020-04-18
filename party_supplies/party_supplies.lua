
local h = require "utilities.h"

local M = {}

M.positions = {}
M.positions[h.COCKTAIL] = vmath.vector3(-435, -277, 0.1)
M.positions[h.BOTTLE] = vmath.vector3(435, -277, 0.1)

M.locations = {}
M.locations[h.COCKTAIL] = h.DOWNSTAIRS
M.locations[h.BOTTLE] = h.DOWNSTAIRS

M.icon_ids = {}
M.icon_ids[h.COCKTAIL] = hash("symbol_cocktail")
M.icon_ids[h.BOTTLE] = hash("symbol_bottle")

M.action_times = {}
M.action_times[h.COCKTAIL] = 3
M.action_times[h.BOTTLE] = 5

M.inventory_nodes = {}
M.inventory_nodes[h.COCKTAIL] = "inventory_cocktail_symbol"
M.inventory_nodes[h.POWDER] = "inventory_powder_symbol"

M.inventory_numbers = {}
M.inventory_numbers[h.COCKTAIL] = "inventory_cocktail"
M.inventory_numbers[h.POWDER] = "inventory_powder"

M.cocktails = 0
M.drink_materials = 1
M.drink_materials_max = 3
M.powder = 0
M.sound_system = false
M.sound_level = 0

function M.make_cocktail()

    M.cocktails = M.cocktails + 1
    msg.post("ui", "wobble_node", {node = M.inventory_numbers[h.COCKTAIL]})

    M.drink_materials = M.drink_materials - 1
    if M.drink_materials <= 0 then
        msg.post("ui", "highlight_node", {node = "bottle"})
        msg.post("ui", "hide_button", {id = h.COCKTAIL})
    end
end

function M.replenish_drink_stocks()

    if M.drink_materials <= 0 then
        msg.post("ui", "show_button", {id = h.COCKTAIL})
    end

    M.drink_materials = M.drink_materials_max
end

return M