-- by mor2000

--------------------
-- Mover (changes translation, rotation and visibility of objects)


local UPK_Mover_mt = ClassUPK(UPK_Mover, UniversalProcessKit)
InitObjectClass(UPK_Mover, "UPK_Mover")
UniversalProcessKit.addModule("mover",UPK_Mover)

function UPK_Mover:new(nodeId,parent)
	printFn('UPK_Mover:new(',nodeId,', ',parent,')')
	local self = UniversalProcessKit:new(nodeId,parent, UPK_Mover_mt)
	registerObjectClassName(self, "UPK_Mover")
	
	self.maxCapacity = 0
	self.fillLevelsCopy = {}
	self.currentFillLevel = nil
	
	-- fill types
	
	self.moveAtFillTypes={}
	
	local moveAtFillTypesArr = getArrayFromUserAttribute(nodeId, "fillTypes")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(moveAtFillTypesArr)) do
		self:printAll('fillType is ',fillType)
		local flbs = self:getFillLevelBubbleShellFromFillType(fillType)
		self:printAll('flbs is ',flbs)
		if flbs~=nil and flbs~=self then
			flbs:registerOnFillLevelChangeFunc(self,"onFillLevelChange")
		end
		self:printAll('accepting fillType ',fillType)
		self.moveAtFillTypes[fillType] = true
		self.fillLevelsCopy[fillType] = self:getFillLevel(fillType)
		self.maxCapacity = mathmax(self.maxCapacity, self:getCapacity(fillType) or 0)
		self:printAll('fillLevel is ',self:getFillLevel(fillType))
		self:printAll('capacity is ',self:getCapacity(fillType))
	end
	
	self.fillTypeChoiceMax = getStringFromUserAttribute(nodeId, "fillTypeChoice", "max")=="max"
	
	-- move
	
	self.useMoving=false
	self.startMovingAt = getNumberFromUserAttribute(nodeId, "startMovingAt", 0)
	self.stopMovingAt = getNumberFromUserAttribute(nodeId, "stopMovingAt", self.maxCapacity, self.startMovingAt)
	
	local posMin = getVectorFromUserAttribute(nodeId, "lowPosition", "0 0 0")
	self.posMin = self.pos + posMin
	local posMax = getVectorFromUserAttribute(nodeId, "highPosition", posMin)
	self.posMax = self.pos + posMax
	local posLower = getVectorFromUserAttribute(nodeId, "lowerPosition", posMin)
	local posHigher = getVectorFromUserAttribute(nodeId, "higherPosition", posMax)
	self.posLower = self.pos + posLower
	self.posHigher = self.pos + posHigher
	self.movingType = getStringFromUserAttribute(nodeId, "movingType", "linear")
	
	if posMin[1]~=0 or posMin[2]~=0 or posMin[3]~=0 or
		posMax[1]~=0 or posMax[2]~=0 or posMax[3]~=0 or
		posLower[1]~=0 or posLower[2]~=0 or posLower[3]~=0 or
		posHigher[1]~=0 or posHigher[2]~=0 or posHigher[3]~=0 then
		self.useMoving=true
	end
	
	-- scale
	
	self.useScaling=false
	self.startScalingAt = getNumberFromUserAttribute(nodeId, "startScalingAt", 0)
	self.stopScalingAt = getNumberFromUserAttribute(nodeId, "stopScalingAt", self.maxCapacity, self.startScalingAt)
	
	local scaleMin = getVectorFromUserAttribute(nodeId, "lowScale", "0 0 0")
	self.scaleMin = self.scale + scaleMin
	local scaleMax = getVectorFromUserAttribute(nodeId, "highScale", scaleMin)
	self.scaleMax = self.scale + scaleMax
	local scaleLower = getVectorFromUserAttribute(nodeId, "lowerScale", scaleMin)
	local scaleHigher = getVectorFromUserAttribute(nodeId, "higherScale", scaleMax)
	self.scaleLower = self.scale + scaleLower
	self.scaleHigher = self.scale + scaleHigher
	self.scalingType = getStringFromUserAttribute(nodeId, "scalingType", "linear")
	
	if scaleMin[1]~=0 or scaleMin[2]~=0 or scaleMin[3]~=0 or
		scaleMax[1]~=0 or scaleMax[2]~=0 or scaleMax[3]~=0 or
		scaleLower[1]~=0 or scaleLower[2]~=0 or scaleLower[3]~=0 or
		scaleHigher[1]~=0 or scaleHigher[2]~=0 or scaleHigher[3]~=0 then
		self.useScaling=true
	end
	
	-- turn
	
	self.useRotation=false
	
	self.startTurningAt = getNumberFromUserAttribute(nodeId, "startTurningAt", 0)
	self.stopTurningAt = getNumberFromUserAttribute(nodeId, "stopTurningAt", self.maxCapacity, self.startTurningAt)
	
	local rotMin = getVectorFromUserAttribute(nodeId, "lowRotation", "0 0 0")
	self.rotMin = rotMin*(2*math.pi)
	local rotMax = getVectorFromUserAttribute(nodeId, "highRotation", rotMin)
	self.rotMax = rotMax*(2*math.pi)
	local rotLower = getVectorFromUserAttribute(nodeId, "lowerRotation", rotMin)
	local rotHigher = getVectorFromUserAttribute(nodeId, "higherRotation", rotMax)
	self.rotLower = rotLower*(2*math.pi)
	self.rotHigher = rotHigher*(2*math.pi)
	self.turningType = getStringFromUserAttribute(nodeId, "turningType", "linear")
	
	if rotMin[1]~=0 or rotMin[2]~=0 or rotMin[3]~=0 or
		rotMax[1]~=0 or rotMax[2]~=0 or rotMax[3]~=0 or
		rotLower[1]~=0 or rotLower[2]~=0 or rotLower[3]~=0 or
		rotHigher[1]~=0 or rotHigher[2]~=0 or rotHigher[3]~=0 then
		self.useRotation=true
	end
	
	-- visibility
	
	self.startVisibilityAt = getNumberFromUserAttribute(nodeId, "startVisibilityAt", -1)
	self.stopVisibilityAt = getNumberFromUserAttribute(nodeId, "stopVisibilityAt", self.maxCapacity+1)
	
	self.showingType = self.startVisibilityAt<=self.stopVisibilityAt
	
	self:printFn('UPK_Mover:new done')
   
   	return self
