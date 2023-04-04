-- written by groverbuger for g3d
-- september 2021
-- MIT license
local parent_path = (...):match("(.-)[^%.]+$")
---@type LoveExt.G3D.Vectors
local vectors = require(parent_path .. "vectors")
local vectorCrossProduct = vectors.crossProduct
local vectorDotProduct = vectors.dotProduct
local vectorNormalize = vectors.normalize

----------------------------------------------------------------------------------------------------
-- matrix class
----------------------------------------------------------------------------------------------------
-- matrices are 16 numbers in table, representing a 4x4 matrix like so:
--
-- |  1   2   3   4  |
-- |                 |
-- |  5   6   7   8  |
-- |                 |
-- |  9   10  11  12 |
-- |                 |
-- |  13  14  15  16 |

---@class LoveExt.G3D.Matrix
local matrix = {}
-- local mt = {__index = matrix}
local newTransform = love.math.newTransform

---Creates a new 4x4 matrix.
---@return love.Transform
function matrix.new()
    -- local self = setmetatable({}, mt)
    -- -- initialize a matrix as the identity matrix
    -- self[1],  self[2],  self[3],  self[4]  = 1, 0, 0, 0
    -- self[5],  self[6],  self[7],  self[8]  = 0, 1, 0, 0
    -- self[9],  self[10], self[11], self[12] = 0, 0, 1, 0
    -- self[13], self[14], self[15], self[16] = 0, 0, 0, 1
    -- return self
    return newTransform()
end

---Converts a matrix to a string
---for printing to console and debugging
---@param t love.Transform
---@return string
local function matrixtostring(t)
    return ("%f\t%f\t%f\t%f\n%f\t%f\t%f\t%f\n%f\t%f\t%f\t%f\n%f\t%f\t%f\t%f"):format(t:getMatrix())
end

matrix.toString = matrixtostring
-- mt.__tostring = matrixtostring

----------------------------------------------------------------------------------------------------
-- transformation, projection, and rotation matrices
----------------------------------------------------------------------------------------------------
-- the three most important matrices for 3d graphics
-- these three matrices are all you need to write a simple 3d shader

---Modifies this matrix to be a transformation matrix.
---@param t love.Transform
---@param translation table? {x, y, z}
---@param rotation table? either {x, y, z} euler angles or {x, y, z, w} quaternion
---@param scale (table|number)? either {x, y, z} scale or a single number applied on each axis
---@return love.Transform t
function matrix.setTransformationMatrix(t, translation, rotation, scale)
    -- translations
    local tx, ty, tz = 0, 0, 0
    if translation then
        tx  = translation[1]
        ty  = translation[2]
        tz = translation[3]
    end
    -- rotations
    local r11, r12, r13 = 1, 0, 0
    local r21, r22, r23 = 0, 1, 0
    local r31, r32, r33 = 0, 0, 1
    if rotation then
        local rot_len = #rotation
        if rot_len == 3 then
            -- use 3D rotation vector as euler angles
            -- source: https://en.wikipedia.org/wiki/Rotation_matrix
            local ca, cb, cc = math.cos(rotation[3]), math.cos(rotation[2]), math.cos(rotation[1])
            local sa, sb, sc = math.sin(rotation[3]), math.sin(rotation[2]), math.sin(rotation[1])
            r11, r12, r13  = ca*cb, ca*sb*sc - sa*cc, ca*sb*cc + sa*sc
            r21, r22, r23  = sa*cb, sa*sb*sc + ca*cc, sa*sb*cc - ca*sc
            r31, r32, r33 = -sb, cb*sc, cb*cc
        elseif rot_len == 4 then
            -- use 4D rotation vector as a quaternion
            local qx, qy, qz, qw = rotation[1], rotation[2], rotation[3], rotation[4]
            r11, r12, r13 = 1 - 2*qy^2 - 2*qz^2, 2*qx*qy - 2*qz*qw,   2*qx*qz + 2*qy*qw
            r21, r22, r23 = 2*qx*qy + 2*qz*qw,   1 - 2*qx^2 - 2*qz^2, 2*qy*qz - 2*qx*qw
            r31, r32, r33 = 2*qx*qz - 2*qy*qw,   2*qy*qz + 2*qx*qw,   1 - 2*qx^2 - 2*qy^2
        end
    end

    -- scale
    local sx, sy, sz = 1, 1, 1
    if type(scale) == "table" then
        sx, sy, sz = scale[1], scale[2], scale[3]
    elseif type(scale) == "number" then
        sx, sy, sz = scale, scale, scale
    end
    r11, r12, r13 = r11 * sx, r12  * sy, r13  * sz
    r21, r22, r23 = r21 * sx, r22  * sy, r23  * sz
    r31, r32, r33 = r31 * sx, r32 * sy, r33 * sz

    -- fourth row is not used, just set it to the fourth row of the identity matrix
    t:setMatrix(
        r11, r12, r13, tx,
        r21, r22, r23, ty,
        r31, r32, r33, tz,
        0,   0,   0,   1
    )
    return t
