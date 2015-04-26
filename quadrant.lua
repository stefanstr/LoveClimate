--A quadrant is one pixel on the map - all weather calculations happen on the level of
--a quadrant and interactions between neighboring quadrants.
--A quadrant is oblivious to its neighbors - it only knows its coordinates and returns
--a table with coordinates of Quadrants that need to be modified. It is for an external
--function to know how to deal with out of bounds values.

Calc = require "calculations"

-- Private functions --

local function check(arg)
	if type(arg) ~= "number" then
		error "A non-numeric argument has been entered."
	end
end

-- To be exported --

local Quadrant = {}
Quadrant.__index = Quadrant

--Temperatures are in Kelvin
function Quadrant.new(x, y, latitude, altitude, temperature, pressure, terrain)
	local q = {}
	check(x)
	q.x = x
	check(y)
	q.y = y
	check(altitude)
	q.altitude = altitude
	check(temperature)
	q.airTemp = temperature
	q.groundTemp = temperature
	check(pressure)
	q.airPressure = pressure
	q.airHumidity = 0
	check(latitude)
	q.latitude = latitude
	q.terrain = terrain
	q.vegetation = "none"
	q.clouds = 0 -- percentage: 0-1
	return setmetatable(q, Quadrant)
end

function Quadrant:ingestData(...)
end

--This function adds incoming insolation to the system.
--The amount of insolation needs to be calculated outside of this function.

function Quadrant:addInsolation(insolation)
	--Atmospheric albedo
	local insolation = insolation * (1 - Calc.albedoTable.atmosphericAlbedo)
	--Cloud cover
	local insolation = Calc.addCloudGreenhouse(insolation, self.clouds)
	--Heat up air
	self.airTemp = Calc.newTemp(self.airTemp, Calc.irradiationToTemp(insolation*Calc.albedoTable.atmosphericAbsorption), Calc.HeatCapacity["air"])
	local insolation = insolation * (1 - Calc.albedoTable.atmosphericAbsorption)
	--Heat up the ground
	self.groundTemp = Calc.newTemp(self.groundTemp, Calc.irradiationToTemp(insolation), Calc.HeatCapacity[self.terrain])
end

function Quadrant:equalizeTemp()
	local airI = Calc.tempToIrradiation(self.airTemp)
	local groundI = Calc.tempToIrradiation(self.groundTemp)
	
end

function Quadrant:updateAir(...)
end

function Quadrant:generateClouds(...)
end

function Quadrant:defineWind(...)
end

function Quadrant:defineCurrent(...)
end

function Quadrant:rainfall(...)
end

function Quadrant:wind(...)
end


--The function below moves the data forward by a given number of days. It does the following
-- steps: 1) it integrates the stored "incoming" data from its neighbors; 
-- 2) it gets insolation and warms up the appropriate layers; 3) it radiates excess 
-- temperature out to the system; 3a) it evaporates ground moisture in the process;
-- 4) it adjust temperature, humidity and pressure of the air; 5) it adjusts the cloud
-- layer 6) it defines wind direction based on local pressure and submitted pressure 
-- vector of its neighbors; 6a) if it's a water quadrant, the direction of the surface
-- water current is determined (and reported in output); 7) rainfall ensues; 8) remaining
-- clouds and air transports are reported in output
function Quadrant:update(...)

end

return Quadrant