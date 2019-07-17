--[[
	// File Name: Function.lua
	// Written by: Carlos Verastegui
	// Description: Base class for storing and parsing mathematical functions
--]]

-- External libraries
Stack = require(script.Stack)
Queue = require(script.Queue)

-- Helper function to evaluate RPN expressions
local function evaluateEquation(parsedEquation)
	local evaluationStack = Stack.new()
	
	for _, token in pairs(parsedEquation) do
		
		-- Pushes onto stack if token is a number
		if (tonumber(token) ~= nil) then
			evaluationStack:push(token)
			
		-- Pushes onto stack the token evalutation if token is an operator
		elseif (string.match(token, "^[%+%-%*%/%^%(%)]") ~= nil) then
			local firstOperand = tonumber(evaluationStack:pop())
			local secondOperand = tonumber(evaluationStack:pop())
			
			if (token == "-") then
				evaluationStack:push(secondOperand - firstOperand)
			elseif (token == "+") then
				evaluationStack:push(secondOperand + firstOperand)
			elseif (token == "/") then
				evaluationStack:push(secondOperand / firstOperand)
			elseif (token == "*") then
				evaluationStack:push(secondOperand * firstOperand)
			elseif (token == "^") then
				evaluationStack:push(secondOperand ^ firstOperand)
			end
			
		-- Pushes onto stack the function evaluation if token is a function
		else
			local operand = evaluationStack:pop()
			
			-- Elementary functions
			if (token == "abs") then
				evaluationStack:push(math.abs(operand))
			elseif (token == "sqrt") then	
				evaluationStack:push(math.sqrt(operand))
			
			-- Exponential/logarithmic functions
			elseif (token == "exp") then	
				evaluationStack:push(math.exp(operand))
			elseif (token == "ln") then	
				evaluationStack:push(math.log(operand))
			elseif (token == "log") then	
				evaluationStack:push(math.log10(operand))
				
			-- Trigonometric functions
			elseif (token == "cos") then
				evaluationStack:push(math.cos(operand))
			elseif (token == "csc") then
				evaluationStack:push(1 / math.sin(operand))
			elseif (token == "cot") then
				evaluationStack:push(1 / math.tan(operand))
			elseif (token == "sec") then
				evaluationStack:push(1 / math.cos(operand))
			elseif (token == "sin") then	
				evaluationStack:push(math.sin(operand))
			elseif (token == "tan") then
				evaluationStack:push(math.tan(operand))
				
			-- Inverse trigonometric functions
			elseif (token == "acos") then
				evaluationStack:push(math.acos(operand))
			elseif (token == "asin") then
				evaluationStack:push(math.asin(operand))
			elseif (token == "atan") then
				evaluationStack:push(math.atan(operand))
				
			-- Hyperbolic trigonometric functions
			elseif (token == "cosh") then
				evaluationStack:push(math.cosh(operand))
			elseif (token == "sinh") then	
				evaluationStack:push(math.sinh(operand))
			elseif (token == "tanh") then
				evaluationStack:push(math.tanh(operand))
			end
			
		end
	end
	
	return tonumber(evaluationStack:pop())
end

-- Helper function to convert an expression to RPN
local function parseEquation(tokenizedEquation)
	local precedence = {
		["[a-z]+"] = 5,
		["^"] = 4,
		["*"] = 3,
		["/"] = 3,
		["+"] = 2,
		["-"] = 2
	}
	
	local operatorStack = Stack.new()
	local outputQueue = Queue.new()
	
	for _, token in pairs(tokenizedEquation) do
		
		-- Inserts token into output queue if its a number
		if (tonumber(token) ~= nil) then
			outputQueue:enqueue(token)
			
		-- Inserts token into output queue if its a left parentheses
		elseif (token == "(") then
			operatorStack:push(token)
			
		-- Pops from the stack into output queue until a parentheses pair is found
		elseif (token == ")") then
			while (operatorStack:peek() ~= "(") do
				outputQueue:enqueue(operatorStack:pop())
			end
			
			operatorStack:pop()	
			
		-- Inserts into output queue according to operator precedence
		else
			if (operatorStack:isEmpty()) then
				operatorStack:push(token)
			else
				
				-- Inserts into output queue from the stack until the stack is empty
				while (not operatorStack:isEmpty()) do
					local tokenPrecedence = precedence[token]
					local peekPrecedence = precedence[operatorStack:peek()]
					
					if (peekPrecedence == nil) then
						break
					end
					
					-- If token precedence is greater than peek precedence, the loop is terminated
					if (peekPrecedence > tokenPrecedence) then
						outputQueue:enqueue(operatorStack:pop())	
					elseif ((peekPrecedence == tokenPrecedence) and (token ~= "^")) then
						outputQueue:enqueue(operatorStack:pop())	
					else
						break
					end
				end	
				
				operatorStack:push(token)
			end
		end
	end
		
	-- Inserts into output queue what is left in the stack
	while (not operatorStack:isEmpty()) do
		outputQueue:enqueue(operatorStack:pop())
	end
	
	return outputQueue:toArray()
