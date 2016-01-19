-- by mor2000

-- handle animation

local AnimationTrack_mt={
	__index=AnimationTrack
}

function AnimationTrack.new(shapeId,syncObj)
	local self={}
	
	self.shapeId=shapeId
	self.shapeName=getName(shapeId)

	self.animCharacterSet = getAnimCharacterSet(shapeId)
	if self.animCharacterSet==0 then
		printAll('no animation found for shape "',self.shapeName,'"')
		return false
	end
	
	if syncObj==nil then
		printErr('no sync object provided')
		return false
	end
	
	self.animationClip = getStringFromUserAttribute(shapeId, "animationClip")
	if self.animationClip~=nil then
		self.animClipIndex = getAnimClipIndex(self.animCharacterSet,self.animationClip)
		if self.animClipIndex==-1 then
			printErr('no animation clip "',self.animationClip,'" found for shape "',self.shapeName,'"')
			return false
		end
		printInfo('animation clip index found for shape "',self.shapeName,'" is ',self.animClipIndex)
	else
		self.animClipIndex = 0
		printInfo('no animation clip name for shape "',self.shapeName,'" found - set to 0')
	end
	
	self.animTrack=0 -- tracks? clips? wtf?
	if not isAnimTrackClipAssigned(self.animCharacterSet,self.animTrack) then
		printInfo('no animation track found for shape "',self.shapeName,'"')
		assignAnimTrackClip(self.animCharacterSet,self.animTrack,self.animClipIndex)
	end
	
	self.animDuration = getAnimClipDuration(self.animCharacterSet,self.animClipIndex)
	printInfo('self.animDuration ', self.animDuration)
	
	local animTrackBlendWeight = getAnimTrackBlendWeight(self.animCharacterSet,self.animTrack)
	self.animTrackBlendWeight = getNumberFromUserAttribute(shapeId, "animationBlendWeight", animTrackBlendWeight, 0, 1)
	
	local loop = getUserAttribute(shapeId, "animationLoop")
	self.loop = 1
	if loop==true then
		self.loop = 0 -- loop till stop
	elseif type(loop)=="number" and loop>=0 then
		self.loop = loop
	end
	self.loopCount = 0
	
	self.animationSpeed = getNumberFromUserAttribute(shapeId, "animationSpeed", 1, 0) -- current
	if self.animationSpeed==0 then
		printErr('animation speed must be greater than 0')
		return false
	end
	self.animationSpeedPlay = self.animationSpeed -- when played
	local rewindAnimationOnDisable = getBoolFromUserAttribute(shapeId, "rewindAnimationOnDisable", false) -- old animator
	self.rewindOnStop = getBoolFromUserAttribute(shapeId, "animationRewindOnStop", rewindAnimationOnDisable)
	
	self.rewindOnEnd = getBoolFromUserAttribute(shapeId, "animationRewindOnEnd", false)
	
	self.offsetPlay = getNumberFromUserAttribute(shapeId, "animationOffsetPlay", 0, 0)*1000
	self.offsetStop = getNumberFromUserAttribute(shapeId, "animationOffsetStop", 0, 0)*1000
	
	self.animTrackTime = getAnimTrackTime(self.animCharacterSet, self.animClipIndex)
	
	local animationEnabled = getBoolFromUserAttribute(shapeId, "animationEnabled", false)

	setmetatable(self,AnimationTrack_mt)
	
	-- timer
	self.onEndTimerId=nil
	self.onEndRunTime=0
	self.playTimerId=nil
	self.playRunTime=0
	self.stopTimerId=nil
	self.stopRunTime=0
	
	-- networking
	self.isServer = g_server~=nil
	self.dirtyMask = 0
	self.nextDirtyFlag = 1
	self.playDirtyFlag = self:getNextDirtyFlag()
	self.stopDirtyFlag = self:getNextDirtyFlag()
	self.syncObj = syncObj
	self.syncObj:registerObjectToSync(self) -- invokes to call read and writeStream
	
	if animationEnabled then
		self:playNow()
	else
		self.animationEnabled=false
	end
	
	return self
