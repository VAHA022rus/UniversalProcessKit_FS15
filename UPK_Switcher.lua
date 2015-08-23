-- by mor2000

--------------------
-- Switcher


local UPK_Switcher_mt = ClassUPK(UPK_Switcher, UniversalProcessKit)
InitObjectClass(UPK_Switcher, "UPK_Switcher")
UniversalProcessKit.addModule("switcher",UPK_Switcher)

UPK_Switcher.MODE_SWITCH = 1
UPK_Switcher.MODE_STACK = 2
UPK_Switcher.MODE_STACKREVERSE = 3
UPK_Switcher.MODE_MATERIAL = 4
UPK_Switcher.MODE_SILENT = 5

function UPK_Switcher:new(nodeId,parent)
	printFn('UPK_Switcher:new(',nodeId,', ',parent,')')
	local self = UniversalProcessKit:new(nodeId,parent, UPK_Switcher_mt)
	registerObjectClassName(self, "UPK_Switcher")

	
	self.hidingPosition = getVectorFromUserAttribute(nodeId, "hidingPosition", "0 -10 0")
	
	self.maxCapacity = 0
	self.fillLevelsCopy = {}
	
	-- fill types
	
	self.switchAtFillTypes={}
	
	local switchAtFillTypesArr = getArrayFromUserAttribute(nodeId, "fillTypes")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(switchAtFillTypesArr)) do
		local flbs = self:getFillLevelBubbleShellFromFillType(fillType)
		if flbs~=nil and flbs~=self then
			flbs:registerOnFillLevelChangeFunc(self,"onFillLevelChange")
		end
		self:printAll('listening to ',fillType)
		self.switchAtFillTypes[fillType] = true
		self.fillLevelsCopy[fillType] = self:getFillLevel(fillType)
		self.maxCapacity = mathmax(self.maxCapacity, self:getCapacity(fillType) or 0)
		self:printAll('fillLevel is ',self:getFillLevel(fillType))
		self:printAll('capacity is ',self:getCapacity(fillType))
	end
	
	self.fillTypeChoiceMax = getStringFromUserAttribute(nodeId, "fillTypeChoice", "max")=="max"
	
	
	-- get materials
	
	self.switchMaterials = {}
	local nrMaterials = getNumMaterials(nodeId) or 0
	for i=1,nrMaterials do
		local materialId = getMaterial(nodeId, (i-1))
		table.insert(self.switchMaterials,materialId)
	end
	
	-- shapes
	
	self.switchFillTypeShapes={}
	self.shapePositions={}
	
	self.useFillTypes=false
    local fillTypeString = getStringFromUserAttribute(nodeId, "switchFillTypes")
	if fillTypeString~=nil then
		local modeStr = getStringFromUserAttribute(nodeId, "mode", "switch")
		if modeStr=="material" then
			self.mode = UPK_Switcher.MODE_MATERIAL
		elseif modeStr=="silent" then
			self.mode = UPK_Switcher.MODE_SILENT
		else
			self.mode = UPK_Switcher.MODE_SWITCH
		end
		
		if self.mode == UPK_Switcher.MODE_MATERIAL then
			self:printInfo("#self.switchMaterials ",#self.switchMaterials)
			self:printInfo("#self.maxfillLevelPerShape ",#self.maxfillLevelPerShape)
			
			local fillTypesPerShape=Utils.splitString(",",fillTypeString)
			for i=1,mathmin(#self.switchMaterials,#fillTypesPerShape) do
				local fillTypesInShape=gmatch(fillTypesPerShape[i], "%S+")
				for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(fillTypesInShape)) do
					local flbs = self:getFillLevelBubbleShellFromFillType(fillType)
					if flbs~=nil and flbs~=self then
						flbs:registerOnFillLevelChangeFunc(self,"onFillLevelChange")
					end
					self:printInfo("assigning "..tostring(UniversalProcessKit.fillTypeIntToName[fillType])..' ('..tostring(v)..") to material "..tostring(i))
					--self.fillLevelsCopy[fillType] = self:getFillLevel(fillType)
					self.switchAtFillTypes[fillType] = true
					self.switchFillTypeShapes[fillType] = i
					self.useFillTypes=true
				end
			end
		elseif self.mode~=UPK_Switcher.MODE_SILENT then
			local fillTypesPerShape=Utils.splitString(",",fillTypeString)
			local numChildren = getNumOfChildren(self.nodeId)
			for i=1,mathmin(numChildren,#fillTypesPerShape) do
				local childId = getChildAt(nodeId, i-1)
				setVisibility(childId,false)
				self.shapePositions[childId]=__c({getTranslation(childId)})
				UniversalProcessKit.setTranslation(childId,unpack(self.shapePositions[childId]+self.hidingPosition))
				local fillTypesInShape=gmatch(fillTypesPerShape[i], "%S+")
				for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(fillTypesInShape)) do
					local flbs = self:getFillLevelBubbleShellFromFillType(fillType)
					if flbs~=nil and flbs~=self then
						flbs:registerOnFillLevelChangeFunc(self,"onFillLevelChange")
					end
					self:printInfo("assigning "..tostring(UniversalProcessKit.fillTypeIntToName[fillType])..' ('..tostring(v)..") to ".."\""..tostring(getName(childId)).."\" ("..tostring(childId)..")")
					--self.fillLevelsCopy[fillType] = self:getFillLevel(fillType)
					self.switchAtFillTypes[fillType] = true
					self.switchFillTypeShapes[fillType]=childId
					self.useFillTypes=true
				end
			end
		else
			local fillTypesPerShape=Utils.splitString(",",fillTypeString)
			for i=1,#fillTypesPerShape do
				local fillTypesInShape=gmatch(fillTypesPerShape[i], "%S+")
				for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(fillTypesInShape)) do
					local flbs = self:getFillLevelBubbleShellFromFillType(fillType)
					if flbs~=nil and flbs~=self then
						flbs:registerOnFillLevelChangeFunc(self,"onFillLevelChange")
					end
					self:printInfo("assigning "..tostring(UniversalProcessKit.fillTypeIntToName[fillType])..' ('..tostring(v)..") to dummy "..tostring(i))
					--self.fillLevelsCopy[fillType] = self:getFillLevel(fillType)
					self.switchAtFillTypes[fillType] = true
					self.switchFillTypeShapes[fillType] = i
					self.useFillTypes=true
				end
			end
		end
	end
	
	self.switchFillLevels={}
	self.maxfillLevelPerShape={}
	self.useFillLevels=false
    local fillLevelString = getStringFromUserAttribute(nodeId, "switchFillLevels")
	if fillLevelString~=nil then
		local modeStr = getStringFromUserAttribute(nodeId, "mode", "switch")
		if modeStr=="stack" then
			self.mode = UPK_Switcher.MODE_STACK
		elseif modeStr=="stackReverse" then
			self.mode = UPK_Switcher.MODE_STACKREVERSE
		elseif modeStr=="material" then
			self.mode = UPK_Switcher.MODE_MATERIAL
		elseif modeStr=="silent" then
			self.mode = UPK_Switcher.MODE_SILENT
		else
			self.mode = UPK_Switcher.MODE_SWITCH
		end
				
		local tmparr = Utils.splitString(" ",fillLevelString)
		for i=1,#tmparr do
			local maxFillLevel=tonumber(tmparr[i])
			if maxFillLevel~=nil then
				table.insert(self.maxfillLevelPerShape,maxFillLevel)
			else
				self:printInfo('Warning: couldn\'t convert \"'..tostring(v)..'\" to number')
			end
		end
		table.insert(self.maxfillLevelPerShape,math.huge)
		if self.mode == UPK_Switcher.MODE_MATERIAL then
			self:printInfo("#self.switchMaterials "..tostring(#self.switchMaterials))
			self:printInfo("#self.maxfillLevelPerShape "..tostring(#self.maxfillLevelPerShape))
			
			for i=1,mathmin(#self.switchMaterials,#self.maxfillLevelPerShape) do
				-- nothing to do
				self:printInfo("assigning max fillLevel of "..tostring(self.maxfillLevelPerShape[i]).." to material "..tostring(self.switchMaterials[i]))
				self.useFillLevels=true
			end
		elseif self.mode~=UPK_Switcher.MODE_SILENT then
			local numChildren = mathmin(getNumOfChildren(nodeId),#self.maxfillLevelPerShape)
			for i=1,numChildren do
				local childId = getChildAt(self.nodeId, i-1)
				setVisibility(childId,false)
				self.shapePositions[childId]=__c({getTranslation(childId)})
				UniversalProcessKit.setTranslation(childId,unpack(self.shapePositions[childId]+self.hidingPosition))
				table.insert(self.switchFillLevels,childId)
				self:printInfo("assigning max fillLevel of "..tostring(self.maxfillLevelPerShape[i]).." to ".."\""..tostring(getName(childId)).."\" ("..tostring(childId)..")")
				self.useFillLevels=true
			end
		else
			self.useFillLevels=true
		end
	end
	
	if (self.useFillTypes and self.useFillLevels) or (not self.useFillTypes and not self.useFillLevels) then
		self:printErr('Error: switcher requires to set either switchFillTypes or switchFillLevels')
		return false
	end
	
	self:getActionUserAttributes('OnSwitchUp')
	self:getActionUserAttributes('OnSwitchDown')
	
	self:printFn('UPK_Switcher:new done')
    
	return self
end

function UPK_Switcher:delete()
	self:printFn('UPK_Switcher:delete()')
	UPK_Switcher:superClass().delete(self)
end

function UPK_Switcher:postLoad()
	self:printFn('UPK_Switcher:postLoad()')
	UPK_Switcher:superClass().postLoad(self)
	for fillType,_ in pairs(self.fillLevelsCopy) do
		local fillLevel = self:getFillLevel(fillType) or 0
		self.fillLevelsCopy[fillType] = fillLevel
		self:onFillLevelChange(fillLevel, fillLevel, fillType)
	end
end;

function UPK_Switcher:onFillLevelChange(deltaFillLevel, newFillLevel, fillType)
	
	self:printFn('UPK_Switcher:onFillLevelChange(',deltaFillLevel,', ',newFillLevel,', ',fillType,')')
	
	if self.switchAtFillTypes[fillType]==true and self.isEnabled then		
		if self.useFillTypes then
			
			self.fillLevelsCopy[fillType] = newFillLevel -- self:getFillLevel(fillType) -- may not be newFillLevel in fifo or filo
			local useFillType=nil
			local tmpminfillLevel = math.huge
			local tmpmaxfillLevel = 0
			for k,v in pairs(self.switchAtFillTypes) do
				if v then
					local fillLevel = self.fillLevelsCopy[k] or 0
					if self.fillTypeChoiceMax then
						if fillLevel>tmpmaxfillLevel then
							--self:print('new max fill level: '..tostring(fillLevel))
							tmpmaxfillLevel=fillLevel
							useFillType = k
						 end
					else
						if fillLevel<tmpminfillLevel then
							tmpminfillLevel=fillLevel
							useFillType = k
						end
					end
				end
			end
			--self:print('usefilltype is '..tostring(useFillType))
			if useFillType~=nil then
				local shapeToShow=nil
				if fillType~=nil and fillType~=UniversalProcessKit.FILLTYPE_UNKNOWN and useFillType~=self.oldFillType then
					shapeToShow=self.switchFillTypeShapes[useFillType]
					--self:print('shapeToShow is '..tostring(shapeToShow))
				end
				if shapeToShow~=nil and shapeToShow~=self.oldShapeToShow then
					if self.mode==UPK_Switcher.MODE_MATERIAL then
						local materialId = self.switchMaterials[shapeToShow]
						setMaterial(self.nodeId, materialId)
					elseif self.mode~=UPK_Switcher.MODE_SILENT then
						if self.oldShapeToShow~=nil then
							setVisibility(self.oldShapeToShow,false)
							UniversalProcessKit.setTranslation(self.oldShapeToShow,unpack((self.shapePositions[self.oldShapeToShow]+self.hidingPosition) or {}))
						end
						--self:print('showing '..tostring(shapeToShow))
						setVisibility(shapeToShow,true)
						local x,y,z=unpack(self.shapePositions[shapeToShow] or {})
						if x~=nil and y~=nil and z~=nil then
							UniversalProcessKit.setTranslation(shapeToShow,x,y,z)
						end
					end
					
					if self.oldShapeToShow~=nil then
						if shapeToShow>self.oldShapeToShow then
							self:printAll('OnSwitchUp')
							self:operateAction('OnSwitchUp')
						elseif self.oldShapeToShow>shapeToShow then
							self:printAll('OnSwitchDown')
							self:operateAction('OnSwitchDown')
						end
					end
								
					self.oldShapeToShow=shapeToShow
				end
				self.oldFillType=useFillType
			else
				if self.mode~=UPK_Switcher.MODE_MATERIAL and self.mode~=UPK_Switcher.MODE_SILENT then
					if self.oldShapeToShow~=nil then
						setVisibility(self.oldShapeToShow,false)
						UniversalProcessKit.setTranslation(self.oldShapeToShow,unpack((self.shapePositions[self.oldShapeToShow]+self.hidingPosition) or {}))
						self.oldShapeToShow=nil
						self.oldFillType=nil
					end
				end
			end
		elseif self.useFillLevels then
			self.fillLevelsCopy[fillType] = newFillLevel -- self:getFillLevel(fillType) -- may not be newFillLevel in fifo or filo
			--self:print('self.fillLevelsCopy[fillType] '..tostring(self.fillLevelsCopy[fillType]))
			local fillLevel = 0
			if self.fillTypeChoiceMax then
				fillLevel = max(self.fillLevelsCopy) or 0
			else
				fillLevel = min(self.fillLevelsCopy) or 0
			end
			if fillLevel ~= self.currentFillLevel then
				self:printAll('fillLevel ~= self.currentFillLevel')
				local newShapeToShow=self:getShapeFromFillLevel(fillLevel)
				
				self:printAll('self.oldShapeToShow ',self.oldShapeToShow)
				self:printAll('newShapeToShow ',newShapeToShow)
				if newShapeToShow~=nil and newShapeToShow~=self.oldShapeToShow then
					if self.mode==UPK_Switcher.MODE_MATERIAL then
						local materialId = self.switchMaterials[newShapeToShow]
						self:printAll('set to materialId ',materialId)
						setMaterial(self.nodeId, materialId)
					elseif self.mode~=UPK_Switcher.MODE_SILENT then	
						local newShapeId=self.switchFillLevels[newShapeToShow]
						setVisibility(newShapeId,true)
						UniversalProcessKit.setTranslation(newShapeId,unpack((self.shapePositions[newShapeId]) or {}))
						if self.oldShapeToShow~=nil then
							if self.mode==UPK_Switcher.MODE_SWITCH then
								local shapeId=self.switchFillLevels[self.oldShapeToShow]
								setVisibility(shapeId,false)
								UniversalProcessKit.setTranslation(shapeId,unpack((self.shapePositions[shapeId]+self.hidingPosition) or {}))
							elseif self.mode==UPK_Switcher.MODE_STACK then
								if newShapeToShow<self.oldShapeToShow then
									for i=self.oldShapeToShow,(newShapeToShow+1),-1 do
										local shapeId=self.switchFillLevels[i]
										setVisibility(shapeId,false)
										UniversalProcessKit.setTranslation(shapeId,unpack((self.shapePositions[shapeId]+self.hidingPosition) or {}))
									end
								end
							elseif self.mode==UPK_Switcher.MODE_STACKREVERSE then
								if newShapeToShow>self.oldShapeToShow then
									for i=self.oldShapeToShow,(newShapeToShow-1) do
										local shapeId=self.switchFillLevels[i]
										setVisibility(shapeId,false)
										UniversalProcessKit.setTranslation(shapeId,unpack((self.shapePositions[shapeId]+self.hidingPosition) or {}))
									end
								end
							end
						else
							if self.mode==UPK_Switcher.MODE_STACK then
								for i=1,(newShapeToShow-1) do
									local shapeId=self.switchFillLevels[i]
									setVisibility(shapeId,true)
									UniversalProcessKit.setTranslation(shapeId,unpack((self.shapePositions[shapeId]) or {}))
								end
							elseif self.mode==UPK_Switcher.MODE_STACKREVERSE then
								for i=getShapeFromFillLevel(math.huge),(newShapeToShow+1),-1 do
									local shapeId=self.switchFillLevels[i]
									setVisibility(shapeId,true)
									UniversalProcessKit.setTranslation(shapeId,unpack((self.shapePositions[shapeId]) or {}))
								end
							end
						end
					end
					
					if self.oldShapeToShow~=nil then
						if newShapeToShow>self.oldShapeToShow then
							self:printAll('OnSwitchUp')
							self:operateAction('OnSwitchUp')
						elseif self.oldShapeToShow>newShapeToShow then
							self:printAll('OnSwitchDown')
							self:operateAction('OnSwitchDown')
						end
					end
					
					self.oldShapeToShow=newShapeToShow
				end
				self.currentFillLevel=fillLevel
			end			
		end
	end
end

function UPK_Switcher:getShapeFromFillLevel(fillLevel)
	self:printFn('UPK_Switcher:getShapeFromFillLevel(',fillLevel,')')
	for i=1,#self.maxfillLevelPerShape do
		if fillLevel<self.maxfillLevelPerShape[i] then
			return i
		end
	end
	return nil
end