end

-- Additional transformation functions

---Performs a 4x4 matrix multiplication without allocating a new matrix, storing the result in the provided matrix.
---@param t love.Transform
---@param e11 number
---@param e12 number
---@param e13 number
---@param e14 number
---@param e21 number
---@param e22 number
---@param e23 number
---@param e24 number
---@param e31 number
---@param e32 number
---@param e33 number
---@param e34 number
---@param e41 number
---@param e42 number
---@param e43 number
---@param e44 number
---@return love.Transform t
function matrix.apply(t, e11, e12, e13, e14, e21, e22, e23, e24, e31, e32, e33, e34, e41, e42, e43, e44)
    local t11, t12, t13, t14, t21, t22, t23, t24, t31, t32, t33, t34, t41, t42, t43, t44 = t:getMatrix()
    return t:setMatrix(
        t11*e11 + t12*e21 + t13*e31 + t14*e41, t11*e12 + t12*e22 + t13*e32 + t14*e42, t11*e13 + t12*e23 + t13*e33 + t14*e43, t11*e14 + t12*e24 + t13*e34 + t14*e44,
        t21*e11 + t22*e21 + t23*e31 + t24*e41, t21*e12 + t22*e22 + t23*e32 + t24*e42, t21*e13 + t22*e23 + t23*e33 + t24*e43, t21*e14 + t22*e24 + t23*e34 + t24*e44,
        t31*e11 + t32*e21 + t33*e31 + t34*e41, t31*e12 + t32*e22 + t33*e32 + t34*e42, t31*e13 + t32*e23 + t33*e33 + t34*e43, t31*e14 + t32*e24 + t33*e34 + t34*e44,
        t41*e11 + t42*e21 + t43*e31 + t44*e41, t41*e12 + t42*e22 + t43*e32 + t44*e42, t41*e13 + t42*e23 + t43*e33 + t44*e43, t41*e14 + t42*e24 + t43*e34 + t44*e44
    )
end

---Transforms a point from local space to world space.
---@param t love.Transform
---@param x number? default 0
---@param y number? default 0
---@param z number? default 0
---@param w number? default 1 (if 0 only rotation and scale applies)
---@return number globalx, number globaly, number globalz, number globalw
function matrix.transformPoint(t, x, y, z, w)
    x = x or 0
    y = y or 0
    z = z or 0
    w = w or 1
    local e11, e12, e13, e14, e21, e22, e23, e24, e31, e32, e33, e34, e41, e42, e43, e44
        = t:getMatrix()
    return
        e11*x + e12*y + e13*z + e14*w,
        e21*x + e22*y + e23*z + e24*w,
        e31*x + e32*y + e33*z + e34*w,
        e41*x + e42*y + e43*z + e44*w
end

---Transform a point from world space to local space.
---@param t love.Transform
---@param x number? default 0
---@param y number? default 0
---@param z number? default 0
---@param w number? default 1 (if 0 only rotation and scale applies)
---@return number localx, number localy, number localz, number localw
function matrix.inverseTransformPoint(t, x, y, z, w)
    return matrix.transformPoint(t:inverse(), x, y, z, w)
end

---@param t love.Transform
---@param x number?
---@param y number?
---@param z number?
---@return love.Transform t
function matrix.translate(t, x, y, z)
    x = x or 0
    y = y or 0
    z = z or 0
    local e11, e12, e13, e14, e21, e22, e23, e24, e31, e32, e33, e34, e41, e42, e43, e44
        = t:getMatrix()
    return t:setMatrix(
        e11, e12, e13, e14+x,
        e21, e22, e23, e24+y,
        e31, e32, e33, e34+z,
        e41, e42, e43, e44
    )
end

function matrix.rotateAxisAngle(t, ax, ay, az, angle)
    error("TODO")
end

---Rotates this matrix by euler angles
---@param t love.Transform
---@param x number?
---@param y number?
---@param z number?
---@return love.Transform t
function matrix.rotateEuler(t, x, y, z)
    x = x or 0
    y = y or 0
    z = z or 0
    local ca, cb, cc = math.cos(z), math.cos(y), math.cos(x)
    local sa, sb, sc = math.sin(z), math.sin(y), math.sin(x)
    local r11, r12, r13  = ca*cb, ca*sb*sc - sa*cc, ca*sb*cc + sa*sc
    local r21, r22, r23  = sa*cb, sa*sb*sc + ca*cc, sa*sb*cc - ca*sc
    local r31, r32, r33 = -sb, cb*sc, cb*cc
    return matrix.apply(t,
        r11, r12, r13, 0,
        r21, r22, r23, 0,
        r31, r32, r33, 0,
        0, 0, 0, 1
    )
