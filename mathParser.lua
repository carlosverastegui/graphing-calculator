Stack = require(script.StackDataStructure)
Queue = require(script.QueueDataStructure)

local function evaluateExpression(parsedExpression)
	local evaluationStack = Stack:new()
	
	for _, token in pairs(parsedExpression) do
		if (tonumber(token) ~= nil) then
			evaluationStack:push(token)
		elseif (string.match(token, "^[%+%-%*%/%^%(%)]") ~= nil) then
			local firstOperand = evaluationStack:pop()
			local secondOperand = evaluationStack:pop()
			
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

local function parseExpression(tokenizedExpression)
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
	
	for _, token in pairs(tokenizedExpression) do
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
	
	return evaluateExpression(outputQueue:toArray())
end

local function tokenizeExpression(expression)
    local target = string.lower(string.gsub(expression, "%s+", ""))
    
    local debounce = false
    local tokens = {}
    
    local match = string.match
    local len = string.len
    
    local insert = table.insert
    local sub = string.sub

    while (not debounce) do
        if (match(target, "^[-]?[0-9]*%.?[0-9]*") ~= "") then
            local token = match(target, "^[-]?[0-9]*%.?[0-9]*")
            
            if (tonumber(tokens[#tokens]) ~= nil) and (match(target, "^%-") ~= nil) then
               token = match(target, "^%-")
               insert(tokens, token)
                
               if (len(token) == len(target)) then
                   debounce = true
               end
            
               target = sub(target, len(token) + 1, len(target))
            else
               insert(tokens, token)
            
               if (len(token) == len(target)) then
                   debounce = true
               end
            
               target = sub(target, len(token) + 1, len(target))
            end
        elseif (match(target, "^[%+%-%*%/%^%(%)]") ~= nil) then
            local token = match(target, "^[%+%-%*%/%^%(%)]")
            insert(tokens, token)
            
            if (len(token) == len(target)) then
                debounce = true
            end
            
            target = sub(target, len(token) + 1, len(target))
        elseif (match(target, "^[a-z]+") ~= nil) then
            local token = match(target, "^[a-z]+")
            insert(tokens, token)
            
            if (len(token) == len(target)) then
                debounce = true
            end
            
            target = sub(target, len(token) + 1, len(target))
        else
			script.Parent.ErrorOccured:Fire("Invalid character in the input!")
			return false
        end
    end
    
    return parseExpression(tokens)
end

Parser = {
	new = function()
		return setmetatable({}, Parser)
	end,
	
	parse = function(self, expression)
		return tokenizeExpression(expression)
	end
}

Parser.__index = Parser

return Parser

