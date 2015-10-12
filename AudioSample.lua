-- by mor2000

-- handle audio sample

local AudioSample_mt={
	__index=AudioSample
}

function AudioSample.new(shapeId,syncObj)
	local self={}
	
	self.shapeId=shapeId
	self.shapeName=getName(shapeId)
	
	if syncObj==nil then
		printErr('no sync object provided')
		return false
	end
	
	self.sampleId=getAudioSourceSample(shapeId)
	
	if self.sampleId==nil or self.sampleId==0 then
		printAll('no audio sample found for shape "',self.shapeName,'"')
		return false
	end
	
	self.sampleDuration=getSampleDuration(self.sampleId)
	
	local loop = getUserAttribute(shapeId, "audioLoop")
	self.loop = 1
	if loop==true then
		self.loop = 0 -- loop till stop
	elseif type(loop)=="number" and loop>=0 then
		self.loop = loop
	end
	self.loopCount = 0
	
	self.offsetPlay = getNumberFromUserAttribute(shapeId, "audioOffsetPlay", 0, 0)*1000
	self.offsetStop = getNumberFromUserAttribute(shapeId, "audioOffsetStop", 0, 0)*1000
	
	local audioEnabled = getBoolFromUserAttribute(shapeId, "audioEnabled") or getVisibility(self.shapeId)
	
	setmetatable(self,AudioSample_mt)
	
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
	
	setVisibility(self.shapeId,false)

	if audioEnabled then
		self:playNow()
	else
		self.audioEnabled=false
	end
	
	return self
end

function AudioSample:delete()
	printFn('AudioSample:delete()')
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

function AudioSample:writeStream(streamId, connection)
	printFn('AudioSample:writeStream(',streamId,', ',connection,')')
	if not connection:getIsServer() then
		--streamWriteAuto(streamId,self:getAudioSampleTime()%self.sampleDuration)
		streamWriteAuto(streamId,self.audioEnabled)
		
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

function AudioSample:readStream(streamId, connection)
	printFn('AudioSample:readStream(',streamId,', ',connection,')')
	if connection:getIsServer() then
		--local audioSourceTime=streamReadAuto(streamId)
		local audioEnabled=streamReadAuto(streamId)
		self:enableAudioSource(audioEnabled)
		
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

function AudioSample:writeUpdateStream(streamId, connection, dirtyMask, syncall)
	printFn('AudioSample:writeUpdateStream(',streamId,', ',connection,', ',dirtyMask,', ',syncall,')')
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

function AudioSample:doAfterAllClientsAreSynced()
	printFn('AudioSample:doAfterAllClientsAreSynced()')
	self.dirtyMask = 0
end

function AudioSample:readUpdateStream(streamId, connection, dirtyMask, syncall)
	printFn('AudioSample:readUpdateStream(',streamId,', ',connection,', ',dirtyMask,', ',syncall,')')
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

function AudioSample:getNextDirtyFlag()
	printFn('AudioSample:getNextDirtyFlag()')
	return Object.getNextDirtyFlag(self)
end

function AudioSample:raiseDirtyFlags(flag)
	printFn('AudioSample:raiseDirtyFlags(',flag,')')
	if self.isServer then
		Object.raiseDirtyFlags(self,flag)
		self.syncObj:raiseDirtyFlags(self.syncObj.objectsToSyncDirtyFlag)
	end
end

function AudioSample:loadFromAttributes(xmlFile, key)
	printFn('AudioSample:loadFromAttributes(',xmlFile,', ',key,')')
	
	local audioEnabled = getXMLBool(xmlFile, key .. "#audioEnabled") or self.audioEnabled
	if audioEnabled then
		self:play(0)
	else
		self:stop(0)
	end
	
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

function AudioSample:getSaveAttributes()
	printFn('AudioSample:getSaveAttributes()')
	local attributes=""
	
	attributes=attributes..' audioEnabled="'..tostring(self.audioEnabled)..'"'
	
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

function AudioSample:getAudioSampleTime()
	printFn('AudioSample:getAudioSampleTime()')
	local audioSampleTime = 0
	if self.audioEnabled then
		audioSampleTime=UniversalProcessKitListener.runTime - self.playRunTime
	end
	return audioSampleTime
end

function AudioSample:enableAudioSource(enable)
	printFn('AudioSample:enableAudioSource(',enable,')')
	enable=enable or false
	if enable~=self.audioEnabled then
		setVisibility(self.shapeId,enable)
		self.audioEnabled=enable
	end
end

function AudioSample:play(offset,alreadySent)
	printFn('AudioSample:play(',offset,')')
	if self.audioEnabled then
		return
	end
	if offset==nil then
		offset=self.offsetPlay
	elseif offset<0 then
		-- should have already started
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

function AudioSample:playNow()
	printFn('AudioSample:playNow()')
	self.playTimerId = nil
	if not self.audioEnabled then
		printInfo('play audio sample')
		self:enableAudioSource(true)
		self:addOnEndTimer()
	end
	return false -- for timer
end

function AudioSample:stop(offset,alreadySent)
	printFn('AudioSample:stop(',offset,')')
	if offset==nil then
		offset = self.offsetStop
	elseif offset<0 then
		-- should have already stopped
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

function AudioSample:stopNow()
	printFn('AudioSample:stopNow()')
	self.stopTimerId = nil
	if self.audioEnabled then
		self:enableAudioSource(false)
		if self.onEndTimerId~=nil then
			removeTimer(self.onEndTimerId)
			self.onEndTimerId=nil
		end
		self.loopCount = 0
	end
	return false -- for timer
end

function AudioSample:addOnEndTimer()
	printFn('AudioSample:addOnEndTimer()')
	local audioSourceTime=self:getAudioSampleTime()%self.sampleDuration
	local offset = self.sampleDuration-audioSourceTime
	self.onEndTimerId = reviveTimer(self.onEndTimerId, offset, "onEndTimerCallback", self)
	self.onEndRunTime = UniversalProcessKitListener.runTime + offset
end

function AudioSample:onEndTimerCallback()
	printFn('AudioSample:onEndTimerCallback()')
	local offset = UniversalProcessKitListener.runTime - self.onEndRunTime
	if offset<-30 then
		-- keep timer for maybe one more frame
		printInfo('reseting onend timer with offset ',-offset)
		setTimerTime(self.onEndTimerId,-offset)
		return true
	end
	self.onEndRunTime = UniversalProcessKitListener.runTime - offset + self.sampleDuration
	if offset<0 then
		offset=0
	end
	self.loopCount = self.loopCount+1
	if self.loop==0 or (self.loop~=0 and self.loopCount<self.loop) then
		setTimerTime(self.onEndTimerId,self.animDuration-offset)
		return true
	end
	self.onEndTimerId=nil
	self:stop()
	return false
end