end

function AnimationTrack:delete()
	printFn('AnimationTrack:delete()')
	if self.playTimerId~=nil then
		removeTimer(self.playTimerId)
	end
	if self.stopTimerId~=nil then
		removeTimer(self.stopTimerId)
	end
	if self.onEndTimerId~=nil then
		removeTimer(self.onEndTimerId)
	end
end

function AnimationTrack:writeStream(streamId, connection)
	printFn('AnimationTrack:writeStream(',streamId,', ',connection,')')
	if not connection:getIsServer() then
		streamWriteAuto(streamId,self:getAnimTrackTime())
		streamWriteAuto(streamId,self.animationSpeed)
		streamWriteAuto(streamId,self.animationEnabled)

		streamWriteAuto(streamId,self.loopCount)
		
		local hasPlayTimer = self.playTimerId~=nil
		streamWriteAuto(streamId,hasPlayTimer)
		if hasPlayTimer then
			streamWriteAuto(streamId,self.playRunTime)
		end
		
		local hasStopTimer = self.stopTimerId~=nil
		streamWriteAuto(streamId,hasStopTimer)
		if hasStopTimer then
			streamWriteAuto(streamId,self.stopRunTime)
		end
		
		local hasOnEndTimer = self.onEndTimerId~=nil
		streamWriteAuto(streamId,hasOnEndTimer)
		if hasOnEndTimer then
			streamWriteAuto(streamId,self.onEndRunTime)
		end
	end
end

function AnimationTrack:readStream(streamId, connection)
	printFn('AnimationTrack:readStream(',streamId,', ',connection,')')
	if connection:getIsServer() then
		local animTrackTime = streamReadAuto(streamId)
		local animationSpeed = streamReadAuto(streamId)
		local animationEnabled = streamReadAuto(streamId)
		
		self:setAnimTrackSpeedScale(1)
		self.initialAnimationSpeed = animationSpeed
		self:setAnimTrackTime(animTrackTime)
		self.initialAnimTrackTime = animTrackTime
		self:enableAnimTrack()
		self.initialAnimationEnabled = animationEnabled
		-- needs 1 frame to refresh position
		self.refreshPositionTimerId = reviveTimer(self.refreshPositionTimerId, 100, "refreshPositionTimer", self)
		
		self.loopCount = streamReadAuto(streamId) or 0
		
		if streamReadAuto(streamId) then
			local playRunTime = streamReadAuto(streamId)
			local offset = playRunTime - UniversalProcessKitListener.runTime
			self:play(offset)
		end
		
		if streamReadAuto(streamId) then
			local stopRunTime = streamReadAuto(streamId)
			local offset = stopRunTime - UniversalProcessKitListener.runTime
			self:stop(offset)
		end
		
		if streamReadAuto(streamId) then
			local onEndRunTime = streamReadAuto(streamId)
			local offset = onEndRunTime - UniversalProcessKitListener.runTime
			self:addOnEndTimer(offset)
		end
	end
end

function AnimationTrack:writeUpdateStream(streamId, connection, dirtyMask, syncall)
	printFn('AnimationTrack:writeUpdateStream(',streamId,', ',connection,', ',dirtyMask,', ',syncall,')')
	if not connection:getIsServer() then
		if bitAND(dirtyMask,self.playDirtyFlag)~=0 then
			printInfo('streaming self.playRunTime ',self.playRunTime)
			streamWriteAuto(streamId,self.playRunTime)
		end
		if bitAND(dirtyMask,self.stopDirtyFlag)~=0 then
			printInfo('streaming self.stopRunTime ',self.stopRunTime)
			streamWriteAuto(streamId,self.stopRunTime)
		end
	end
end

function AnimationTrack:doAfterAllClientsAreSynced()
	printFn('AnimationTrack:doAfterAllClientsAreSynced()')
	self.dirtyMask = 0
end

