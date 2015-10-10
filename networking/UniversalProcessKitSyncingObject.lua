-- by mor2000

UniversalProcessKitSyncingObject = {}
UniversalProcessKitSyncingObject_mt = Class(UniversalProcessKitSyncingObject, Object)
InitObjectClass(UniversalProcessKitSyncingObject, "UniversalProcessKitSyncingObject")

function UniversalProcessKitSyncingObject:new(isServer, isClient)
	printFn('UniversalProcessKitSyncingObject:new(',isServer,', ',isClient,')')
	local self = Object:new(isServer, isClient, UniversalProcessKitSyncingObject_mt)
	registerObjectClassName(self, "UniversalProcessKitSyncingObject")
	printInfo('UniversalProcessKitSyncingObject id is ',self.id)
	
	self.runTimeDirtyFlag = self:getNextDirtyFlag()
	
	self.fillTypeNamesToSyncDirtyFlag = self:getNextDirtyFlag()
	self.fillTypeNamesToSync = {}
	
	self.actionNamesToSyncDirtyFlag = self:getNextDirtyFlag()
	self.actionNamesToSync = {}
	
	self.syncedClients={}
	
	return self
end

UniversalProcessKitSyncingObject.load = emptyFunc
UniversalProcessKitSyncingObject.update = emptyFunc

function UniversalProcessKitSyncingObject:delete()
	printFn('UniversalProcessKitSyncingObject:delete()')
	if g_client ~= nil then
		local serverId = g_client:getObjectId(self)
		printAll('serverId = ',serverId)
	end
	
	
	--[[
	
	unregisterObjectClassName(self)
	
	self:unregister()
	if g_server ~= nil then
		g_server:unregisterObject(self)
		g_server:removeObject(self, self.id)
		--self.isRegistered = false
	else
		local serverId = g_client:getObjectId(self)
		print('serverId = ',serverId))
		print('g_client.tempClientCreatingObjects[serverId] = ',g_client.tempClientCreatingObjects[serverId]))
	--]]
		--[[
		if serverId~=nil and serverId~=0 then		
			g_client:unregisterObject(self, true)
		end
		
		local serverId = g_client:getObjectId(self)
		print('serverId = ',serverId))
		
		print('g_client.tempClientCreatingObjects[serverId] = ',g_client.tempClientCreatingObjects[serverId]))
		]]--
		--g_client:removeObject(self, self.net)
		--self.isRegistered = false
	--end
	UniversalProcessKitSyncingObject:superClass().delete(self)
end

function UniversalProcessKitSyncingObject:addFillTypeNameToSync(name)
	printFn('UniversalProcessKitSyncingObject:addFillTypeNameToSync(',name,')')
	if type(name)=="string" and name ~= "" then
		table.insert(self.fillTypeNamesToSync, name)
		self:raiseDirtyFlags(self.fillTypeNamesToSyncDirtyFlag)
	end
end

function UniversalProcessKitSyncingObject:addActionNameToSync(name)
	printFn('UniversalProcessKitSyncingObject:addActionNameToSync(',name,')')
	if type(name)=="string" and name ~= "" then
		table.insert(self.actionNamesToSync, name)
		self:raiseDirtyFlags(self.actionNamesToSyncDirtyFlag)
	end
end

