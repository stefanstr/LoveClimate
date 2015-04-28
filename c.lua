local Calc = {}

--Stefan-Bolzman Constant
Calc.SBC = 5.67 * 10^-8 -- W/(m^2*K^4)

--Kelvin to Celsius
Calc.K2C = 272.15

--Heat capacity of various mediums
Calc.HC = {
	air = 1,
	soil = 0.8,
	water = 4.18,
}

--Convert incoming irradiation to temperature
function Calc.irradToTemp(irradiation)
	--based on http://motls.blogspot.com/2008/05/average-temperature-vs-average.html
	return (irradiation/Calc.SBC)^0.25
end

--Convert temperature to outgoing radiation
function Calc.tempToIrrad(temperature)
	--based on http://motls.blogspot.com/2008/05/average-temperature-vs-average.html
	return Calc.SBC*(temperature)^4
end

--Heat stuff up with incoming irradiation
function Calc.newTemp(temp, irradiation, hc1, hc2) -- hc = heat capacity
	local current = Calc.tempToIrrad(temp)
	local added = irradiation
	return Calc.irradToTemp((current * hc1 + added * hc2)/(hc1 + hc2))
end

--Get pressure difference to determine wind strength
function Calc.getWind(pressure1, pressure2)
	return pressure2-pressure1
end

--Adjust vector for Coriolis force
function Calc.addCoriolis(vector, latitude)
	--This is a rather primitive calculation: giving a 90deg turn
	local y = vector.x
	local x = vector.y
	local sign =(latitude < 0 and -1) or 1
	return {x=x*sign, y=y*-1}
end

--Adjust vector for Ekman spiral
--For now, this is equal to Coriolis, but shoud be adjusted.
function Calc.addEkman(vector, latitude)
	--This is a rather primitive calculation: giving a 90deg turn
	local y = vector.x
	local x = vector.y
	local sign =(latitude < 0 and -1) or 1
	return {x=x*sign, y=y*-1}
end

function Calc.toCelsius(temp)
	return temp - Calc.K2C
end

return Calc