function AnimationTrack:readUpdateStream(streamId, connection, dirtyMask, syncall)
	printFn('AnimationTrack:readUpdateStream(',streamId,', ',connection,', ',dirtyMask,', ',syncall,')')
	if connection:getIsServer() then
		if bitAND(dirtyMask,self.playDirtyFlag)~=0 then
			local playRunTime = streamReadAuto(streamId)
			printInfo('reading playRunTime ',playRunTime)
			local offset = playRunTime - UniversalProcessKitListener.runTime
			self:play(offset,true)
		end
		if bitAND(dirtyMask,self.stopDirtyFlag)~=0 then
			local stopRunTime = streamReadAuto(streamId)
			printInfo('reading stopRunTime ',stopRunTime)
			local offset = stopRunTime - UniversalProcessKitListener.runTime
			self:stop(offset,true)
		end
	end
end

function AnimationTrack:getNextDirtyFlag()
	printFn('AnimationTrack:getNextDirtyFlag()')
	return Object.getNextDirtyFlag(self)
end

function AnimationTrack:raiseDirtyFlags(flag)
	printFn('AnimationTrack:raiseDirtyFlags(',flag,')')
	if self.isServer then
		Object.raiseDirtyFlags(self,flag)
		self.syncObj:raiseDirtyFlags(self.syncObj.objectsToSyncDirtyFlag)
	end
end

function AnimationTrack:loadFromAttributes(xmlFile, key)
	printFn('AnimationTrack:loadFromAttributes(',xmlFile,', ',key,')')
	
	local animTrackTime = getXMLFloat(xmlFile, key .. "#animTrackTime") or self.animTrackTime
	local animationSpeed = getXMLFloat(xmlFile, key .. "#animationSpeed") or 1
	-- allows new speed settings in i3d
	if animationSpeed~=0 and mathabs(animationSpeed)~=mathabs(self.animationSpeed) then
		animationSpeed = animationSpeed/mathabs(animationSpeed)*self.animationSpeed
	end
	local animationEnabled = getXMLBool(xmlFile, key .. "#animationEnabled") or self.animationEnabled
	
	printInfo('animTrackTime ',animTrackTime)
	printInfo('animationSpeed ',animationSpeed)
	printInfo('animationEnabled ',animationEnabled)
	
	self:setAnimTrackSpeedScale(1)
	self.initialAnimationSpeed = animationSpeed
	self:setAnimTrackTime(animTrackTime)
	self.initialAnimTrackTime = animTrackTime
	self:enableAnimTrack()
	self.initialAnimationEnabled = animationEnabled
	-- needs 1 frame to refresh position
	self.refreshPositionTimerId = reviveTimer(self.refreshPositionTimerId, 100, "refreshPositionTimer", self)
	
	self.loopCount = getXMLInt(xmlFile, key .. "#loopCount") or 0
	
	local playRunTime = getXMLInt(xmlFile, key .. "#playRunTime")
	if playRunTime~=nil then
		self:play(playRunTime,true)
	end
	
	local stopRunTime = getXMLInt(xmlFile, key .. "#stopRunTime")
	if stopRunTime~=nil then
		self:stop(stopRunTime,true)
	end
	
	local onEndRunTime = getXMLInt(xmlFile, key .. "#onEndRunTime")
	if onEndRunTime~=nil then
		self:addOnEndTimer(onEndRunTime)
	end
	
	return true
end

function AnimationTrack:refreshPositionTimer()
	printFn('AnimationTrack:refreshPositionTimer()')
	self:setAnimTrackSpeedScale(self.initialAnimationSpeed)
	self.initialAnimationSpeed = nil
	self:setAnimTrackTime(self.initialAnimTrackTime)
	self.initialAnimTrackTime = nil
	self:enableAnimTrack(self.initialAnimationEnabled)
	self.initialAnimationEnabled = nil
	self.refreshPositionTimerId = nil
	return false
end

