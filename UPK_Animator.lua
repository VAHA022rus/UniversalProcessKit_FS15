-- by mor2000

--------------------
-- Animator

local UPK_Animator_mt = ClassUPK(UPK_Animator,UniversalProcessKit)
InitObjectClass(UPK_Animator, "UPK_Animator")
UniversalProcessKit.addModule("animator",UPK_Animator)

function UPK_Animator:new(id, parent)
	local self = UniversalProcessKit:new(id, parent, UPK_Animator_mt)
	registerObjectClassName(self, "UPK_Animator")
	
	self.tmpSteps={}
		
	self.tmpSteps["rotation"]={}
	
	-- move
	
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
		
		self.tmpSteps["movement"]={}
		self.tmpSteps["movement"][1] = self.movementMainSpeed * (self.movementDuration*self.movementSpeedupPeriod)/(mathpi/2)
		self.tmpSteps["movement"][2] = self.tmpSteps["movement"][1] + self.movementMainSpeed * (self.movementDuration * (1-self.movementSpeedupPeriod-self.movementSlowdownPeriod))
		self.tmpSteps["movement"][3] = self.moveTo - self.tmpSteps["movement"][2]
	end
	self.movementOrigPos = __c(getTranslation(self.nodeId))
		
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
		
		self.tmpSteps["rotation"]={}
		self.tmpSteps["rotation"][1] = self.rotationMainSpeed * (self.rotationDuration*self.rotationSpeedupPeriod)/(mathpi/2)
		self.tmpSteps["rotation"][2] = self.tmpSteps["rotation"][1] + self.rotationMainSpeed * (self.rotationDuration * (1-self.rotationSpeedupPeriod-self.rotationSlowdownPeriod))
		self.tmpSteps["rotation"][3] = self.rotateTo - self.tmpSteps["rotation"][2]
	end
	self.rotationOrigRot = __c(getRotation(self.nodeId))
	
	-- animation
	
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

function UPK_Animator:writeStream(streamId, connection)
	if not connection:getIsServer() then -- in connection with client
		if self.doMovement then
			streamWriteFloat32(streamId, self.movementTime)
		end
		if self.doRotation then
			streamWriteFloat32(streamId, self.rotationTime)
		end
		if self.doRotatePerSecond then
			local rx, ry, rz = getRotation(self.nodeId)
			streamWriteFloat32(streamId, rx)
			streamWriteFloat32(streamId, ry)
			streamWriteFloat32(streamId, rz)
		end
	end
end

function UPK_Animator:readStream(streamId, connection)
	if connection:getIsServer() then -- in connection with server
		if self.doMovement then
			self.movementTime = streamReadFloat32(streamId)
		end
		if self.doRotation then
			self.rotationTime = streamReadFloat32(streamId)
		end
		if self.doRotatePerSecond then
			local px = streamReadFloat32(streamId)
			local py = streamReadFloat32(streamId)
			local pz = streamReadFloat32(streamId)
			UniversalProcessKit.setRotation(self.nodeId, rx, ry, rz)
		end
	end
end

function UPK_Animator:delete()
	UniversalProcessKitListener.removeUpdateable(self)
	UPK_Animator:superClass().delete(self)
end

function UPK_Animator:update(dt)
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
	UPK_ActivatorTrigger:superClass().postLoad(self)
	if self.rotateToWhenLoaded~=nil then
		local rx, ry, rz = unpack(self.rotateToWhenLoaded)
		self:print('set to saved rotation '..tostring(rx)..', '..tostring(ry)..', '..tostring(rz))
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
			self:print('read saved rotation '..tostring(rotateToWhenLoaded[1])..', '..tostring(rotateToWhenLoaded[2])..', '..tostring(rotateToWhenLoaded[3]))
			self.rotateToWhenLoaded = { tonumber(rotateToWhenLoaded[1]), tonumber(rotateToWhenLoaded[2]), tonumber(rotateToWhenLoaded[3]) }
		end
	end
	return true
end;

function UPK_Animator:getSaveExtraNodes(nodeIdent)
	local nodes=""
	if false and self.doAnimation then -- didnt worked yet to save animation time
		nodes=nodes.." animTrackEnabled=\""..tostring(self.animTrackEnabled).."\" animTime=\""..tostring(self:getAnimTime()).."\""
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

