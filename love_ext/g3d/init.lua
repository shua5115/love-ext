-- written by groverbuger for g3d
-- september 2021
-- MIT license

--[[
         __       __
       /'__`\    /\ \
   __ /\_\L\ \   \_\ \
 /'_ `\/_/_\_<_  /'_` \
/\ \L\ \/\ \L\ \/\ \L\ \
\ \____ \ \____/\ \___,_\
 \/___L\ \/___/  \/__,_ /
   /\____/
   \_/__/
--]]

---@class LoveExt.G3D
local g3d = {
    _VERSION     = "g3d 1.5.2*", -- *=modified
    _DESCRIPTION = "Simple and easy 3D engine for LÖVE.",
    _URL         = "https://github.com/groverburger/g3d",
    _LICENSE     = [[
        MIT License

        Copyright (c) 2022 groverburger

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.
    ]],
}
local path = ...
local filepath = string.gsub(path, "%.", "/")
-- the shader is what does the heavy lifting, displaying 3D meshes on a 2D texture
---@type love.Shader
g3d.shader = require(path .. ".shader")
---The vertex shader used by the default g3d shader. Useful for making your own 3D shader programs.
g3d.vertex_shader_source = love.filesystem.read(filepath.."/g3d.vert")
---@type LoveExt.G3D.Model
g3d.model = require(path .. ".model")
---@type LoveExt.G3D.Camera
g3d.camera = require(path .. ".camera")
---@type LoveExt.G3D.Collisions
g3d.collisions = require(path .. ".collisions")
---@type function (path, uflip, vflip)
g3d.loadObj = require(path .. ".objloader")
---@type LoveExt.G3D.Vectors
g3d.vectors = require(path .. ".vectors")
-- g3d.primitives = require(path .. ".primitives") -- primitives are opt-in because of the loading of .obj files

g3d.default_texture = require(path .. ".default_texture")

g3d.camera.updateProjectionMatrix()
g3d.camera.updateViewMatrix()

-- so that far polygons don't overlap near polygons
love.graphics.setDepthMode("lequal", true)

return g3d