function UniversalProcessKitSyncingObject:writeStream(streamId, connection)
	printFn('UniversalProcessKitSyncingObject:writeStream(',streamId,', ',connection,')')
	if not connection:getIsServer() then -- in connection with client
		printInfo('serverId = ',self.id)
		streamWriteAuto(streamId, self.id)
		
		-- runtime
		streamWriteAuto(streamId, UniversalProcessKitListener.runTime)
		
		-- filltypes
		local countFillTypes = 0
		for fillType=32768,UniversalProcessKit.NUM_FILLTYPES do
			local fillTypeName = UniversalProcessKit.fillTypeIntToName[fillType]
			if fillTypeName~=nil then
				printInfo('I have fill type "',fillTypeName,'" to sync')
				countFillTypes = countFillTypes + 1
			end
		end
		streamWriteAuto(streamId, countFillTypes)
		for fillType=32768,UniversalProcessKit.NUM_FILLTYPES do
			local fillTypeName = UniversalProcessKit.fillTypeIntToName[fillType]
			if fillTypeName~=nil then
				streamWriteAuto(streamId, fillType)
				streamWriteString(streamId, fillTypeName)
			end
		end
		
		-- actions
		local len = length(UniversalProcessKit.actionIdToName)
		streamWriteAuto(streamId, len)
		for id,name in pairs(UniversalProcessKit.actionIdToName) do
			streamWriteAuto(streamId, id)
			streamWriteString(streamId, name)
		end
	end
end

function UniversalProcessKitSyncingObject:readStream(streamId, connection)
	printFn('UniversalProcessKitSyncingObject:readStream(',streamId,', ',connection,')')
	if connection:getIsServer() then -- in connection with server
		local networkNode = streamReadAuto(streamId)
		g_client:finishRegisterObject(self, networkNode or self.id)
		local serverId = g_client:getObjectId(self)
		printInfo('serverId = ',serverId)
		printInfo('g_client.tempClientCreatingObjects[serverId] = ',g_client.tempClientCreatingObjects[serverId])
		
		-- runTime
		UniversalProcessKitListener.runTime = streamReadAuto(streamId)
		
		-- filltypes
		local countFillTypes = streamReadAuto(streamId)
		for i=1,countFillTypes do
			local fillTypeServer = streamReadAuto(streamId)
			local fillTypeName = streamReadString(streamId)
			local fillTypeClient = UniversalProcessKit.fillTypeNameToInt[fillTypeName]
			printInfo('got fill type "',fillTypeName,'" with # ',fillTypeServer,' from server, mine is ',fillTypeClient)
			if fillTypeServer ~= fillTypeClient then
				if fillTypeClient == nil then
					local index = UniversalProcessKit.addFillType(fillTypeName)
					if index ~= fillTypeServer then
						rawset(UniversalProcessKit.fillTypeIntServerToClient, fillTypeServer, index)
						rawset(UniversalProcessKit.fillTypeIntClientToServer, index, fillTypeServer)
					end
				elseif type(fillTypeClient)=="number" then
					rawset(UniversalProcessKit.fillTypeIntServerToClient, fillTypeServer, fillTypeClient)
					rawset(UniversalProcessKit.fillTypeIntClientToServer, fillTypeClient, fillTypeServer)
				end
			end
		end
		
		-- actions
		local len = streamReadAuto(streamId, len)
		for i=1,len do
			local actionId=streamReadAuto(streamId)
			local actionName=streamReadString(streamId)
			UniversalProcessKit.registerActionName(actionName, actionId)
		end
	end
end

function UniversalProcessKitSyncingObject:writeUpdateStream(streamId, connection, dirtyMask)
	printFn('UniversalProcessKitSyncingObject:writeUpdateStream(',streamId,', ',connection,', ',dirtyMask,')')
	if not connection:getIsServer() then -- in connection with client
		streamWriteAuto(streamId,dirtyMask)
		
		if bitAND(dirtyMask,self.runTimeDirtyFlag)~=0 then
			printAll('syncing run time ',UniversalProcessKitListener.runTime)
			streamWriteAuto(streamId, mathfloor(UniversalProcessKitListener.runTime))
		end
			
		if bitAND(dirtyMask,self.fillTypeNamesToSyncDirtyFlag)~=0 then
			local fillTypeNamesToSyncNr = #self.fillTypeNamesToSync
			streamWriteAuto(streamId, fillTypeNamesToSyncNr)
			for i=1,fillTypeNamesToSyncNr do
				local fillTypeName = self.fillTypeNamesToSync[i]
				local fillType = UniversalProcessKit.fillTypeNameToInt[fillTypeName]
				streamWriteAuto(streamId, fillType)
				streamWriteString(streamId, fillTypeName)
			end
		end
		
		if bitAND(dirtyMask,self.actionNamesToSyncDirtyFlag)~=0 then
			local actionNamesToSyncNr = #self.actionNamesToSync
			streamWriteAuto(streamId, actionNamesToSyncNr)
			for i=1,actionNamesToSyncNr do
				local actionName = self.actionNamesToSync[i]
				local actionId = UniversalProcessKit.actionNameToId[actionName]
				streamWriteAuto(streamId, actionId)
				streamWriteString(streamId, actionName)
			end
		end
		
		self.syncedClients[streamId] = true
		local allClientsSynced=true
		for _,client in pairs(g_server.clients) do
			if not self.syncedClients[client] then
				allClientsSynced=false
				break
			end
		end
		if allClientsSynced then
			self.fillTypeNamesToSync = {}
			self.actionNamesToSync = {}
		end
	end
