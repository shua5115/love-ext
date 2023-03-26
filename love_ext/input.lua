---@diagnostic disable: undefined-field

---@class LoveExt.Input
local input = {}

---@alias LoveExt.Input.Device "keyboard"|"mouse"|"gamepad"|"joystickbutton"|"joystickaxis"
---@alias LoveExt.InputType "button"|"axis"|"axis2d"
---@alias LoveExt.JoystickID love.Joystick|integer
---@alias LoveExt.InputConstant string
-- love.KeyConstant|love.JoystickHat|love.GamepadAxis|love.GamepadButton|"leftxy"|"rightxy"|"pos"|"delta"|"wheel"

--== DEPENDENCIES ==--
local parent_path = (...):match("(.-)[^%.]+$")
---@type LoveExt.Events
local events = require(parent_path .. "events")
---@type LoveExt.Math
local math_ext = require(parent_path .. "math")
local map = math_ext.map
local isqrt2 = 2^-0.5

--== HELPERS ==--

--- Recursively indexes into a table, returning nil if any indexing fails
local function safeget(t, ...)
	local arg = {...}
	local argc = #arg
	for i, v in ipairs(arg) do
		if not (type(t) == "table") then return nil end
		if i < argc then
			t = t[v]
		else
			return t[v]
		end
	end
	return nil
end

---Tries to tell if a given value is of type LoveExt.JoystickID
---@param j any
---@return boolean
local function isJoystick(j)
	if j == nil then return false end
	if type(j) == "number" then
		return true
	end
	local success, isJoyType = pcall(j.typeOf, j, "Joystick")
	return success and isJoyType
end

---Gets the Joystick associated with a JoystickID, if possible.
---@param joystick LoveExt.JoystickID
---@return love.Joystick?
function input.joystickFromID(joystick)
    if isJoystick(joystick) then
        if type(joystick) == "number" then return love.joystick.getJoysticks()[joystick] end
        ---@diagnostic disable-next-line: return-type-mismatch
        return joystick
    end
end

--== BACKEND ==--

local buttonjustpressed = {}
local buttonjustreleased = {}

---Handles a button press from any device
---@param press boolean
---@param ctrl LoveExt.Input.Controls
---@param device LoveExt.Input.Device
---@param key LoveExt.InputConstant
local function handlebutton(press, ctrl, device, key)
	local function process(actionname)
		local action = safeget(ctrl.actions, actionname)
		if action then
			action.button = press
			if press then
				action.buttonpressed = true
				table.insert(buttonjustpressed, action)
			else
				action.buttonreleased = true
				table.insert(buttonjustreleased, action)
			end
			if (press and rawget(love.handlers, "actionpressed") or rawget(love.handlers, "actionreleased")) then
				pcall(love.event.push, press and "actionpressed" or "actionreleased", ctrl, actionname, action)
			end
		end
	end
	local actions = safeget(ctrl.mapping, device, key)
	if type(actions) ~= "table" then
		process(actions)
	else
		for _, actionname in ipairs(actions) do
			process(actionname)
		end
	end
end

---Handles an axis input from any device
---@param v number
---@param ctrl LoveExt.Input.Controls
---@param device LoveExt.Input.Device
---@param key LoveExt.InputConstant
local function handleaxis(v, ctrl, device, key)
	local function process(actionname)
		local action = safeget(ctrl.actions, actionname)
		if action then
			action.value = v
			if rawget(love.handlers, "actionaxis") then
				pcall(love.event.push, "actionaxis", ctrl, actionname, action)
			end
		end
	end
	local actions = safeget(ctrl.mapping, device, key)
	if type(actions) ~= "table" then
		process(actions)
	else
		for _, actionname in ipairs(actions) do
			process(actionname)
		end
	end
end

