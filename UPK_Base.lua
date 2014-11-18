-- by mor2000

--------------------
-- Base (root of every building, has no parent, main storage in simple buildings)


local UPK_Base_mt = ClassUPK(UPK_Base,UniversalProcessKit)
InitObjectClass(UPK_Base, "UPK_Base")
UniversalProcessKit.addModule("base",UPK_Base)

function UPK_Base:new(id, placeable, builtIn)
	self:print('UPK_Base:new')
	local self = UniversalProcessKit:new(id, self, UPK_Base_mt)
	registerObjectClassName(self, "UPK_Base")
	
	self.placeable = placeable or false
	self.builtIn = builtIn or false
	
	if self.builtIn then
		g_currentMission:addOnCreateLoadedObjectToSave(self)
	end
	
	local upk=ModsUtil.modNameToMod["AAA_UniversalProcessKit"]
	if upk==nil then
		print('ERROR (YOUR FAULT): DO NOT RENAME THE UniversalProcessKit MOD FILE - NOTHING WILL WORK - it has to be "AAA_UniversalProcessKit"')
		return false
	end
	
	local UPKversion = getUserAttribute(id, "UPKversion")
	if UPKversion~=nil then
		local reqversion={}
		for _,v in pairs(gmatch(UPKversion,"[0-9]+")) do
			table.insert(reqversion,v)
		end;
		local upk_version={}
		for _,v in pairs(gmatch(upk.version,"[0-9]+")) do
			table.insert(upk_version,v)
		end;
		for k,v in pairs(upk_version) do
			if v>(reqversion[k] or 0) then
				break
			elseif v<(reqversion[k] or 0) then
				print('Error (your fault): the required upk version of this mod ('..tostring(UPKversion)..') doesnt fit your upk mod ('..tostring(upk.version)..')', true)
				return false
			end
		end
	end
	
	self:print('loaded Base successfully')
	
	return self
end

function UPK_Base:delete()
	if self.builtIn then
		g_currentMission:removeOnCreateLoadedObjectToSave(self)
		if self.nodeId ~= 0 then
	        g_currentMission:removeNodeObject(self.nodeId)
	    end
	end
	UPK_Base:superClass().delete(self)
end