end

function UPK_Mover:delete()
	self:printFn('UPK_Mover:delete()')
	UPK_Mover:superClass().delete(self)
end

function UPK_Mover:postLoad()
	self:printFn('UPK_Mover:postLoad()')
	UPK_Mover:superClass().postLoad(self)
	for fillType,_ in pairs(self.fillLevelsCopy) do
		local fillLevel = self:getFillLevel(fillType) or 0
		self.fillLevelsCopy[fillType] = fillLevel
		self:onFillLevelChange(fillLevel, fillLevel, fillType)
	end
end;

function UPK_Mover:onFillLevelChange(deltaFillLevel, newFillLevel, fillType) -- to be overwritten
	
	self:printFn('UPK_Mover:onFillLevelChange(',deltaFillLevel,', ',newFillLevel,', ',fillType,')')
	
	if self.moveAtFillTypes[fillType]==true and self.isEnabled then		
		self.fillLevelsCopy[fillType] = newFillLevel -- self:getFillLevel(fillType) -- may not be newFillLevel in fifo or filo
		self:printAll('self.fillLevelsCopy[fillType] '..tostring(self.fillLevelsCopy[fillType]))
		local fillLevel = 0
		if self.fillTypeChoiceMax then
			fillLevel = max(self.fillLevelsCopy) or 0
		else
			fillLevel = min(self.fillLevelsCopy) or 0
		end

		if fillLevel ~= self.currentFillLevel then
			self:printAll('fillLevel = ',fillLevel)
			-- move
			if self.useMoving then
				if fillLevel <= self.startMovingAt then -- startMovingAt included in posLower
					self:printAll('fillLevel <= self.startMovingAt')
					self.pos=self.posLower
				elseif fillLevel > self.stopMovingAt then
					self:printAll('fillLevel > self.stopMovingAt')
					self.pos=self.posHigher
				else
					self:printAll('getRatio()')
					local ratio=self:getRatio("pos",self.movingType,fillLevel,self.startMovingAt,self.stopMovingAt)
					self.pos=self.posMin+(self.posMax-self.posMin)*ratio
				end
				self:printAll('want to move shape to y=',self.pos[2])
				UniversalProcessKit.setTranslation(self.nodeId,unpack(self.pos))
			end
			
			-- scale
			if self.useScaling then
				if fillLevel <= self.startScalingAt then -- startScalingAt included in scaleLower
					self:printAll('fillLevel <= self.startScalingAt')
					self.scale=self.scaleLower
				elseif fillLevel > self.stopScalingAt then
					self:printAll('fillLevel > self.stopScalingAt')
					self.scale=self.scaleHigher
				else
					self:printAll('getRatio()')
					local ratio=self:getRatio("scale",self.scalingType,fillLevel,self.startScalingAt,self.stopScalingAt)
					self.scale=self.scaleMin+(self.scaleMax-self.scaleMin)*ratio
				end
				self:printAll('want to scale shape to y=',self.scale[2])
				setScale(self.nodeId,unpack(self.scale))
			end
		
			-- turn
			if self.useRotation then
				if fillLevel <= self.startTurningAt then -- startTurningAt included in rotLower
					self.rotStep = self.rotLower
				elseif fillLevel > self.stopTurningAt then
					self.rotStep = self.rotHigher
				else
					local rotRatio=self:getRatio("rot",self.turningType,fillLevel,self.startTurningAt,self.stopTurningAt)
					self.rotStep=self.rotMin+(self.rotMax-self.rotMin)*rotRatio
				end	
				setRotation(self.nodeId, unpack(self.rotStep))
			end
		
			local show = false
			if self.showingType and fillLevel > self.startVisibilityAt and fillLevel < self.stopVisibilityAt then
				show = true
			elseif not self.showingType and (fillLevel > self.startVisibilityAt or fillLevel < self.stopVisibilityAt) then
				show = true
			end
		
			if show~=self.currentVisibility then
				setVisibility(self.nodeId,show)
				self.currentVisibility = show
			end
		
			self.currentFillLevel = fillLevel
			
		end
	end
