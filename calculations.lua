--http://www.quora.com/How-can-you-calculate-the-length-of-the-day-on-Earth-at-a-given-latitude-on-a-given-date-of-the-year
--cos h = – tan φ · tan δ where h = "hour angle", φ = latitude
--day length = 2h/(planet rotation in degrees per hour) -- for Earth, this is 2h/15
--for the polar region, day length is either 0 or 24 hours - not this formula
--insolation = sin(angle of incidence of sun rays) * day length ? approximation

--https://en.wikipedia.org/wiki/Lapse_rate
--From 11 km up to 20 km (65,620 ft or 12.4 mi), the constant temperature is −56.5 °C (−69.7 °F), which is the lowest assumed temperature in the ISA.

-- Local functions and constants --

local sin = math.sin
local cos = math.cos
local tan = math.tan
local asin = math.asin
local acos = math.acos
local pi = math.pi
local rad = math.rad
local deg = math.deg
local exp = math.exp

--Solar constant
local SC =  1360.8 -- W/m^2 or 0.08165 MJ/m^2

--Kelvin to Celsius
local K2C = 272.15

--Stefan-Bolzman Constant
local SBC = 5.67 * 10^-8 -- W/(m^2*K^4)

--standard albedo
local stdAlbedo = 0.3 -- mean Earth's albedo

--standard greenhouse coefficient
local stdGreenhouse = 0.4355 -- guestimate in line with Earth's values

--Environmental Lapse Rate
--(change of temperature with altitude)
local ELR = 6.49 -- C/km

--(change of temperature with altitude for contiguous air masses)
--Dry Adiabatic Lapse Rate
local DALR = 9.8 -- C/km
--Saturated Adiabatic Lapse Rate
local SALR = 5 -- C/km

--The below is an approximation taken from here:
--https://en.wikipedia.org/wiki/Dew_point
local function dewPoint (T, RH)
	--T - temperature
	--RH - relative humidity (0-100%)
	return T - (100-RH)/5
end

--The below calculates the relative humidity based on temperature and the dew point:
local function RH(T, Tdp)
	return 100 - (T-Tdp)
end


--δ=-arcsin(sin(-axial_tilt)*cos(360deg/year_length_in_days * days_from_winter_solstice 
--   + 360deg/pi * orbit_eccentricity * sin(360deg/year_length_in_days * days_from_perihelion)))
--http://en.wikipedia.org/wiki/Position_of_the_Sun

local function solarDeclination(tilt, daysinyear, daysfromwintersolstice, eccentricity, daysfromperihelion)
	return asin(sin(-rad(tilt))*cos(rad(360/daysinyear * daysfromwintersolstice + 360/pi * eccentricity * sin(rad(360/daysinyear * daysfromperihelion)))))
end

local function cosHourAngleOfSunrise(day, latitude, declinationfunction)
	return tan(declinationfunction(day)) * -tan(rad(latitude))
end

-- To be exported --

local Calc = {}

--https://en.wikipedia.org/wiki/Heat_capacity#Extensive_and_intensive_quantities
--I am taking aproximate values - enough for my needs.
Calc.HeatCapacity = {
	air = 1,
	soil = 0.8,
	water = 4.18,
}

-- Albedo and absorption
--http://www.physicalgeography.net/fundamentals/7f.html
--values from: http://en.wikipedia.org/wiki/Albedo
--and from: https://corona-renderer.com/forum/index.php?topic=2359.0
Calc.albedoTable = { 
	atmosphericAlbedo = 0.26,
	atmosphericAbsorption = 0.19,
--these values possibly need a rework - not sure if they include atmospheric albedo...:
	desert				= 0.4, -- 0.35-0.45
	wetSoil				= 0.05,
	bareSoil			= 0.17,
	deciduousForest		= 0.15,
	coniferousForest	= 0.1,
	grassland			= 0.25,
	oceanIce			= 0.6,
	glacierIce			= 0.4,
	freshSnow			= 0.85,
	oldSnow				= 0.6,
	water				= 0.05,
	tundra				= 0.2,
	default				= 0.1,
}
--Cloud albedo can range from 0.1 to 0.9 and needs to be calculated separately:
--http://en.wikipedia.org/wiki/Cloud_albedo
--It also reflects energy radiated by the Earth back to it - greenhouse effect
--http://en.wikipedia.org/wiki/Greenhouse_effect
Calc.baseGreenhouse = 0.25 --this is w/o water vapor
--for water vapor, I will need to write a function based on humidity
--for now, this will do
Calc.cloudGreenhouse = 2 * stdGreenhouse - Calc.baseGreenhouse


function Calc.getDeclinationFunction(tilt, daysinyear, daysfromwintersolstice, eccentricity, daysfromperihelion)
-- daysfromwintersolstice and daysfromperihelion should be for the first day of the year here
-- defaults for Earth:
	local tilt = tilt or 23.44
	local daysinyear = daysinyear or 365.24
	local daysfromwintersolstice = daysfromwintersolstice or 10
	local eccentricity = eccentricity or 0.0167
	local daysfromperihelion = daysfromperihelion or -2
	return function(day)
		return solarDeclination(tilt, daysinyear, day+daysfromwintersolstice, eccentricity, day+daysfromperihelion)
	end
end

function Calc.dayPercentage(day, latitude, declinationfunction)
	local cosh0 = cosHourAngleOfSunrise(day, latitude, declinationfunction)
	if -cosh0 > 1 then
		return 1
	elseif -cosh0 < -1 then
		return 0
	else 
		return 1 - acos(cosh0)/pi
	end
end

function Calc.dayLength(day, latitude, declinationfunction, nychthemeron)
	nychthemeron = nychthemeron or 24
	return nychthemeron * Calc.dayPercentage(day, latitude, declinationfunction)
