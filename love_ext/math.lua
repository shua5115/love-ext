-- Some functions taken from cpml code which uses an MIT License

local math = require "math"

---@class LoveExt.Math
local math_ext = {}

function math_ext.sign(n)
    return (n < 0 and -1) or (n > 0 and 1) or 0
end

---Linearly interpolates from a to b for t from 0 to 1.
---Does not clamp.
---@return number
function math_ext.lerp(a, b, t)
	return a + t*(b - a)
end

---Inverse linear interpolation. Returns a 't' value.
---Will fail if a==b.
---@return number
function math_ext.invlerp(a, b, v)
	return (v - a)/(b - a)
end

---Maps from one linear scale to another using lerp and invlerp.
---Will fail if a1==b1.
function math_ext.map(v, a1, b1, a2, b2)
	return math_ext.lerp(a2, b2, math_ext.invlerp(a1, b1, v))
end

---Constrains the given value between lo and hi.
---Will fail if lo > hi.
---@return number
function math_ext.clamp(v, lo, hi)
    return math.min(math.max(v, lo), hi)
end

--- Shorthand for color creation. 
--- Creates grayscale rgba values with 1 or 2 arguments.
--- Creates regular rgba values with 3 or 4 arguments.
--- @param r number Grayscale if b is omitted
--- @param g? number Alpha if b is omitted
--- @param b? number
--- @param a? number
function math_ext.color(r, g, b, a)
    if b then return r, g, b, a or 1 end
	return r, r, r, g or 1
end

---Creates a grayscale color which contrasts the given color.
---Good for choosing a text color on top of a background.
---@param r number
---@param g number
---@param b number
---@return number, number, number, number
function math_ext.grayscale_contrast_color(r, g, b)
	if type(r) == "table" then
		r, g, b = unpack(r)
	end
	-- from https://stackoverflow.com/questions/1855884/determine-font-color-based-on-background-color
	local luminance = (0.299 * r + 0.587 * g + 0.114 * b);
	if luminance > 0.5 then
		return math_ext.color(0)
	end
	return math_ext.color(1)
end

---Like inverse lerp, but clamps from 0 to 1 and smooths out when approaching the limits.
---@param low number
---@param high number
---@param v number
---@return number
function math_ext.smoothstep(low, high, v)
	local t = math_ext.clamp((v - low) / (high - low), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
end

---Round number to nearest integer, or by steps of "precision" if provided.
---@param value number
---@param precision number?
---@return number
function math_ext.round(value, precision)
	if precision then return math_ext.round(value / precision) * precision end
	return value >= 0 and math.floor(value+0.5) or math.ceil(value-0.5)
end

---Wrap `value` around if it exceeds `limit`.
---@param value number
---@param limit number
---@return number
function math_ext.wrap(value, limit)
	if value < 0 then
		value = value + math_ext.round(((-value/limit)+1))*limit
	end
	return value % limit
end

return math_ext