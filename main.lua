local ext = require "love_ext"
local _ = require "love_ext.g3d.matrices"
love.run = ext.run
local testnames = {
    "input";
    "g3d";
}
---@type string
local help_text = {"Press numbers 1-9 to select a test:"}
local tests = {}
for i, name in ipairs(testnames) do
    if i > 9 then
        break
    end
    tests[i] = require("test."..name)
    help_text[#help_text+1] = i..". "..name
end
---@diagnostic disable-next-line: param-type-mismatch
help_text = table.concat(help_text, "\n")
local show_help = true
function love.load()
    ext.gamestate.registerEvents()
end

function love.draw()
    if show_help then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(help_text)
    else
        local fpslabel = love.timer.getFPS().." FPS"
        local screenw = love.graphics.getWidth()
        local labelw = love.graphics.getFont():getWidth(fpslabel)
        love.graphics.printf(fpslabel, (screenw-labelw)*0.5, 0, labelw, "center")
    end
end
local blank_state = {}
function love.keypressed(k)
    if k == "escape" then
        love.event.push("quit")
    end
    if k == "0" then
        ext.gamestate.switch(blank_state)
        show_help = true
    end
    local testidx = tonumber(k)
    if testidx then
        local state_to_enter = tests[testidx]
        if state_to_enter and state_to_enter~=ext.gamestate.current() then
            show_help = false
            ext.gamestate.switch(state_to_enter)
        end
    end
end