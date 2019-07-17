--[[
	// File Name: Optimize.lua
	// Written by: Carlos Verastegui
	// Description: Sub-class for calculating local extremas using Brents Method
--]]

-- External inheritence
local Function = require(script.Parent:WaitForChild("Function"))

-- Helper function to find the machine epsilon
local function machEps()
	local epsilon = 1
	
	while (1 + (.5 * epsilon) ~= 1) do
		epsilon = epsilon * .5
	end
	
	return epsilon
end

-- Helper function to find the best of two points
local function bestPair(a, b, isMinimum)
	if (a == nil) then
		return b
	end
	
	if (b == nil) then
		return a
	end
	
	if (isMinimum) then
		return (a[2] <= b[2]) and a or b
	else
		return (a[2] >= b[2]) and a or b
	end
end

-- Helper function to find the local extrema of a function
local function brentsMethod(func, a, b)
	local goldenSection = .5 * (3 - math.sqrt(5))
	local isMinimum = func:isMinimum()
	
	if (b < a) then
		a, b = b, a
	end
	
	local x = a + (goldenSection * (b - a))
	local v = x
	local w = x
	
	local d = 0
	local e = 0
	
	local fx = func:compute(x)
	if (not isMinimum) then
		fx = -fx
	end
	
	local fv = fx
	local fw = fx
	
	local previous = nil
	local current = {
		x,
		(isMinimum and fx or -fx)
	}
	local best = current
	
	local absTol = 0.0001
	local relTol = ((2 * machEps() + math.sqrt(machEps())) / 2)
	
	while (true) do
		local m = .5 * (a + b)
		
		local tol = relTol * math.abs(x) + absTol
		local tol2 = 2 * tol
		
		-- Default stopping criterion
		if (math.abs(x - m) > tol2 - .5 * (b - a)) then
			local p, q, r, u = 0
			
			-- Fit the parabola
			if math.abs(e) > tol then
				r = (x - w) * (fx - fv)
				q = (x - v) * (fx - fw)
				p = (x - v) * q - (x - w) * r
				q = 2 * (q - r)
				
				if (q < 0) then
					p = -p
				else
					q = -q
				end
				
				r = e
				e = d
				
				-- Perform the parabolic interpolation step
				if (p > q * (a - x) and p < q * (b - x) and math.abs(p) < math.abs(0.5 * q * r)) then
					d = p / q
					u = x + d
					
					-- The function must not be evaluated too close to a or b
					if (u - a < tol2) or (b - u < tol2) then
						if (x <= m) then
							d = tol
						else
							d = -tol
						end
					end
				else
					
					-- Perform the golden section step
					if (x < m) then
						e = b - x
					else
						e = a - x
					end
					
					d = goldenSection * e
				end
			else
				
				-- Perform the golden section step
				if (x < m) then
					e = b - x
				else
					e = a - x
				end
				
				d = goldenSection * e
			end
			
			-- Update by at least tol1
			if (math.abs(d) < tol) then
				if (d >= 0) then
					u = x + tol
				else
					u = x - tol
				end
			else
				u = x + d
			end
			
			local fu = func:compute(u)
			if (not isMinimum) then
				fu = -fu
			end
			
			previous = current
			current = {
				u,
				(isMinimum and fu or -fu)
			}
			best = bestPair(best, bestPair(previous, current, isMinimum), isMinimum)
			
			-- Update a, b, v, w, and x
			if (fu <= fx) then
				if (u < x) then
					b = x
				else
					a = x
				end
				
				v = w
				fv = fw
				
				w = x
				fw = fx
				
				x = u
				fx = fu
			else
				if (u < x) then
					a = u
				else
					b = u
				end
				
				if (fu <= fw) or (w == x) then
					v = w
					fv = fw
					
					w = u
					fw = fu
				elseif (fu <= fv) or (v == x) or (v == w) then
					v = u
					fv = fu
				end
			end
			
		-- Default to Brents termination conditions
		else
			return bestPair(best, bestPair(previous, current, isMinimum), isMinimum)[1]
		end
	end
end

-- Optimize class
Optimize = {
	-- Constructor method for Derivative
	new = function(expression, minimum, variable)
		local newOptimize = setmetatable(
			Function.new(expression, variable), Optimize)
		
		newOptimize.Minimum = minimum
		
		return newOptimize
	end,
	
	-- Returns which extrema the optimizer is finding
	isMinimum = function(self)
		return self.Minimum
	end,
	
	-- Sets which extrema to find
	setMinimum = function(self, minimum)
		self.Minimum = minimum
	end,
	
	-- Returns the type of this object
	getObjectType = function(self)
		return script.Name
	end,
	
	-- Calculates the local extrema
	findExtrema = function(self, lower, upper)
		
		-- Sanity checking
		if (type(lower) ~= "number") or (type(upper) ~= "number") then
			return assert(false, "Invalid bounds!")
		end
		
		if (self.Expression == "") then
			return assert(false, "Empty expression!")
		end
		
		-- Safely compute the local extrema
		local returned, data = pcall(function()
			return brentsMethod(self, lower, upper)
		end)
		
		return (returned) and data or assert(false, data)
	end
}

Optimize.__index = Optimize
setmetatable(Optimize, Function)

return Optimize
