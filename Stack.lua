Stack = {
	new = function()
		return setmetatable({}, Stack)
	end,
	
	isEmpty = function(self)
		return #self == 0
	end,
	
	push = function(self, ...)
		local inputs = {...}
		
		for _, child in ipairs(inputs) do
			table.insert(self, child)
		end
	end,
	
	pop = function(self)
		assert(#self > 0, "Stack underflow!")
		
		return table.remove(self, #self)
	end,
	
	peek = function(self)
		assert(#self > 0, "Stack underflow!")
		
		return self[#self]
	end,
	
	empty = function(self)
		for index = 1, #self do
			self[index] = nil
		end
	end,
	
	toString = function(self)
		local str = "["
		
		for _, child in ipairs(self) do
			str = str .. tostring(child) .. ", "
		end
		
		return string.sub(str, 0, #str - 2) .. "]"
	end,
	
	toArray = function(self)
		local arr = {}
		
		for _, child in ipairs(self) do
			table.insert(arr, child)
		end
		
		return arr
	end
}

Stack.__index = Stack

return Stack
