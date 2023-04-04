-- written by groverbuger for g3d
-- september 2021
-- MIT license
local parent_path = (...):match("(.-)[^%.]+$")
---@type LoveExt.G3D.Matrix
local matrix = require(parent_path .. "matrices")
local newMatrix = matrix.new
local loadObjFile = require(parent_path .. "objloader")
local collisions = require(parent_path .. "collisions")
---@type LoveExt.G3D.Vectors
local vectors = require(parent_path .. "vectors")
local camera = require(parent_path .. "camera")
local default_shader = require(parent_path .. "shader")
local default_texture = require(parent_path .. "default_texture")
local vectorCrossProduct = vectors.crossProduct
local vectorNormalize = vectors.normalize

----------------------------------------------------------------------------------------------------
-- define a model class
----------------------------------------------------------------------------------------------------
---@class LoveExt.G3D.Model
local model = {}
local mt = {__index = model}

-- define some default properties that every model should inherit
-- that being the standard vertexFormat and basic 3D shader
model.vertexFormat = {
    {"VertexPosition", "float", 3},
    {"VertexTexCoord", "float", 2},
    {"VertexNormal", "float", 3},
    {"VertexColor", "byte", 4},
}
model.default_shader = default_shader

---Creates a new Model with either a list of vertices or a .obj file.
---If you choose to create with a list of vertices, you should specify which
---mesh draw mode is used to create the mesh.
---@see love.MeshDrawMode
---@param verts table|string List of 3D vectors with which to create the mesh, or the name of a .obj file.
---@param texture (string|love.Image|love.Texture)?
---@param mode love.MeshDrawMode?
---@param usage love.SpriteBatchUsage?
---@param cullMode love.CullMode?
---@return LoveExt.G3D.Model
function model.new(verts, texture, mode, usage, cullMode)
    ---@class LoveExt.G3D.Model
    local self = setmetatable({}, mt)

    -- if verts is a string, use it as a path to a .obj file
    -- otherwise verts is a table, use it as a model defintion
    if type(verts) == "string" then
        verts = loadObjFile(verts)
    end

    -- if texture is a string, use it as a path to an image file
    -- otherwise texture is already an image, so don't bother
    if type(texture) == "string" then
        texture = love.graphics.newImage(texture)
    end
    if not texture then
        texture = default_texture
    end

    -- initialize my variables
    self.verts = verts
    self.texture = texture
    mode = mode or "triangles"
    usage = usage or "dynamic"
    self.mesh = love.graphics.newMesh(self.vertexFormat, self.verts, mode, usage)
    self.mesh:setTexture(self.texture)
    self.cullMode = cullMode or "none"
    return self
end

---Populate the model's normals from the model's mesh.
---@param isFlipped boolean? Flip the normals.
function model:makeNormals(isFlipped)
    for i=1, #self.verts, 3 do
        if isFlipped then
            self.verts[i+1], self.verts[i+2] = self.verts[i+2], self.verts[i+1]
        end

        local vp = self.verts[i]
        local v = self.verts[i+1]
        local vn = self.verts[i+2]

        local n_1, n_2, n_3 = vectorNormalize(vectorCrossProduct(v[1]-vp[1], v[2]-vp[2], v[3]-vp[3], vn[1]-v[1], vn[2]-v[2], vn[3]-v[3]))
        vp[6], v[6], vn[6] = n_1, n_1, n_1
        vp[7], v[7], vn[7] = n_2, n_2, n_2
        vp[8], v[8], vn[8] = n_3, n_3, n_3
    end

    self.mesh = love.graphics.newMesh(self.vertexFormat, self.verts, "triangles")
    self.mesh:setTexture(self.texture)
end

-- -Update the model's matrix by changing these parameters.
-- -If a parameter is omitted, do not change.
-- -@param translation table? {x, y, z}
-- -@param rotation table? {x, y, z}
-- -@param scale table? {x, y, z}
-- function model:setTransform(translation, rotation, scale)
--     self.translation = translation or self.translation
--     self.rotation = rotation or self.rotation
--     self.scale = scale or self.scale
--     self:updateMatrix()
-- end

-- ---Set the translation of a model.
-- ---@param tx number
-- ---@param ty number
-- ---@param tz number
-- function model:setTranslation(tx,ty,tz)
--     self.translation[1] = tx
--     self.translation[2] = ty
--     self.translation[3] = tz
--     self:updateMatrix()
-- end

-- ---Set the rotation of a model.
-- ---@param rx number
-- ---@param ry number
-- ---@param rz number
-- function model:setRotation(rx,ry,rz)
--     self.rotation[1] = rx
--     self.rotation[2] = ry
--     self.rotation[3] = rz
--     self.rotation[4] = nil
--     self:updateMatrix()
-- end