---Handles a 2d axis for any device
---@param x number? If omitted, the value goes unchanged.
---@param y number? If omitted, the value goes unchanged.
---@param ctrl LoveExt.Input.Controls
---@param device LoveExt.Input.Device
---@param key LoveExt.InputConstant
local function handleaxis2d(x, y, ctrl, device, key)
	local function process(actionname)
		local action = safeget(ctrl.actions, actionname)
		if action then
			action.x, action.y = x or action.x, y or action.y	-- allow only setting one axis at a time
			if rawget(love.handlers, "actionaxis2d") then
				pcall(love.event.push, "actionaxis2d", ctrl, actionname, action)
			end
		end
	end
	local actions = safeget(ctrl.mapping, device, key)
	if type(actions) ~= "table" then
		process(actions)
	else
		for _, actionname in ipairs(actions) do
			process(actionname)
		end
	end
end

---Handles button input from a joystick. Filters out inputs not associated with a Controls' joystick.
---@param joystick LoveExt.JoystickID
---@param press boolean
---@param ctrl LoveExt.Input.Controls
---@param device LoveExt.Input.Device
---@param key LoveExt.InputConstant
local function handlejoystickbutton(joystick, press, ctrl, device, key)
	if type(ctrl.joystick) == "number" then
		if love.joystick.getJoysticks()[ctrl.joystick] ~= joystick then return end
	elseif ctrl.joystick and ctrl.joystick ~= joystick then return end
    handlebutton(press, ctrl, device, key)
end

---Handles axis input from a joystick. Filters out inputs not associated with a Controls' joystick.
---@param joystick LoveExt.JoystickID
---@param value number
---@param ctrl LoveExt.Input.Controls
---@param device LoveExt.Input.Device
---@param key LoveExt.InputConstant
local function handlejoystickaxis(joystick, value, ctrl, device, key)
	if type(ctrl.joystick) == "number" then
		if love.joystick.getJoysticks()[ctrl.joystick] ~= joystick then return end
	elseif ctrl.joystick and ctrl.joystick ~= joystick then return end
	
	local function process(actionname)
		local action = safeget(ctrl.actions, actionname)
		if action then
			action.value = value
		end
		if action and rawget(love.handlers, "actionaxis") then
			pcall(love.event.push, "actionaxis", ctrl, actionname, action)
		end
		if key == "leftx" then
			handleaxis2d(value, nil, ctrl, device, "leftxy")
		end
		if key == "lefty" then
			handleaxis2d(nil, value, ctrl, device, "leftxy")
		end
		if key == "rightx" then
			handleaxis2d(value, nil, ctrl, device, "rightxy")
		end
		if key == "righty" then
			handleaxis2d(nil, value, ctrl, device, "rightxy")
		end
	end
	local actions = safeget(ctrl.mapping, device, key)
	if type(actions) ~= "table" then
		process(actions)
	else
		for _, actionname in ipairs(actions) do
			process(actionname)
		end
	end
end

local lastinput = {}

---Stores a previous input
---@param inputtype LoveExt.InputType
---@param device LoveExt.Input.Device
---@param key any
---@param joystick LoveExt.JoystickID?
local function setlastinput(inputtype, device, key, joystick)
	lastinput[inputtype] = lastinput[inputtype] or {}
	lastinput[inputtype][device] = key
	lastinput[inputtype][1] = device
	lastinput[inputtype][2] = key
	lastinput[device] = {inputtype, key}
	if isJoystick(joystick) and joystick then
		lastinput[inputtype][joystick] = lastinput[inputtype][joystick] or {}
		lastinput[inputtype][joystick][device] = key
		lastinput[joystick] = lastinput[joystick] or {}
		lastinput[joystick][device] = {inputtype, key}
	end
	lastinput[1], lastinput[2], lastinput[3] = inputtype, device, key
end

-- only referenced Controls objects should recieve updates
local active = setmetatable({}, {__mode = "k"})

--== CALLBACKS ==--

local callbacks = {}

-- For all of the callbacks, the calls to "setlastinput" come before the handler
-- because if a callback checks for the last input with a call to input.listen(),
-- we want the returned information to be up-to-date (usable) even if the response time
-- is delayed by a few microseconds

