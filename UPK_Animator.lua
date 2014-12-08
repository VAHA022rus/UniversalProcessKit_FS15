-- by mor2000

--------------------
-- Animator

local UPK_Animator_mt = ClassUPK(UPK_Animator,UniversalProcessKit)
InitObjectClass(UPK_Animator, "UPK_Animator")
UniversalProcessKit.addModule("animator",UPK_Animator)

function UPK_Animator:new(id, parent)
	local self = UniversalProcessKit:new(id, parent, UPK_Animator_mt)
	registerObjectClassName(self, "UPK_Animator")
	
	self.movementSpeedupPeriod = getNumberFromUserAttribute(id, "movementSpeedupPeriod", 0, 0, 1)
	self.movementSlowdownPeriod = getNumberFromUserAttribute(id, "movementSlowdownPeriod", 0, 0, (1-self.movementSpeedupPeriod))
	self.moveTo = getVectorFromUserAttribute(id, "moveTo", "0 0 0")
	self.movementDuration = getNumberFromUserAttribute(id, "movementDuration")
	self.rewindMovementOnDisable = getBoolFromUserAttribute(id, "rewindMovementOnDisable", true)
	self.doMovement = self.movementDuration~=nil
	self.movementTime = 0
	if self.doMovement then
		local dx,dy,dz = unpack(self.moveTo)
		local distance = Utils.vector3Length(dx,dy,dz)
		self:print('distance='..tostring(distance))
		local factor=mathpi/(mathpi+(2-mathpi)*self.movementSpeedupPeriod+(2-mathpi)*self.movementSlowdownPeriod)
		self:print('factor='..tostring(factor))
		if factor==0 then
			self.doMovement = false
		else
			self.movementMainSpeed = __c(dx,dy,dz)/self.movementDuration*factor
		end
		self:print('self.movementMainSpeed='..tostring(self.movementMainSpeed[1])..', '..tostring(self.movementMainSpeed[2])..
			', '..tostring(self.movementMainSpeed[3]))
	end
	
	-- rotate per Second
	
	self.doRotatePerSecond = false
	self.rotationsPerSecond = getVectorFromUserAttribute(id, "rotationsPerSecond", "0 0 0")*(2*math.pi)
	if self.rotationsPerSecond[1]~=0 or self.rotationsPerSecond[2]~=0 or self.rotationsPerSecond[3]~=0 then
		self.doRotatePerSecond = true
	end
	
	-- rotate
	
	self.rotationSpeedupPeriod = getNumberFromUserAttribute(id, "rotationSpeedupPeriod", 0, 0, 1)
	self.rotationSlowdownPeriod = getNumberFromUserAttribute(id, "rotationSlowdownPeriod", 0, 0, (1-self.rotationSpeedupPeriod))
	self.rotateTo = getVectorFromUserAttribute(id, "rotateTo", "0 0 0")*(2*mathpi)
	self.rotationDuration = getNumberFromUserAttribute(id, "rotationDuration")
	self.rewindRotationOnDisable = getBoolFromUserAttribute(id, "rewindRotationOnDisable", true)
	self.doRotation = self.rotationDuration~=nil
	self.rotationTime = 0
	if self.doRotation then
		--local x1,y1,z1 = getRotation(id)
		local rx,ry,rz = unpack(self.rotateTo)
		local distance = Utils.vector3Length(rx,ry,rz)
		local factor=mathpi/(mathpi+(2-mathpi)*self.rotationSpeedupPeriod+(2-mathpi)*self.rotationSlowdownPeriod)
		self:print('factor='..tostring(factor))
		if factor==0 then
			self.doRotation = false
		else
			self.rotationMainSpeed = __c(rx,ry,rz)/self.rotationDuration*factor
		end
	end
	
	self.animTime=0
	self.animationLoop = getBoolFromUserAttribute(id, "animationLoop", false)
	self.animationSpeed = getNumberFromUserAttribute(id, "animationSpeed", 1)
	self.rewindAnimationOnDisable = getBoolFromUserAttribute(id, "rewindAnimationOnDisable", false)
	self.animationClip = getStringFromUserAttribute(id, "animationClip")
	self.doAnimation = self.animationClip~=nil
	if self.doAnimation then
		self.animCharacterSet = getAnimCharacterSet(id)
		self:print('self.animCharacterSet='..tostring(self.animCharacterSet))
		if self.animCharacterSet ~= 0 then
			self.animClipIndex = getAnimClipIndex(self.animCharacterSet,self.animationClip)
			self:print('self.animationClip='..tostring(self.animationClip))
			self:print('self.animClipIndex='..tostring(self.animClipIndex))
			if self.animClipIndex >= 0 then
				self.doAnimation=true
			end
		end
	end
	self.animTrackEnabled=false
	
	if self.doAnimation then
		assignAnimTrackClip(self.animCharacterSet,0,self.animClipIndex)
		setAnimTrackLoopState(self.animCharacterSet,0,self.animationLoop)
		setAnimTrackBlendWeight(self.animCharacterSet, self.animClipIndex, 1)
		setAnimTrackSpeedScale(self.animCharacterSet, self.animClipIndex, self.animationSpeed)
		setAnimTrackTime(self.animCharacterSet, self.animClipIndex, 0)
		self.animDuration = getAnimClipDuration(self.animCharacterSet,self.animClipIndex)
	end
	
	if not self.doMovement and not self.doRotation and not self.doRotatePerSecond and not self.doAnimation then
		self:print('Error: Neither movement, nor rotation, nor animation specified (correctly)')
		self:print('loading Animator failed')
		return false
	end
	
	UniversalProcessKitListener.addUpdateable(self)
	
	self:print('loaded Animator successfully')
	
	return self
