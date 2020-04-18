
local h = require "utilities.h"
local M = {}

M.mouse_location = vmath.vector3()

function M.check(action_id)

    if M[action_id] == nil then
        M[action_id] = {}
    end
    
    return M[action_id]
end

return M