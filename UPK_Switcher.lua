-- by mor2000

--------------------
-- Switcher


local UPK_Switcher_mt = ClassUPK(UPK_Switcher, UniversalProcessKit)
InitObjectClass(UPK_Switcher, "UPK_Switcher")
UniversalProcessKit.addModule("switcher",UPK_Switcher)

function UPK_Switcher:new(id,parent)
	local self = UniversalProcessKit:new(id,parent, UPK_Switcher_mt)
	registerObjectClassName(self, "UPK_Switcher")

	
	self.hidingPosition = getVectorFromUserAttribute(self.nodeId, "hidingPosition", "0 -10 0")
	
	self.maxCapacity = 0
	self.fillLevelsCopy = {}
	
	-- fill types
	
	self.switchAtFillTypes={}
	
	local switchAtFillTypesArr = getArrayFromUserAttribute(id, "fillTypes")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(switchAtFillTypesArr)) do
		local flbs = self:getFillLevelBubbleShellFromFillType(fillType)
		if flbs~=nil and flbs~=self then
			flbs:registerOnFillLevelChangeFunc(self,"onFillLevelChange")
		end
		self:print('accepting fillType '..tostring(fillType))
		self.switchAtFillTypes[fillType] = true
		self.fillLevelsCopy[fillType] = self:getFillLevel(fillType)
		self.maxCapacity = mathmax(self.maxCapacity, self:getCapacity(fillType) or 0)
		self:print('fillLevel is '..tostring(self:getFillLevel(fillType)))
		self:print('capacity is '..tostring(self:getCapacity(fillType)))
	end
	
	self.fillTypeChoiceMax = getStringFromUserAttribute(id, "fillTypeChoice", "max")=="max"
	
	-- shapes
	
	self.switchFillTypeShapes={}
	self.shapePositions={}
	
	self.useFillTypes=false
    local fillTypeString = Utils.getNoNil(getUserAttribute(id, "switchFillTypes"))
	if fillTypeString~=nil then
		local fillTypesPerShape=Utils.splitString(",",fillTypeString)
		local numChildren = getNumOfChildren(self.nodeId)
		for i=1,mathmin(numChildren,#fillTypesPerShape) do
			local childId = getChildAt(id, i-1)
			setVisibility(childId,false)
			self.shapePositions[childId]=__c({getTranslation(childId)})
			UniversalProcessKit.setTranslation(childId,unpack(self.shapePositions[childId]+self.hidingPosition))
			local fillTypesInShape=gmatch(fillTypesPerShape[i], "%S+")
			for _,v in pairs(UniversalProcessKit.fillTypeNameToInt(fillTypesInShape)) do
				self:print("assigning "..tostring(UniversalProcessKit.fillTypeIntToName[v])..' ('..tostring(v)..") to ".."\""..tostring(getName(childId)).."\" ("..tostring(childId)..")")
				self.switchFillTypeShapes[v]=childId
				self.useFillTypes=true
			end
		end
	end
	
	self.switchFillLevels={}
	self.maxfillLevelPerShape={}
	self.useFillLevels=false
    local fillLevelString = Utils.getNoNil(getUserAttribute(id, "switchFillLevels"))
	if fillLevelString~=nil then
		for _,v in pairs(Utils.splitString(" ",fillLevelString)) do
			local maxFillLevel=tonumber(v)
			if maxFillLevel~=nil then
				table.insert(self.maxfillLevelPerShape,maxFillLevel)
			else
				self:print('Warning: couldn\'t convert \"'..tostring(v)..'\" to number')
			end
		end
		table.insert(self.maxfillLevelPerShape,math.huge)
		local numChildren = getNumOfChildren(self.nodeId)
		for i=1,numChildren do
			local childId = getChildAt(self.nodeId, i-1)
			setVisibility(childId,false)
			self.shapePositions[childId]=__c({getTranslation(childId)})
			UniversalProcessKit.setTranslation(childId,unpack(self.shapePositions[childId]+self.hidingPosition))
			table.insert(self.switchFillLevels,childId)
			self:print("assigning max fillLevel of "..tostring(self.maxfillLevelPerShape[i]).." to ".."\""..tostring(getName(childId)).."\" ("..tostring(childId)..")")
			self.useFillLevels=true
		end
	end
	
	if (self.useFillTypes and self.useFillLevels) or (not self.useFillTypes and not self.useFillLevels) then
		self:print('Error: switcher requires to set either switchFillTypes or switchFillLevels')
		return false
	end
	
	local modeStr = getStringFromUserAttribute(self.nodeId, "mode", "switch")
	if modeStr=="stack" or modeStr=="stackReverse" then
		self.mode=modeStr
	else
		self.mode="switch"
	end
	
	self.oldFillType=nil

	self:print('loaded Switcher successfully')
    
	return self
end

function UPK_Switcher:delete()
	UPK_Switcher:superClass().delete(self)
end

function UPK_Switcher:postLoad()
	self:print('UPK_Switcher:postLoad()')
	UPK_Switcher:superClass().postLoad(self)
	for fillType,_ in pairs(self.fillLevelsCopy) do
		local fillLevel = self:getFillLevel(fillType) or 0
		self.fillLevelsCopy[fillType] = fillLevel
		self:onFillLevelChange(fillLevel, fillLevel, fillType)
	end
end;

function UPK_Switcher:onFillLevelChange(deltaFillLevel, newFillLevel, fillType) -- to be overwritten
	
	self:print('UPK_Switcher:onFillLevelChange('..tostring(deltaFillLevel)..', '..tostring(newFillLevel)..', '..tostring(fillType)..')')
	
	if self.switchAtFillTypes[fillType]==true and self.isClient and self.isEnabled then		
		if self.useFillTypes then
			local fillType=self.fillType
			local shapeToShow=nil
			if fillType~=nil and fillType~=Fillable.FILLTYPE_UNKNOWN and fillType~=self.oldFillType then
				shapeToShow=self.switchFillTypeShapes[fillType]
			end
			if shapeToShow~=nil and shapeToShow~=self.oldShapeToShow then
				if self.oldShapeToShow~=nil then
					setVisibility(self.oldShapeToShow,false)
					UniversalProcessKit.setTranslation(self.oldShapeToShow,unpack((self.shapePositions[self.oldShapeToShow]+self.hidingPosition) or {}))
				end
				setVisibility(shapeToShow,true)
				local x,y,z=unpack(self.shapePositions[shapeToShow] or {})
				if x~=nil and y~=nil and z~=nil then
					UniversalProcessKit.setTranslation(shapeToShow,x,y,z)
				end
				self.oldShapeToShow=shapeToShow
			end
			self.oldFillType=fillType
		elseif self.useFillLevels then
			self.fillLevelsCopy[fillType] = newFillLevel -- self:getFillLevel(fillType) -- may not be newFillLevel in fifo or filo
			self:print('self.fillLevelsCopy[fillType] '..tostring(self.fillLevelsCopy[fillType]))
			local fillLevel = 0
			if self.fillTypeChoiceMax then
				fillLevel = max(self.fillLevelsCopy) or 0
			else
				fillLevel = min(self.fillLevelsCopy) or 0
			end
			if fillLevel ~= self.currentFillLevel then
				self:print("fillLevel ~= self.currentFillLevel")
				for i=1,#self.maxfillLevelPerShape do
					if self.maxfillLevelPerShape[i]>=fillLevel then
						shapeToShow=self.switchFillLevels[i]
						shapeToShowIndex=i
						break
					end
				end
			end
			self:print("shapeToShowIndex="..tostring(shapeToShowIndex))
			self:print("shapeToShow="..tostring(shapeToShow))
			self:print("self.oldShapeToShow="..tostring(self.oldShapeToShow))
			if shapeToShow~=nil and shapeToShow~=self.oldShapeToShow then
				self:print("self.oldShapeToShowIndex="..tostring(self.oldShapeToShowIndex))
				if self.mode=="stack" then
					self:print("mode=stack")
					local oldShapeToShowIndex = self.oldShapeToShowIndex or 0
					if oldShapeToShowIndex>shapeToShowIndex then
						for i=(shapeToShowIndex+1),oldShapeToShowIndex do
							self:print('hiding node '..tostring(self.switchFillLevels[i]))
							setVisibility(self.switchFillLevels[i],false)
							UniversalProcessKit.setTranslation(self.switchFillLevels[i],unpack((self.shapePositions[self.switchFillLevels[i]]+self.hidingPosition) or {}))
						end
					else
						for i=(oldShapeToShowIndex+1),shapeToShowIndex do
							self:print('showing node '..tostring(self.switchFillLevels[i]))
							setVisibility(self.switchFillLevels[i],true)
							UniversalProcessKit.setTranslation(self.switchFillLevels[i],unpack(self.shapePositions[self.switchFillLevels[i]] or {}))
						end
					end
				elseif self.mode=="stackReverse" then --wrecked
					self:print("mode=stackReverse")
					local oldShapeToShowIndex = self.oldShapeToShowIndex or #self.switchFillLevels
					if oldShapeToShowIndex>shapeToShowIndex then
						for i=shapeToShowIndex,(oldShapeToShowIndex-1) do
							self:print('showing node '..tostring(self.switchFillLevels[i]))
							setVisibility(self.switchFillLevels[i],true)
							UniversalProcessKit.setTranslation(self.switchFillLevels[i],unpack(self.shapePositions[self.switchFillLevels[i]] or {}))
							
						end
					else
						for i=oldShapeToShowIndex,(shapeToShowIndex-1) do
							self:print('hiding node '..tostring(self.switchFillLevels[i]))
							setVisibility(self.switchFillLevels[i],false)
							UniversalProcessKit.setTranslation(self.switchFillLevels[i],unpack((self.shapePositions[self.switchFillLevels[i]]+self.hidingPosition) or {}))
						end
					end
				else
					if self.oldShapeToShow~=nil then
						setVisibility(self.oldShapeToShow,false)
						UniversalProcessKit.setTranslation(self.oldShapeToShow,unpack((self.shapePositions[self.oldShapeToShow]+self.hidingPosition) or {}))
					end
					setVisibility(shapeToShow,true)
					UniversalProcessKit.setTranslation(shapeToShow,unpack(self.shapePositions[shapeToShow] or {}))
				end
				
				self.oldShapeToShow=shapeToShow
				self.oldShapeToShowIndex=shapeToShowIndex
				self.currentFillLevel=fillLevel
			end
		end
	end
end