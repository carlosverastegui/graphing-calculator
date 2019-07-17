--[[
	// File Name: CalculatorCore.lua
	// Written by: Carlos Verastegui
	// Description: Main script that handles all calculator events
--]]

-----------------------------
--| Local Constants Begin |--
-----------------------------
local BACKGROUND = script.Parent:WaitForChild("Background")
local FUNCTION_MODULE = require(script.Function)

local INTERCEPT_MODULE = require(script.Intercept)
local OPTIMIZE_MODULE = require(script.Optimize)

local DERIVATIVE_MODULE = require(script.Derivative)
local INTEGRAL_MODULE = require(script.Integral)

local GRAPH_FRAME = BACKGROUND.GraphFrame
local INPUT_FRAME = BACKGROUND.InputFrame

local APPLICATION_FRAME = BACKGROUND.ApplicationFrame
local INTERACTABLE_FOLDER = INPUT_FRAME.Interactable

local ENTER_BUTTON = INTERACTABLE_FOLDER.EnterButton
local FUNCTION_INPUT = INTERACTABLE_FOLDER.FunctionInput

local INFORMATION_TEXT = GRAPH_FRAME.Value
local APPLICATION_PROMPTS = APPLICATION_FRAME.Prompts

local APPLICATION_BUTTONS = APPLICATION_FRAME.Buttons
local INTERCEPT_BUTTON = APPLICATION_BUTTONS.Intercept

local MINIMUM_BUTTON = APPLICATION_BUTTONS.Minimum
local MAXIMUM_BUTTON = APPLICATION_BUTTONS.Maximum

local DERIVATIVE_BUTTON = APPLICATION_BUTTONS.Derivative
local INTEGRAL_BUTTON = APPLICATION_BUTTONS.Integral
-----------------------------
---| Local Constants End |---
-----------------------------

-----------------------------
--| Local Variables Begin |--
-----------------------------
local connections = {}
local formula = ""

local node = Instance.new("Frame") do
	node.Size = UDim2.new(0, 1, 0, 1)
	node.Name = "Node"
	node.BackgroundColor3 = Color3.new(0, 0, 0)
	node.BorderSizePixel = 0
	node.AnchorPoint = Vector2.new(0.5, 0.5)
	
end

local edge = Instance.new("Frame") do
	edge.Name = "Edge"
	edge.BorderSizePixel = 0
	edge.AnchorPoint = Vector2.new(0.5, 0.5)
end

local shader = Instance.new("Frame") do
	shader.Name = "Shader"
	shader.BorderSizePixel = 0
	shader.BackgroundTransparency = 0.25
	shader.BackgroundColor3 = Color3.new(1, 0, 0)
end

local point = Instance.new("ImageLabel") do
	point.Name = "Point"
	point.AnchorPoint = Vector2.new(0.5, 0.5)
	point.BackgroundTransparency = 1
	point.Size = UDim2.new(0, 10, 0, 10)
	point.Image = "rbxassetid://142700369"
	point.ZIndex = 2
end
-----------------------------
---| Local Variables End |---
-----------------------------

-----------------------------
--| Local Functions Begin |--
-----------------------------
local function removeAllDescendants(...)
	local parents = {...}
	
	for _, child in pairs(parents) do
		for _, descendant in pairs(child:GetChildren()) do
			descendant:Destroy()
		end
	end
end

local function resetApplications(command)
	if (command) and (type(command) == "boolean") then
		for _, child in pairs(APPLICATION_PROMPTS:GetChildren()) do
			child.Visible = false
		end
		
		for _, connection in pairs(connections) do
			connection:disconnect()
		end
	else
		for _, child in pairs(APPLICATION_PROMPTS:GetChildren()) do
			if (child.Name == command) then
				if (child.Visible == true) then
					child.Visible = false
					return false
				end
				
				child.Visible = true
			elseif (child.Visible) then
				child.Visible = false
			end
		end
	end
	
	return true
end

local function resetGraph(resetValue)
	local DRAWING_FOLDER = GRAPH_FRAME.Drawing
	
	for _, child in pairs(DRAWING_FOLDER:GetChildren()) do
		removeAllDescendants(child)
	end
	
	if (resetValue) then
		INFORMATION_TEXT.Text = ""
	end
	
	APPLICATION_FRAME.Visible = false
	
	resetApplications(true)
