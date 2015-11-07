-- by mor2000

--------------------
-- Animator

local UPK_Animator_mt = ClassUPK(UPK_Animator,UniversalProcessKit)
InitObjectClass(UPK_Animator, "UPK_Animator")
UniversalProcessKit.addModule("animator",UPK_Animator)

UPK_Animator.EVENT_ANIMTIME=1
UPK_Animator.EVENT_ANIMTRACKENABLED=2

function UPK_Animator:new(nodeId, parent)
	printFn('UPK_Animator:new(',nodeId,', ',parent,')')
	local self = UniversalProcessKit:new(nodeId, parent, UPK_Animator_mt)
	registerObjectClassName(self, "UPK_Animator")
	
	self.tmpSteps={}
		
	self.tmpSteps["rotation"]={}
	
	-- move
	
	self.movementSpeedupPeriod = getNumberFromUserAttribute(nodeId, "movementSpeedupPeriod", 0, 0, 1)
	self.movementSlowdownPeriod = getNumberFromUserAttribute(nodeId, "movementSlowdownPeriod", 0, 0, (1-self.movementSpeedupPeriod))
	self.moveTo = getVectorFromUserAttribute(nodeId, "moveTo", "0 0 0")
	self.movementDuration = getNumberFromUserAttribute(nodeId, "movementDuration")
	self.rewindMovementOnDisable = getBoolFromUserAttribute(nodeId, "rewindMovementOnDisable", true)
	self.doMovement = self.movementDuration~=nil
	self.movementTime = 0
	if self.doMovement then
		local dx,dy,dz = unpack(self.moveTo)
		local distance = Utils.vector3Length(dx,dy,dz)
		self:printAll('distance=',distance)
		local factor=mathpi/(mathpi+(2-mathpi)*self.movementSpeedupPeriod+(2-mathpi)*self.movementSlowdownPeriod)
		self:printAll('factor=',factor)
		if factor==0 then
			self.doMovement = false
		else
			self.movementMainSpeed = __c(dx,dy,dz)/self.movementDuration*factor
		end
		self:printAll('self.movementMainSpeed=',self.movementMainSpeed[1],', ',self.movementMainSpeed[2],', ',self.movementMainSpeed[3])
		
		self.tmpSteps["movement"]={}
		self.tmpSteps["movement"][1] = self.movementMainSpeed * (self.movementDuration*self.movementSpeedupPeriod)/(mathpi/2)
		self.tmpSteps["movement"][2] = self.tmpSteps["movement"][1] + self.movementMainSpeed * (self.movementDuration * (1-self.movementSpeedupPeriod-self.movementSlowdownPeriod))
		self.tmpSteps["movement"][3] = self.moveTo - self.tmpSteps["movement"][2]
	end
	self.movementOrigPos = __c(getTranslation(self.nodeId))
		
	-- rotate per Second
	
	self.doRotatePerSecond = false
	self.rotationsPerSecond = getVectorFromUserAttribute(nodeId, "rotationsPerSecond", "0 0 0")*(2*math.pi)
	if self.rotationsPerSecond[1]~=0 or self.rotationsPerSecond[2]~=0 or self.rotationsPerSecond[3]~=0 then
		self.doRotatePerSecond = true
		UniversalProcessKitListener.addHourChangeListener(self)
	end
	
	-- rotate
	
	self.rotationSpeedupPeriod = getNumberFromUserAttribute(nodeId, "rotationSpeedupPeriod", 0, 0, 1)
	self.rotationSlowdownPeriod = getNumberFromUserAttribute(nodeId, "rotationSlowdownPeriod", 0, 0, (1-self.rotationSpeedupPeriod))
	self.rotateTo = getVectorFromUserAttribute(nodeId, "rotateTo", "0 0 0")*(2*mathpi)
	self.rotationDuration = getNumberFromUserAttribute(nodeId, "rotationDuration")
	self.rewindRotationOnDisable = getBoolFromUserAttribute(nodeId, "rewindRotationOnDisable", true)
	self.doRotation = self.rotationDuration~=nil
	self.rotationTime = 0
	if self.doRotation then
		--local x1,y1,z1 = getRotation(nodeId)
		local rx,ry,rz = unpack(self.rotateTo)
		local distance = Utils.vector3Length(rx,ry,rz)
		local factor=mathpi/(mathpi+(2-mathpi)*self.rotationSpeedupPeriod+(2-mathpi)*self.rotationSlowdownPeriod)
		self:printAll('factor='..tostring(factor))
		if factor==0 then
			self.doRotation = false
		else
			self.rotationMainSpeed = __c(rx,ry,rz)/self.rotationDuration*factor
		end
		
		self.tmpSteps["rotation"]={}
		self.tmpSteps["rotation"][1] = self.rotationMainSpeed * (self.rotationDuration*self.rotationSpeedupPeriod)/(mathpi/2)
		self.tmpSteps["rotation"][2] = self.tmpSteps["rotation"][1] + self.rotationMainSpeed * (self.rotationDuration * (1-self.rotationSpeedupPeriod-self.rotationSlowdownPeriod))
		self.tmpSteps["rotation"][3] = self.rotateTo - self.tmpSteps["rotation"][2]
	end
	self.rotationOrigRot = __c(getRotation(nodeId))
	
	-- animation
	
	self.animTime=0
	self.animationLoop = getBoolFromUserAttribute(nodeId, "animationLoop", false)
	self.animationSpeed = getNumberFromUserAttribute(nodeId, "animationSpeed", 1)
	self.rewindAnimationOnDisable = getBoolFromUserAttribute(nodeId, "rewindAnimationOnDisable", false)
	self.animationClip = getStringFromUserAttribute(nodeId, "animationClip")
	self.doAnimation = false
	if self.animationClip~=nil then
		self.animCharacterSet = getAnimCharacterSet(nodeId)
		self:printAll('self.animCharacterSet=',self.animCharacterSet)
		if self.animCharacterSet ~= 0 then
			self.animClipIndex = getAnimClipIndex(self.animCharacterSet,self.animationClip)
			self:printAll('self.animationClip=',self.animationClip)
			self:printAll('self.animClipIndex=',self.animClipIndex)
			if self.animClipIndex~=nil and self.animClipIndex >= 0 then
				self.doAnimation=true
			end
		end
	end
	self.animTrackEnabled=false
	
	if self.doAnimation then
		enableAnimTrack(self.animCharacterSet, 0)
		assignAnimTrackClip(self.animCharacterSet,0,self.animClipIndex)
		setAnimTrackLoopState(self.animCharacterSet,0,self.animationLoop)
		setAnimTrackBlendWeight(self.animCharacterSet, self.animClipIndex, 1)
		setAnimTrackSpeedScale(self.animCharacterSet, self.animClipIndex, self.animationSpeed)
		setAnimTrackTime(self.animCharacterSet, self.animClipIndex, 0)
		self.animDuration = getAnimClipDuration(self.animCharacterSet,self.animClipIndex)
	end
	
	if not self.doMovement and not self.doRotation and not self.doRotatePerSecond and not self.doAnimation then
		self:printErr('Error: Neither movement, nor rotation, nor animation specified (correctly)')
		self:printInfo('loading Animator failed')
		return false
	end
	
	UniversalProcessKitListener.addUpdateable(self)
	
	self:printFn('UPK_Animator:new done')
	
	return self
