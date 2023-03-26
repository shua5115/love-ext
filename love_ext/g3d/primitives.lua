local parent_path = (...):match("(.-)[^%.]+$")
local filepath = string.gsub(parent_path, "%.", "/")
---@type LoveExt.G3D.Vectors
local vectors = require(parent_path .. "vectors")
---@type LoveExt.G3D.Model
local model = require(parent_path .. "model")
local loadObj = require(parent_path .. "objloader")
---@class LoveExt.G3D.Primitives
local prim = {}

local cube_verts = loadObj(filepath.."cube.obj")
local sphere_verts = loadObj(filepath.."sphere.obj")
local cylinder_verts = loadObj(filepath.."cylinder.obj")

---Creates a model for a box
---@param xsize number
---@param ysize number
---@param zsize number
---@param texture (string|love.Image|love.Texture)?
---@return LoveExt.G3D.Model
function prim.box(xsize, ysize, zsize, texture)
    xsize = math.abs(xsize)*0.5
    ysize = math.abs(ysize)*0.5
    zsize = math.abs(zsize)*0.5
    local verts = {}
    for i, v in ipairs(cube_verts) do
        verts[i] = {v[1]*xsize, v[2]*ysize, v[3]*zsize, unpack(v, 4)}
    end
    return model.new(verts, texture)
end

---Creates a model for a sphere
---@param radius number
---@param texture (string|love.Image|love.Texture)?
---@return LoveExt.G3D.Model
function prim.sphere(radius, texture)
    local verts = {}
    for i, v in ipairs(sphere_verts) do
        verts[i] = {v[1]*radius, v[2]*radius, v[3]*radius, unpack(v, 4)}
    end
    return model.new(verts, texture)
end

---Creates a model for a cylinder
---@param radius number
---@param height number
---@param texture (string|love.Image|love.Texture)?
---@return LoveExt.G3D.Model
function prim.cylinder(radius, height, texture)
    height = height*0.5
    local verts = {}
    for i, v in ipairs(cylinder_verts) do
        verts[i] = {v[1]*radius, v[2]*radius, v[3]*height, unpack(v, 4)}
    end
    return model.new(verts, texture)
end

---Create a plane with a set size and detail.
---@param width number
---@param height number
---@param xcells integer? 1 by default
---@param ycells integer? 1 by default
---@param texture (string|love.Image|love.Texture)?
---@return LoveExt.G3D.Model
function prim.plane(width, height, xcells, ycells, texture)
    local verts = {}
    local n = 1
    xcells = math.max(xcells or 0, 1)
    ycells = math.max(ycells or 0, 1)
    local step_x = width/xcells
    local step_y = height/ycells
    for x=width*-0.5,width*0.5-step_x,step_x do
        for y=height*-0.5,height*0.5-step_y,step_y do
            local x2 = x+step_x
            local y2 = y+step_y
            verts[n+0] = {x, y, 0, (x+width*0.5)/width, (y+height*0.5)/height}
            verts[n+1] = {x2, y, 0, (x2+width*0.5)/width, (y+height*0.5)/height}
            verts[n+2] = {x2, y2, 0, (x2+width*0.5)/width, (y2+height*0.5)/height}
            verts[n+3] = {x, y2, 0, (x+width*0.5)/width, (y2+height*0.5)/height}
            verts[n+4] = {x, y, 0, (x+width*0.5)/width, (y+height*0.5)/height}
            verts[n+5] = {x2, y2, 0, (x2+width*0.5)/width, (y2+height*0.5)/height}
            n = n+6
        end
    end
    local m = model.new(verts, texture)
    m:makeNormals()
    return m
end

return prim