end

function UniversalProcessKitSyncingObject:readUpdateStream(streamId, timestamp, connection)
	printFn('UniversalProcessKitSyncingObject:readUpdateStream(',streamId,', ',timestamp,', ',connection,')')
	if connection:getIsServer() then -- in connection with server
		local dirtyMask=streamReadAuto(streamId)
		
		if bitAND(dirtyMask,self.runTimeDirtyFlag)~=0 then
			local runTime = streamReadAuto(streamId)
			printAll('server runtime is ',runTime,', mine is ',UniversalProcessKitListener.runTime)
			if mathabs(UniversalProcessKitListener.runTime-runTime)>50 then
				printAll('setting local run time to server run time')
				UniversalProcessKitListener.runTime = runTime
			end
			
		end
		
		if bitAND(dirtyMask,self.fillTypeNamesToSyncDirtyFlag)~=0 then
			local fillTypeNamesToSyncNr = streamReadAuto(streamId)
			for i=1,fillTypeNamesToSyncNr do
				local fillTypeServer = streamReadAuto(streamId)
				local fillTypeName = streamReadString(streamId)
				local fillTypeClient = UniversalProcessKit.fillTypeNameToInt[fillTypeName]
				printAll('got fill type "',fillTypeName,'" with # ',fillTypeServer,' from server, mine is ',fillTypeClient)
				if fillTypeServer ~= fillTypeClient then
					if fillTypeClient == nil then
						local index = UniversalProcessKit.addFillType(fillTypeName)
						if index ~= fillTypeServer then
							rawset(UniversalProcessKit.fillTypeIntServerToClient, fillTypeServer, index)
							rawset(UniversalProcessKit.fillTypeIntClientToServer, index, fillTypeServer)
						end
					elseif type(fillTypeClient)=="number" then
						rawset(UniversalProcessKit.fillTypeIntServerToClient, fillTypeServer, fillTypeClient)
						rawset(UniversalProcessKit.fillTypeIntClientToServer, fillTypeClient, fillTypeServer)
					end
				end
			end
		end
		
		if bitAND(dirtyMask,self.actionNamesToSyncDirtyFlag)~=0 then
			local actionNamesToSyncNr = streamReadAuto(streamId)
			for i=1,actionNamesToSyncNr do
				local actionIdServer = streamReadAuto(streamId)
				local actionName = streamReadString(streamId)
				local actionIdClient = UniversalProcessKit.actionNameToId[actionName]
				printAll('got action "',actionName,'" with # ',actionIdServer,' from server, mine is ',actionIdClient)
				if fillTypeServer ~= fillTypeClient then
					if fillTypeClient == nil then
						UniversalProcessKit.registerActionName(actionName, actionIdServer)
					elseif type(actionIdClient)=="number" then
						printErr('faulty actionId on Client, overwriting for now')
						UniversalProcessKit.actionIdToName[actionIdServer]=actionName
						UniversalProcessKit.actionNameToId[actionName]=actionIdServer
					end
				end
			end
		end
	end
end