function callbacks.keypressed(k)
    setlastinput("button", "keyboard", k)
	for ctrl in pairs(active) do
		handlebutton(true, ctrl, "keyboard", k)
	end
end

function callbacks.keyreleased(k)
	for ctrl in pairs(active) do
		handlebutton(false, ctrl, "keyboard", k)
	end
end

function callbacks.mousepressed(x, y, button)
    setlastinput("button", "mouse", button)
	for ctrl in pairs(active) do
		handlebutton(true, ctrl, "mouse", button)
	end
end

function callbacks.mousereleased(x, y, button)
	for ctrl in pairs(active) do
		handlebutton(false, ctrl, "mouse", button)
	end
end

-- used to detect when the mouse and mouse wheel starts and stops moving
local wasmousemoved = false
local waswheelmoved = false	
local pwasmousemoved = false
local pwaswheelmoved = false

function callbacks.mousemoved(x, y, dx, dy)
    if dx > 0 or dx < 0 or dy > 0 or dy < 0 then
        setlastinput("axis2d", "mouse", "delta")
    end
	wasmousemoved = true
	for ctrl in pairs(active) do
		handleaxis2d(x, y, ctrl, "mouse", "pos")
		handleaxis2d(dx*input.mouseSensitivity, dy*input.mouseSensitivity, ctrl, "mouse", "delta")
	end
end

function callbacks.wheelmoved(x, y)
    setlastinput("axis2d", "mouse", "wheel")
	waswheelmoved = true
	for ctrl in pairs(active) do
		handleaxis2d(x, y, ctrl, "mouse", "wheel")
	end
end

function callbacks.gamepadpressed(j, b)
    setlastinput("button", "gamepad", b, j)
	for ctrl in pairs(active) do
		-- handlebutton(true, ctrl, "gamepad", b)
        handlejoystickbutton(j, true, ctrl, "gamepad", b)
	end
end

function callbacks.gamepadreleased(j, b)
	for ctrl in pairs(active) do
		-- handlebutton(false, ctrl, "gamepad", b)
        handlejoystickbutton(j, false, ctrl, "gamepad", b)
	end
end

function callbacks.gamepadaxis(j, a, v)
	if v > 0.5 or v < -0.5 then
		setlastinput("axis", "gamepad", a, j)
        -- prioritize detecting axis2d from gamepad
		if a == "leftx" or a == "lefty" then
			setlastinput("axis2d", "gamepad", "leftxy", j)
		end
		if a == "rightx" or a == "righty" then
			setlastinput("axis2d", "gamepad", "rightxy", j)
		end
	end
    for ctrl in pairs(active) do
		handlejoystickaxis(j, v, ctrl, "gamepad", a)
	end
end

function callbacks.joystickpressed(j, b)
	setlastinput("button", "joystickbutton", b, j)
    for ctrl in pairs(active) do
		handlejoystickbutton(j, true, ctrl, "joystickbutton", b)
	end
end

function callbacks.joystickreleased(j, b)
	for ctrl in pairs(active) do
		handlejoystickbutton(j, false, ctrl, "joystickbutton", b)
	end
end

function callbacks.joystickaxis(j, a, v)
	if v > 0.5 or v < -0.5 then
		setlastinput("axis", "joystickaxis", a, j)
	end
	for ctrl in pairs(active) do
		handlejoystickaxis(j, v, ctrl, "joystickaxis", a)
	end
end

function callbacks.update(dt)
	for ctrl in pairs(active) do
		if not wasmousemoved and pwasmousemoved then
			handleaxis2d(0, 0, ctrl, "mouse", "delta")
		end
		if not waswheelmoved and pwaswheelmoved then
			handleaxis2d(0, 0, ctrl, "mouse", "wheel")
		end
	end
	pwasmousemoved = wasmousemoved
	pwaswheelmoved = waswheelmoved
	wasmousemoved = false
	waswheelmoved = false