end


--http://education.gsfc.nasa.gov/experimental/July61999siteupdate/inv99Project.Site/Pages/solar.insolation.html
--Need to take into account: distance from star (<eccentricity), day length, latitude, clouds
--and terrain! -> albedo, heat absorption - but this maybe not here
--http://en.wikipedia.org/wiki/Solar_zenith_angle
--Solar elevation angle is the angle between the horizon and the centre of the sun's disc.
--Formula:
--sin(solar_elevation_angle) = cos(hour_angle)*cos(declination)*cos(latitude) + sin(declination)*sin(latitude)
--Formula for solar insolation throughout a 24 hour period (excluding atmosphere) is:
--Q=solarconstant/pi*meandistancetosun^2/actualdistancetosun^2*(hourangleofsunrise*sin(latitude)*sin(declination)+cos(latitude)*cos(declination)*sin(hourangleofsunrise))
-- 
--Atmosphere absorbs 30-70% of insolation
--see also: http://www.conversion-website.com/energy/from-Celsius-heat-unit-IT.html

function Calc.getBaseDailyInsolation(day, latitude, meandistancetosun, declinationfunction, orbitfunction, solarconstant)
	local actualdistancetosun = (orbitfunction and orbitfunction(day)) or 1
	local cosh0 = cosHourAngleOfSunrise(day, latitude, declinationfunction)
	local h0
	if cosh0 > 1 then
		return 0
	elseif cosh0 < -1 then
		h0 = pi
	else h0 = acos(cosh0)
	end
	local declination = declinationfunction(day)
	local solarconstant = (solarconstant or SC) / pi
	return solarconstant*meandistancetosun^2/actualdistancetosun^2*(h0*sin(rad(latitude))*sin(declination)+cos(rad(latitude))*cos(declination)*sin(h0))
end

function Calc.addGreenhouse(temperature, greenhouse, albedo)
	local greenhouse = greenhouse or stdGreenhouse
	local albedo = albedo or stdAlbedo
	return temperature * (1 -albedo +greenhouse)^0.25
end

function Calc.irradiationToTemp(irradiation)
	--based on http://motls.blogspot.com/2008/05/average-temperature-vs-average.html
	return (irradiation/SBC)^0.25
end

function Calc.irradiationToAtmosphericTemp(irradiation, greenhouse,albedo)
	return Calc.addGreenhouse(Calc.irradiationToTemp(irradiation), greenhouse, albedo)
end

function Calc.tempToIrradiation(temperature)
	--based on http://motls.blogspot.com/2008/05/average-temperature-vs-average.html
	return SBC*(temperature)^4
end

function Calc.atmosphericTempToIrradiation (temperature, greenhouse, albedo)
		local greenhouse = greenhouse or stdGreenhouse
		local albedo = albedo or stdAlbedo
		local T0 = temperature / (1 -albedo +greenhouse)^0.25
		return Calc.tempToIrradiation(T0)
end

--The below function bases on Stefan's law, and calculates the mean temperature of the planet.
--The assumption is that there is only one star.
--http://en.wikipedia.org/wiki/Stefan–Boltzmann_law
function Calc.basePlanetTemp(starradius, startemperature, distancetostar)
	--distancetostar in AU
	local starradius = starradius or 696 -- x10^6 m = Sun
	local distancetostar = (distancetostar or 1) * 149598 -- x10^6 m = Earth to Sun
	local startemperature = startemperature or 5780 -- K = Sun
	return startemperature * math.sqrt(starradius/(2*distancetostar))
end

function Calc.realPlanetTemp(starradius, startemperature, distancetostar, greenhouse, albedo)
	--distancetostar in AU
	--first, let's calculate temperature if planet perfectly absorbed irradiation
	local T0 = Calc.basePlanetTemp(starradius, startemperature, distancetostar)
	--second, we need to calculate the "real" temperature, taking into account the planet's
	--albedo and greenhouse effect
	return Calc.addGreenhouse(T0, greenhouse, albedo)
end

function Calc.getBasePressure(altitude)
	--g - gravitational constant
	local g = g or 9.80665
	--M - molar mass of air
	local M = 0.0289644
	--R - universal gas constant
	local R = 8.31447
	--T0 - sea level standard temperature in K (=15C)
	local T0 = 288.15 
	--p0 - sea level standard atmospheric pressure in Pa (1013.25 hPa)
--	local p0 = 101325
--	return p0 * exp(-g*M*altitude/R/T0) -> commented out as I am actually only interested in the ratio to standard pressure.

	return exp(-g*M*altitude/R/T0)
end

--This function gives the net difference between the insolation reflected by the clouds
--and the heat reflected back to the Earth. It is a very rough guestimate for now.
function Calc.addCloudGreenhouse(irradiance, clouds)
	return irradiance * (1 + Calc.baseGreenhouse + clouds * Calc.cloudGreenhouse)
end

function Calc.newTemp(currenttemp, addedtemp, heatcapacity)
	return (currenttemp * heatcapacity + addedtemp)/(heatcapacity + 1)
end

function Calc.toCelsius(temp)
	return temp - K2C
end

function Calc.toKelvin(temp)
	return temp + K2C
end

-- DEBUG FUNCTION

function Calc.init()
	e= Calc.getDeclinationFunction()
	o=function () return 1 end
	for k, day in pairs{-10,81,172, 263} do
		print("DAY: ", day)
		for i=-90,90, 10 do
			local j = Calc.getBaseDailyInsolation(day,i,1,e)
			print(j, "-->", Calc.irradiationToTemp(j), "-->", Calc.irradiationToAtmosphericTemp(j))
			print("latitude: ", i)
		end
		print("-------------")
	end
end

return Calc