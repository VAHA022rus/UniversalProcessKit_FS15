-- by mor2000

--------------------
-- Base (root of every building, has no parent, main storage in simple buildings)

local UniversalProcessKit_i18n_mt = {
	__index = function(t,key)
		local text=""
		if type(key)=="string" then
			local i18nNameSpace=rawget(t,"i18nNameSpace") -- modname
			if i18nNameSpace~=nil and
				(_g or {})[i18nNameSpace]~=nil and
				_g[i18nNameSpace].g_i18n~=nil and
				_g[i18nNameSpace].g_i18n:hasText(key) then
				text=_g[i18nNameSpace].g_i18n:getText(key)
			elseif g_i18n:hasText(key) then
				text=g_i18n:getText(key)
			end
			rawset(t,key,text)
			--print('asked i18n for \"'..tostring(key)..'\" returning \"'..tostring(text)..'\"')
		end
		return text
	end
}

local UPK_Base_mt = ClassUPK(UPK_Base,UniversalProcessKit)
InitObjectClass(UPK_Base, "UPK_Base")
UniversalProcessKit.addModule("base",UPK_Base)

function UPK_Base:new(nodeId, placeable, builtIn, syncObj)
	printFn('UPK_Base:new(',nodeId,', ',placeable,', ',builtIn,', ',syncObj,')')
	
	local self = UniversalProcessKit:new(nodeId, nil, UPK_Base_mt)
	registerObjectClassName(self, "UPK_Base")
	
	self.placeable = placeable or false
	self.builtIn = builtIn or false
	self.syncObj = syncObj
	self.base = self
	self.syncObj:registerObjectToSync(self) -- invokes to call read and writeStream
	
	-- shape visibilities
	self.shapeVisibility={} -- current shape visibility (by shape name)
	self.shapeVisibilityDefault={} -- default shape visibility (by shape name)
	self.shapeVisibilityChanged={} -- run time when changed
	
	if self.builtIn then
		g_currentMission:addOnCreateLoadedObjectToSave(self)
	end
	
	self.timesSaved = 0
	
	local upk=ModsUtil.modNameToMod["AAA_UniversalProcessKit"]
	if upk==nil then
		self:printErr('ERROR (YOUR FAULT): DO NOT RENAME THE UniversalProcessKit MOD FILE - NOTHING WILL WORK - it has to be "AAA_UniversalProcessKit"')
		return false
	end
	
	-- i18nNameSpace
	
	self.i18nNameSpace = getStringFromUserAttribute(nodeId, "modname")
	self.i18n.i18nNameSpace = self.i18nNameSpace
	setmetatable(self.i18n, UniversalProcessKit_i18n_mt)
	
	-- check version
	
	local function versionStringToNumber(versionStr)
		local versionArr=gmatch(versionStr,"[0-9]+")
		local version=0
		for i=1,length(versionArr) do
			version=version+versionArr[i]*10^((4-i)^2)
		end
		return version
	end
	
	local UPKversion = getUserAttribute(nodeId, "UPKversion")
	if UPKversion~=nil and type(UPKversion)=="string" then
		local currentUpkVersion=versionStringToNumber(upk.version)
		local requiredUpkVersion=versionStringToNumber(UPKversion)
		if currentUpkVersion<requiredUpkVersion then
			self:printErr('Error: the required upk version of this mod (',UPKversion,') doesnt fit your upk mod (',upk.version,')')
			
			--[[
			if not UniversalProcessKitListener.requiredUpkVersionWarningShown then
				-- gui callback function
				local currentGuiName=g_gui.currentGuiName
				local function quitInfoDialog()
					g_gui:showGui(currentGuiName)
				end
			
				-- check for version
				local versionWarning=string.format(_g["AAA_UniversalProcessKit"].g_i18n:getText('versionWarning'),UPKversion,upk.version)
				local wrongVersionDialog = g_gui:showGui("InfoDialog")
				wrongVersionDialog.target:setText(versionWarning)
				wrongVersionDialog.target:setCallbacks(quitInfoDialog)
			
				UniversalProcessKitListener.requiredUpkVersionWarningShown=true
			end
			]]--
			
			return false
		end
	end
	
	-- check required mods
	
	--[[
	local requiredMods = getArrayFromUserAttribute(nodeId, "requiredMods")
	for _,mod in ipairs(requiredMods) do
		if ModsUtil.modNameToMod[mod]==nil then
			if not UniversalProcessKitListener.requiredModsWarningShown then
				-- gui callback function
				local currentGuiName=g_gui.currentGuiName
				local function quitInfoDialog()
					g_gui:showGui(currentGuiName)
				end
			
				-- check for version
				local myModTitle=ModsUtil.modNameToMod[self.i18nNameSpace].title
				local requiredModWarning=string.format(_g["AAA_UniversalProcessKit"].g_i18n:getText('requiredModWarning'),myModTitle,mod)
				local requiredModDialog = g_gui:showGui("InfoDialog")
				requiredModDialog.target:setText(requiredModWarning)
				requiredModDialog.target:setCallbacks(quitInfoDialog)
				
				UniversalProcessKitListener.requiredModsWarningShown=true
				break
			end
		end
	end
	]]--
	
	
	self.shapeNamesToNodeIds={}
	self.playableShapes={}
	
	self:printInfo('UPK_Base:new done')
	
	return self
end

