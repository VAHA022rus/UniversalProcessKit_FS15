-- by mor2000

----------------------------------
-- fill level bubble -------------
----------------------------------

_g.FillLevelBubble = {}

_g.fillLevelBubble_mt = {
	__index = function(t,k)
		if k=="fillLevel" then
			--print(tostring(t)..' fillLevel is '..tostring(t.p_fillLevel))
			return t.p_fillLevel or 0
		elseif k=="fillType" then
			return t.p_fillType or Fillable.FILLTYPE_UNKNOWN
		elseif k=="capacity" then
			return t.capacities[t.p_fillType] or math.huge
		end
		return FillLevelBubble[k]
	end,
	__newindex = function(t,k,v)
		if k=="fillLevel" then
			if v==0 then
				t.p_fillType = Fillable.FILLTYPE_UNKNOWN
			end
			--print(tostring(t)..' fillLevel set to '..tostring(v))
			t.p_fillLevel = v
		end
	end,
	__add = function(lhs,rhs)
		if type(rhs)=="number" then
			if rhs<0 then
				return lhs - (-rhs)
			end
			local oldFillLevel = lhs.fillLevel
			local newFillLevel = math.max(math.min(oldFillLevel + rhs, lhs.capacity), 0)
			local diff = newFillLevel - oldFillLevel
			lhs:onFillLevelChange(diff,newFillLevel,lhs.fillType)
			lhs.fillLevel = newFillLevel
			return diff
		elseif type(rhs)=="table" then
			if not rhs.isflb then
				rhs = FillLevelBubble:new(rhs)
			end
			if rhs.fillLevel<0 then
				return lhs - {-rhs.fillLevel, rhs.fillType}
			end
			print('wanne add '..tostring(rhs.fillLevel)..' to existing '..tostring(lhs.fillType))
			local newFillType = lhs.fillTypesConversionMatrix[lhs.fillType][rhs.fillType]
			if newFillType~=nil then
				lhs.p_fillType = newFillType
				local diff = lhs + rhs.fillLevel
				local newFillLevel = rhs.fillLevel - diff
				rhs:onFillLevelChange(-diff,newFillLevel,rhs.fillType)
				rhs.fillLevel = newFillLevel
				return diff
			end
		end
		return 0
	end,
	__sub = function(lhs,rhs)
		if type(rhs)=="number" then
			if rhs<0 then
				return lhs + (-rhs)
			end
			local oldFillLevel = lhs.fillLevel
			local newFillLevel = math.min(math.max(oldFillLevel - rhs, 0), lhs.capacity)
			local diff = newFillLevel - oldFillLevel
			lhs:onFillLevelChange(diff,newFillLevel,lhs.fillType)
			lhs.fillLevel = newFillLevel
			return diff
		elseif type(rhs)=="table" then
			if not rhs.isflb then
				rhs = FillLevelBubble:new(rhs)
			end
			if rhs.fillLevel<0 then
				return lhs + {-rhs.fillLevel, rhs.fillType}
			end
			local newFillType = lhs.fillTypesConversionMatrix[lhs.fillType][rhs.fillType]
			if newFillType~=nil then
				lhs.p_fillType = newFillType
				local diff = lhs - rhs.fillLevel
				local newFillLevel = rhs.fillLevel + diff
				rhs:onFillLevelChange(-diff,newFillLevel,rhs.fillType)
				rhs.fillLevel = newFillLevel
				return diff
			end
		end
		return 0
	end
}

function FillLevelBubble:new(...)
	local arr=...
	if type(arr)~="table" then
		arr={...}
	end
			
	local self={}
	self.isflb = true
	self.p_fillLevel = arr['fillLevel'] or arr[1] or 0
	self.p_fillType = arr['fillType'] or arr[2] or Fillable.FILLTYPE_UNKNOWN
	
	self.capacities = arr['capacities'] or FillLevelBubbleCapacities:new()
	self.fillTypesConversionMatrix = arr['fillTypesConversionMatrix'] or FillTypesConversionMatrix:new(self.p_fillType)
	
	self.onFillLevelChangeFuncs = {}
	
	setmetatable(self,fillLevelBubble_mt)
	
	return self
end

function FillLevelBubble:onFillLevelChange(deltaFillLevel, newFillLevel, fillType)
	--print(tostring(deltaFillLevel)..', '..tostring(newFillLevel)..', '..tostring(fillType))
	if deltaFillLevel~=0 then
		for obj,func in pairs(self.onFillLevelChangeFuncs) do
			obj[func](obj, deltaFillLevel, newFillLevel, fillType)
		end
	end
end

function FillLevelBubble:registerOnFillLevelChangeFunc(obj,func)
	--print('FillLevelBubble:registerOnFillLevelChangeFunc('..tostring(obj)..', '..tostring(func)..')')
	if type(obj)=="table" and type(func)=="string" and type(obj[func])=="function" then
		self.onFillLevelChangeFuncs[obj]=func
	end
