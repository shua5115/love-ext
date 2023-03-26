---@class LoveExt.Events
local events = {}
love.listeners = setmetatable({}, {__index = events})

local listenermt = {__newindex = function(t, k, v)
	if type(k) == "function" then
		rawset(t, k, v)
		return
	elseif type(k) == "number" and type(v) == "function" then
		rawset(t, v, true)
		return
	end
	assert(false, "cannot add or remove a non-function as a listener")
end}

---Add a new callback for an event. Note that this listener will not be easily disabled if no references to it are kept.
---@param event_name string
---@param func function function to be called when this event is triggered (like with love.event.push)
---@return boolean success
function events.add_callback(event_name, func)
	if type(event_name) ~= "string" or type(func) ~= "function" then return false end
	-- if the table for the callback does not exist, create it
	if not love.listeners[event_name] then
        love.listeners[event_name] = setmetatable({}, listenermt)
    end
	love.listeners[event_name][func] = true
	return true
end

---Removes a callback for an event, if it exists
---@param event_name string
---@param func function
function events.remove_callback(event_name, func)
	if love.listeners and type(love.listeners[event_name]) == "table" then
		love.listeners[event_name][func] = nil
	end
end

return events