function AnimationTrack:getSaveAttributes()
	printFn('AudioSample:getSaveAttributes()')
	local attributes=""
	
	attributes = attributes..' animTrackTime="'..tostring(self:getAnimTrackTime())..'"'
	attributes = attributes..' animationSpeed="'..tostring(self.animationSpeed)..'"'
	attributes = attributes..' animationEnabled="'..tostring(self.animationEnabled)..'"'
	
	attributes=attributes..' loopCount="'..tostring(self.loopCount)..'"'
	
	if self.playTimerId~=nil then
		attributes = attributes..' playRunTime="'..tostring(round(self.playRunTime - UniversalProcessKitListener.runTime,0))..'"'
	end
	
	if self.stopTimerId~=nil then
		attributes = attributes..' stopRunTime="'..tostring(round(self.stopRunTime - UniversalProcessKitListener.runTime,0))..'"'
	end
	
	if self.onEndTimerId~=nil then
		attributes = attributes..' onEndRunTime="'..tostring(round(self.onEndRunTime - UniversalProcessKitListener.runTime,0))..'"'
		
	end
	
	return attributes
end

function AnimationTrack:getAnimTrackTime()
	printFn('AnimationTrack:getAnimTrackTime()')
	local animTrackTime = getAnimTrackTime(self.animCharacterSet, self.animClipIndex)
	animTrackTime = animTrackTime / self.animationSpeedPlay
	printInfo('animTrackTime ',animTrackTime)
	animTrackTime = mathmin(self.animDuration,mathmax(0,animTrackTime))
	return animTrackTime
end

function AnimationTrack:setAnimTrackTime(animTrackTime)
	printFn('AnimationTrack:setAnimTrackTime(',animTrackTime,')')
	animTrackTime = mathmin(self.animDuration,mathmax(0,animTrackTime * self.animationSpeedPlay))
	setAnimTrackTime(self.animCharacterSet, self.animClipIndex, animTrackTime)
end

function AnimationTrack:refreshAnimTrackTime()
	printFn('AnimationTrack:refreshAnimTrackTime()')
	local animTrackTime = self:getAnimTrackTime()
	self:setAnimTrackTime(animTrackTime)
end

function AnimationTrack:setAnimTrackSpeedScale(animationSpeed)
	printFn('AnimationTrack:setAnimTrackSpeedScale(',animationSpeed,')')
	self.animationSpeed = animationSpeed
	setAnimTrackSpeedScale(self.animCharacterSet, self.animClipIndex, self.animationSpeed)
	self.animDuration = getAnimClipDuration(self.animCharacterSet,self.animClipIndex) / self.animationSpeedPlay
	printInfo('self.animDuration ', self.animDuration)
end

function AnimationTrack:enableAnimTrack(enable)
	printFn('AnimationTrack:enableAnimTrack(',enable,')')
	if enable==nil or enable==true then
		self:refreshAnimTrackTime()
		enableAnimTrack(self.animCharacterSet, self.animTrack)
		self.animationEnabled = true
	else
		self:refreshAnimTrackTime()
		disableAnimTrack(self.animCharacterSet, self.animTrack)
		self:setAnimTrackSpeedScale(0)
		self.animationEnabled = false
	end
end

function AnimationTrack:disableAnimTrack()
	printFn('AnimationTrack:disableAnimTrack()')
	self:enableAnimTrack(false)
end

function AnimationTrack:play(offset,alreadySent)
	printFn('AnimationTrack:play(',offset,')')
	printInfo('self.animationEnabled ',self.animationEnabled)
	printInfo('self.stopTimerId ',self.stopTimerId)
	printInfo('self.onEndTimerId ',self.onEndTimerId)
	printInfo('self:getAnimTrackTime() ',self:getAnimTrackTime())
	printInfo('self.animationSpeed ',self.animationSpeed)
	
	
	if offset==nil then
		offset = self.offsetPlay
	elseif offset<0 then
		-- should have already started
		local animTrackTime=self:getAnimTrackTime()
		if self.animationSpeed<0 then
			animTrackTime=animTrackTime+offset
		else
			animTrackTime=animTrackTime-offset
		end
		self:setAnimTrackTime(animTrackTime)
		offset=0
	end
	if offset>0 then
		printInfo('add play timer with offset ',offset)
		self.playTimerId = reviveTimer(self.playTimerId, offset, "playNow", self)
		self.playRunTime = UniversalProcessKitListener.runTime + offset
	else
		self.playRunTime = UniversalProcessKitListener.runTime
		self:playNow()
	end
	if not alreadySent then
		self:raiseDirtyFlags(self.playDirtyFlag)
	end
