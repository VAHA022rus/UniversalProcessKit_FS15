-- by mor2000

UniversalProcessKit.actionIdToName = {}
UniversalProcessKit.actionNameToId = {}
UniversalProcessKit.actionIdsSyncThruStream = {}

function UniversalProcessKit.registerActionName(actionName,actionId)
	if type(actionName)=="string" and UniversalProcessKit.actionNameToId[actionName]==nil then
		local id=actionId or length(UniversalProcessKit.actionNameToId)+1
		UniversalProcessKit.actionIdToName[id]=actionName
		UniversalProcessKit.actionNameToId[actionName]=id
		if g_server~=nil and UniversalProcessKitListener.syncingObject~=nil then -- loadmap done
			UniversalProcessKitListener.syncingObject:addActionNameToSync(actionName)
		end
	end
end

function UniversalProcessKit.syncActionThruStream(actionName,syncThruStream)
	printFn('UniversalProcessKit.syncActionThruStream(',actionName,', ',syncThruStream,')')
	local actionId = UniversalProcessKit.actionNameToId[actionName]
	if type(actionName)~="string" or actionId==nil then
		printErr('cannot set sync attribute for unknown action')
		return
	end
	if syncThruStream or syncThruStream==nil then
		UniversalProcessKit.actionIdsSyncThruStream[actionId] = true
	else
		UniversalProcessKit.actionIdsSyncThruStream[actionId] = nil
	end
end

function UniversalProcessKit:getActionUserAttributes(actionName, defaultEnableChildren, defaultDisableChildren)
	self:printFn('UniversalProcessKit:getActionUserAttributes(',actionName,', ',defaultEnableChildren,', ',defaultDisableChildren,')')
	
	if type(actionName)~="string" or strlen(actionName)==0 or self.actions[actionName]~=nil then
		self:printErr('faulty actionName')
		return
	end
	
	local nodeId = self.nodeId
	
	local actions_mt = {
		__index = function(t,k)
			rawset(t,k,false)
			return false
		end
	}
	self.actions[actionName] = {}
	setmetatable(self.actions[actionName],actions_mt)
	
	if self.isServer then
		UniversalProcessKit.registerActionName(actionName)
	end

	local enableChildrenAction = 'enableChildren'..actionName
	local disableChildrenAction = 'disableChildren'..actionName
	
	local emptyFillTypesAction = 'emptyFillTypes'..actionName
	local topUpFillTypesAction = 'topUpFillTypes'..actionName
	
	local addAction = 'add'..actionName
	local removeAction = 'remove'..actionName
	
	-- show and hide shapes
	local showAction = 'show'..actionName
	local hideAction = 'hide'..actionName
	
	-- audio samples and animations
	local playAction = 'play'..actionName
	local stopAction = 'stop'..actionName
	
	local action = self.actions[actionName]
	
	action['enableChildren'] = getBoolFromUserAttribute(nodeId, enableChildrenAction, defaultEnableChildren or false)
	action['disableChildren'] = getBoolFromUserAttribute(nodeId, disableChildrenAction, defaultDisableChildren or false)
	
	if action['enableChildren'] then
		action['disableChildren'] = false
	end
	
	action['emptyFillTypes'] = {}
	local arr = getArrayFromUserAttribute(nodeId, emptyFillTypesAction)
	for i=1,#arr do
		local fillType = unpack(UniversalProcessKit.fillTypeNameToInt(arr[i]))
		table.insert(action['emptyFillTypes'],fillType)
		action['hasEmptyFillTypes'] = true
	end
	
	action['topUpFillTypes'] = {}
	local arr = getArrayFromUserAttribute(nodeId, topUpFillTypesAction)
	for i=1,#arr do
		local fillType = unpack(UniversalProcessKit.fillTypeNameToInt(arr[i]))
		table.insert(action['topUpFillTypes'],fillType)
		action['hasTopUpFillTypes'] = true
	end
	
	action['add'] = __c()
	local arr = getArrayFromUserAttribute(nodeId, addAction)
	for i=1,#arr,2 do
		local amount = tonumber(arr[i])
		local fillType = unpack(UniversalProcessKit.fillTypeNameToInt(arr[i+1]))
		if type(amount)=="number" and amount>0 and type(fillType)=="number" then
			action['add'][fillType] = (action['add'][fillType] or 0) + amount
			action['hasAdd'] = true
		end
	end
	
	action['remove'] = __c()
	local arr=getArrayFromUserAttribute(nodeId, removeAction)
	for i=1,#arr,2 do
		local amount = tonumber(arr[i])
		local fillType = unpack(UniversalProcessKit.fillTypeNameToInt(arr[i+1]))
		if type(amount)=="number" and amount>0 and type(fillType)=="number" then
			action['remove'][fillType] = (action['remove'][fillType] or 0) - amount
			action['hasRemove'] = true
		end
	end
	
	-- shapes
	local emptyArr = {}
	
	action['show'] = getArrayFromUserAttribute(nodeId, showAction, emptyArr)
	if action['show']~=emptyArr then
		action['hasShow'] = true
	end
	
	action['hide'] = getArrayFromUserAttribute(nodeId, hideAction, emptyArr)
	if action['hide']~=emptyArr then
		action['hasHide'] = true
	end
	
	-- audio samples and animations
	action['play'] = getArrayFromUserAttribute(nodeId, playAction, emptyArr)
	if action['play']~=emptyArr then
		action['hasPlay'] = true
	end
	
	action['stop'] = getArrayFromUserAttribute(nodeId, stopAction, emptyArr)
	if action['stop']~=emptyArr then
		action['hasStop'] = true
	end
