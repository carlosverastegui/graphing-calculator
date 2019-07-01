Stack = require(script.Stack)
Queue = require(script.Queue)

local function evaluateEquation(parsedEquation)
	local evaluationStack = Stack:new()
	
	for _, token in pairs(parsedEquation) do
		if (tonumber(token) ~= nil) then
			evaluationStack:push(token)
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
		else
			local firstOperand = evaluationStack:pop()
			
			if (token == "abs") then
				evaluationStack:push(math.abs(firstOperand))
			elseif (token == "cos") then
				evaluationStack:push(math.cos(firstOperand))
			elseif (token == "exp") then	
				evaluationStack:push(math.exp(firstOperand))
			elseif (token == "ln") then	
				evaluationStack:push(math.log(firstOperand))
			elseif (token == "log") then	
				evaluationStack:push(math.log10(firstOperand))
			elseif (token == "sin") then	
				evaluationStack:push(math.sin(firstOperand))
			elseif (token == "sqrt") then	
				evaluationStack:push(math.sqrt(firstOperand))
			elseif (token == "tan") then
				evaluationStack:push(math.tan(firstOperand))
			end
		end
	end
	
	return tonumber(evaluationStack:pop())
end

local function parseEquation(tokenizedEquation)
	local precedence = {
		["[a-z]+"] = 5,
		["^"] = 4,
		["*"] = 3,
		["/"] = 3,
		["+"] = 2,
		["-"] = 2
	}
	
	local operatorStack = Stack:new()
	local outputQueue = Queue:new()
	
	for _, token in pairs(tokenizedEquation) do
		if (tonumber(token) ~= nil) then
			outputQueue:enqueue(token)
		elseif (token == "(") then
			operatorStack:push(token)
		elseif (token == ")") then
			while (operatorStack:peek() ~= "(") do
				outputQueue:enqueue(operatorStack:pop())
			end
			
			operatorStack:pop()	
		else
			if (operatorStack:isEmpty()) then
				operatorStack:push(token)
			else
				while (not operatorStack:isEmpty()) do
					local tokenPrecedence = precedence[token]
					local peekPrecedence = precedence[operatorStack:peek()]
					
					if (peekPrecedence == nil) then
						break
					end
					
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
		
	while (not operatorStack:isEmpty()) do
		outputQueue:enqueue(operatorStack:pop())
	end
	
	return outputQueue:toArray()
end

local function tokenizeEquation(equation, val)
    local debounce = false
    local tokens = {}
    
    local match = string.match
    local len = string.len
    
    local insert = table.insert
    local sub = string.sub

    while (not debounce) do
        if (match(equation, "^[-]?[0-9]*%.?[0-9]*") ~= "") then
            local token = match(equation, "^[-]?[0-9]*%.?[0-9]*")
            
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
        elseif (match(equation, "^[%+%-%*%/%^%(%)]") ~= nil) then
            local token = match(equation, "^[%+%-%*%/%^%(%)]")
            insert(tokens, token)
            
            if (len(token) == len(equation)) then
                debounce = true
            end
            
            equation = sub(equation, len(token) + 1, len(equation))
        elseif (match(equation, "^[a-z]+") ~= nil) then
            local token = match(equation, "^[a-z]+")

			if (token == "x") then
				insert(tokens, val)
			elseif (token == "e") then
				if (tokens[#tokens] == "-") then
					tokens[#tokens] = "-2.71828"
				else
					insert(tokens, "2.71828")
				end
			elseif (token == "pi") then
				insert(tokens, "3.14159")
			else
				insert(tokens, token)
			end
            
            if (len(token) == len(equation)) then
                debounce = true
            end
            
            equation = sub(equation, len(token) + 1, len(equation))
        else
			assert(false, "Invalid characters in input!")
        end
    end
    
    return tokens
end

Parser = {
	new = function(expression, variable)
		local newParser = setmetatable({}, Parser)
		
		newParser.Expression = (expression == nil) and "" or tostring(expression)
		newParser.Variable = (variable == nil) and "x" or tostring(variable)

		return newParser
	end,

	getExpression = function(self)
		return self.Expression
	end,

	setExpression = function(self, expression)
		self.Expression = tostring(expression)
	end,

	getVariable = function(self)
		return self.Variable
	end,

	setVariable = function(self, variable)
		self.Expression = string.gsub(self.Expression, self.Variable, tostring(variable))
		self.Variable = tostring(variable)
	end,
	
	parse = function(self, value)
		if (self.Expression == "") then
			return assert(false, "Attempting to parse empty expression!")
		elseif (type(value) ~= "number") then
			return assert(false, "Expected number for value, got " .. type(value) .. "!")
		end

		if (tonumber(self.Expression)) then
			return tonumber(self.Expression)
		end

		local value = tostring(value)
		local equation = string.lower(string.gsub(self.Expression, "%s+", ""))
	
		local returned, data = pcall(function()
			local tokenized = tokenizeEquation(equation, value)
			local parsed = parseEquation(tokenized)
			local evaluated = evaluateEquation(parsed)
		
			return tonumber(evaluated)
		end)
		
		return data
	end,
	
	toString = function(self)
		return ("Expression: " .. self.Expression .. "\tVariable: " .. self.Variable)
	end
}

Parser.__index = Parser

return Parser
