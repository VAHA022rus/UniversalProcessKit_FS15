-- by mor2000

-- storage controller

function UniversalProcessKitStorageController:new(storageType, capacity, upkmodule)
	local self={}
	setmetatable(self, {__index=UniversalProcessKitStorageController})
	self.storageType = storageType or UPK_Storage.SEPARATE
	self.capacity = capacity or math.huge
	self.upkmodule = upkmodule
	if type(self.upkmodule)=='table' and type(self.upkmodule.parent)=='table' and type(self.upkmodule.parent.storageController)=='table' and self.upkmodule.parent.storageController~=self then
		self.parent = self.upkmodule.parent.storageController
	end
	
	self.storageBits = {}
	
	setmetatable(self.storageBits, {
		__index = function(t,k)
			print('self.storageBits: asked for '..tostring(k))
			local storageBit=nil
			print('storageBit for '..tostring(k)..' doesnt exist')
			if self.storageType==UPK_Storage.SEPARATE then
				if type(rawget(self,"parent"))=="table" then
					storageBit=self.parent.storageBits[k]
					print('parents storageBit is '..tostring(storageBit))
					if storageBit~=nil then
						rawset(self.storageBits,k,storageBit) -- establish shortcut for next time
					end
				end
			end
			return storageBit or UniversalProcessKitStorageBit.emptyStorageBit
		end
	})
	--]]
	
	if self.storageType == UPK_Storage.SEPARATE then
		-- set links to special fill types
		rawset(self.storageBits, UniversalProcessKit.FILLTYPE_MONEY, UniversalProcessKitStorageBit.emptyStorageBit) -- g_currentMission:getTotalMoney()
		rawset(self.storageBits, UniversalProcessKit.FILLTYPE_VOID, UniversalProcessKitStorageBit.emptyStorageBit)
		rawset(self.storageBits, UniversalProcessKit.FILLTYPE_SUN, UniversalProcessKitStorageBit.emptyStorageBit) -- UniversalProcessKitEnvironment.sun
		rawset(self.storageBits, UniversalProcessKit.FILLTYPE_RAIN, UniversalProcessKitStorageBit.emptyStorageBit) -- UniversalProcessKitEnvironment.rain
		rawset(self.storageBits, UniversalProcessKit.FILLTYPE_TEMPERATURE, UniversalProcessKitStorageBit.emptyStorageBit) -- UniversalProcessKitEnvironment.temperature
	elseif self.storageType == UPK_Storage.SINGLE then
		self.singleStorageBitFillType = nil
	elseif self.storageType == UPK_Storage.FIFO or self.storageType == UPK_Storage.FILO then
		rawset(self.storageBits, 1, UniversalProcessKitStorageBit:new(fillType, capacity or self.capacity))
	end
	
	return self
end

-- handle fillLevels

function UniversalProcessKitStorageController:addFillLevel(deltaFillLevel, fillType)
	if self.storageType == UPK_Storage.SEPARATE then
		local addedFillLevel,_ = self.storageBits[fillType]:addFillLevel(deltaFillLevel, fillType)
		print('added '..tostring(addedFillLevel))
		return addedFillLevel
	elseif self.storageType == UPK_Storage.SINGLE then
		fillType = fillType or self.singleStorageBitFillType
		if fillType~=nil and (self.singleStorageBitFillType==fillType or self.singleStorageBitFillType==nil) then
			local addedFillLevel,newfillLevel = self.storageBits[fillType]:addFillLevel(deltaFillLevel, fillType)
			if newfillLevel==0 then
				self.singleStorageBitFillType = nil
			else
				self.singleStorageBitFillType = fillType
			end
			print('added '..tostring(addedFillLevel))
			return addedFillLevel
		end
		return deltaFillLevel
	elseif self.storageType == UPK_Storage.FIFO or self.storageType == UPK_Storage.FILO then
		 if self.storageBits[self.lastStorageBit]:getFillType()==fillType then
			 if self.storageType == UPK_Storage.FIFO and deltaFillLevel<0 then
			 	local firstStorageBit,_ = getMinMaxKeys(self.storageBits)
				local addedFillLevel, newFillLevel = self.storageBits[firstStorageBit]:addFillLevel(deltaFillLevel, fillType)
   			 	if newFillLevel==0 then
					self.storageBits[firstStorageBit]:unregisterStorageBit()
   					self.storageBits[firstStorageBit] = nil
   			 	end
				return addedFillLevel
			end
			 local addedFillLevel, newFillLevel = self.storageBits[self.lastStorageBit]:addFillLevel(deltaFillLevel, fillType)
			 if newFillLevel==0 then
				 self.storageBits[self.lastStorageBit]:unregisterStorageBit()
				 self.storageBits[self.lastStorageBit] = nil
				 self.lastStorageBit = self.lastStorageBit - 1
			 end
			 return addedFillLevel
		 else
			 if self.storageType == UPK_Storage.FIFO and deltaFillLevel<0 then
				 return 0
			 end
			 if self.lastStorageBit>=32768 then -- may collide with filltypes money etc
				 return 0
			 end
			 self.lastStorageBit = self.lastStorageBit + 1
			 self.storageBits[self.lastStorageBit] = UniversalProcessKitStorageBit:new(fillType, self.capacity)
			 local addedFillLevel,_ = self.storageBits[self.lastStorageBit]:addFillLevel(deltaFillLevel, fillType)
			 return addedFillLevel
		 end
	end
	return 0
