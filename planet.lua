local class = require "middleclass"

local initTemp = 20

local Planet = class("Planet")

function Planet:initialize(daylength, yearlength, climateslices, diameter, rotationspeed, axialtilt, insolationpattern, albedos, 
		altitudetemperaturecoefficient, altitudepressurecoefficient, seacurrentimpact, map)
	self.dayLength = daylength
	self.yearLength = yearlength
	self.day = 1
	self.diameter = diameter
	self.rotationSpeed = rotationspeed
	self.axialTilt = axialtilt
	self.insolationPattern = insolationpattern
	self.albedos = albedos
	self.altTempCoef = altitudetemperaturecoefficient
	self.altPressCoef = altitudepressurecoefficient
	self.seaCurrentCoef = seacurrentimpact
	self.map = map
	self.width = #map
	self.height = #map[1]
	
end

function Planet:getInsolation(day)

end

function Planet:getCurrentInsolation()
	return self:getInsolation(self.day)
end

function Planet:resetTemperatures()
	self.temperature = {}
	for c=1, climateslices do
		self.temperature[c] = {}
		for x=0, self.width do
			self.temperature[c][x] = {}
			for y=0, self.height do
				self.temperature[c][x][y] = initTemp
				-- tu trzeba wziąć insolację, dodać wysokości i ustawić początkowe wartości
			end
		end
	end
end

return Planet		
		