end

function FillLevelBubble:unregisterOnFillLevelChangeFunc(obj)
	if type(obj)=="table" then
		self.onFillLevelChangeFuncs[obj]=nil
	end
end

----------------------------------
-- fill types conversion matrix --
----------------------------------

_g.FillTypesConversionMatrix = {}

_g.fillTypesConversionMatrix_mt = {
	__index = function(t,k)
		local newarr={}
		newarr[k]=k
		t[k]=newarr
		return newarr
	end,
	__add = function(lhs,rhs)
		if type(lhs)~="table" or type(rhs)~="table" then
			return FillTypesConversionMatrix:new()
		end
		local ret = FillTypesConversionMatrix:new()
		for k,v in pairs(lhs) do
			for l,w in pairs(v) do
				ret[k][l] = w
			end
		end
		for k,v in pairs(rhs) do
			for l,w in pairs(v) do
				ret[k][l] = w
			end
		end
		return ret
	end,
	__sub = function(lhs,rhs)
		if type(lhs)~="table" or type(rhs)~="table" then
			return FillTypesConversionMatrix:new()
		end
		local ret = FillTypesConversionMatrix:new()
		for k,v in pairs(lhs) do
			for l,w in pairs(v) do
				ret[k][l] = w
			end
		end
		for k,v in pairs(rhs) do
			for l,_ in pairs(v) do
				if k~=Fillable.FILLTYPE_UNKNOWN and l~=Fillable.FILLTYPE_UNKNOWN then
					ret[k][l] = nil
				end
			end
		end
		return ret
	end	
}

function FillTypesConversionMatrix:new(...)
	local arr=...
	if type(arr)~="table" then
		arr={...}
	end
	
	local self={}
	setmetatable(self, fillTypesConversionMatrix_mt)
	
	self[Fillable.FILLTYPE_UNKNOWN][Fillable.FILLTYPE_UNKNOWN] = Fillable.FILLTYPE_UNKNOWN
	if #arr>=1 then
		for i=1,#arr do
			self[arr[1]][arr[i]] = arr[1]
			self[Fillable.FILLTYPE_UNKNOWN][arr[i]] = arr[1]
		end
		self[arr[1]][Fillable.FILLTYPE_UNKNOWN] = arr[1]
	end

	return self
end

----------------------------------
-- fill level bubble capacities --
----------------------------------

_g.FillLevelBubbleCapacities = {}

_g.fillLevelBubbleCapacities_mt = {
	__index = function(t,k)
		return t.p_capacities[k] or t.p_defaultCapacity
	end
}

function FillLevelBubbleCapacities:new(defaultCapacity, capacities) -- fill type bubble capacity
	local self = {}
	self.p_defaultCapacity = defaultCapacity or math.huge
	self.p_capacities = capacities or {}
	
	setmetatable(self, fillLevelBubbleCapacities_mt)
	
	return self
end

----------------------------------
-- fill level bubbles shell ------
----------------------------------

-- might not work, changed/ fixed version in ClassUPK

