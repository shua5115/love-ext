local parent_path = (...):match("(.-)[^%.]+$")
local filepath = string.gsub(parent_path, "%.", "/")
return love.graphics.newShader(filepath.."g3d.vert")