-----------------------------
--| Local Constants Begin |--
-----------------------------
local BACKGROUND = script.Parent:WaitForChild("Background")

local PARSER_MODULE = require(script.Parser)
local INTERCEPT_MODULE = require(script.Intercept)

local MINIMUM_MODULE = require(script.Minimum)
local MAXIMUM_MODULE = require(script.Maximum)

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
	node.Size = UDim2.new(0, 2, 0, 2)
	node.Name = "Node"
	node.BackgroundColor3 = Color3.new(1, 0, 0)
	node.BorderSizePixel = 0
	node.AnchorPoint = Vector2.new(0.5, 0.5)
	node.ZIndex = 2
end

local edge = Instance.new("Frame") do
	--edge.Name = "Edge"
	edge.BackgroundColor3 = Color3.new(0, 0, 0)
	edge.BorderSizePixel = 0
	edge.AnchorPoint = Vector2.new(0.5, 0.5)
end

local point = Instance.new("ImageLabel") do
	point.Name = "Point"
	point.AnchorPoint = Vector2.new(0.5, 0.5)
	point.BackgroundTransparency = 1
	point.Size = UDim2.new(0, 10, 0, 10)
	point.Image = "rbxassetid://142700369"
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
	if (type(command) == "boolean") and (command) then
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

local function connectNodes(firstNode, secondNode, reference)
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
	newEdge.Position = UDim2.new(newPosition.X, 0, newPosition.Y, 0)
	newEdge.Size = UDim2.new(newSize, 0, 0, 2)
	newEdge.Rotation = math.deg(rotation)
	newEdge.Parent = reference
end

local function createEdges(container, storage)
	for index = 1, #storage - 1 do
		connectNodes(storage[index], storage[index + 1], container, index)
	end
	
	return true
end

local function createNodes(amount, container)
	local abscissa = 0
	
	for index = 0, math.ceil(amount / 3) do
		local x = ((20 / math.ceil(amount / 3)) * index) - 10
		
		local func = PARSER_MODULE.new(formula)
		local y = 0
		
		local returned, data = pcall(function()
			return func:parse(x)
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
		local scaledY = ((.05 * math.clamp(y, -10.05, 10.05)) + .5)
		
		local pointNode = node:Clone()
		pointNode.Name = "Node" .. index + 1
		pointNode.Position = UDim2.new(scaledX, 0, 1 - scaledY, 0)
		pointNode.Parent = container
		
		abscissa = abscissa + 3
	end
	
	return true
end

local function displayFunction()
	local orderedPairs = {}
	
	local DRAWING_FOLDER = GRAPH_FRAME.Drawing
	local MARKERS_FOLDER = DRAWING_FOLDER.Markers
	
	local NODES_FOLDER = DRAWING_FOLDER.Nodes
	local EDGES_FOLDER = DRAWING_FOLDER.Edges
	
	local GRAPH_SIZE_X = GRAPH_FRAME.AbsoluteSize.X
	local GRAPH_SIZE_Y = GRAPH_FRAME.AbsoluteSize.Y
	
	for _, edge in pairs(EDGES_FOLDER:GetChildren()) do
		edge:Destroy()
	end
		
	for _, marker in pairs(MARKERS_FOLDER:GetChildren()) do
		marker:Destroy()
	end
		
	for index = 0, #orderedPairs do
		orderedPairs[index] = nil
	end
	
	if not (createNodes((GRAPH_SIZE_X), NODES_FOLDER)) then
		return false
	end
	
	for _, child in pairs(NODES_FOLDER:GetChildren()) do
		table.insert(orderedPairs, child)
	end
	
	if not (createEdges(EDGES_FOLDER, orderedPairs)) then
		return false
	end
	
	--for _, child in pairs(NODES_FOLDER:GetChildren()) do
	--	child:Destroy()
	--end
	
	do
		APPLICATION_FRAME.Visible = false
		INPUT_FRAME.Visible = false
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
		local debounce = true
		
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
			local interceptCalculator = INTERCEPT_MODULE.new(formula)
			
			local returned, data = pcall(function()
				return interceptCalculator:root(lowerBound, upperBound)
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
			local debounce = true
			-- TODO: Create new Minimum class object
			local returned, data = pcall(function()
				-- TODO: Get the minimum of the function
				return true
			end)
			
			if (returned) then
				GRAPH_FRAME.Value.Text = data
				MINIMUM_PROMPT.Visible = false
				
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
				
					GRAPH_FRAME.Value.Text = "Error" .. data:sub(position, #data)
					wait(1)
					GRAPH_FRAME.Value.Text = tostring(current)
					
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
	local MAXIMUM_PROMPT = APPLICATION_PROMPTS.Minimum
	
	if (resetApplications("Minimum")) then
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
			local debounce = true
			-- TODO: Create new Maximum class object
			local returned, data = pcall(function()
				-- TODO: Get the maximum of the function
				return true
			end)
			
			if (returned) then
				GRAPH_FRAME.Value.Text = data
				MAXIMUM_PROMPT.Visible = false
				
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
				
					GRAPH_FRAME.Value.Text = "Error" .. data:sub(position, #data)
					wait(1)
					GRAPH_FRAME.Value.Text = tostring(current)
					
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
			local debounce = true
			-- TODO: Create new Derivative class object
			local returned, data = pcall(function()
				-- TODO: Get the derivative of the function
				return true
			end)
			
			if (returned) then
				GRAPH_FRAME.Value.Text = data
				DERIVATIVE_PROMPT.Visible = false
				
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
				
					GRAPH_FRAME.Value.Text = "Error" .. data:sub(position, #data)
					wait(1)
					GRAPH_FRAME.Value.Text = tostring(current)
					
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
	local INTEGRAL_PROMPT = APPLICATION_PROMPTS.Minimum
	
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
			local debounce = true
			-- TODO: Create new Maximum class object
			local returned, data = pcall(function()
				-- TODO: Get the maximum of the function
				return true
			end)
			
			if (returned) then
				GRAPH_FRAME.Value.Text = data
				INTEGRAL_PROMPT.Visible = false
				
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
				
					GRAPH_FRAME.Value.Text = "Error" .. data:sub(position, #data)
					wait(1)
					GRAPH_FRAME.Value.Text = tostring(current)
					
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
		APPLICATION_FRAME.Visible = false
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
print("What are you doing here? Use the calculator dummy, nothing imporant here.")