end

function callbacks.pre()
	for _, action in ipairs(buttonjustpressed) do
		action.buttonpressed = false
	end
	for _, action in ipairs(buttonjustreleased) do
		action.buttonreleased = false
	end
	buttonjustpressed = {}
	buttonjustreleased = {}
end

-- function callbacks.draw()
-- if love.listeners and love.listeners.pre[callbacks.pre] then return end
--     for _, action in ipairs(buttonupdated) do
--         action.buttonpressed = false
--         action.buttonreleased = false
--     end
-- end

for funcname, func in pairs(callbacks) do
    events.add_callback(funcname, func)
end
love.handlers.actionpressed = function(ctrl, name, action) if love.actionpressed then love.actionpressed(ctrl, name, action) end end
love.handlers.actionreleased = function(ctrl, name, action)	if love.actionreleased then love.actionreleased(ctrl, name, action) end end
love.handlers.actionaxis = function(ctrl, name, action) if love.actionaxis then love.actionaxis(ctrl, name, action) end end
love.handlers.actionaxis2d = function(ctrl, name, action) if love.actionaxis2d then love.actionaxis2d(ctrl, name, action) end end

---Creates a new Action object.
---@param src table?
---@return LoveExt.Input.Action
local function newAction(src)
    ---@class LoveExt.Input.Action
	local action = {
        button = false;
        value = 0;
        x = 0;
        y = 0;
        buttonpressed = false; --- True if the button was just pressed this frame
        buttonreleased = false; --- True if the button was just released this frame
    }
	if type(src) == "table" then
		for k, v in pairs(src) do
			action[k] = v
		end
	end
	return action
end

--== PUBLIC FUNCTIONS ==--

input.newAction = newAction

---Modifies an action's x and y to be constrained and rescaled by deadzone limits.
---@param action LoveExt.Input.Action
---@param deadmin number
---@param deadmax number
---@return LoveExt.Input.Action
function input.deadzone(action, deadmin, deadmax)
	assert(deadmin < deadmax, "deadzone min must be less than deadzone max")
	local x, y = action.x or 0, action.y or 0
	local mag = (x*x + y*y)^0.5
	if mag < deadmin then
		x, y = 0, 0
	else
		x, y = x/mag, y/mag	-- normalize
		local newmag = map(mag, deadmin, deadmax, 0, 1)
		if newmag < 0 then newmag = 0 end
		if newmag > 1 then newmag = 1 end
		x, y = x*newmag, y*newmag -- remap
	end
	local ret = newAction(action)
	ret.x, ret.y = x, y
	return ret
end

---Creates/modifies an action with the `x` and `y` fields set from multiple button actions.
---@param dest LoveExt.Input.Action? An action to overwrite. If omitted, creates a new action.
---@param left LoveExt.Input.Action
---@param right LoveExt.Input.Action
---@param down LoveExt.Input.Action
---@param up LoveExt.Input.Action
---@return LoveExt.Input.Action
function input.buttonsToAxis2d(dest, left, right, down, up, normalize)
	local action = dest or newAction()
	left = left or newAction()
	right = right or newAction()
	down = down or newAction()
	up = up or newAction()
	action.x = 0 + (left.button and -1 or 0) + (right.button and 1 or 0)
	action.y = 0 + (down.button and -1 or 0) + (up.button and 1 or 0)
	if normalize and action.x ~= 0 and action.y ~= 0 then
		action.x, action.y = action.x * isqrt2, action.y * isqrt2
	end
	return action
end
---Creates/modifies an action with the `value` field set from multiple button actions.
---@param dest LoveExt.Input.Action? An action to overwrite. If omitted, creates a new action.
---@param neg LoveExt.Input.Action? If omitted, use a default Action
---@param pos LoveExt.Input.Action? If omitted, use a default Action
---@return LoveExt.Input.Action
function input.buttonsToAxis(dest, neg, pos)
	local action = dest or newAction()
	neg = neg or newAction()
	pos = pos or newAction()
	action.value = 0 + (neg.button and -1 or 0) + (pos.button and 1 or 0)
	return action
