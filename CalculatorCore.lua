-----------------------------
--| Local Constants Begin |--
-----------------------------
local BACKGROUND = script.Parent:WaitForChild("Background")
local PARSER_MODULE = require(script.ExpressionParser)

local GRAPH_FRAME = BACKGROUND.GraphFrame
local INPUT_FRAME = BACKGROUND.InputFrame

local INTERACTABLE_FOLDER = INPUT_FRAME.Interactable
local APPLICATION_FRAME = BACKGROUND.ApplicationFrame

local ENTER_BUTTON = INTERACTABLE_FOLDER.EnterButton
local FUNCTION_INPUT = INTERACTABLE_FOLDER.FunctionInput

local ERROR_OCCURED = script.ErrorOccured
local ALERT_FRAME = FUNCTION_INPUT.Alert
-----------------------------
---| Local Constants End |---
-----------------------------

-----------------------------
--| Local Variables Begin |--
-----------------------------
local formula = ""

local node = Instance.new("Frame") do
	node.Size = UDim2.new(0, 2, 0, 2)
	node.Name = "Node"
	node.BackgroundColor3 = Color3.new(0, 0, 0)
	node.BorderSizePixel = 0
	node.AnchorPoint = Vector2.new(0.5, 0.5)
end

local edge = Instance.new("Frame") do
	--edge.Name = "Edge"
	edge.BackgroundColor3 = Color3.new(0, 0, 0)
	edge.BorderSizePixel = 0
	edge.AnchorPoint = Vector2.new(0.5, 0.5)
end
-----------------------------
---| Local Variables End |---
-----------------------------

-----------------------------
--| Local Functions Begin |--
-----------------------------
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
	newEdge.Size = UDim2.new(newSize, 0, 0, 3)
	newEdge.Rotation = math.deg(rotation)
	newEdge.Name = "Edge"
	newEdge.Parent = reference
end

local function createEdges(container, storage)
	for index = 1, #storage - 1 do
		connectNodes(storage[index], storage[index + 1], container)
	end
	
	return true
end

local function initializeNode(x, y, parent)
	local pointNode = node:Clone()
	pointNode.Position = UDim2.new(x, 0, 1 - y, 0)
	pointNode.Parent = parent
	
	return pointNode
end

local function createNodes(amount, container)
	local abscissa = 0
	
	for index = 0, math.ceil(amount / 3) do
		local x = ((20 / math.ceil(amount / 3)) * index) - 10
		local expression = string.gsub(formula, "x", x)
		
		local expressionParser = PARSER_MODULE.new()
		local y = expressionParser:parse(expression)
		
		if (type(y) ~= "number") then
			return false
		end
		
		local newy = math.clamp(y, -10.05, 10.05)
		print("Old: " .. y .. " New: " .. newy) 
		local node = initializeNode((abscissa / amount), ((.05 * newy) + .5), container)
		
		abscissa = abscissa + 3
	end
	
	return true
end

local function displayFunction()
	local orderedPairs = {}
	local DRAWING_FOLDER = GRAPH_FRAME.Drawing
	
	local NODES_FOLDER = DRAWING_FOLDER.Nodes
	local EDGES_FOLDER = DRAWING_FOLDER.Edges
	
	local GRAPH_SIZE_X = GRAPH_FRAME.AbsoluteSize.X
	local GRAPH_SIZE_Y = GRAPH_FRAME.AbsoluteSize.Y
	
	print("Deleting all previous edges...")
	do
		for _, child in pairs(EDGES_FOLDER:GetChildren()) do
			child:Destroy()
		end
		
		for index = 0, #orderedPairs do
			orderedPairs[index] = nil
		end
	end
	
	print("Creating nodes...")
	if not (createNodes((GRAPH_SIZE_X), NODES_FOLDER)) then
		return false
	end
	
	for _, child in pairs(NODES_FOLDER:GetChildren()) do
		table.insert(orderedPairs, child)
	end
	
	print("Nodes created. Creating edges...")
	if not (createEdges(EDGES_FOLDER, orderedPairs)) then
		return false
	end
	
	print("Edges created. Destroying Nodes...\n")
	for _, child in pairs(NODES_FOLDER:GetChildren()) do
		child:Destroy()
	end
	
	return true
	
end
-----------------------------
---| Local Functions End |---
-----------------------------

-----------------------------
----| Game Events Begin |----
-----------------------------
ERROR_OCCURED.Event:Connect(function(message)
	local info = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	local goal = {Transparency = 1}
	
	local tween = game:GetService("TweenService")
	local transparencyTween = tween:Create(ALERT_FRAME, info, goal)
	
	do
		transparencyTween:Play()
		ALERT_FRAME.Visible = true
		FUNCTION_INPUT.Text = ""
	end
	
	delay(0.5, function()
		ALERT_FRAME.Visible = false
		ALERT_FRAME.Transparency = 0.3
	end)
	
	assert(false, message)
end)

ENTER_BUTTON.MouseButton1Click:Connect(function()
	local start = tick()
	print("\nChecking if input is empty...")
	if (formula == "") then
		print("Input is empty, rejecting request...\n")
		return nil
	end
	
	print("Attempting to display function...\n")
	if (displayFunction()) then
		print("Function is now displayed. Displaying applications...")
		APPLICATION_FRAME.Visible = true
	else
		print("Function was unable to display. Restarting...\n")
		return nil
	end
	
	print("Full cycle complete. Completed in " .. (tick() - start) .. " seconds.\n")
end)

FUNCTION_INPUT:GetPropertyChangedSignal("Text"):Connect(function()
	formula = FUNCTION_INPUT.Text
	print("Text changed to: " .. formula)
end)
-----------------------------
-----| Game Events End |-----
-----------------------------
print("What are you doing here? Use the calculator dummy, nothing imporant here.")