end

function UPK_Animator:writeStream(streamId, connection)
	self:printFn('UPK_Animator:writeStream(',streamId,', ',connection,')')
	if not connection:getIsServer() then -- in connection with client
		if self.doMovement then
			streamWriteAuto(streamId, self.movementTime)
		end
		if self.doRotation then
			streamWriteAuto(streamId, self.rotationTime)
		end
		if self.doRotatePerSecond then
			local rx, ry, rz = getRotation(self.nodeId)
			streamWriteAuto(streamId, rx, ry, rz)
		end
		if self.doAnimation then
			local animTime=getAnimTrackTime(self.animCharacterSet, self.animClipIndex)
			streamWriteAuto(streamId, animTime)
		end
	end
end

function UPK_Animator:readStream(streamId, connection)
	self:printFn('UPK_Animator:readStream(',streamId,', ',connection,')')
	if connection:getIsServer() then -- in connection with server
		if self.doMovement then
			self.movementTime = streamReadAuto(streamId)
		end
		if self.doRotation then
			self.rotationTime = streamReadAuto(streamId)
		end
		if self.doRotatePerSecond then
			local rx, ry, rz = streamReadAuto(streamId)
			UniversalProcessKit.setRotation(self.nodeId, rx, ry, rz)
		end
		if self.doAnimation then
			local animTime=streamReadAuto(streamId)
		end
	end
