-- by mor2000

-- audio source sample

local AudioSourceSample_mt={
	__index=AudioSourceSample
}

function AudioSourceSample.new(shapeId)
	local sample={}
	sample.shapeId=shapeId
	sample.sampleId=getAudioSourceSample(shapeId)
	if sample.sampleId==nil or sample.sampleId==0 then
		return false
	end
	sample.sampleDuration=getSampleDuration(sample.sampleId)
	sample.timerId=nil
	setmetatable(sample,AudioSourceSample_mt)
	setVisibility(sample.shapeId,false)
	return sample
end

function AudioSourceSample.play(self)
	if self.timerId~=nil then
		removeTimer(self.timerId)
		self.timerId=nil
	end
	setVisibility(self.shapeId,true)
	self.timerId=addTimer(self.sampleDuration, "timerCallback", self)
end

function AudioSourceSample.stop(self)
	setVisibility(self.shapeId,false)
	if self.timerId~=nil then
		removeTimer(self.timerId)
		self.timerId=nil
	end
end
	
function AudioSourceSample.timerCallback(self)
	setVisibility(self.shapeId,false)
	self.timerId=nil
	return false
end
