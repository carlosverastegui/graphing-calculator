--[[
	// File Name: Derivative
	// Written by: Carlos Verastegui
	// Description: Sub-class for calculating numerical derivatives using the difference quotient
--]]

-- External inheritence
local Function = require(script.Parent:WaitForChild("Function"))

-- Helper function to initialize multi-dimensional arrays
local function createMultidimensionalArray()
	local arr = { }
	
	for row = 1, 10 do
		arr[row] = {}
		
		for col = 1, 10 do
			arr[row][col] = 0
		end
	end
	
	return arr
end

-- Helper function to compute the numerical derivative of a function
local function differenceQuotient(func, var)
	local err = 1e30
	local errTolerance = 0
	
	local step = 2
	local answer = 0
	
	local tableau = createMultidimensionalArray()
	tableau[1][1] = ((func:compute(var + step) - func:compute(var - step)) / (2 * step))
	
	for col = 2, 10 do
		local fac = 1.96
		
		step = step / 1.4
		tableau[1][col] = ((func:compute(var + step) - func:compute(var - step)) / (2 * step))
		
		for row = 2, col do
			tableau[row][col] = (fac*tableau[row - 1][col] - tableau[row - 1][col - 1]) / (fac - 1)
			
			fac = fac * 1.96
			errTolerance = math.max(tableau[row][col] - tableau[row - 1][col], 
				math.abs(tableau[row][col] - tableau[row - 1][col - 1]))
			
			if (errTolerance <= err) then
				err = errTolerance
				answer = tableau[row][col]
			end
		end
		
		if (math.abs(tableau[col][col] - tableau[col - 1][col - 1]) >= 2*err) then
			break
		end
	end
	
	return answer
end

-- Derivative class
Derivative = {
	-- Constructor method for Derivative
	new = function(expression, variable)
		local newDerivative = setmetatable(
			Function.new(expression, variable), Derivative)
		
		return newDerivative
	end,
	
	-- Returns the type of this object
	getObjectType = function(self)
		return script.Name
	end,
	
	-- Returns the numerical derivative at the specified point
	differentiate = function(self, abscissa)
		if (type(abscissa) ~= "number") then
			return assert(false, "X-value must be a number!")
		end
		
		if (self.Expression == "") then
			return assert(false, "Empty expression!")
		end
		
		local returned, data = pcall(function()
			return differenceQuotient(self, abscissa)
		end)
		
		return (returned) and data or assert(false, data)
	end,
	
	-- Returns the equation of the tangent line
	tangentLine = function(self, abscissa, derivative)
		if (type(derivative) ~= "number") then 
			return assert(false, "Derivative must be a number!")
		end
			
		if (type(abscissa) ~= "number") then
			return assert(false, "X-value must be a number!")
		end
		
		if (self.Expression == "") then
			return assert(false, "Empty expression!")
		end
		
		local returned, data = pcall(function()
			local yIntercept = -(derivative * abscissa) + self:compute(abscissa)
			return tostring(derivative) .. "*" .. self.Variable .. "+" .. tostring(yIntercept)
		end)
		
		return (returned) and data or assert(false, data)
	end
}

Derivative.__index = Derivative
setmetatable(Derivative, Function)

return Derivative