end

---Creates/modifies an action with its `x` and `y` fields set from two actions' `value` fields.
---@param dest LoveExt.Input.Action? An action to overwrite. If omitted, creates a new action.
---@param xvalue LoveExt.Input.Action? If omitted, use a default Action
---@param yvalue LoveExt.Input.Action? If omitted, use a default Action
---@param normalize boolean?
---@return LoveExt.Input.Action
function input.toAxis2d(dest, xvalue, yvalue, normalize)
	local action = dest or newAction()
	xvalue = xvalue or newAction()
	yvalue = yvalue or newAction()
	action.x, action.y = xvalue.value, yvalue.value
	if normalize and (action.x ~= 0 or action.y ~= 0) then
		local mag = (action.x*action.x + action.y*action.y)^0.5
		action.x, action.y = action.x / mag, action.y / mag
	end
	return action
end

---Splits an axis2d into its two components, and sends them to xdest and ydest.
---@param xdest LoveExt.Input.Action? If omitted, use a default Action
---@param ydest LoveExt.Input.Action? If omitted, use a default Action
---@param src LoveExt.Input.Action
---@param normalize boolean?
---@return LoveExt.Input.Action x_action, LoveExt.Input.Action y_action
function input.toAxis(xdest, ydest, src, normalize)
	xdest = xdest or newAction()
	ydest = ydest or newAction()
	if normalize and (src.x ~= 0 or src.y ~= 0) then
		local mag = (src.x*src.x + src.y*src.y)^0.5
		xdest.value, ydest.value = src.x / mag, src.y / mag
	else
		xdest.value, ydest.value = src.x, src.y
	end
	return xdest, ydest
end

---@class LoveExt.Input.Controls
local controls = {}
local controls_mt = {__index=controls}

---Enables or disables a Controls object.
---Disabled Controls don't create any callbacks.
---@param isactive boolean?
function controls:setActive(isactive)
	if isactive then
		active[self] = true
	else
		active[self] = nil
		-- This may be a good idea for mouse.delta, but not for mouse.pos
		--for name, action in pairs(ctrl.actions) do
		--	resetaction(action)
		--end
	end
end

function controls:isActive()
	return (active[self] ~= nil)
end

function controls:hasAction(actionname)
    return safeget(self.actions, actionname) ~= nil
end

---Gets an Action object associated with a Controls.
---If the Action doesn't exist, a default action is returned.
---If you want to check if an action exists,
---@see LoveExt.Input.Controls.hasAction
---@param actionname any
---@return LoveExt.Input.Action
function controls:getAction(actionname)
	return safeget(self.actions, actionname) or newAction()
end

---Wrapper around input.deadzone where the action used is the action associated with actionname.
---If the action named actionname doesn't exist, then a default action will be returned.
---@see LoveExt.Input.deadzone
---@param actionname any
---@param deadmin number
---@param deadmax number
---@return LoveExt.Input.Action
function controls:deadzone(actionname, deadmin, deadmax)
	return input.deadzone(self:getAction(actionname), deadmin, deadmax)
end