end

function UPK_Animator:delete()
	self:printFn('UPK_Animator:delete()')
	if self.doRotatePerSecond then
		UniversalProcessKitListener.removeHourChangeListener(self)
	end
	UniversalProcessKitListener.removeUpdateable(self)
	UPK_Animator:superClass().delete(self)
end

function UPK_Animator:hourChanged()
	self:printFn('UPK_Animator:hourChanged()')
	if self.doRotatePerSecond then
		local rx, ry, rz = getRotation(self.nodeId)
		setRotation(self.nodeId, rx%(2*mathpi),ry%(2*mathpi),rz%(2*mathpi)) -- resets rotation to small numbers
	end
end

function UPK_Animator:update(dt)
	self:printAll('UPK_Animator:update(',dt,')')
	if self.doMovement or self.doRotation or self.doRotatePerSecond then
		local dts=dt/1000
		if self.doMovement then
			if self.isEnabled and self.movementTime<self.movementDuration then
				self.movementTime = mathmax(mathmin(self.movementTime + dts, self.movementDuration),0)
				local totalStep = self:getTotalStep("movement",self.movementTime,self.movementSpeedupPeriod,self.movementSlowdownPeriod,self.movementDuration,self.movementMainSpeed)
				UniversalProcessKit.setTranslation(self.nodeId,unpack(self.movementOrigPos+totalStep))
				self.movementShapeMoved=true
			elseif not self.isEnabled and self.rewindMovementOnDisable and self.movementTime>0 then
				self.movementTime = mathmin(mathmax(self.movementTime - dts, 0), self.movementDuration)
				local totalStep = self:getTotalStep("movement",self.movementTime,self.movementSpeedupPeriod,self.movementSlowdownPeriod,self.movementDuration,self.movementMainSpeed)
				UniversalProcessKit.setTranslation(self.nodeId,unpack(self.movementOrigPos+totalStep))
				self.movementShapeMoved=true
			elseif self.movementTime==0 and self.movementShapeMoved then
				UniversalProcessKit.setTranslation(self.nodeId,unpack(self.movementOrigPos))
				self.movementShapeMoved=false
			elseif self.movementTime==self.movementDuration and self.movementShapeMoved then
				UniversalProcessKit.setTranslation(self.nodeId,unpack(self.movementOrigPos+self.moveTo))
				self.movementShapeMoved=false
			end
		end
		if self.doRotation then
			if self.isEnabled and self.rotationTime<self.rotationDuration then
				self.rotationTime = mathmax(mathmin(self.rotationTime + dts, self.rotationDuration),0)
				local totalStep = self:getTotalStep("rotation",self.rotationTime,self.rotationSpeedupPeriod,self.rotationSlowdownPeriod,self.rotationDuration,self.rotationMainSpeed)
				UniversalProcessKit.setRotation(self.nodeId,unpack(self.rotationOrigRot+totalStep))
				self.rotationShapeMoved=true
			elseif not self.isEnabled and self.rewindRotationOnDisable and self.rotationTime>0 then
				self.rotationTime = mathmin(mathmax(self.rotationTime - dts, 0), self.rotationDuration)
				local totalStep = self:getTotalStep("rotation",self.rotationTime,self.rotationSpeedupPeriod,self.rotationSlowdownPeriod,self.rotationDuration,self.rotationMainSpeed)
				UniversalProcessKit.setRotation(self.nodeId,unpack(self.rotationOrigRot+totalStep))
				self.rotationShapeMoved=true
			elseif self.rotationTime==0 and self.rotationShapeMoved then
				UniversalProcessKit.setRotation(self.nodeId,unpack(self.rotationOrigRot))
				self.rotationShapeMoved=false
			elseif self.rotationTime==self.rotationDuration and self.rotationShapeMoved then
				UniversalProcessKit.setRotation(self.nodeId,unpack(self.rotationOrigRot+self.rotateTo))
				self.rotationShapeMoved=false
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