_g.fillLevelBubbleShell_mt = {
	__index = function(t,k)
		if t.storageType==UPK_Storage.SEPARATE then
			if k=="capacity" then
				return nil
			elseif k=="fillLevel" then
				return 0
			elseif k=="fillType" then
				return Fillable.FILLTYPE_UNKNOWN
			end
		elseif t.storageType==UPK_Storage.SINGLE then
			if k=="capacity" then
				return t.p_capacity
			elseif k=="fillLevel" then
				return t.p_flbs[1].fillLevel
			elseif k=="fillType" then
				return t.p_flbs[1].fillType
			end
		elseif t.storageType==UPK_Storage.FIFO or t.storageType==UPK_Storage.FILO then
			if k=="capacity" then
				return t.p_capacity
			elseif k=="fillLevel" then
				return t.p_totalFillLevel
			elseif k=="fillType" then
				return t.p_flbs[1].fillType
			end
		end
		return UniversalProcessKit[k]
	end,
	__add = function(lhs,rhs)
		local added = 0
		if type(rhs)=="table" then
			if not rhs.isflb then
				rhs = FillLevelBubble:new(rhs)
			end
			if rhs.fillLevel<0 then
				return lhs - {-rhs.fillLevel, rhs.fillType}
			end
			
			if lhs.storageType==UPK_Storage.SEPARATE then
				added = (lhs.p_flbs[lhs.fillTypesConversionMatrix[Fillable.FILLTYPE_UNKNOWN][rhs.fillType]] or lhs.parent or FillLevelBubble:new()) + rhs
			elseif lhs.storageType==UPK_Storage.SINGLE then
				added = lhs.p_flbs[1] + rhs
			elseif lhs.storageType==UPK_Storage.FIFO then
				local newFillType = lhs.p_flbs[lhs.p_flbs_fifo_lastkey].fillTypesConversionMatrix[lhs.p_flbs[lhs.p_flbs_fifo_lastkey].fillType][rhs.fillType]
				if newFillType~=nil then
					local newCapacity = lhs.p_capacity - lhs.p_totalFillLevel
					lhs.capacities[newFillType] = newCapacity
					added = lhs.p_flbs[lhs.p_flbs_fifo_lastkey] + rhs
				end
				if added==0 then
					local flb = FillLevelBubble:new()
					flb.capacities = lhs.capacities
					flb.fillTypesConversionMatrix = lhs.fillTypesConversionMatrix
					flb:registerOnFillLevelChangeFunc(lhs,"onFillLevelChange")
					local newFillType = flb.fillTypesConversionMatrix[flb.fillType][rhs.fillType]
					if newFillType~=nil then
						local newCapacity = lhs.p_capacity - lhs.p_totalFillLevel
						lhs.capacities[newFillType] = newCapacity
						added = flb + rhs
					end
					if added>0 then
						lhs.p_flbs_fifo_lastkey = lhs.p_flbs_fifo_lastkey + 1
						table.insert(lhs.p_flbs,lhs.p_flbs_fifo_lastkey,flb)
					end
				end
				lhs.p_totalFillLevel = lhs.p_totalFillLevel + added
			elseif lhs.storageType==UPK_Storage.FILO then
				local newFillType = lhs.p_flbs[1].fillTypesConversionMatrix[lhs.p_flbs[1].fillType][rhs.fillType]
				if newFillType~=nil then
					local newCapacity = lhs.p_capacity - lhs.p_totalFillLevel
					lhs.capacities[newFillType] = newCapacity
					added = lhs.p_flbs[1] + rhs
				end
				if added==0 then
					local flb = FillLevelBubble:new()
					flb.capacities = lhs.capacities
					flb.fillTypesConversionMatrix = lhs.fillTypesConversionMatrix
					flb:registerOnFillLevelChangeFunc(lhs,"onFillLevelChange")
					local newFillType = flb.fillTypesConversionMatrix[flb.fillType][rhs.fillType]
					if newFillType~=nil then
						local newCapacity = lhs.p_capacity - lhs.p_totalFillLevel
						lhs.capacities[newFillType] = newCapacity
						added = flb + rhs
					end
					if added>0 then
						table.insert(lhs.p_flbs,1,flb)
					end
				end
				lhs.p_totalFillLevel = lhs.p_totalFillLevel + added
			end
		end	
		return added
	end,
	__sub = function(lhs,rhs)
		local added = 0
		if type(rhs)=="table" then
			if not rhs.isflb then
				rhs = FillLevelBubble:new(rhs)
			end
			if rhs.fillLevel<0 then
				return lhs + {-rhs.fillLevel, rhs.fillType}
			end
			
			if lhs.storageType==UPK_Storage.SEPARATE then
				added = (lhs.p_flbs[lhs.fillTypesConversionMatrix[Fillable.FILLTYPE_UNKNOWN][rhs.fillType]] or lhs.parent or FillLevelBubble:new()) - rhs
			elseif lhs.storageType==UPK_Storage.SINGLE then
				added = lhs.p_flbs[1] - rhs
			elseif lhs.storageType==UPK_Storage.FIFO then
				local newFillType = lhs.p_flbs[1].fillTypesConversionMatrix[lhs.p_flbs[1].fillType][rhs.fillType]
				if newFillType~=nil then
					local newCapacity = lhs.p_capacity - lhs.p_totalFillLevel + lhs.p_flbs[1].fillLevel
					lhs.capacities[newFillType] = newCapacity
					added = lhs.p_flbs[1] - rhs
				end
				if added<0 and lhs.p_flbs[1].fillLevel==0 and lhs.p_flbs[2]~=nil then
					table.remove(lhs.p_flbs,1)
					lhs.p_flbs_fifo_lastkey = lhs.p_flbs_fifo_lastkey - 1
				end
				lhs.p_totalFillLevel = lhs.p_totalFillLevel + added
			elseif lhs.storageType==UPK_Storage.FILO then
				local newFillType = lhs.p_flbs[1].fillTypesConversionMatrix[lhs.p_flbs[1].fillType][rhs.fillType]
				if newFillType~=nil then
					local newCapacity = lhs.p_capacity - lhs.p_totalFillLevel + lhs.p_flbs[1].fillLevel
					lhs.capacities[newFillType] = newCapacity
					added = lhs.p_flbs[1] - rhs
				end
				if added<0 and lhs.p_flbs[1].fillLevel==0 and lhs.p_flbs[2]~=nil then
					table.remove(lhs.p_flbs,1)
				end
				lhs.p_totalFillLevel = lhs.p_totalFillLevel + added
			end
		end	
		return added
	end
}