end

function AnimationTrack:playNow()
	printFn('AnimationTrack:playNow()')
	
	self.playTimerId = nil
	--if not self.animationEnabled then
		printInfo('play animation')
		self:setAnimTrackSpeedScale(self.animationSpeedPlay)
		self:enableAnimTrack()
		self:addOnEndTimer()
	--end
	return false -- for timer
end

function AnimationTrack:stop(offset,alreadySent)
	printFn('AnimationTrack:stop(',offset,')')
	if offset==nil then
		offset = self.offsetStop
	elseif offset<0 then
		-- should have already stopped
		local animTrackTime=self:getAnimTrackTime()
		if self.animationSpeed<0 then
			animTrackTime=animTrackTime-offset
		else
			animTrackTime=animTrackTime+offset
		end
		self:setAnimTrackTime(animTrackTime)
		offset=0
	end
	if offset>0 then
		printInfo('add stop timer with offset ',offset)
		self.stopTimerId = reviveTimer(self.stopTimerId, offset, "stopNow", self)
		self.stopRunTime = UniversalProcessKitListener.runTime + offset
	else
		self.stopRunTime = UniversalProcessKitListener.runTime
		self:stopNow()
	end
	if not alreadySent then
		self:raiseDirtyFlags(self.stopDirtyFlag)
	end
end

function AnimationTrack:stopNow()
	printFn('AnimationTrack:stopNow()')
	-- rewind on stop
	if self.rewindOnStop and self.animationSpeed>=0 then
		printInfo('rewind on stop')
		self:setAnimTrackSpeedScale(-self.animationSpeedPlay)
		self:enableAnimTrack()
		self:addOnEndTimer()
		return false
	end
	if self.animationEnabled then
		
		printInfo('stop animation')
		self:disableAnimTrack()
		if self.onEndTimerId~=nil then
			removeTimer(self.onEndTimerId)
			self.onEndTimerId=nil
		end
		self.loopCount = 0
	end
	self.stopTimerId = nil
	return false -- for timer
end
	
function AnimationTrack:addOnEndTimer(offset)
	printFn('AnimationTrack:addOnEndTimer()')
	offset = offset or 0
	local animTrackTime=self:getAnimTrackTime()
	printAll('animTrackTime ',animTrackTime)
	if self.animationSpeed<0 then
		offset = max(0,min(self.animDuration,animTrackTime))
	else
		offset = max(0,min(self.animDuration,self.animDuration-animTrackTime))
	end
	printAll('offset ',offset)
	self.onEndTimerId = reviveTimer(self.onEndTimerId, offset, "onEndTimerCallback", self)
	self.onEndRunTime = UniversalProcessKitListener.runTime + offset
end


function AnimationTrack:onEndTimerCallback()
	printFn('AnimationTrack:onEndTimerCallback()')
	local offset = UniversalProcessKitListener.runTime - self.onEndRunTime
	if offset<-30 then
		-- keep timer for maybe one more frame
		printInfo('reseting onend timer with offset ',-offset)
		setTimerTime(self.onEndTimerId,-offset)
		return true
	end
	self.onEndRunTime = UniversalProcessKitListener.runTime - offset + self.animDuration
	if offset<0 then
		offset=0
	end
	if self.loop==0 or (self.loop~=0 and self.loopCount<self.loop) then
		self.loopCount = self.loopCount+1
		if self.rewindOnEnd then
			self:setAnimTrackSpeedScale(-self.animationSpeed)
			if self.animationSpeed<0 then
				self:setAnimTrackTime(self.animDuration-offset)
			else
				self:setAnimTrackTime(offset)
			end
		else
			self:setAnimTrackTime(offset)
		end
		setTimerTime(self.onEndTimerId,self.animDuration-offset)
		return true
	end
	self.onEndTimerId=nil
	self:disableAnimTrack()
	return false
end

