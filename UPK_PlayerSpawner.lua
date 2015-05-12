-- by mor2000

--------------------
-- PlayerSpawner


local UPK_PlayerSpawner_mt = ClassUPK(UPK_PlayerSpawner,UniversalProcessKit)
InitObjectClass(UPK_PlayerSpawner, "UPK_PlayerSpawner")
UniversalProcessKit.addModule("playerspawner",UPK_PlayerSpawner)

UPK_PlayerSpawner.spawner = {}
UPK_PlayerSpawner.spawnerIndex = 1

function UPK_PlayerSpawner:new(nodeId, parent)
	local self = UniversalProcessKit:new(nodeId, parent, UPK_PlayerSpawner_mt)
	registerObjectClassName(self, "UPK_PlayerSpawner")
	
	table.insert(UPK_PlayerSpawner.spawner,self)
	
	self:print('loaded PlayerSpawner successfully')
	
	return self
end

function UPK_PlayerSpawner:delete()
	removeValueFromTable(UPK_PlayerSpawner.spawner,self)
	UPK_PlayerSpawner.superClass().delete(self)
end

function UPK_PlayerSpawner:setEnable(isEnabled,alreadySent)
	
	UPK_PlayerSpawner.superClass().setEnable(self,isEnabled,alreadySent)
end

function UPK_PlayerSpawner.togglePlayerSpawner(delta)
	print("UPK_PlayerSpawner.togglePlayerSpawner("..tostring(delta)..")")
	local nrPlayerSpawner = #UPK_PlayerSpawner.spawner
	print("nrPlayerSpawner "..tostring(nrPlayerSpawner))
	if nrPlayerSpawner > 0 then
		local index = UPK_PlayerSpawner.spawnerIndex
		local found = false
		for i=1,nrPlayerSpawner do
			index = index + delta
			if index < 1 then
				index = nrPlayerSpawner
			elseif index > nrPlayerSpawner then
				index = 1
			end
			print('index '..tostring(index))
			if UPK_PlayerSpawner.spawner[index].isEnabled then
				found = true
				break
			end
		end
		if found then
			print('next spawner found!')
			print('index '..tostring(index))
			UPK_PlayerSpawner.spawnerIndex = index
			local spawner = UPK_PlayerSpawner.spawner[index]
			local x, y, z = getWorldTranslation(spawner.nodeId)
			local miny = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z) + 0.5
			local dx, _, dz = localDirectionToWorld(spawner.nodeId, 0, 0, 1)
			g_client:getServerConnection():sendEvent(PlayerTeleportEvent:new(x, mathmin(y,miny), z))
			g_currentMission.player.rotY = Utils.getYRotationFromDirection(dx, dz) + math.pi
		end
	end
end