end

---Rotates this matrix by a quaternion
---@param t love.Transform
---@param qx number
---@param qy number
---@param qz number
---@param qw number
---@return love.Transform t
function matrix.rotateQuaternion(t, qx, qy, qz, qw)
    return matrix.apply(t, 
        1 - 2*qy^2 - 2*qz^2, 2*qx*qy - 2*qz*qw,   2*qx*qz + 2*qy*qw, 0,
        2*qx*qy + 2*qz*qw,   1 - 2*qx^2 - 2*qz^2, 2*qy*qz - 2*qx*qw, 0,
        2*qx*qz - 2*qy*qw,   2*qy*qz + 2*qx*qw,   1 - 2*qx^2 - 2*qy^2, 0,
        0, 0, 0, 1
    )
end

---Scales a matrix axially or uniformly.
---@param t love.Transform
---@param x number?
---@param y number?
---@param z number?
---@return love.Transform t
function matrix.scale(t, x, y, z)
    x = x or 1
    y = y or 1
    z = z or 1
    local e11, e12, e13, e14, e21, e22, e23, e24, e31, e32, e33, e34, e41, e42, e43, e44
        = t:getMatrix()
    return t:setMatrix(
        e11*x, e12*y, e13*z, e14,
        e21*x, e22*y, e23*z, e24,
        e31*x, e32*y, e33*z, e34,
        e41*x, e42*y, e43*z, e44
    )
end

---Creates a perspective projection matrix
---(things farther away appear smaller)
---all arguments are scalars (numbers)
---aspectRatio is defined as window width divided by window height
---@param t love.Transform
---@param fov number
---@param near number
---@param far number
---@param aspectRatio number
---@return love.Transform t
function matrix.setProjectionMatrix(t, fov, near, far, aspectRatio)
    local top = near * math.tan(fov/2)
    local bottom = -1*top
    local right = top * aspectRatio
    local left = -1*right
    t:setMatrix(
        2*near/(right-left), 0, (right+left)/(right-left), 0,
        0, 2*near/(top-bottom), (top+bottom)/(top-bottom), 0,
        0, 0, -1*(far+near)/(far-near), -2*far*near/(far-near),
        0, 0, -1, 0
    )
    return t
end

---Creates an orthographic projection matrix
---(things farther away are the same size as things closer)
---all arguments are scalars (numbers)
---aspectRatio is defined as window width divided by window height
---@param t love.Transform
---@param fov number
---@param size number
---@param near number
---@param far number
---@param aspectRatio number
---@return love.Transform t
function matrix.setOrthographicMatrix(t, fov, size, near, far, aspectRatio)
    local top = size * math.tan(fov/2)
    local bottom = -1*top
    local right = top * aspectRatio
    local left = -1*right
    t:setMatrix(
        2/(right-left), 0, 0, -1*(right+left)/(right-left),
        0, 2/(top-bottom), 0, -1*(top+bottom)/(top-bottom),
        0, 0, -2/(far-near), -(far+near)/(far-near),
        0, 0, 0, 1
    )
    return t
end

---Creates a view matrix.
---eye, target, and up are all 3D vectors
---@param t love.Transform
---@param eyex number
---@param eyey number
---@param eyez number
---@param targetx number
---@param targety number
---@param targetz number
---@param upx number
---@param upy number
---@param upz number
---@return love.Transform t
function matrix.setViewMatrix(t, eyex, eyey, eyez, targetx, targety, targetz, upx, upy, upz)
    local z1, z2, z3 = vectorNormalize(eyex - targetx, eyey - targety, eyez - targetz)
    local x1, x2, x3 = vectorNormalize(vectorCrossProduct(upx, upy, upz, z1, z2, z3))
    local y1, y2, y3 = vectorCrossProduct(z1, z2, z3, x1, x2, x3)

    t:setMatrix(
        x1, x2, x3, -1*vectorDotProduct(x1, x2, x3, eyex, eyey, eyez),
        y1, y2, y3, -1*vectorDotProduct(y1, y2, y3, eyex, eyey, eyez),
        z1, z2, z3, -1*vectorDotProduct(z1, z2, z3, eyex, eyey, eyez),
        0, 0, 0, 1
    )
    return t
end

return matrix
