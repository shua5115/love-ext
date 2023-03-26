-- literally a white pixel
local imagedata = love.image.newImageData(1, 1)
imagedata:mapPixel(function ()
    return 1, 1, 1, 1
end)
return love.graphics.newImage(imagedata)