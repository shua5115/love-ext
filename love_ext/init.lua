---@diagnostic disable: undefined-field, redundant-parameter
local EMPTY = {}

---@class LoveExt
local love_ext = {}
local path = ...
---@type LoveExt.Events
love_ext.events = require(path .. ".events")
---@type LoveExt.Input
love_ext.input = require(path .. ".input")
---@type LoveExt.Math
love_ext.math = require(path .. ".math")
---@type LoveExt.SerializeTable
love_ext.serializetable = require(path .. ".serializetable")
---@type LoveExt.GameState
love_ext.gamestate = require(path .. ".gamestate")
-- do not require g3d or the imgui by default
-- they are opt-in because both are heavy libraries

---Override for the default love.run function to enable more flexible event handling.
---Required for using the input library.
---
---Put this code somewhere in your main.lua to use: `love.run = love_ext.run`.
---@return function main_loop
function love_ext.run()
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
	---The maximum framerate of the application. If nil, 0 or negative, the framerate is uncapped
	love.graphics.targetFrameRate = 0
	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then 
		love.timer.step()
		love.timer.frameCount = 0
	end

	local dt = 0

	-- Main loop time.
	return function()
		local start_time
		if love.timer then
			start_time = love.timer.getTime()
		end 
		-- Preprocessing events, helpful for libraries that want to reset state before processing events or drawing
		if love.listeners then
			for func in pairs(love.listeners.pre or EMPTY) do
				func()
			end
		end
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0
					end
				end
				love.handlers[name](a,b,c,d,e,f)
				if love.listeners then
					for func in pairs(love.listeners[name] or EMPTY) do
						func(a,b,c,d,e,f)
					end
				end
			end
		end

		-- Update dt, as we'll be passing it to update
		if love.timer then 
			dt = love.timer.step()
			love.timer.frameCount = love.timer.frameCount+1
		end

		-- Call update and draw
		if love.listeners then
			for func in pairs(love.listeners.update or EMPTY) do
				func(dt)
			end
		end
		if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled

		local g = love.graphics
		if g and g.isActive() then
			g.origin()
			g.clear(g.getBackgroundColor())
			if love.listeners then
				for func in pairs(love.listeners.draw or EMPTY) do
					func()
				end
			end
			if love.draw then love.draw() end

			g.present()
		end

		if love.timer and love.graphics.targetFrameRate and love.graphics.targetFrameRate > 0 then
			local end_time = love.timer.getTime()
			local frame_time = end_time - start_time
			
			if love.timer then love.timer.sleep(1/love.graphics.targetFrameRate-frame_time) end
		end
		-- if love.timer then love.timer.sleep(0.001) end
	end
end

return love_ext