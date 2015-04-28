Calc = require "c"

--This is for testing - will have to be substituted with something better
local testplanet = {albedo = 0.24, greenhouse = 0.4}

local Quadrant = {}
Quadrant.__index = Quadrant

function Quadrant.new(x, y, latitude, altitude, type, planet)
	local q = {}
	q.x = x
	q.y = y
	q.latitude = latitude
	q.altitude = altitude
	q.type = type
	q.albedo = 0
	q.greenhouse = 0
	q.planet = planet or testplanet
	q.temp = 0
	q.wind = {x=0, y=0}
	return setmetatable(q, Quadrant)
end

--Adjust temperature for incoming irradiation/insolation
function Quadrant:heatUp(incomingradiation)
	local irradiation = incomingradiation * (1 - self.planet.albedo - self.albedo + self.planet.greenhouse + self.greenhouse)
	self.temp = Calc.newTemp(self.temp, irradiation, Calc.HC[self.type], Calc.HC["air"])
end

--Initialize pressure - this needs to be fed with the right pressure for latitude
function Quadrant:initPressure(pressure)
	self.pressure = pressure
end

--Based on current pressure and neighbors taken from the map, calculate the wind vector
function Quadrant:calcWindVec(map)
	local vec = {}
	vec.x = 0
	vec.y = 0
	for x=-1,1 do
		for y=-1, 1 do
			if x ~= 0 or y ~= 0 then
				local wind = Calc.getWind(self.pressure, map:getNeighbor(self.x, self.y, x, y).pressure)
				vec.x = vec.x + x * wind
				vec.y = vec.y + y * wind
			end
		end
	end
	wind = Calc.addCoriolis(wind, self.latitude)
	self.wind.x = self.wind.x + vec.x
	self.wind.y = self.wind.y + vec.y
end

--This adds surface ocean currents. I give them same strength as winds for now.
function Quadrant:calcWaterVec()
	if self.type == "water" then
		self.current = Calc.addEkman(self.wind, self.latitude)
	end
end

function Quadrant:moveWater(map)

end

return Quadrant

