--[[
	// File Name: Intercept.lua
	// Written by: Carlos Verastegui
	// Description: Sub-class for finding roots of a function using Brents Method
--]]

-- External inheritence
local Function = require(script.Parent:WaitForChild("Function"))

-- Helper function to compute the secant between two points
local function secantMethod(f, a, b)
	local fa = f:compute(a)
	local fb = f:compute(b)

	return b - (fb * ((b - a) / (fb - fa)))
end

-- Helper function to interpolate quadratic polynomials
local function inverseInterpolation(f, a, b, c)
	local fa = f:compute(a)
	local fb = f:compute(b)
	local fc = f:compute(c)

	return ((a * fb * fc) / ((fa - fb) * (fa - fc))) + 
			((b * fa * fc) / ((fb - fa) * (fb - fc))) +
			((c * fa * fb) / ((fc - fa) * (fc - fb)))
end

-- Helper function to get the root of a function in an interval
local function brentsMethod(f, a, b)
	if (b < a) then
		a, b = b, a
	end
	
	local fa = f:compute(a)
	local fb = f:compute(b)
	
	-- Assume no root exists if both bounds share the same sign
	if (fa * fb >= 0) then
		return assert(false, "No root found!")
	end
	
	local s = 0
	local fs = 0
	
	repeat
		local c = (a + b) / 2
		local fc = f:compute(c)
		
		-- Check to see if its faster to perform inverse interpolation
		if (fa ~= fc) and (fb ~= fc) then
			s = inverseInterpolation(f, a, b, c)
			
			-- Ignore secant if s falls between bounds
			if (a < s) and (s < b) then
				fs = f:compute(s)
			else
				
				-- Perform the secant based on which partition contains the root
				if (not ((fa < 0) == (fc < 0))) then
					s = secantMethod(f, a, c)
					fs = f:compute(s)
				elseif (not ((fc < 0) == (fb < 0))) then
					s = secantMethod(f, c, b)
					fs = f:compute(s)
				end
			end
		else
			
			-- Perform the secant same as above
			if (not ((fa < 0) == (fc < 0))) then
				s = secantMethod(f, a, c)
				fs = f:compute(s)
			elseif (not ((fc < 0) == (fb < 0))) then
				s = secantMethod(f, c, b)
				fs = f:compute(s)
			end
		end
		
		if (c > s) then
			s, c = c, s
			fs, fc = fc, fs
		end
		
		-- Change of variables depending on root location
		if (fc * fs <= 0) then
			a = c
			b = s
		else
			if (fa * fc < 0) then
				b = c
			else
				a = s
			end
		end
		
	-- Stop if exact root is found or if error is negligible
	until (fa == 0) or (fb == 0) or (math.abs(b - a) < 0.0001)
	
	return (fa == 0) and a or b
end

-- Intercept class
Intercept = {
	-- Constructor method for Intercept
	new = function(expression, variable)
		local newIntercept = setmetatable(
			Function.new(expression, variable), Intercept)
		
		return newIntercept
	end,
	
	-- Returns the type of this object
	getObjectType = function(self)
		return script.Name
	end,
	
	-- Returns the root (if found) between the given intervals
	root = function(self, lower, upper)
		
		-- Sanity checking
		if (type(lower) ~= "number") or (type(upper) ~= "number") then
			return assert(false, "Invalid bounds!")
		end
		
		if (self.Expression == "") then
			return assert(false, "Empty expression!")
		end
		
		-- Safely compute the root of a function
		local returned, data = pcall(function()
			return brentsMethod(self, lower, upper)
		end)
		
		return (returned) and data or assert(false, data)
	end
}

Intercept.__index = Intercept
setmetatable(Intercept, Function)

return Intercept