--[[
function UPK_Animator:getNextStep(time,dts,speedupPeriod,slowdownPeriod,duration,mainSpeed)
	local r=0
	if time < speedupPeriod * duration then
		r = mainSpeed * dts * mathsin(time/ (speedupPeriod * duration) * (mathpi/2))
	elseif time > ((1-slowdownPeriod) * duration) then
		r = mainSpeed * dts * mathsin((duration-time)/ (slowdownPeriod * duration) * (mathpi/2))
	else
		r = mainSpeed * dts
	end
	return r
end
]]--

function UPK_Animator:getTotalStep(type,time,speedupPeriod,slowdownPeriod,duration,mainSpeed)
	self:printFn('UPK_Animator:getTotalStep(',type,',',time,',',speedupPeriod,',',slowdownPeriod,',',duration,',',mainSpeed,')')
	if time < speedupPeriod * duration then
		return (self.tmpSteps[type][1] * (1-mathcos(time/ (speedupPeriod * duration) * (mathpi/2))))
	elseif time < ((1-slowdownPeriod) * duration) then
		return (self.tmpSteps[type][1] + mainSpeed * (time - (duration*speedupPeriod)))
	else
		return (self.tmpSteps[type][2] + self.tmpSteps[type][3] * mathsin(((time-((1-slowdownPeriod)*duration))/(slowdownPeriod * duration))*(mathpi/2)))
	end
	return 0
end

function UPK_Animator:postLoad()
	self:printFn('UPK_Animator:postLoad()')
	UPK_ActivatorTrigger:superClass().postLoad(self)
	if self.rotateToWhenLoaded~=nil then
		local rx, ry, rz = unpack(self.rotateToWhenLoaded)
		self:printAll('set to saved rotation ',rx,', ',ry,', ',rz)
		UniversalProcessKit.setRotation(self.nodeId, rx, ry, rz)
		self.rotateToWhenLoaded = nil
	end
	if self.doMovement then
		self.movementShapeMoved=true
	end
	if self.doRotation then
		self.rotationShapeMoved=true
	end
end

function UPK_Animator:setEnable(isEnabled,alreadySent)
	self:printFn('UPK_Animator:setEnable(',isEnabled,', ',alreadySent,')')
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
	self:printFn('UPK_Animator:loadExtraNodes(',xmlFile,', ',key,')')
	if self.doAnimation then
		local animTime=Utils.getNoNil(tonumber(getXMLFloat(xmlFile, key .. "#animTime")),0)
		self:setAnimTime(animTime,true)
		local animTrackEnabled=tobool(getXMLBool(xmlFile, key .. "#animTrackEnabled"))
		if animTrackEnabled==true then
			self:enableAnimTrack(true)
		elseif animTrackEnabled==false then
			self:disableAnimTrack(true)
		end
	end
	if self.doMovement then
		self.movementTime = getXMLFloat(xmlFile, key .. "#movementTime") or 0
	end
	if self.doRotation then
		self.rotationTime = getXMLFloat(xmlFile, key .. "#rotationTime") or 0
	end
	if self.doRotatePerSecond then
		local rotateToWhenLoaded = gmatch(getXMLString(xmlFile, key .. "#rotation"), "(%d+%.%d+)")
		if type(rotateToWhenLoaded)=="table" and rotateToWhenLoaded[1]~=nil then
			self:printAll('read saved rotation '..tostring(rotateToWhenLoaded[1])..', '..tostring(rotateToWhenLoaded[2])..', '..tostring(rotateToWhenLoaded[3]))
			self.rotateToWhenLoaded = { tonumber(rotateToWhenLoaded[1]), tonumber(rotateToWhenLoaded[2]), tonumber(rotateToWhenLoaded[3]) }
		end
	end
	return true
