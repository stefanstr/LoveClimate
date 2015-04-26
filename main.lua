local class = require "middleclass"

local HeightMap = class("HeightMap")

function HeightMap:initialize(img)
  self.width = img:getWidth()-1
  self.height = img:getHeight()-1
  for w=0, self.width do
  	self[w] = {}
    for h=0, self.height do
      local r,g,b,a = img:getPixel(w, h)
	  local pix = {}
	  pix.r = r
	  pix.g = g
	  pix.b = b
	  pix.a = a
      self[w][h] = pix
    end
  end
end

function HeightMap:modify()
  for w=0, self.width do
    for h=0, self.height do
      self[w][h].r = 120
    end
  end
end

function HeightMap:update(img)
  for w=0, self.width do
    for h=0, self.height do
      img:setPixel(w, h, self[w][h].r, self[w][h].g, self[w][h].b, self[w][h].a)
    end
  end

end

function love.load()
	cwd = love.filesystem.getWorkingDirectory( )
	heightmap = love.image.newImageData("heightmap.png")
	hm = HeightMap:new(heightmap)
	hm:modify()
	hm:update(heightmap)
	result = love.graphics.newImage(heightmap)
end

function love.update(dt)
end

function love.draw()
-- love.graphics.print(cwd)
--love.graphics.print(heightmap:type())
--love.graphics.print(hm[1][1]["b"])
love.graphics.draw(result)
end