end

function UPK_Mover:getRatio(use,type,fillLevel,minFillLevel,maxFillLevel)
	self:printFn('UPK_Mover:getRatio(',use,',',type,', ',fillLevel,', ',minFillLevel,', ',maxFillLevel,')')
	if minFillLevel==nil or maxFillLevel==nil or minFillLevel<0 or maxFillLevel<0 then
		return 0
	end
	local dividend
	if self.ratioMaxFillLevel==nil then
		self.ratioMaxFillLevel={}
	end
	if self.ratioMaxFillLevel[use]== nil then
		self.ratioMaxFillLevel[use]={}
		self.ratioMaxFillLevel[use].sphere=((maxFillLevel-minFillLevel)/(4/3*math.pi))^(1/3)
		self.ratioMaxFillLevel[use].cone=((maxFillLevel-minFillLevel)/(1/3*math.pi))^(1/3)
		self.ratioMaxFillLevel[use].square=(maxFillLevel-minFillLevel)^(1/2)
		self.ratioMaxFillLevel[use].circle=((maxFillLevel-minFillLevel)/math.pi)^(1/2)
		self.ratioMaxFillLevel[use].sinus=1
		self.ratioMaxFillLevel[use].linear=maxFillLevel-minFillLevel
	end
	if type=="sphere" then
		dividend=((fillLevel-minFillLevel)/(4/3*math.pi))^(1/3)
	elseif type=="cone" then
		dividend=((fillLevel-minFillLevel)/(1/3*math.pi))^(1/3)
	elseif type=="square" then
		dividend=(fillLevel-minFillLevel)^(1/2)
	elseif type=="circle" then
		dividend=((fillLevel-minFillLevel)/math.pi)^(1/2)
	elseif type=="sinus" then
		dividend=math.sin((fillLevel-minFillLevel)/(maxFillLevel-minFillLevel)*math.pi)
	else
		type="linear"
		dividend=fillLevel-minFillLevel
	end
	return dividend/self.ratioMaxFillLevel[use][type]
end