end;

function UPK_Animator:getSaveExtraNodes(nodeIdent)
	self:printFn('UPK_Animator:getSaveExtraNodes(',nodeIdent,')')
	local nodes=""
	if self.doAnimation then -- didnt worked yet to save animation time
		local animTime=max(0,min(self:getAnimTime(),self.animDuration))
		nodes=nodes..' animTrackEnabled="'..tostring(self.animTrackEnabled)..'" animTime="'..tostring(animTime)..'"'
	end
	if self.doMovement and self.movementTime~=0 then
		nodes=nodes.." movementTime=\""..tostring(round(self.movementTime,4)).."\""
	end
	if self.doRotation and self.rotationTime~=0 then
		nodes=nodes.." rotationTime=\""..tostring(round(self.rotationTime,4)).."\""
	end
	if self.doRotatePerSecond then
		local rx, ry, rz = getRotation(self.nodeId)
		nodes=nodes.." rotation=\""..string.format("%f",rx).." "..string.format("%f",ry).." "..string.format("%f",rz).."\""
	end
	return nodes
end;

function UPK_Animator:setAnimTime(animTime,alreadySent)
	self:printFn('UPK_Animator:setAnimTime(',animTime,', ',alreadySent,')')
	setAnimTrackTime(self.animCharacterSet, self.animClipIndex, animTime)
	if animTime>self.animDuration then
		animTime=self.animDuration
	end
	if animTime<0 then
		animTime=0
	end
	self.animTime=animTime
	if not alreadySent then
		self:sendEvent(UPK_Animator.EVENT_ANIMTIME,animTime)
	end
end;

function UPK_Animator:eventCallback(eventType,...)
	self:printFn('UPK_Animator:eventCallback(',eventType,'...)')
	if eventType==UPK_Animator.EVENT_ANIMTIME then
		self:printAll('UPK_Animator.EVENT_ANIMTIME')
		local animTime=...
		self:printAll(...)
		self:setAnimTime(animTime,true)
	elseif eventType==UPK_Animator.EVENT_ANIMTRACKENABLED then
		self:printAll('UPK_Animator.EVENT_ANIMTRACKENABLED')
		local animTrackEnabled=...
		self:printAll(...)
		if animTrackEnabled==true then
			self:enableAnimTrack(alreadySent)
		else
			self:disableAnimTrack(alreadySent)
		end
	end
end

function UPK_Animator:getAnimTime()
	self:printFn('UPK_Animator:getAnimTime()')
	local animTime=getAnimTrackTime(self.animCharacterSet, self.animClipIndex)
	return animTime
end;

function UPK_Animator:enableAnimTrack(alreadySent)
	self:printFn('UPK_Animator:enableAnimTrack(',alreadySent,')')
	if self.animTrackEnabled==false then
		self.animTrackEnabled=true
		self:setAnimTime(self:getAnimTime(),true)
		if self.rewindAnimationOnDisable then
			setAnimTrackSpeedScale(self.animCharacterSet, self.animClipIndex, self.animationSpeed)
		end
		enableAnimTrack(self.animCharacterSet, self.animClipIndex)
		if not alreadySent then
			self:sendEvent(UPK_Animator.EVENT_ANIMTRACKENABLED,true)
		end
	end
end;

function UPK_Animator:disableAnimTrack(alreadySent)
	self:printFn('UPK_Animator:disableAnimTrack(',alreadySent,')')
	if self.animTrackEnabled==true then
		self.animTrackEnabled=false
		if self.rewindAnimationOnDisable then
			self:setAnimTime(self:getAnimTime(),true)
			setAnimTrackSpeedScale(self.animCharacterSet, self.animClipIndex, -self.animationSpeed)
			enableAnimTrack(self.animCharacterSet, self.animClipIndex)
		else
			disableAnimTrack(self.animCharacterSet, self.animClipIndex)
		end
		if not alreadySent then
			self:sendEvent(UPK_Animator.EVENT_ANIMTRACKENABLED,false)
		end
	end
end;