end;

-- handle bulk fillLevels

function UniversalProcessKitStorageController:getFillLevel(fillType, totalsum) -- totalsum for FIFO and FILO
	local fillLevel=0
	if totalsum then
		if self.storageType == UPK_Storage.SEPARATE then
			fillType = fillType or Fillable.FILLTYPE_UNKNOWN
			fillLevel = self.storageBits[fillType]:getFillLevel()
		elseif self.storageType == UPK_Storage.SINGLE then
			fillType = fillType or self.singleStorageBitFillType
			if fillType~=nil and fillType==self.singleStorageBitFillType then
				fillLevel=self.storageBits[fillType]:getFillLevel()
			end
		elseif self.storageType == UPK_Storage.FIFO or self.storageType == UPK_Storage.FILO then
			for _,storageBit in pairs(self.storageBits) do
				fillLevel = fillLevel + storageBit:getFillLevel()
			end
		end
	else
		if self.storageType == UPK_Storage.SEPARATE then
			fillType = fillType or Fillable.FILLTYPE_UNKNOWN
			fillLevel = self.storageBits[fillType]:getFillLevel()
		elseif self.storageType == UPK_Storage.SINGLE then
			fillType = fillType or self.singleStorageBitFillType
			if fillType~=nil and fillType==self.singleStorageBitFillType then
				fillLevel=self.storageBits[fillType]:getFillLevel()
			end
		elseif self.storageType == UPK_Storage.FIFO then
			local firstStorageBit,_ = getMinMaxKeys(self.storageBits)
			if fillType==self.storageBits[firstStorageBit]:getFillType() then
				fillLevel=self.storageBits[firstStorageBit]:getFillLevel()
			end
		elseif self.storageType == UPK_Storage.FILO then
			if fillType==self.storageBits[self.lastStorageBit]:getFillType() then
				fillLevel=self.storageBits[self.lastStorageBit]:getFillLevel()
			end
		end
	end
	return fillLevel
end;

-- handle bulk fillType

function UniversalProcessKitStorageController:getFillType()
	if self.storageType == UPK_Storage.SINGLE then
		return self.singleStorageBitFillType or Fillable.FILLTYPE_UNKNOWN
	elseif self.storageType == UPK_Storage.FIFO then
		local firstStorageBit,_ = getMinMaxKeys(self.storageBits)
		return self.storageBits[firstStorageBit]:getFillType()
	elseif self.storageType == UPK_Storage.FILO then
		return self.storageBits[self.lastStorageBit]:getFillType()
	end
	return Fillable.FILLTYPE_UNKNOWN
end;

-- set capacities

function UniversalProcessKitStorageController:getCapacity()
	return self.capacity
end;

function UniversalProcessKitStorageController:setCapacity(capacity)
	self.capacity = capacity or math.huge
end;

function UniversalProcessKitStorageController:setStorageBitCapacity(fillType, capacity) -- for storageType separate and single only
	if self.storageType == UPK_Storage.SEPARATE or self.storageType == UPK_Storage.SINGLE then
		if fillType~=nil and fillType~=Fillable.FILLTYPE_UNKNOWN then
			if rawget(self.storageBits, fillType)~=nil then
				self.storageBits[fillType]:setCapacity(capacity)
			end
		end
	end
end;

function UniversalProcessKitStorageController:getStorageBitCapacity(fillType)
	if self.storageType == UPK_Storage.SINGLE then
		fillType = fillType or self.singleStorageBitFillType
	end
	return self.storageBits[fillType or Fillable.FILLTYPE_UNKNOWN]:getCapacity()
end;

function UniversalProcessKitStorageController:createStorageBit(fillType, capacity)
	print('UniversalProcessKitStorageController:createStorageBit('..tostring(fillType)..', '..tostring(capacity)..')')
	if rawget(self.storageBits, fillType)==nil then
		print('created storage bit')
		local storageBit = UniversalProcessKitStorageBit:new(fillType, capacity or self.capacity) -- create new storageBit
		rawset(self.storageBits, fillType, storageBit)
		print('creating successful? '..tostring(rawget(self.storageBits, fillType)~=nil))
	end
end
		