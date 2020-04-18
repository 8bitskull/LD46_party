-- Put functions in this file to use them in several other scripts.
-- To get access to the functions, you need to put:
-- require "my_directory.my_file"
-- in any script using the functions.

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