-- ---Set the rotation by rotating about an axis by angle radians.
-- ---@param x number
-- ---@param y number
-- ---@param z number
-- ---@param angle number
-- function model:setAxisAngleRotation(x,y,z,angle)
--     x,y,z = vectorNormalize(x,y,z)
--     angle = angle / 2
-- 
--     self.rotation[1] = x * math.sin(angle)
--     self.rotation[2] = y * math.sin(angle)
--     self.rotation[3] = z * math.sin(angle)
--     self.rotation[4] = math.cos(angle)
-- 
--     self:updateMatrix()
-- end

-- ---Set the model's rotation with a quaternion.
-- ---@param x number
-- ---@param y number
-- ---@param z number
-- ---@param w number
-- function model:setQuaternionRotation(x,y,z,w)
--     self.rotation[1] = x
--     self.rotation[2] = y
--     self.rotation[3] = z
--     self.rotation[4] = w
--     self:updateMatrix()
-- end

-- ---Set the scale of a model.
-- ---@param sx number
-- ---@param sy number
-- ---@param sz number
-- function model:setScale(sx,sy,sz)
--     self.scale[1] = sx
--     self.scale[2] = sy or sx
--     self.scale[3] = sz or sx
--     self:updateMatrix()
-- end

---Update the model's transformation matrix
-- function model:updateMatrix()
--     self.matrix:setTransformationMatrix(self.translation, self.rotation, self.scale)
-- end

---Draw the model with a shader program.
---@param modelMatrix (LoveExt.G3D.Matrix|love.Transform) Defines where in world space the model should be drawn
---@param shader love.Shader? If omitted, use the default 3D shader
function model:draw(modelMatrix, shader)
    shader = shader or model.default_shader
    love.graphics.setShader(shader)
    shader:send("modelMatrix", modelMatrix)
    shader:send("viewMatrix", camera.viewMatrix)
    shader:send("projectionMatrix", camera.projectionMatrix)
    if shader:hasUniform "isCanvasEnabled" then
        shader:send("isCanvasEnabled", love.graphics.getCanvas() ~= nil)
    end
    love.graphics.draw(self.mesh)
    love.graphics.setShader()
end

---Compress a model's vertices by using a C struct instead of tables.
---Will fail if the system does not support ffi through luaJIT
function model:compress()
    print("[g3d warning] Compression requires FFI!\n" .. debug.traceback())
end

-- makes models use less memory when loaded in ram
-- by storing the vertex data in an array of vertix structs instead of lua tables
-- requires ffi
-- note: throws away the model's verts table
local success, ffi = pcall(require, "ffi")
if success then
    ffi.cdef([[
        struct vertex {
            float x, y, z;
            float u, v;
            float nx, ny, nz;
            uint8_t r, g, b, a;
        }
    ]])

    function model:compress()
        local data = love.data.newByteData(ffi.sizeof("struct vertex") * #self.verts)
        local datapointer = ffi.cast("struct vertex *", data:getFFIPointer())

        for i, vert in ipairs(self.verts) do
            local dataindex = i - 1
            datapointer[dataindex].x  = vert[1]
            datapointer[dataindex].y  = vert[2]
            datapointer[dataindex].z  = vert[3]
            datapointer[dataindex].u  = vert[4] or 0
            datapointer[dataindex].v  = vert[5] or 0
            datapointer[dataindex].nx = vert[6] or 0
            datapointer[dataindex].ny = vert[7] or 0
            datapointer[dataindex].nz = vert[8] or 0
            datapointer[dataindex].r  = (vert[9] or 1)*255
            datapointer[dataindex].g  = (vert[10] or 1)*255
            datapointer[dataindex].b  = (vert[11] or 1)*255
            datapointer[dataindex].a  = (vert[12] or 1)*255
        end
        self.mesh:release()
        self.mesh = love.graphics.newMesh(self.vertexFormat, #self.verts, "triangles")
        self.mesh:setVertices(data)
        self.mesh:setTexture(self.texture)
        self.verts = nil
    end
end

-- collision functions are broken since models no longer store their transform

-- function model:rayIntersection(src_x, src_y, src_z, dir_x, dir_y, dir_z)
--     return collisions.rayIntersection(self.verts, self, src_x, src_y, src_z, dir_x, dir_y, dir_z)
-- end

-- function model:isPointInside(x, y, z)
--     return collisions.isPointInside(self.verts, self, x, y, z)
-- end

-- function model:sphereIntersection(src_x, src_y, src_z, radius)
--     return collisions.sphereIntersection(self.verts, self, src_x, src_y, src_z, radius)
-- end

-- function model:closestPoint(src_x, src_y, src_z)
--     return collisions.closestPoint(self.verts, self, src_x, src_y, src_z)
-- end

-- function model:capsuleIntersection(tip_x, tip_y, tip_z, base_x, base_y, base_z, radius)
--     return collisions.capsuleIntersection(self.verts, self, tip_x, tip_y, tip_z, base_x, base_y, base_z, radius)
-- end

return model