end

function UniversalProcessKit:operateAction(actionName, multiplier, alreadySent)
	self:printFn('UniversalProcessKit:operateAction(',actionName,',',multiplier,',',alreadySent,')')
	
	if type(actionName)~="string" or strlen(actionName)==0 or self.actions[actionName]==nil then
		self:printErr('faulty actionName')
		return
	end
	
	if multiplier==nil then
		multiplier=1
	end
	
	if self.isServer then
		local actionId = UniversalProcessKit.actionNameToId[actionName]
		if UniversalProcessKit.actionIdsSyncThruStream[actionId] then
			-- wait for stream
			table.insert(self.actionsToSync,{actionId, multiplier})
			self:raiseDirtyFlags(self.actionsDirtyFlag)
		else
			-- instant sync
			self:sendEvent(UniversalProcessKitEvent.TYPE_ACTION, actionId, multiplier)
		end
	end

	local action = self.actions[actionName]
	
	if self.isServer and self.isLoaded then
		if action['hasEmptyFillTypes'] then
			for i=1,#action['emptyFillTypes'] do
				self:setFillLevel(0,action['emptyFillTypes'][i])
			end
		end
		if action['hasTopUpFillTypes'] then
			for i=1,#action['topUpFillTypes'] do
				local fillType = action['topUpFillTypes'][i]
				local capacity = self:getCapacity(fillType)
				if capacity<math.huge then
					self:setFillLevel(capacity,fillType)
				end
			end
		end
		if action['hasAdd'] then
			self:addFillLevels(action['add']*multiplier)
		end
		if action['hasRemove'] then
			self:addFillLevels(action['remove']*multiplier)
		end
		
		-- audio samples and animations
		if action['hasPlay'] then
			for _,shapeName in pairs(action['play']) do
				if self.base.playableShapes[shapeName]~=nil then
					self.base.playableShapes[shapeName]:play()
				end
			end
		end
	
		if action['hasStop'] then
			for _,shapeName in pairs(action['stop']) do
				if self.base.playableShapes[shapeName]~=nil then
					self.base.playableShapes[shapeName]:stop()
				end
			end
		end
	end
	
	if action['enableChildren'] then
		self:printAll('enable children')
		self:setEnableChildren(true, alreadySent)
	end
	if action['disableChildren'] then
		self:printAll('disable children')
		self:setEnableChildren(false, alreadySent)
	end	
	
	if action['hasShow'] then
		self.base:setVisibility(action['show'],true)
	end
	
	if action['hasHide'] then
		self.base:setVisibility(action['hide'],false)
	end
end

