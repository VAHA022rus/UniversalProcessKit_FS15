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
	
	self.animationSpeed = getNumberFromUserAttribute(shapeId, "animationSpeed", 1)
	local rewindAnimationOnDisable = getBoolFromUserAttribute(shapeId, "rewindAnimationOnDisable", false) -- animator
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
	if self.onEndTimerId~=nil then
		removeTimer(self.onEndTimerId)
	end
	if self.playTimerId~=nil then
		removeTimer(self.playTimerId)
	end
	if self.stopTimerId~=nil then
		removeTimer(self.stopTimerId)
	end
	self.syncObj.base.playableShapeNames[self.shapeName]=nil
end

function AnimationTrack:writeStream(streamId, connection)
	printFn('AnimationTrack:writeStream(',streamId,', ',connection,')')
	if not connection:getIsServer() then
		streamWriteAuto(streamId,self:getAnimTrackTime()%self.animDuration)
		streamWriteAuto(streamId,self.animationSpeed)
		streamWriteAuto(streamId,self.animationEnabled)

		local hasOnEndTimer = self.onEndTimerId~=nil
		streamWriteAuto(streamId,hasOnEndTimer)
		if hasOnEndTimer then
			streamWriteAuto(streamId,self.loopCount)
		end
		
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
	end
end

function AnimationTrack:readStream(streamId, connection)
	printFn('AnimationTrack:readStream(',streamId,', ',connection,')')
	if connection:getIsServer() then
		local animTrackTime=streamReadAuto(streamId)
		local animationSpeed=streamReadAuto(streamId)
		local animationEnabled=streamReadAuto(streamId)
		
		self:setAnimTrackTime(animTrackTime)
		self:setAnimTrackSpeedScale(animationSpeed)
		self:enableAnimTrack(animationEnabled)
		
		if streamReadAuto(streamId) then
			self:addOnEndTimer()
			self.loopCount=streamReadAuto(streamId)
		end
		
		if streamReadAuto(streamId) then
			local playRunTime = streamReadAuto(streamId)
			local offset = playRunTime - UniversalProcessKitListener.runTime
			self:play(offset)
		end
		
		if streamReadAuto(streamId) then
			local stopRunTime = streamReadAuto(streamId)
			local offsetStop = stopRunTime - UniversalProcessKitListener.runTime
			self:stop(offset)
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
	printFn('AudioSample:loadFromAttributes(',xmlFile,', ',key,')')
	
	local animTrackTime=getXMLFloat(xmlFile, key .. "#animTrackTime") or self.animTrackTime
	local animationSpeed=getXMLFloat(xmlFile, key .. "#animationSpeed") or self.animationSpeed
	local animationEnabled=getXMLBool(xmlFile, key .. "#animationEnabled") or self.animationEnabled
	
	self:setAnimTrackTime(animTrackTime)
	self:setAnimTrackSpeedScale(animationSpeed)
	self:enableAnimTrack(animationEnabled)
	
	self.loopCount = getXMLInt(xmlFile, key .. "#loopCount") or 0
	
	local playRunTime = getXMLInt(xmlFile, key .. "#playRunTime")
	if playRunTime~=nil then
		self:play(playRunTime,true)
	end
	
	local stopRunTime = getXMLInt(xmlFile, key .. "#stopRunTime")
	if stopRunTime~=nil then
		self:stop(stopRunTime,true)
	end
	
	return true
end

function AnimationTrack:getSaveAttributes()
	printFn('AudioSample:getSaveAttributes()')
	local attributes=""
	
	attributes=attributes..' animTrackTime="'..tostring(self:getAnimTrackTime()%self.animDuration)..'"'
	attributes=attributes..' animationSpeed="'..tostring(self.animationSpeed)..'"'
	attributes=attributes..' animationEnabled="'..tostring(self.animationEnabled)..'"'
	
	if self.onEndTimerId~=nil then
		attributes=attributes..' loopCount="'..tostring(self.loopCount)..'"'
	end
	
	if self.playTimerId~=nil then
		attributes=attributes..' playRunTime="'..tostring(round(self.playRunTime - UniversalProcessKitListener.runTime,0))..'"'
	end
	
	if self.stopTimerId~=nil then
		attributes=attributes..' stopRunTime="'..tostring(round(self.stopRunTime - UniversalProcessKitListener.runTime,0))..'"'
	end
	
	return attributes
end

function AnimationTrack:getAnimTrackTime()
	printFn('AnimationTrack:getAnimTrackTime()')
	local animTrackTime = getAnimTrackTime(self.animCharacterSet, self.animClipIndex)
	return animTrackTime
end

function AnimationTrack:setAnimTrackTime(animTrackTime)
	printFn('AnimationTrack:setAnimTrackTime(',animTrackTime,')')
	animTrackTime = max(0,min(animTrackTime%self.animDuration,self.animDuration))
	setAnimTrackTime(self.animCharacterSet, self.animClipIndex, animTrackTime)
end

function AnimationTrack:setAnimTrackSpeedScale(animationSpeed)
	printFn('AnimationTrack:setAnimTrackSpeedScale(',animationSpeed,')')
	self.animationSpeed = animationSpeed
	setAnimTrackSpeedScale(self.animCharacterSet, self.animClipIndex, self.animationSpeed)
end

function AnimationTrack:enableAnimTrack(enable)
	printFn('AnimationTrack:enableAnimTrack(',enable,')')
	if enable==nil or enable==true then
		self.animationEnabled = true
		enableAnimTrack(self.animCharacterSet, self.animTrack)
	else
		self.animationEnabled = false
		disableAnimTrack(self.animCharacterSet, self.animTrack)
	end
end

function AnimationTrack:disableAnimTrack()
	printFn('AnimationTrack:disableAnimTrack()')
	self:enableAnimTrack(false)
end

function AnimationTrack:play(offset,alreadySent)
	printFn('AnimationTrack:play(',offset,')')
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
	if not self.animationEnabled then
		printInfo('play animation')
		self:enableAnimTrack()
		self:addOnEndTimer()
	end
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
	self.stopTimerId = nil
	if self.animationEnabled then
		printInfo('stop animation')
		self:disableAnimTrack()
		if self.onEndTimerId~=nil then
			removeTimer(self.onEndTimerId)
			self.onEndTimerId=nil
		end
		self.loopCount = 0
	end
	return false -- for timer
end
	
function AnimationTrack:addOnEndTimer()
	printFn('AnimationTrack:addOnEndTimer()')
	local offset = 0
	local animTrackTime=self:getAnimTrackTime()%self.animDuration
	if self.animationSpeed<0 then
		offset = max(0,min(self.animDuration,animTrackTime))
	else
		offset = max(0,min(self.animDuration,self.animDuration-animTrackTime))
	end
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
	self.loopCount = self.loopCount+1
	if self.loop==0 or (self.loop~=0 and self.loopCount<self.loop) then
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
	return false
end

