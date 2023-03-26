-- written by groverbuger for g3d
-- september 2021
-- MIT license

----------------------------------------------------------------------------------------------------
-- vector functions
----------------------------------------------------------------------------------------------------
-- some basic vector functions that don't use tables
-- because these functions will happen often, this is done to avoid frequent memory allocation

---@class LoveExt.G3D.Vectors
local vectors = {}

function vectors.subtract(v1,v2,v3, v4,v5,v6)
    return v1-v4, v2-v5, v3-v6
end

function vectors.add(v1,v2,v3, v4,v5,v6)
    return v1+v4, v2+v5, v3+v6
end

function vectors.scalarMultiply(scalar, v1,v2,v3)
    return v1*scalar, v2*scalar, v3*scalar
end

function vectors.crossProduct(a1,a2,a3, b1,b2,b3)
    return a2*b3 - a3*b2, a3*b1 - a1*b3, a1*b2 - a2*b1
end

vectors.cross = vectors.crossProduct

function vectors.dotProduct(a1,a2,a3, b1,b2,b3)
    return a1*b1 + a2*b2 + a3*b3
end

vectors.dot = vectors.dotProduct

function vectors.normalize(x,y,z)
    local mag = math.sqrt(x^2 + y^2 + z^2)
    if mag ~= 0 then
        return x/mag, y/mag, z/mag
    else
        return 0, 0, 0
    end
end

function vectors.magnitude(x,y,z)
    return math.sqrt(x^2 + y^2 + z^2)
end

function vectors.magnitudeSq(x, y, z)
    return x^2+y^2+z^2
end

---Project a vector onto another vector. 
---The resulting vector points in the direction of b
---with the magnitude of (a dot b).
function vectors.project(ax, ay, az, bx, by, bz)
    local ux, uy, uz = vectors.normalize(bx, by, bz)
    local mag = vectors.dot(ax, ay, az, bx, by, bz)
    return ux*mag, uy*mag, uz*mag
end

---Project a position (v) onto a plane with normal (n) passing through the origin.
function vectors.projectOnPlane(vx, vy, vz, nx, ny, nz)
    local ux, uy, uz = vectors.project(vx, vy, vz, nx, ny, nz)
    return vx-ux, vy-uy, vz-uz
end

-- Code from cpml.vec3 and cpml.utils

---Rotate vector (v) about an axis (a) by an angle (phi, radians)
function vectors.rotate(vx, vy, vz, phi, ax, ay, az)
	local ux, uy, uz = vectors.normalize(ax, ay, az)
	local c = math.cos(phi)
	local s = math.sin(phi)

	-- Calculate generalized rotation matrix
	local m1x, m1y, m1z = (c + ux * ux * (1 - c))     , (ux * uy * (1 - c) - uz * s), (ux * uz * (1 - c) + uy * s)
	local m2x, m2y, m2z = (uy * ux * (1 - c) + uz * s), (c + uy * uy * (1 - c))     , (uy * uz * (1 - c) - ux * s)
	local m3x, m3y, m3z = (uz * ux * (1 - c) - uy * s), (uz * uy * (1 - c) + ux * s), (c + uz * uz * (1 - c))

	return 
		vectors.dot(vx, vy, vz, m1x, m1y, m1z),
		vectors.dot(vx, vy, vz, m2x, m2y, m2z),
		vectors.dot(vx, vy, vz, m3x, m3y, m3z)
end

return vectors
