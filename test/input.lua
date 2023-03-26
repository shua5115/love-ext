---@diagnostic disable: cast-local-type
local input = require "love_ext.input"
local state = {}
local g = love.graphics
local math = require "math"
local math_ext = require("love_ext.math")
local color = math_ext.color
---@type LoveExt.Input.Controls
local ctrl;
local actions = {
    "move","look","left","right","down","up","jump","attack","scroll","scrollup","scrolldown"
}
local mapping = {
    keyboard = {w="up", a="left", s="down", d="right", space="jump", up="scrollup", down="scrolldown"},
    mouse = {delta="look", wheel="scroll", [1]="attack"},
    gamepad = {dpup="up", dpdown="down", dpleft="left", dpright="right", leftxy="move", a="jump", b="jump", triggerright="attack", rightxy="look", leftshoulder="scrolldown", rightshoulder="scrollup"},
}

---Draws the data from an action in a box with top left corner at 0,0.
---Use transformations to change its position.
---@param action LoveExt.Input.Action
---@param h number height
local function drawInputAction(action, h)
    -- axis2d
    g.setColor(color(1))
    g.circle("line", h*0.5, h*0.5, h*0.5)
    g.setColor(color(0.5))
    g.circle("fill", math_ext.map(action.x, -1, 1, 0, h), math_ext.map(action.y, -1, 1, 0, h), h*0.125)
    -- button
    local buttonfillmode = "line"
    if action.buttonpressed then
        g.setColor(0, 1, 0)
        buttonfillmode = "fill"
    elseif action.buttonreleased then
        g.setColor(1, 0, 0)
        buttonfillmode = "fill"
    else
        g.setColor(color(1))
        if action.button then
            buttonfillmode = "fill"
        end
    end
    g.rectangle(buttonfillmode, 10+h, 0, h, h)
    -- axis
    g.setColor(color(1))
    g.rectangle("line", 2*(10+h), 0, h, h)
    local scaledvalue = math_ext.map(action.value, -1, 1, h*0.5, h*-0.5)
    g.rectangle("fill", 2*(10+h), h*0.5, h, scaledvalue)
end

function state:init()
    ctrl = input.newControls(actions, mapping, 1) -- 1->use the first joystick, if available
    input.mouseSensitivity = 0.05
    ctrl:setActive(false)
end

function state:enter()
    ctrl:setActive(true)
end

---@type LoveExt.Input.Action
local move_clean

function state:update(dt)
    if ctrl:isDown("left", "right", "up", "down") or ctrl:wasJustReleased("left", "right", "up", "down") then
        ctrl:buttonsToAxis2d("move", ctrl:getAction("left"), ctrl:getAction("right"), ctrl:getAction("up"), ctrl:getAction("down"), true)
    end
    if ctrl:isDown("scrollup", "scrolldown") or ctrl:wasJustReleased("scrollup", "scrolldown") then
        local yaxis = input.buttonsToAxis(nil, ctrl:getAction("scrolldown"), ctrl:getAction("scrollup"))
        ctrl:toAxis2d("scroll", nil, yaxis)
    end
    local attack_action = ctrl:getAction("attack")
    if attack_action.button or attack_action.buttonreleased then
        input.buttonsToAxis(attack_action, nil, attack_action)
    end
    move_clean = ctrl:deadzone("move", 0.2, 0.9)
end

function state:draw()
    -- Input Display
    local nactions = #actions
    local move_y = 0
    for i = 1, nactions do
        local name = actions[i]
        g.push()
        local y = (i-1)*60
        g.translate(0, y)
        if name == "move" then
            move_y = y
        end
        drawInputAction(ctrl.actions[name], 50)
        g.setColor(color(1))
        g.print(name, 0, 0)
        g.pop()
    end
    g.push()
    g.translate(200, move_y)
    drawInputAction(move_clean, 50)
    g.setColor(color(1))
    g.print("move with deadzone", 0, 0)
    g.pop()
    -- Input Listening
    do
        if ctrl:getAction("attack").value > 0.1 then input.clearListen() end
        g.push()
        g.translate(love.graphics.getWidth()-500, 0)
        local offset = 0
        local function nextLine() offset = offset + 20 end
        local joysticks = love.joystick.getJoysticks()
        for i, joystick in ipairs(joysticks) do
            love.graphics.print("Connected ("..i.."):" .. joystick:getName(), 0, offset)
            nextLine()
        end
        love.graphics.print('Press the "attack" button to clear.', 0, offset)
        nextLine()
        local inputtype, device, inputkey
        local function listenPrint(desc, ...)
            inputtype, device, inputkey = input.listen(...)
            inputtype = inputtype or ""
            device = device or ""
            inputkey = inputkey or ""
            love.graphics.print(desc..": "..inputtype..", "..device..", "..inputkey, 0, offset)
            nextLine()
        end
        listenPrint("Last button", "button")
        listenPrint("Last axis", "axis")
        listenPrint("Last axis2d", "axis2d")
        listenPrint("Last keyboard input", nil, "keyboard")
        listenPrint("Last mouse input", nil, "mouse")
        listenPrint("Last gamepad input", nil, "gamepad", 1)
        listenPrint("Last joystick button input", nil, "joystickbutton", 1)
        listenPrint("Last joystick axis input", nil, "joystickaxis", 1)
        g.pop()
    end
end

function state:leave()
    ctrl:setActive(false)
end

---@param ctrl LoveExt.Input.Controls
---@param name any
---@param action LoveExt.Input.Action
function state:actionpressed(ctrl, name, action)
    -- print(("Action %q pressed"):format(name))
end

---@param ctrl LoveExt.Input.Controls
---@param name any
---@param action LoveExt.Input.Action
function state:actionreleased(ctrl, name, action)
    -- print(("Action %q released"):format(name))
end

---@param ctrl LoveExt.Input.Controls
---@param name any
---@param action LoveExt.Input.Action
function state:actionaxis(ctrl, name, action)
    -- print(("Action %q axis moved: %f"):format(name, action.value))
end

---@param ctrl LoveExt.Input.Controls
---@param name any
---@param action LoveExt.Input.Action
function state:actionaxis2d(ctrl, name, action)
    -- print(("Action %q axis2d moved: (%f, %f)"):format(name, action.x, action.y))
end

return state