---Returns a table of all input mappings which reference an action name.
---The returned table has entries in the form: `{"device", "key"}`.
---For example, `getInputs("jump")` may returns something like:
---`{{"keyboard", "space"}, {"gamepad", "a"}, {"keyboard", "w"}}`.
---Note: This function performs a depth-first search over the entire mapping table,
---so it is not recommended to call it every frame.
---@param actionname any
---@return table
function controls:getInputs(actionname)
	local mapping = self.mapping
	if not mapping then return {} end
	local inputs = {}
	local seen = {}
	-- depth first search for any input that maps to action actionname
	local function search(t, path)
		if seen[t] then return end
		path = path or {}	-- array of table names/indexes
		local function addinput(key)
			local newpath = {}
			for i, p in ipairs(path) do
				newpath[i] = p
			end
			table.insert(newpath, key)
			table.insert(inputs, newpath)
		end
		for k, v in pairs(t) do
			if type(v) == "table" then
				if (#v) > 0 then	-- v is likely an array of names
					for _, name in ipairs(v) do
						if name == actionname then
							addinput(k)
							break
						end
					end
				else	-- v is likely a sub-table containing more mappings
					seen[t] = true
					local newpath = {}
					for i, p in ipairs(path) do
						newpath[i] = p
					end
					table.insert(newpath, k)
					search(v, newpath)
				end
			elseif v == actionname then	-- k is an input mapping to actionname
				addinput(k)
			end
		end
	end
	search(mapping)
	return inputs
end

---Associates an action name with this Controls object.
---@param actionname any
function controls:newAction(actionname)
	self.actions[actionname] = newAction()
end

---Adds a mapping from an input to action.
---For example, to add a mapping to the "jump" action for keyboard key "space":
---`addMapping("jump", "keyboard", "space")`.
---This function will create tables in the mapping table if they don't exist to reach the path specified by the arguments.
---@param actionname any
---@param device LoveExt.Input.Device
---@param key LoveExt.InputConstant
function controls:addMapping(actionname, device, key)
	if actionname == nil then return end
	local arg = {device, key}
	local argc = #arg
	if argc == 0 then return end
	local t = self.mapping
	for i, k in ipairs(arg) do
		local v = t[k]
		if i == argc then
			if type(v) == "table" then
				table.insert(v, actionname)
			elseif v == nil then
				t[k] = actionname
			else
				t[k] = {t[k], actionname}
			end
		else
			if type(v) == "table" then
				t = v -- recurse
			else
				if v ~= nil then
					local errormsg = "Tried to index a non-table when adding a mapping for \""..actionname.."\" following indices: "
					for index, name in ipairs(arg) do
						errormsg = errormsg..name..(index < argc and ", " or "")
					end
					error(errormsg, 2)
				end
				t[k] = {}
				t = t[k]
			end
		end
	end
end

--- Removes all elements from a table which cause fnKeep to return true.
--- Always iterates over the entire table, but is faster than calling table.remove successively in many cases.
--- Code from https://stackoverflow.com/a/53038524.
---@param t table
---@param fnKeep function
---@return table t
local function arrayremove(t, fnKeep)
    local j, n = 1, #t;

    for i=1,n do
        if (fnKeep(t, i, j)) then
            -- Move i's kept value to j's position, if it's not already there.
            if (i ~= j) then
                t[j] = t[i];
                t[i] = nil;
            end
            j = j + 1; -- Increment position of where we'll place the next kept value.
        else
            t[i] = nil;
        end
    end

    return t;
end

---Ensures the only mapping to actionname is the one created through this function.
---It first removes all mappings associated with actionname,
---then it adds the action specified by the arguments
---@param actionname any
---@param device LoveExt.Input.Device
---@param key LoveExt.InputConstant
function controls:setUniqueMapping(actionname, device, key)
	if actionname == nil then return end
	local inputs = self:getInputs(actionname)
	-- first, remove all references to this actionname from the mapping
	for _, path in ipairs(inputs) do
		local m = safeget(self.mapping, unpack(path))
		if type(m) == "table" then
			arrayremove(m, function(t, i)
				return t[i] == actionname
			end)
		else	-- remove mapping entirely
			local premap = safeget(self.mapping, unpack(path, 1, #path - 1))
			if premap then premap[path[#path]] = nil end
		end
	end
	self:addMapping(actionname, device, key)
end

---Creates an action with the `x` and `y` fields set from multiple button actions.
---If the provided actionname is an action that exists for this Controls,
---then **events will be fired as if this remapping was an input event!**
---This may be useful if, for example, movement is controlled by a single action, "move", using its x and y components.
---Using this function, you could remap WASD to the "move" action and send the appropriate input events,
---allowing you to have multiple devices contributing to the same input.
---@param actionname any Action to associate this remapping with. **If this Action exists, then events will be fired as if this remapping was an input event!**
---@param left LoveExt.Input.Action
---@param right LoveExt.Input.Action
---@param down LoveExt.Input.Action
---@param up LoveExt.Input.Action
---@param normalize boolean?
---@return LoveExt.Input.Action
function controls:buttonsToAxis2d(actionname, left, right, down, up, normalize)
	local action = self:getAction(actionname)
	local exists = self:hasAction(actionname)
	input.buttonsToAxis2d(action, left, right, down, up, normalize)
	if exists then
		pcall(love.event.push, "actionaxis2d", self, actionname, action)
	end
	return action
end

---Creates an action with the `value` field set from multiple button actions.
---If the provided actionname is an action that exists for this Controls, 
---then **events will be fired as if this remapping was an input event!**
---@param actionname any
---@param neg LoveExt.Input.Action?
---@param pos LoveExt.Input.Action?
---@return LoveExt.Input.Action
function controls:buttonsToAxis(actionname, neg, pos)
	local action = self:getAction(actionname)
	local exists = self:hasAction(actionname)
	input.buttonsToAxis(action, neg, pos)
	if exists then
		pcall(love.event.push, "actionaxis", self, actionname, action)
	end
	return action
end

---Creates an action with its `x` and `y` fields set from two actions' `value` fields.
---If the provided actionname is an action that exists for this Controls,
---then **events will be fired as if this remapping was an input event!**
---This may be useful if, for example, movement is controlled by a single action, "move", using its x and y components.
---Using this function, you could remap two arbitrary analog inputs to the "move" action and send the appropriate input events,
---allowing you to have multiple devices contributing to the same input.
---@param actionname any
---@param xvalue LoveExt.Input.Action?
---@param yvalue LoveExt.Input.Action?
---@param normalize boolean?
---@return LoveExt.Input.Action
function controls:toAxis2d(actionname, xvalue, yvalue, normalize)
	local action = self:getAction(actionname)
	local exists = self:hasAction(actionname)
	input.toAxis2d(action, xvalue, yvalue, normalize)
	if exists then
		pcall(love.event.push, "actionaxis2d", self, actionname, action)
	end
	return action
end

---Splits an axis2d into its two components, and sends them to xaxisname and yaxisname.
---If the provided actionname is an action that exists for this Controls,
---then **events will be fired as if this remapping was an input event!**
---@param xaxisname any
---@param yaxisname any
---@param src LoveExt.Input.Action
---@param normalize boolean?
---@return LoveExt.Input.Action x_action, LoveExt.Input.Action y_action
function controls:toAxis(xaxisname, yaxisname, src, normalize, suppress_events)
	local action = src or newAction()
	local x_exists = self:hasAction(xaxisname)
	local destx = self:getAction(xaxisname)
	local y_exists = self:hasAction(yaxisname)
	local desty = self:getAction(yaxisname)
	input.toAxis(destx, desty, action, normalize)
	if not suppress_events then
		if x_exists then
			pcall(love.event.push, "actionaxis", self, xaxisname, destx)
		end
		if y_exists then
			pcall(love.event.push, "actionaxis", self, yaxisname, desty)
		end
	end
	return destx, desty
end

---Returns if the button of the action name is pressed
---@param actionname any
---@param ... any additional buttons to check. Returns true if any are down.
---@return boolean
function controls:isDown(actionname, ...)
	local arg = {actionname, ...}
	for i, name in ipairs(arg) do
		if self:getAction(name).button then return true end
	end
	return false
end

---Returns if the button of the action name was just pressed
---@param actionname any
---@param ... any additional buttons to check. Returns true if any are down.
---@return boolean
function controls:wasJustPressed(actionname, ...)
	local arg = {actionname, ...}
	for i, name in ipairs(arg) do
		if self:getAction(name).buttonpressed then return true end
	end
	return false
end

---Returns if the button of the action name was just released
---@param actionname any
---@param ... any additional buttons to check. Returns true if any are down.
---@return boolean
function controls:wasJustReleased(actionname, ...)
	local arg = {actionname, ...}
	for i, name in ipairs(arg) do
		if self:getAction(name).buttonreleased then return true end
	end
	return false
end

---Creates a new Controls object.
---@param actions table? A list or set of action names
---@param mapping table? A mapping table in the form `{keyboard={love.KeyConstant="actionname"}, gamepad={love.GamepadAxis="actionname", love.GamepadButton="actionname"}, ...}`
---@param joystick LoveExt.JoystickID? A joystick to associate with this Controls.
---@return LoveExt.Input.Controls
function input.newControls(actions, mapping, joystick)
    ---@class LoveExt.Input.Controls
	local ctrl = {}
	ctrl.actions = {}
	if type(actions) == "table" then
		if (#actions) > 0 then -- treat as list
			for _, v in ipairs(actions) do
				ctrl.actions[v] = newAction()
			end
		else -- treat as set
			for k in pairs(actions) do
				ctrl.actions[k] = newAction()
			end
		end
	end
    if type(mapping) == "table" then
        ctrl.mapping = mapping
    else
        ---@class LoveExt.Input.Mapping
        ctrl.mapping = {
            keyboard = {};
            mouse = {};
            joystickbutton = {};
			joystickaxis = {};
            gamepad = {};
        }
    end
	if isJoystick(joystick) then
        ---@type LoveExt.JoystickID?
		ctrl.joystick = joystick
	end
	--for some strange reason, the metatable member __index of the ctrl must be set for it to be an argument in a love event
	setmetatable(ctrl, {__index = controls})
	ctrl:setActive(true)
	return ctrl
end

---Clears the stored inputs used for input listening to allow for more intentional input detection with input.listen().
---If your game supports custom control schemes, then you would call this function upon the user wishing to remap a control.
---@see LoveExt.Input.listen
function input.clearListen()
	lastinput = {}
end

---Filters stored previous inputs to match the specified input type and device. Can also filter by joystick association.
---If no matches are found, return nil.
---If no arguments are provided, it returns the most recent input from any device.
---@param inputtype LoveExt.InputType? The required input type
---@param device LoveExt.Input.Device? The required input device
---@param joystick LoveExt.JoystickID? The required joystick ID
---@return LoveExt.InputType|nil
---@return LoveExt.Input.Device|nil
---@return LoveExt.InputConstant|nil key The input constant associated with the input type and device 
function input.listen(inputtype, device, joystick)
	if inputtype then
		if device then -- inputtype and device
			local key
			if isJoystick(joystick) then
				if type(joystick) == "number" then joystick = love.joystick.getJoysticks()[joystick] end
				key = safeget(lastinput, inputtype, joystick, device)
			else
				key = safeget(lastinput, inputtype, device)
			end
			if key then
				return inputtype, device, key
			end
		else
			device = safeget(lastinput, inputtype, 1)
			local key = safeget(lastinput, inputtype, 2)
			if device and key then
				return inputtype, device, key
			end
		end
	else
		if device then -- device without inputtype
			local typekey
			local isJoy = isJoystick(joystick)
			if isJoy then
				if type(joystick) == "number" then joystick = love.joystick.getJoysticks()[joystick] end
				typekey = safeget(lastinput, joystick, device)
			else
				typekey = safeget(lastinput, device)
			end
			if typekey then
				return typekey[1], device, typekey[2]
			end
			if isJoy or lastinput[2] ~= device then return end
		end
		return lastinput[1], lastinput[2], lastinput[3]
	end
end

---A multiplier on the mouse "delta" axis2d.
---Useful for allowing the mouse and gamepad for the same action
input.mouseSensitivity = 1.0

return input