-- by mor2000

-- handle storageBits

UniversalProcessKitStorageBit.storageBits = {}

function UniversalProcessKitStorageBit.getNewStorageBitId()
	local len = #UniversalProcessKitStorageBit.storageBits
	if len==0 then
		return 1
	end
	local _, maxk = getMinMaxKeys(UniversalProcessKitStorageBit.storageBits)
	if len<maxk then -- recycle old keys
		for i=1,maxk do
			if UniversalProcessKitStorageBit.storageBits[i]==nil then
				return i
			end
		end
	end
	return maxk+1
end;

function UniversalProcessKitStorageBit:new(fillType, capacity)
	local self={}
	setmetatable(self, {__index=UniversalProcessKitStorageBit})
	self:registerStorageBit()
	self.fillLevel = 0
	self.fillType = fillType or Fillable.FILLTYPE_UNKNOWN
	self.capacity = capacity or math.huge
	return self
end;

function UniversalProcessKitStorageBit:registerStorageBit()
	self.storageBitId = UniversalProcessKitStorageBit.getNewStorageBitId()
	UniversalProcessKitStorageBit.storageBits[self.storageBitId] = self
end;

function UniversalProcessKitStorageBit:unregisterStorageBit()
	UniversalProcessKitStorageBit.storageBits[self.storageBitId] = nil
end;

-- functions for fillLevel

function UniversalProcessKitStorageBit:getFillLevel(fillType)
	if fillType==nil or fillType==self.fillType then
		return self.fillLevel
	end
	return 0
end;

function UniversalProcessKitStorageBit:setFillLevel(fillLevel, fillType)
	local currentFillType=self.fillType
	fillType=fillType or currentFillType -- fillType may be nil
	if fillType==currentFillType and currentFillType~=Fillable.FILLTYPE_UNKNOWN then
		if fillLevel~=nil and fillLevel>0 then
			local newFillLevel=mathmin(fillLevel,self.capacity)
			self.fillLevel=newFillLevel
			return newFillLevel-fillLevel -- returns sth (negative) when new fillLevel exceeds capacity
		end
	end
	return 0, self.fillLevel
end;

function UniversalProcessKitStorageBit:addFillLevel(deltaFillLevel, fillType) -- can also substract
	local currentFillType=self.fillType
	fillType=fillType or currentFillType -- fillType may be nil
	if fillType==currentFillType and currentFillType~=Fillable.FILLTYPE_UNKNOWN then
		if deltaFillLevel~=nil and deltaFillLevel~=0 then
			local added =self:setFillLevel(self.fillLevel+deltaFillLevel, fillType)
			return added+deltaFillLevel, self.fillLevel -- how much of deltaFillLevel was added to the fillLevel?
		end
	end
	return 0, self.fillLevel
end;

function UniversalProcessKitStorageBit:resetFillLevel()
	self.fillLevel = 0
end;

-- functions for fillType

function UniversalProcessKitStorageBit:getFillType()
	return self.fillType
end;

function UniversalProcessKitStorageBit:setFillType(fillType)
	self.fillType = fillType or Fillable.FILLTYPE_UNKNOWN	
end;

function UniversalProcessKitStorageBit:resetFillType()
	self.fillType = Fillable.FILLTYPE_UNKNOWN	
end;

-- functions for capacity

function UniversalProcessKitStorageBit:getCapacity()
	return self.capacity
end;

function UniversalProcessKitStorageBit:setCapacity(capacity)
	self.capacity = capacity or math.huge	
end;

UniversalProcessKitStorageBit.emptyStorageBit = UniversalProcessKitStorageBit:new()