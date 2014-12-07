-- by mor2000

--------------------
-- Mover (changes translation, rotation and visibility of objects)


local UPK_Mover_mt = ClassUPK(UPK_Mover, UniversalProcessKit)
InitObjectClass(UPK_Mover, "UPK_Mover")
UniversalProcessKit.addModule("mover",UPK_Mover)

function UPK_Mover:new(id,parent)
	local self = UniversalProcessKit:new(id,parent, UPK_Mover_mt)
	registerObjectClassName(self, "UPK_Mover")
	
	self.maxCapacity = 0
	self.fillLevelsCopy = {}
	self.currentFillLevel = nil
	
	-- fill types
	
	self.moveAtFillTypes={}
	
	local moveAtFillTypesArr = getArrayFromUserAttribute(id, "fillTypes")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(moveAtFillTypesArr)) do
		local flbs = self:getFillLevelBubbleShellFromFillType(fillType)
		if flbs~=nil and flbs~=self then
			flbs:registerOnFillLevelChangeFunc(self,"onFillLevelChange")
		end
		self:print('accepting fillType '..tostring(fillType))
		self.moveAtFillTypes[fillType] = true
		self.fillLevelsCopy[fillType] = self:getFillLevel(fillType)
		self.maxCapacity = mathmax(self.maxCapacity, self:getCapacity(fillType) or 0)
		self:print('fillLevel is '..tostring(self:getFillLevel(fillType)))
		self:print('capacity is '..tostring(self:getCapacity(fillType)))
	end
	
	self.fillTypeChoiceMax = getStringFromUserAttribute(id, "fillTypeChoice", "max")=="max"
	
	-- move
	
	self.useMoving=false
	self.startMovingAt = getNumberFromUserAttribute(id, "startMovingAt", 0)
	self.stopMovingAt = getNumberFromUserAttribute(id, "stopMovingAt", self.maxCapacity, self.startMovingAt)
	
	local posMin = getVectorFromUserAttribute(id, "lowPosition", "0 0 0")
	self.posMin = self.pos + posMin
	local posMax = getVectorFromUserAttribute(id, "highPosition", posMin)
	self.posMax = self.pos + posMax
	local posLower = getVectorFromUserAttribute(id, "lowerPosition", posMin)
	local posHigher = getVectorFromUserAttribute(id, "higherPosition", posMax)
	self.posLower = self.pos + posLower
	self.posHigher = self.pos + posHigher
	self.movingType = getStringFromUserAttribute(id, "movingType", "linear")
	
	if posMin[1]~=0 or posMin[2]~=0 or posMin[3]~=0 or
		posMax[1]~=0 or posMax[2]~=0 or posMax[3]~=0 or
		posLower[1]~=0 or posLower[2]~=0 or posLower[3]~=0 or
		posHigher[1]~=0 or posHigher[2]~=0 or posHigher[3]~=0 then
		self.useMoving=true
	end
	
	-- turn
	
	self.useRotation=false
	
	self.startTurningAt = getNumberFromUserAttribute(id, "startTurningAt", 0)
	self.stopTurningAt = getNumberFromUserAttribute(id, "stopTurningAt", self.maxCapacity, self.startTurningAt)
	
	local rotMin = getVectorFromUserAttribute(self.nodeId, "lowRotation", "0 0 0")
	self.rotMin = rotMin*(2*math.pi)
	local rotMax = getVectorFromUserAttribute(self.nodeId, "highRotation", rotMin)
	self.rotMax = rotMax*(2*math.pi)
	local rotLower = getVectorFromUserAttribute(self.nodeId, "lowerRotation", rotMin)
	local rotHigher = getVectorFromUserAttribute(self.nodeId, "higherRotation", rotMax)
	self.rotLower = rotLower*(2*math.pi)
	self.rotHigher = rotHigher*(2*math.pi)
	self.turningType = getStringFromUserAttribute(id, "turningType", "linear")
	
	if rotMin[1]~=0 or rotMin[2]~=0 or rotMin[3]~=0 or
		rotMax[1]~=0 or rotMax[2]~=0 or rotMax[3]~=0 or
		rotLower[1]~=0 or rotLower[2]~=0 or rotLower[3]~=0 or
		rotHigher[1]~=0 or rotHigher[2]~=0 or rotHigher[3]~=0 then
		self.useRotation=true
	end
	
	-- visibility
	
	self.startVisibilityAt = getNumberFromUserAttribute(id, "startVisibilityAt", -1)
	self.stopVisibilityAt = getNumberFromUserAttribute(id, "stopVisibilityAt", self.maxCapacity+1)
	
	self.showingType = self.startVisibilityAt<=self.stopVisibilityAt
	
	self:print('loaded Mover successfully')
   
   	return self
end

function UPK_Mover:delete()
	UPK_Mover:superClass().delete(self)
end

function UPK_Mover:postLoad()
	self:print('UPK_Mover:postLoad()')
	UPK_Mover:superClass().postLoad(self)
	for fillType,_ in pairs(self.fillLevelsCopy) do
		local fillLevel = self:getFillLevel(fillType) or 0
		self.fillLevelsCopy[fillType] = fillLevel
		self:onFillLevelChange(fillLevel, fillLevel, fillType)
	end
end;

function UPK_Mover:onFillLevelChange(deltaFillLevel, newFillLevel, fillType) -- to be overwritten
	
	self:print('UPK_Mover:onFillLevelChange('..tostring(deltaFillLevel)..', '..tostring(newFillLevel)..', '..tostring(fillType)..')')
	
	if self.moveAtFillTypes[fillType]==true and self.isClient and self.isEnabled then		
		self.fillLevelsCopy[fillType] = newFillLevel -- self:getFillLevel(fillType) -- may not be newFillLevel in fifo or filo
		self:print('self.fillLevelsCopy[fillType] '..tostring(self.fillLevelsCopy[fillType]))
		local fillLevel = 0
		if self.fillTypeChoiceMax then
			fillLevel = max(self.fillLevelsCopy) or 0
		else
			fillLevel = min(self.fillLevelsCopy) or 0
		end

		if fillLevel ~= self.currentFillLevel then
			self:print('fillLevel = '..tostring(fillLevel))
			-- move
			if self.useMoving then
				if fillLevel <= self.startMovingAt then -- startMovingAt included in posLower
					self:print('fillLevel <= self.startMovingAt')
					self.pos=self.posLower
				elseif fillLevel > self.stopMovingAt then
					self:print('fillLevel > self.stopMovingAt')
					self.pos=self.posHigher
				else
					self:print('getRatio()')
					local ratio=self:getRatio("pos",self.movingType,fillLevel,self.startMovingAt,self.stopMovingAt)
					self.pos=self.posMin+(self.posMax-self.posMin)*ratio
				end
				self:print('want to move shape to y='..tostring(self.pos[2]))
				UniversalProcessKit.setTranslation(self.nodeId,unpack(self.pos))
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

