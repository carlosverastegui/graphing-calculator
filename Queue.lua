-- Testing
-- Adding even more stuff
-- Maybe just an extra line or two
Queue = {
	new = function()
		return setmetatable({}, Queue)
	end,
	
	isEmpty = function(self)
		return #self == 0
	end,
	
	enqueue = function(self, ...)
		local inputs = {...}
		
		for _, child in ipairs(inputs) do
			table.insert(self, child)
		end
	end,
	
	dequeue = function(self)
		assert(#self > 0, "Queue underflow!")
		
		return table.remove(self, 1)
	end,
	
	peek = function(self)
		assert(#self > 0, "Queue underflow!")
		
		return self[1]
	end,
	
	empty = function(self)
		for index = 1, #self do
			self[index] = nil
		end
	end,
	
	toString = function(self)
		local str = "["
		
		for _, child in ipairs(self) do
			str = str .. ", " .. tostring(child)
		end
		
		return str .. "]"
	end,
	
	toArray = function(self)
		local arr = {}
		
		for _, child in ipairs(self) do
			table.insert(arr, child)
		end
		
		return arr
	end
}

Queue.__index = Queue

return Queue