end

function UPK_Animator:delete()
	UniversalProcessKitListener.removeUpdateable(self)
	UPK_Animator:superClass().delete(self)
end

function UPK_Animator:update(dt)
	if self.isClient and (self.doMovement or self.doRotation or self.doRotatePerSecond) then
		local dts=dt/1000
		if self.doMovement then
			if self.isEnabled and self.movementTime<self.movementDuration then
				self.movementTime = mathmin(self.movementTime + dts, self.movementDuration)
				local nextStep=self:getNextStep(self.movementTime,dts,self.movementSpeedupPeriod,self.movementSlowdownPeriod,self.movementDuration,self.movementMainSpeed)
				UniversalProcessKit.setTranslation(self.nodeId,unpack(__c(getTranslation(self.nodeId))+nextStep))
			elseif not self.isEnabled and self.rewindMovementOnDisable and self.movementTime>0 then
				self.movementTime = mathmax(self.movementTime - dts, 0)
				local nextStep=self:getNextStep(self.movementTime,dts,self.movementSpeedupPeriod,self.movementSlowdownPeriod,self.movementDuration,self.movementMainSpeed)
				UniversalProcessKit.setTranslation(self.nodeId,unpack(__c(getTranslation(self.nodeId))-nextStep))
			end
		end
		if self.doRotation then
			if self.isEnabled and self.rotationTime<self.rotationDuration then
				self.rotationTime = mathmin(self.rotationTime + dts, self.rotationDuration)
				local nextStep=self:getNextStep(self.rotationTime,dts,self.rotationSpeedupPeriod,self.rotationSlowdownPeriod,self.rotationDuration,self.rotationMainSpeed)
				UniversalProcessKit.setRotation(self.nodeId,unpack(__c(getRotation(self.nodeId))+nextStep))
			elseif not self.isEnabled and self.rewindRotationOnDisable and self.rotationTime>0 then
				self.rotationTime = mathmax(self.rotationTime - dts, 0)
				local nextStep=self:getNextStep(self.rotationTime,dts,self.rotationSpeedupPeriod,self.rotationSlowdownPeriod,self.rotationDuration,self.rotationMainSpeed)
				UniversalProcessKit.setRotation(self.nodeId,unpack(__c(getRotation(self.nodeId))-nextStep))
			end
		end
		if self.isEnabled and self.doRotatePerSecond then
			local x,y,z = unpack(self.rotationsPerSecond*dts)
			if x~=nil and y~=nil and z~=nil then
				rotate(self.nodeId, x,y,z)
			end
		end
	end
end

function UPK_Animator:getNextStep(time,dts,speedupPeriod,slowdownPeriod,duration,mainSpeed)
	local r
	if time < speedupPeriod * duration then
		r = mainSpeed * dts * mathsin(time/ (speedupPeriod * duration) * (mathpi/2))
	elseif time > ((1-slowdownPeriod) * duration) then
		r = mainSpeed * dts * mathsin((duration-time)/ (slowdownPeriod * duration) * (mathpi/2))
	else
		r = mainSpeed * dts
	end
	return r
end

function UPK_Animator:setEnable(isEnabled,alreadySent)
	UPK_Animator:superClass().setEnable(self,isEnabled,alreadySent)
	if self.isEnabled then
		if self.doMovement and not self.rewindMovementOnDisable then
			self.movementTime=0
		end
		if self.doRotation and not self.rewindRotationOnDisable then
			self.rotationTime=0
		end
		if self.doAnimation then
			self:enableAnimTrack(alreadySent)
		end
	else
		if self.doAnimation then
			self:disableAnimTrack(alreadySent)
		end
	end
end;

function UPK_Animator:loadExtraNodes(xmlFile, key)
	if self.doAnimation then
		local animTime=Utils.getNoNil(tonumber(getXMLString(xmlFile, key .. "#animTime")),0)
		self:setAnimTime(animTime,true)
		local animTrackEnabled=tobool(getXMLString(xmlFile, key .. "#animTrackEnabled"))
		if animTrackEnabled==true then
			self:enableAnimTrack(true)
		elseif animTrackEnabled==false then
			self:disableAnimTrack(true)
		end
	end
	return true
end;

function UPK_Animator:getSaveExtraNodes(nodeIdent)
	local nodes=""
	if false and self.doAnimation then
		nodes=nodes.." animTrackEnabled=\""..tostring(self.animTrackEnabled).."\" animTime=\""..tostring(self:getAnimTime()).."\""
	end
	return nodes
end;

function UPK_Animator:setAnimTime(animTime,alreadySent)
	setAnimTrackTime(self.animCharacterSet, self.animClipIndex, animTime, true)
	self.animTime=animTime
end;

function UPK_Animator:getAnimTime()
	return getAnimTrackTime(self.animCharacterSet, self.animClipIndex)
end;

function UPK_Animator:enableAnimTrack(alreadySent)
	if self.animTrackEnabled==false then
		self.animTrackEnabled=true
		if self.rewindAnimationOnDisable then
			setAnimTrackSpeedScale(self.animCharacterSet, self.animClipIndex, self.animationSpeed)
		end
		enableAnimTrack(self.animCharacterSet, self.animClipIndex)
	end
end;

function UPK_Animator:disableAnimTrack(alreadySent)
	if self.animTrackEnabled==true then
		self.animTrackEnabled=false
		if self.rewindAnimationOnDisable then
			setAnimTrackSpeedScale(self.animCharacterSet, self.animClipIndex, -self.animationSpeed)
			enableAnimTrack(self.animCharacterSet, self.animClipIndex)
		else
			disableAnimTrack(self.animCharacterSet, self.animClipIndex)
		end
	end
end;

