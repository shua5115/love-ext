local g3d = require "love_ext.g3d" -- g3d is opt-in
local primitives = require "love_ext.g3d.primitives"
local state = {}

local newTransform = love.math.newTransform
local setTransform = g3d.matrices.setTransformationMatrix

local uv_shader = love.graphics.newShader([[
    uniform mat4 projectionMatrix;
    uniform mat4 viewMatrix;
    uniform mat4 modelMatrix;
    uniform bool isCanvasEnabled;

    varying vec4 worldPosition;
    varying vec4 viewPosition;
    varying vec4 screenPosition;
    varying vec3 vertexNormal;
    varying vec4 vertexColor;

    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
        vec4 texcolor = Texel(tex, texcoord);
        // vec4 modelscreenpos = projectionMatrix * viewMatrix * modelMatrix * vec4(0, 0, 0, 1);
        // get rid of transparent pixels
        //if (texcolor.a == 0.0) {
        //    discard;
        //}
        
        return texcolor * color * vec4(texcoord.x, texcoord.y, 0, 1);
    }
]], g3d.vertex_shader_source)

local normal_shader = love.graphics.newShader([[
    uniform mat4 projectionMatrix;
    uniform mat4 viewMatrix;
    uniform mat4 modelMatrix;
    uniform bool isCanvasEnabled;

    varying vec4 worldPosition;
    varying vec4 viewPosition;
    varying vec4 screenPosition;
    varying vec3 vertexNormal;
    varying vec4 vertexColor;

    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
        vec4 texcolor = Texel(tex, texcoord);
        // vec4 modelscreenpos = projectionMatrix * viewMatrix * modelMatrix * vec4(0, 0, 0, 1);
        // get rid of transparent pixels
        //if (texcolor.a == 0.0) {
        //    discard;
        //}
        vec3 remapped_normals = (vertexNormal+vec3(1, 1, 1))*0.5; // remap from -1,1 -> 0,1
        return texcolor * color * vec4(remapped_normals,1);
    }
]], g3d.vertex_shader_source)

local box = primitives.box(1, 1, 1)
local sphere = primitives.sphere(1)
local cylinder = primitives.cylinder(1, 1)
local plane = primitives.plane(10, 10, 10, 10)
local skybox = primitives.sphere(100)

function state:init()
    box.transform = setTransform(newTransform(), {0, 0, 0}, {0.1, 0.2, 0.5})
    sphere.transform = setTransform(newTransform(), {0, 10 ,0})
    cylinder.transform = setTransform(newTransform(), {0, -10, 0})
    plane.transform = setTransform(newTransform(), {0, 0, -5})
    skybox.transform = newTransform()
end

function state:enter()
    g3d.camera.lookInDirection(-10, 0, 0)
    g3d.camera.firstPersonLook(0, 0)
end

function state:leave()
    love.mouse.setRelativeMode(false)
    love.graphics.setMeshCullMode("none")
end

function state:update(dt)
    g3d.camera.firstPersonMovement(dt)
end

function state:mousemoved(x, y, dx, dy)
    g3d.camera.firstPersonLook(dx, dy)
end

function state:draw()
    love.graphics.setMeshCullMode("back")
    love.graphics.setColor(1, 1, 1, 1)
    box:draw(box.transform, uv_shader)
    sphere:draw(sphere.transform, uv_shader)
    cylinder:draw(cylinder.transform, uv_shader)
    plane:draw(plane.transform, uv_shader)
    love.graphics.setMeshCullMode("front")
    skybox:draw(skybox.transform, normal_shader)
    love.graphics.setColor(0, 0, 0, 1)
    local cx, cy = love.graphics.getWidth()/2, love.graphics.getHeight()/2
    love.graphics.line(cx, cy-4, cx, cy+4)
    love.graphics.line(cx-4, cy, cx+4, cy)
end

return state