function UPK_Base:delete()
	self:printFn('UPK_Base:delete()')
	if self.builtIn then
		g_currentMission:removeOnCreateLoadedObjectToSave(self)
		if self.nodeId ~= 0 then
	        g_currentMission:removeNodeObject(self.nodeId)
	    end
	end
	UPK_Base:superClass().delete(self)
end

function UPK_Base:loadFromAttributesAndNodes(xmlFile, key)
	self:printFn('UPK_Base:loadFromAttributesAndNodes(',xmlFile,', ',key,')')
	
	self.timesSaved = getXMLInt(xmlFile, key .. "#timesSaved") or 0
	
	self:printAll('times saved: '..tostring(self.timesSaved))
	
	for shapeName,playableShape in pairs(self.playableShapes) do
		playableShape:loadFromAttributes(xmlFile, key..'.'..shapeName)
	end
	
	return UPK_Base:superClass().loadFromAttributesAndNodes(self, xmlFile, key)
end;

function UPK_Base:getSaveAttributesAndNodes(nodeIdent)
	self:printFn('UPK_Base:getSaveAttributesAndNodes(',nodeIdent,')')
	local attributes, nodes = UPK_Base:superClass().getSaveAttributesAndNodes(self,nodeIdent)
	
	if nodes~="" then
		nodes = "\t\t" .. nodes
	end
	
	local timesSaved = ' timesSaved=\"' .. ((self.timesSaved or 0)+1) .. '\"'

	if attributes~="" then
		attributes = timesSaved .. ' ' .. attributes
	else
		attributes = timesSaved
	end
	
	for shapeName,playableShape in pairs(self.playableShapes) do
		local shapeAttributes = playableShape:getSaveAttributes()
		if shapeAttributes~="" then
			nodes = nodes .. "\n\t\t" .. '<' .. shapeName .. shapeAttributes .. ' />'
		end
	end

	return attributes, nodes
end;

-- networking

function UPK_Base:writeStream(streamId, connection)
	self:printFn('UPK_Base:writeStream(',streamId,', ',connection,')')
	UniversalProcessKit.writeStream(self, streamId, connection)
	if not connection:getIsServer() then -- in connection with client
		local shapeVisLen=length(self.shapeVisibility)
		streamWriteAuto(streamId, shapeVisLen)
		for name,vis in pairs(self.shapeVisibility) do
			streamWriteAuto(streamId, name)
			streamWriteAuto(streamId, vis)
			streamWriteAuto(streamId, self.shapeVisibilityChanged[name])
		end
	end
end

function UPK_Base:readStream(streamId, connection)
	self:printFn('UPK_Base:readStream(',streamId,', ',connection,')')
	UniversalProcessKit.readStream(self, streamId, connection)
	if connection:getIsServer() then -- in connection with server
		local shapeVisLen=streamReadAuto(streamId)
		for i=1,shapeVisLen do
			local name=streamReadAuto(streamId)
			local vis=streamReadAuto(streamId)
			local changed=streamReadAuto(streamId) or UniversalProcessKitListener.runTime
			if self.shapeNamesToAudioSamples[name]==nil then
				self:setVisibility(name,vis)
			else
				local offset=UniversalProcessKitListener.runTime - changed
				self:playSample(name,vis,offset)
			end
		end
	end
end

-- shapes

function UPK_Base:setVisibility(name,show) -- show and hide
	self:printFn('UPK_Base:setVisibility(',name,',',show,')')
	
	if name==nil or name=="" then
		return false
	end
	
	if type(name)=="table" then
		for _,shapeName in pairs(name) do
			self:setVisibility(shapeName,show)
		end
		return
	end
	
	local shapeId=self.shapeNamesToNodeIds[name]
	if shapeId==nil then
		self:printErr('name of shape "',name,'" unknown and/or not valid')
		return false
	end
	
	if self.shapeVisibilityDefault[name]==nil then
		self.shapeVisibilityDefault[name]=getVisibility(shapeId)
	end
	
	if show~=self.shapeVisibilityDefault[name] then
		self.shapeVisibility[name]=show
		self.shapeVisibilityChanged[name]=UniversalProcessKitListener.runTime
	else
		self.shapeVisibility[name]=nil
		self.shapeVisibilityChanged[name]=nil
	end
	
	setVisibility(shapeId,show)
end

function UPK_Base:playSample(name,play,offset) -- start and stop
	self:printFn('UPK_Base:playSample(',name,')')
	
	if name==nil or name=="" then
		return false
	end
	
	if type(name)=="table" then
		for _,shapeName in pairs(name) do
			self:playSample(shapeName,play,offset)
		end
		return
	end
	
	local audioSample=self.shapeNamesToAudioSamples[name]
	if audioSample==nil then
		self:printErr('name of audio source "',name,'" unknown and/or not valid')
		return false
	end
	
	local shapeId=self.shapeNamesToNodeIds[name]
	
	if self.shapeVisibilityDefault[name]==nil then
		self.shapeVisibilityDefault[name]=getVisibility(shapeId)
	end
	
	if play~=self.shapeVisibilityDefault[name] then
		self.shapeVisibility[name]=play
		self.shapeVisibilityChanged[name]=UniversalProcessKitListener.runTime
	else
		self.shapeVisibility[name]=nil
		self.shapeVisibilityChanged[name]=nil
	end
	
	if play then
		audioSample:play(offset)
	else
		audioSample:stop()
	end
end