end

-- Helper function to tokenize an expression
local function tokenizeEquation(func, val)
	local debounce = false
	local tokens = {}

	local equation = func:getExpression()
	local variable = func:getVariable()
    
	local match = string.match
	local len = string.len
    
	local insert = table.insert
	local sub = string.sub

	while (not debounce) do
	
		-- Case #1: token is a number
		if (match(equation, "^[-]?[0-9]*%.?[0-9]*") ~= "") then
			local token = match(equation, "^[-]?[0-9]*%.?[0-9]*")
            
			-- Checks if the first token is a negative number
			if (tonumber(tokens[#tokens]) ~= nil) and (match(equation, "^%-") ~= nil) then
				token = match(equation, "^%-")
				insert(tokens, token)

				if (len(token) == len(equation)) then
					debounce = true
				end
            
				equation = sub(equation, len(token) + 1, len(equation))
			else
				insert(tokens, token)
            
				if (len(token) == len(equation)) then
					debounce = true
				end
            
				equation = sub(equation, len(token) + 1, len(equation))
			end

		-- Case #2: token is an operand
		elseif (match(equation, "^[%+%-%*%/%^%(%)]") ~= nil) then
			local token = match(equation, "^[%+%-%*%/%^%(%)]")
			insert(tokens, token)
            
			if (len(token) == len(equation)) then
				debounce = true
			end
            
			equation = sub(equation, len(token) + 1, len(equation))

		-- Case #3: token is an elementary function
		elseif (match(equation, "^[a-z]+") ~= nil) then
			local token = match(equation, "^[a-z]+")

			-- Checks for special character cases
			if (token == variable) then
				insert(tokens, val)
				
			-- Eulers constant
			elseif (token == "e") then
				if (tokens[#tokens] == "-") then
					tokens[#tokens] = "-2.71828"
				else
					insert(tokens, "2.71828")
				end
				
			-- Math constant Pi
			elseif (token == "pi") then
				insert(tokens, "3.14159")
			else
				insert(tokens, token)
			end
            
			if (len(token) == len(equation)) then
				debounce = true
			end
            
			equation = sub(equation, len(token) + 1, len(equation))

		-- Case #4: token is an invalid character
		else
			assert(false, "Invalid characters in input!")
		end
	end
    
	return tokens
end

-- Function class
mathFunction = {
	
	-- Constructor method for Function
	new = function(expression, variable)
		local newFunction = setmetatable({}, mathFunction)
		
		-- Checks the validity of the expression parameter
		if (expression) then
			if (type(expression) ~= "string") then
				assert(false, "Expression must be a string!")
			end
			
			expression = string.lower(string.gsub(expression, "%s+", ""))
		else
			expression = ""
		end
		
		-- Checks the validity of the variable parameter
		if (variable) then
			if (type(variable) ~= "string") then
				assert(false, "Variable must be a string!")
				
			elseif (string.len(variable) > 1) then
				assert(false, "Variable can't be more than a char long!")
			end
			
			variable = string.lower(variable)
		else
			variable = "x"
		end
		
		newFunction.Expression = expression
		newFunction.Variable = variable
		
		return newFunction
	end,
	
	-- Getter method for the expression
	getExpression = function(self)
		return self.Expression
	end,

	-- Setter method for the expression
	setExpression = function(self, expression)
		
		-- Sanity checking
		if (type(expression) ~= "string") then
			assert(false, "Expression must be a string!")
		end
		
		self.Expression = expression
	end,

	-- Getter method for the variable
	getVariable = function(self)
		return self.Variable
	end,

	-- Setter method for the variable
	setVariable = function(self, variable)
		
		-- Sanity checking
		if (type(variable) ~= "string") then
			assert(false, "Variable must be a string!")
				
		elseif (string.len(variable) > 1) then
			assert(false, "Variable can't be more than a char long!")
		end
		
		self.Expression = string.gsub(self.Expression, self.Variable, variable)
		self.Variable = variable
	end,
	
	-- Returns the type of this object
	getObjectType = function(self)
		return script.Name
	end,
	
	-- Returns the object in string format
	toString = function(self)
		return ("Expression: " .. self.Expression .. "\tVariable: " .. self.Variable)
	end,
	
	-- Computes the function at the specified value
	compute = function(self, value)
		
		-- Sanity checking
		if (self.Expression == "") then
			return assert(false, "Empty expression!")
			
		elseif (type(value) ~= "number") then
			return assert(false, "Value must be a number!")
		end

		-- If the expression is a constant then return the constant
		if (tonumber(self.Expression)) then
			return tonumber(self.Expression)
		end

		-- Safely parse and evaluate the expression
		local returned, data = pcall(function()
			local tokenized = tokenizeEquation(self, tostring(value))
			local parsed = parseEquation(tokenized)
			local evaluated = evaluateEquation(parsed)
		
			return tonumber(evaluated)
		end)
		
		return (returned) and data or assert(false, data)
	end
}

mathFunction.__index = mathFunction

return mathFunction
