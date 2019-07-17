--[[
	// File Name: Integral.lua
	// Written by: Carlos Verastegui
	// Description: Sub-class for computing the definite integral using Gauss-Legendre quadrature
--]]

-- External inheritence
local Function = require(script.Parent:WaitForChild("Function"))

-- Array containing roots for a 10-point quadrature
local roots = {
	0.1488743389816312,
	0.4333953941292472,
	0.6794095682990244,
	0.8650633666889845,
	0.9739065285171717
}

-- Array containing weights for a 10-point quadrature
local weights = {
	0.2955242247147529,
	0.2692667193099963, 
	0.2190863625159820,
	0.1494513491505806,
	0.0666713443086881
}

-- Helper function to compute the definite integral
local function gaussLegendre(func, lower, upper)
	local midvalue = (upper - lower) / 2
	local midpoint = (upper + lower) / 2
	
	local sum = 0
	
	for index = 1, 5 do
		local dx = midvalue * roots[index]
		
		sum = sum + weights[index] 
			* (func:compute(midpoint + dx) + func:compute(midpoint - dx))
	end
	
	return midvalue * sum
end

-- Integral class
Integral = {
	-- Constructor method for Integral
	new = function(expression, variable)
		local newIntegral = setmetatable(
			Function.new(expression, variable), Integral)
		
		return newIntegral
	end,
	
	-- Returns the type of this object
	getObjectType = function(self)
		return script.Name
	end,
	
	-- Returns the definite integral at the specified interval
	integrate = function(self, lower, upper)
		
		-- Sanity checking
		if (type(lower) ~= "number") or (type(upper) ~= "number") then
			return assert(false, "Invalid bounds!")
		end
		
		if (lower >= upper) then
			return assert(false, "Lower bound larger than upper!")
		end
		
		if (self.Expression == "") then
			return assert(false, "Empty expression!")
		end
		
		-- Safely compute the definite integral
		local returned, data = pcall(function()
			return gaussLegendre(self, lower, upper)
		end)
		
		return (returned) and data or assert(false, data)
	end
}

Integral.__index = Integral
setmetatable(Integral, Function)

return Integral