end

local function displayError(message, ...)
	local easingBack = Enum.EasingStyle.Back
	local easingIn = Enum.EasingDirection.In
	
	local info = TweenInfo.new(0.5, easingBack, easingIn)
	local goal = {Transparency = 1}
	
	local inputBoxes = {...}
	
	for _, child in pairs(inputBoxes) do
		local errorFrame = child:FindFirstChild("ErrorFrame")
		if (not errorFrame) then
			error("FATAL: Missing ErrorFrame!")
		end
	
		local tween = game:GetService("TweenService")
		local transparencyTween = tween:Create(errorFrame, info, goal)
	
		do
			transparencyTween:Play()
			errorFrame.Visible = true
			child.Text = ""
		end
	
		delay(0.5, function()
			errorFrame.Visible = false
			errorFrame.Transparency = 0.3
		end)
	end
	
	local _, position = message:find(".*:")
	INFORMATION_TEXT.Text = "Error" .. message:sub(position, #message)
	
	return false
end

local function connectNodes(firstNode, secondNode, reference, isApplication)
	--Position
	local firstPosition = firstNode.Position
	local secondPosition = secondNode.Position
	
	local firstX = firstNode.Position.X.Scale
	local secondX = secondNode.Position.X.Scale
	
	local firstY = firstNode.Position.Y.Scale
	local secondY = secondNode.Position.Y.Scale
	
	local newX = (firstX + secondX) / 2
	local newY = (firstY + secondY) / 2
	
	local newPosition = Vector2.new(newX, newY)
	
	--Size
	local firstNodeCoordinates = Vector2.new(firstX, firstY)
	local secondNodeCoordinates = Vector2.new(secondX, secondY)
	
	local newSize = (firstNodeCoordinates - secondNodeCoordinates).Magnitude
	
	if (newSize > 0.5) then
		return nil
	end
	
	--Rotation
	local displacement = secondNode.AbsolutePosition - firstNode.AbsolutePosition
   	local rotation = math.atan2(displacement.Y , displacement.X)
	
	local newEdge = edge:Clone()
	newEdge.ZIndex = isApplication and 1 or 2
	
	newEdge.Position = UDim2.new(newPosition.X, 0, newPosition.Y, 0)
	newEdge.BackgroundColor3 = isApplication and Color3.new(0.3, 0.3, 0.3) or Color3.new(0, 0, 0)
	
	newEdge.BackgroundTransparency = isApplication and .25 or 0
	newEdge.Size = UDim2.new(newSize, 0, 0, 2)
	
	newEdge.Rotation = math.deg(rotation)
	newEdge.Parent = reference
end

local function createEdges(container, storage, isApplication)
	for index = 1, #storage - 1 do
		connectNodes(storage[index], storage[index + 1], container, isApplication)
	end
	
	return true
end

local function createNodes(expression, amount, container)
	local abscissa = 0
	
	for index = 0, math.ceil(amount / 1) do
		local x = ((20 / math.ceil(amount / 1)) * index) - 10
		
		local f = FUNCTION_MODULE.new(expression)
		local y = 0
		
		local returned, data = pcall(function()
			return f:compute(x)
		end)
		
		if (returned) then
			if (tonumber(data) == nil) then
				return displayError(data, FUNCTION_INPUT)
			end
			
			y = tonumber(data)
		else
			return displayError(data, FUNCTION_INPUT)
		end
		
		local scaledX = (abscissa / amount)
		local scaledY = ((.05 * math.clamp(y, -10.1, 10.1)) + .5)
		
		local pointNode = node:Clone()
		pointNode.Position = UDim2.new(scaledX, 0, 1 - scaledY, 0)
		pointNode.Parent = container
		
		abscissa = abscissa + 1
	end
	
	return true
end

local function shadeUnderFunction(lower, upper)
	local scaledLower = ((.05 * lower) + .5)
	local scaledUpper = ((.05 * upper) + .5)
	
	local distance = scaledUpper - scaledLower
	local trueDistance = distance * GRAPH_FRAME.AbsoluteSize.X
	
	local abscissa = 0
	
	for index = 1, trueDistance do
		local f = FUNCTION_MODULE.new(formula)
		local newShade = shader:Clone()
		
		local x = (((upper - lower) / trueDistance) * (index - 1)) + lower
		local y = f:compute(x)
		
		newShade.Size = UDim2.new(0, 1, 0.5 - ((.05 * math.clamp(y, -10.1, 10.1)) + .5), 0)
		newShade.Position = UDim2.new(scaledLower, abscissa, 0.5, 0)
		
		newShade.Parent = GRAPH_FRAME.Drawing.Markers
		abscissa = abscissa + 1
	end
end

local function displayApplication(expression)
	local DRAWING_FOLDER = GRAPH_FRAME.Drawing
	local MARKER_FOLDER = DRAWING_FOLDER.Markers
	
	local GRAPH_SIZE_X = GRAPH_FRAME.AbsoluteSize.X
	local orderedPairs = {}
	
	for _, child in pairs(MARKER_FOLDER:GetChildren()) do
		child:Destroy()
	end
	
	for index = 0, #orderedPairs do
		orderedPairs[index] = nil
	end
	
	if (createNodes(expression, GRAPH_SIZE_X, MARKER_FOLDER)) then
		for _, child in pairs(MARKER_FOLDER:GetChildren()) do
			table.insert(orderedPairs, child)
		end
	else
		return false
	end
	
	if (createEdges(MARKER_FOLDER, orderedPairs, true)) then
		for _, child in pairs(MARKER_FOLDER:GetChildren()) do
			if (child.Name == "Node") then
				child:Destroy()
			end
		end
	else
		return false
	end
	
	return true
end

local function displayFunction()
	local orderedPairs = {}
	
	local DRAWING_FOLDER = GRAPH_FRAME.Drawing
	local NODES_FOLDER = DRAWING_FOLDER.Nodes
	
	local EDGES_FOLDER = DRAWING_FOLDER.Edges
	local GRAPH_SIZE_X = GRAPH_FRAME.AbsoluteSize.X
	
	resetGraph(false)
	
	for index = 0, #orderedPairs do
		orderedPairs[index] = nil
	end
	
	if (createNodes(formula, GRAPH_SIZE_X, NODES_FOLDER)) then
		for _, child in pairs(NODES_FOLDER:GetChildren()) do
			table.insert(orderedPairs, child)
		end
	else
		return false
	end
	
	if (createEdges(EDGES_FOLDER, orderedPairs)) then
		for _, child in pairs(NODES_FOLDER:GetChildren()) do
			child:Destroy()
		end
	else
		return false
	end
	
	return true
end
-----------------------------
---| Local Functions End |---
-----------------------------

-----------------------------------
----| Calculator Events Begin |----
-----------------------------------
INTERCEPT_BUTTON.MouseButton1Click:Connect(function()
	local INTERCEPT_PROMPT = APPLICATION_PROMPTS.Intercept
	
	if (resetApplications("Intercept")) then
		local INPUT_FOLDER = INTERCEPT_PROMPT.Inputs
		local ENTER_BUTTON = INPUT_FOLDER.EnterButton
		
		local LOWER_BOUND = INPUT_FOLDER.LowerInput
		local UPPER_BOUND = INPUT_FOLDER.UpperInput
		
		local lowerBound = LOWER_BOUND.Text
		local upperBound = UPPER_BOUND.Text
		
		local lower = LOWER_BOUND:GetPropertyChangedSignal("Text"):Connect(function()
			lowerBound = LOWER_BOUND.Text
		end)
		
		local upper = UPPER_BOUND:GetPropertyChangedSignal("Text"):Connect(function()
			upperBound = UPPER_BOUND.Text
		end)
		
		local enter = ENTER_BUTTON.MouseButton1Click:Connect(function()
			local intercept = INTERCEPT_MODULE.new(formula)
			local debounce = true
			
			local returned, data = pcall(function()
				return intercept:root(tonumber(lowerBound), tonumber(upperBound))
			end)
			
			if (returned) then
				GRAPH_FRAME.Value.Text = data
				INTERCEPT_PROMPT.Visible = false
				
				removeAllDescendants(GRAPH_FRAME.Drawing.Markers)
				
				local marker = point:Clone()
				marker.Position = UDim2.new(((0.05 * tonumber(data)) + .5), 0, 0.5, 0)
				marker.Parent = GRAPH_FRAME.Drawing.Markers
				
				for _, connection in pairs(connections) do
					connection:disconnect()
				end
			else
				if debounce then
					debounce = false
					local current = GRAPH_FRAME.Value.Text
					
					local _, position = data:find(".*:")
					local err = data:sub(position, #data)
					
					if (err == ": Invalid bounds!") then
						displayError(data, LOWER_BOUND, UPPER_BOUND)
						wait(1)
						GRAPH_FRAME.Value.Text = tostring(current)
					else
						GRAPH_FRAME.Value.Text = "Error" .. data:sub(position, #data)
						wait(1)
						GRAPH_FRAME.Value.Text = tostring(current)
					end
				
					debounce = true
				end
			end
		end)
		
		local signals = {lower, upper, enter}
					
		for _, child in pairs(signals) do
			table.insert(connections, child)
		end
	else
		for _, connection in pairs(connections) do
			connection:disconnect()
		end
	end
end)

MINIMUM_BUTTON.MouseButton1Click:Connect(function()
	local MINIMUM_PROMPT = APPLICATION_PROMPTS.Minimum
	
	if (resetApplications("Minimum")) then
		local INPUT_FOLDER = MINIMUM_PROMPT.Inputs
		local ENTER_BUTTON = INPUT_FOLDER.EnterButton
		
		local LOWER_BOUND = INPUT_FOLDER.LowerInput
		local UPPER_BOUND = INPUT_FOLDER.UpperInput
		
		local lowerBound = LOWER_BOUND.Text
		local upperBound = UPPER_BOUND.Text
		
		local lower = LOWER_BOUND:GetPropertyChangedSignal("Text"):Connect(function()
			lowerBound = LOWER_BOUND.Text
		end)
		
		local upper = UPPER_BOUND:GetPropertyChangedSignal("Text"):Connect(function()
			upperBound = UPPER_BOUND.Text
		end)
		
		local enter = ENTER_BUTTON.MouseButton1Click:Connect(function()
			local minimize = OPTIMIZE_MODULE.new(formula, true)
			local debounce = true
			
			local returned, data = pcall(function()
				return minimize:findExtrema(tonumber(lowerBound), tonumber(upperBound))
			end)
			
			if (returned) then
				GRAPH_FRAME.Value.Text = data
				MINIMUM_PROMPT.Visible = false
				
				removeAllDescendants(GRAPH_FRAME.Drawing.Markers)
				local scaledY = ((.05 * math.clamp(minimize:compute(tonumber(data)), -10.1, 10.1)) + .5)
				
				local marker = point:Clone()
				marker.Position = UDim2.new(((0.05 * tonumber(data)) + .5), 0, 1 - scaledY, 0)
				marker.Parent = GRAPH_FRAME.Drawing.Markers
				
				for _, connection in pairs(connections) do
					connection:disconnect()
				end
			else
				if debounce then
					debounce = false
					local current = GRAPH_FRAME.Value.Text
					
					local _, position = data:find(".*:")
					local err = data:sub(position, #data)
					
					if (err == ": Invalid bounds!") then
						displayError(data, LOWER_BOUND, UPPER_BOUND)
						wait(1)
						GRAPH_FRAME.Value.Text = tostring(current)
					else
						GRAPH_FRAME.Value.Text = "Error" .. data:sub(position, #data)
						wait(1)
						GRAPH_FRAME.Value.Text = tostring(current)
					end
				
					debounce = true
				end
			end
		end)
		
		local signals = {lower, upper, enter}
					
		for _, child in pairs(signals) do
			table.insert(connections, child)
		end
	else
		for _, connection in pairs(connections) do
			connection:disconnect()
		end
	end
end)

MAXIMUM_BUTTON.MouseButton1Click:Connect(function()
	local MAXIMUM_PROMPT = APPLICATION_PROMPTS.Maximum
	
	if (resetApplications("Maximum")) then
		local INPUT_FOLDER = MAXIMUM_PROMPT.Inputs
		local ENTER_BUTTON = INPUT_FOLDER.EnterButton
		
		local LOWER_BOUND = INPUT_FOLDER.LowerInput
		local UPPER_BOUND = INPUT_FOLDER.UpperInput
		
		local lowerBound = LOWER_BOUND.Text
		local upperBound = UPPER_BOUND.Text
		
		local lower = LOWER_BOUND:GetPropertyChangedSignal("Text"):Connect(function()
			lowerBound = LOWER_BOUND.Text
		end)
		
		local upper = UPPER_BOUND:GetPropertyChangedSignal("Text"):Connect(function()
			upperBound = UPPER_BOUND.Text
		end)
		
		local enter = ENTER_BUTTON.MouseButton1Click:Connect(function()
			local maximize = OPTIMIZE_MODULE.new(formula, false)
			local debounce = true
			
			local returned, data = pcall(function()
				return maximize:findExtrema(tonumber(lowerBound), tonumber(upperBound))
			end)
			
			if (returned) then
				GRAPH_FRAME.Value.Text = data
				MAXIMUM_PROMPT.Visible = false
				
				removeAllDescendants(GRAPH_FRAME.Drawing.Markers)
				local scaledY = ((.05 * math.clamp(maximize:compute(tonumber(data)), -10.1, 10.1)) + .5)
				
				local marker = point:Clone()
				marker.Position = UDim2.new(((0.05 * tonumber(data)) + .5), 0, 1 - scaledY, 0)
				marker.Parent = GRAPH_FRAME.Drawing.Markers
				
				for _, connection in pairs(connections) do
					connection:disconnect()
				end
			else
				if debounce then
					debounce = false
					local current = GRAPH_FRAME.Value.Text
					
					local _, position = data:find(".*:")
					local err = data:sub(position, #data)
					
					if (err == ": Invalid bounds!") then
						displayError(data, LOWER_BOUND, UPPER_BOUND)
						wait(1)
						GRAPH_FRAME.Value.Text = tostring(current)
					else
						GRAPH_FRAME.Value.Text = "Error" .. data:sub(position, #data)
						wait(1)
						GRAPH_FRAME.Value.Text = tostring(current)
					end
				
					debounce = true
				end
			end
		end)
		
		local signals = {lower, upper, enter}
					
		for _, child in pairs(signals) do
			table.insert(connections, child)
		end
	else
		for _, connection in pairs(connections) do
			connection:disconnect()
		end
	end
end)

DERIVATIVE_BUTTON.MouseButton1Click:Connect(function()
	local DERIVATIVE_PROMPT = APPLICATION_PROMPTS.Derivative
	
	if (resetApplications("Derivative")) then
		local INPUT_FOLDER = DERIVATIVE_PROMPT.Inputs
		local ENTER_BUTTON = INPUT_FOLDER.EnterButton
		
		local X_VALUE = INPUT_FOLDER.Input
		local x = X_VALUE.Text
		
		local xValue = X_VALUE:GetPropertyChangedSignal("Text"):Connect(function()
			x = X_VALUE.Text
		end)
		
		local enter = ENTER_BUTTON.MouseButton1Click:Connect(function()
			local derivative = DERIVATIVE_MODULE.new(formula)
			local debounce = true
			
			local returned, data = pcall(function()
				return derivative:differentiate(tonumber(x))
			end)
			
			if (returned) then
				local display = data
				
				--[[if (string.match(data, "%d+.99999999") ~= nil) then
					display = tostring(math.floor(tonumber(data)))
				elseif (string.match(data, "%d+.00000000") ~= nil) then
					display = tostring(math.ceil(tonumber(data)))
				end]]--
				
				GRAPH_FRAME.Value.Text = display
				DERIVATIVE_PROMPT.Visible = false
				
				local yValue = derivative:compute(tonumber(x))
				local tangentLine = derivative:tangentLine(tonumber(x), tonumber(data))
				
				displayApplication(tangentLine, true)
				
				if (yValue <= 10) and (yValue >= -10) then
					local marker = point:Clone()
					marker.Position = UDim2.new(((0.05 * x) + .5), 0, 1 - ((0.05 * yValue) + .5), 0)
					marker.Parent = GRAPH_FRAME.Drawing.Markers
				end
				
				for _, connection in pairs(connections) do
					connection:disconnect()
				end
			else
				if debounce then
					debounce = false
					local current = GRAPH_FRAME.Value.Text
					
					local _, position = data:find(".*:")
					local err = data:sub(position, #data)
					
					if (err == ": X-value must be a number!") then
						displayError(data, X_VALUE)
						wait(1)
						GRAPH_FRAME.Value.Text = tostring(current)
					else
						GRAPH_FRAME.Value.Text = "Error" .. data:sub(position, #data)
						wait(1)
						GRAPH_FRAME.Value.Text = tostring(current)
					end
					
					debounce = true
				end
			end
		end)
		
		local signals = {xValue, enter}
					
		for _, child in pairs(signals) do
			table.insert(connections, child)
		end
	else
		for _, connection in pairs(connections) do
			connection:disconnect()
		end
	end
end)

INTEGRAL_BUTTON.MouseButton1Click:Connect(function()
	local INTEGRAL_PROMPT = APPLICATION_PROMPTS.Integral
	
	if (resetApplications("Integral")) then
		local INPUT_FOLDER = INTEGRAL_PROMPT.Inputs
		local ENTER_BUTTON = INPUT_FOLDER.EnterButton
		
		local LOWER_BOUND = INPUT_FOLDER.LowerInput
		local UPPER_BOUND = INPUT_FOLDER.UpperInput
		
		local lowerBound = LOWER_BOUND.Text
		local upperBound = UPPER_BOUND.Text
		
		local lower = LOWER_BOUND:GetPropertyChangedSignal("Text"):Connect(function()
			lowerBound = LOWER_BOUND.Text
		end)
		
		local upper = UPPER_BOUND:GetPropertyChangedSignal("Text"):Connect(function()
			upperBound = UPPER_BOUND.Text
		end)
		
		local enter = ENTER_BUTTON.MouseButton1Click:Connect(function()
			local integral = INTEGRAL_MODULE.new(formula)
			local debounce = true
			
			local returned, data = pcall(function()
				return integral:integrate(tonumber(lowerBound), tonumber(upperBound))
			end)
			
			if (returned) then
				GRAPH_FRAME.Value.Text = data
				INTEGRAL_PROMPT.Visible = false
				
				removeAllDescendants(GRAPH_FRAME.Drawing.Markers)
				shadeUnderFunction(tonumber(lowerBound), tonumber(upperBound))
				
				for _, connection in pairs(connections) do
					connection:disconnect()
				end
			else
				if debounce then
					debounce = false
					local current = GRAPH_FRAME.Value.Text
					
					local _, position = data:find(".*:")
					local err = data:sub(position, #data)
					
					if (err == ": Invalid bounds!") then
						displayError(data, LOWER_BOUND, UPPER_BOUND)
						wait(1)
						GRAPH_FRAME.Value.Text = tostring(current)
					else
						GRAPH_FRAME.Value.Text = "Error" .. data:sub(position, #data)
						wait(1)
						GRAPH_FRAME.Value.Text = tostring(current)
					end
				
					debounce = true
				end
			end
		end)
		
		local signals = {lower, upper, enter}
					
		for _, child in pairs(signals) do
			table.insert(connections, child)
		end
	else
		for _, connection in pairs(connections) do
			connection:disconnect()
		end
	end
end)

ENTER_BUTTON.MouseButton1Click:Connect(function()
	if (formula == "") then
		resetGraph(true)
		return nil
	end
	
	if (displayFunction()) then
		APPLICATION_FRAME.Visible = true
		GRAPH_FRAME.Value.Text = "y = " .. formula
	else
		resetGraph()
		return nil
	end
end)

FUNCTION_INPUT:GetPropertyChangedSignal("Text"):Connect(function()
	formula = FUNCTION_INPUT.Text
end)
-----------------------------------
-----| Calculator Events End |-----
-----------------------------------
--print("What are you doing here? Use the calculator dummy, nothing imporant here.")
