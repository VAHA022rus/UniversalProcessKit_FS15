-- by mor2000

upkModDirectory = g_currentModDirectory

_m=_G;_G=nil;_g=_G;_G=_m;

_m.mathrandom = math.random
_m.mathsqrt = math.sqrt
_m.mathlog = math.log
_m.mathmin = math.min
_m.mathmax = math.max
_m.mathfloor = math.floor
_m.mathceil = math.ceil
_m.mathabs = math.abs
_m.mathpi = math.pi
_m.mathsin = math.sin
_m.mathcos = math.cos

_g.UniversalProcessKit = {};
_g.UniversalProcessKitStorageBit={};
_g.UniversalProcessKitStorageController={};

----------------------------------
-- basic functions ---------------
----------------------------------

function _m.print(string, debug)
	if debug==nil then
		debug=debugMode
	end
	if debug then
		if type(string)=="string" then
			local msg=string
			if debug then
				msg='DEBUG '..msg
			end
			_g.print(' [UPK] '..msg)
		end
	end
end;

function UniversalProcessKit.InitEventClass(classObject,className)
	if _g[className]~=classObject then
		_g[className]=classObject
		--print("Error: Can't assign eventId to "..tostring(className).." (object name conflict)",true)
		--return
	end
	_g.InitEventClass(classObject,className)
	if classObject.eventId==nil then
		EventIds.assignEventObjectId(classObject,className,EventIds.eventIdNext)
	end
end;

function length(t)
	if t==nil or type(t)~="table" then
		return 0
	end
	local len=0
	for _ in pairs(t) do
		len=len+1
	end
	return len
end;
	
function max(...)
	tmpmax=-math.huge
	arr=...
	if type(arr)~="table" then
		arr={...}
	end
	if length(arr)>0 then
		for _,v in pairs(arr) do
			if v>tmpmax then
				tmpmax=v
			end
		end
		return tmpmax
	end
	return nil
end;

function min(...)
	tmpmin=math.huge
	arr=...
	if type(arr)~="table" then
		arr={...}
	end
	if #arr>0 then
		for _,v in pairs(arr) do
			if v<tmpmin then
				tmpmin=v
			end
		end
		return tmpmin
	end
	return nil
end;

local times10 = {}
local times10_mt = {
	__index = function(t,k)
		local result=10^k
		rawset(t,k,result)
		return result
	end
	}
setmetatable(times10, times10_mt)

function round(nr, digits)
	digits = digits or 0
	local result=mathfloor(nr*times10[digits]+0.5)/times10[digits]
	return result
end

function gmatch(str, pattern)
	local arr={}
	if type(str)=="string" then
		for v in string.gmatch(str,pattern) do
			table.insert(arr,v)
		end
	end
	return arr
end;

function tobool(val)
	return not (val == nil or val == false or val == 0 or val == "0" or val == "false" )
end;

function strlen(...)
	return utf8Strlen(...)
end

function getMinMaxKeys(t)
	if t==nil or type(t)~="table" then
		return nil, nil
	end
	if #t>0 then
		local mink = math.huge
		local maxk = -math.huge
		for k,_ in pairs(t) do
			mink=math.min(mink,k)
			maxk=math.max(maxk,k)
		end
		return mink, maxk
	end
	return nil, nil
end;

function getVectorFromUserAttribute(nodeId, attribute, default)
	local str=Utils.getNoNil(getUserAttribute(nodeId, attribute), default)
	if type(str)=="string" then
		return __c({Utils.getVectorFromString(str)})
	end
	return str
end;

function getNumberFromUserAttribute(nodeId, attribute, default, lowerBound, upperBound)
	local nr=tonumber(Utils.getNoNil(getUserAttribute(nodeId, attribute), default))
	if lowerBound~=nil and nr~=nil then
		nr=mathmax(nr,lowerBound)
	end
	if upperBound~=nil and nr~=nil then
		nr=mathmin(nr,upperBound)
	end
	return nr
end;

function getBoolFromUserAttribute(nodeId, attribute, default)
	local bool=tobool(Utils.getNoNil(getUserAttribute(nodeId, attribute), default))
	return bool
end;

--[[
function _m.getUserAttribute(nodeId, attribute)
	if nodeId==0 or nodeId==nil or attribute=="" or attribute==nil then
		print('Warning: wanted to get UserAttribute "'..tostring(attribute)..'" from node '..tostring(nodeId)..' but failed')
		return nil
	end
	return _g.getUserAttribute(nodeId, attribute)
end
--]]

function getStringFromUserAttribute(nodeId, attribute, default)
	local str=Utils.getNoNil(getUserAttribute(nodeId, attribute), default)
	if str~=nil then
		str=tostring(str)
	end
	return str
end;

function getArrayFromUserAttribute(nodeId, attribute, default)
	local str=getStringFromUserAttribute(nodeId, attribute)
	if str==nil then
		return default or {}
	end
	local arr=gmatch(str, "%S+")
	return arr
end;

function removeValueFromTable(tbl, value, all)
	local index={}
	if type(tbl)=="table" and value~=nil then
		for k,v in pairs(tbl) do
			if v==value then
				table.insert(index,k)
				if all~=true then
					break
				end
			end
		end
		table.sort(index, function(a, b) return a>b end)
		for _,v in pairs(index) do
			table.remove(tbl,v)
		end
		return #index
	end
	return 0
end;

function loopThruChildren(id,loopFunction,obj)
	print('loopThruChildren nodeId '..tostring(id))
	if id==nil or id==0 or type(obj)~="table" or type(loopFunction)~="string" then
		return false
	end
	local numChildren = getNumOfChildren(id)
	print('number of children of nodeId is '..tostring(numChildren))
	if type(numChildren)=="number" and numChildren>0 then
		for i=1,numChildren do
			local childId = getChildAt(id, i-1)
			if childId~=nil or childId~=0 then
				if not obj[loopFunction](obj,childId) then
					print('abort loopThruChildren')
					return true
				end
			end
		end
	end
	return true
end;

function getChildrenRigidBodyTypeStatic(id)
	local class={}
	class.staticShapes={}
	if getRigidBodyType(id)=="Static" then
		table.insert(class.staticShapes,id)
	end
	function class:loopFunc(childId)
		if getRigidBodyType(childId)=="Static" then
			table.insert(self.staticShapes,childId)
		end
		loopThruChildren(childId,"loopFunc",self)
		return true
	end
	loopThruChildren(id,"loopFunc",class)
	return class.staticShapes
end;

function UniversalProcessKit.setTranslation(id,x,y,z)
	local staticShapes=getChildrenRigidBodyTypeStatic(id)
	for _,v in pairs(staticShapes) do
		setRigidBodyType(v,"Kinematic")
	end
	_g.setTranslation(id,x,y,z)
	for _,v in pairs(staticShapes) do
		setRigidBodyType(v,"Static")
	end
end

function UniversalProcessKit.setWorldTranslation(id,x,y,z)
	local staticShapes=getChildrenRigidBodyTypeStatic(id)
	for _,v in pairs(staticShapes) do
		setRigidBodyType(v,"Kinematic")
	end
	Utils.setWorldTranslation(id,x,y,z)
	for _,v in pairs(staticShapes) do
		setRigidBodyType(v,"Static")
	end
end

function UniversalProcessKit.setRotation(id,rx,ry,rz)
	local staticShapes=getChildrenRigidBodyTypeStatic(id)
	for _,v in pairs(staticShapes) do
		setRigidBodyType(v,"Kinematic")
	end
	_g.setRotation(id,rx,ry,rz)
	for _,v in pairs(staticShapes) do
		setRigidBodyType(v,"Static")
	end
end

function UniversalProcessKit.adjustToTerrainHeight(id)
	print('UniversalProcessKit.adjustToTerrainHeight')
	local x,_,z=getWorldTranslation(id)
	local y=getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
	UniversalProcessKit.setWorldTranslation(id, x, y, z)
end;

local secondNormalDistributedRandomNumber=false -- function below generates 2 normal distributed random numbers

function getNormalDistributedRandomNumber() -- see http://de.wikipedia.org/wiki/Polar-Methode
	if secondNormalDistributedRandomNumber~=false then
		local r=secondNormalDistributedRandomNumber
		secondNormalDistributedRandomNumber=false
		return r
	end	
	local u,v,q,p
	repeat
		u=2*mathrandom()-1
		v=2*mathrandom()-1
		q=u*u+v*v
	until 0<q and q<1
	p=mathsqrt(-2 * mathlog(q)/q)
	secondNormalDistributedRandomNumber=v*p
	return u*p
end;

----------------------------------
-- classes and variables ---------
----------------------------------

_g.UPK_ActivatorTrigger={}
_g.UPK_Animator={}
_g.UPK_BaleSpawner={}
_g.UPK_BaleTrigger={}
_g.UPK_Base={}
_g.UPK_BuyTrigger={}
_g.UPK_Conveyor={}
_g.UPK_DisplayTrigger={}
_g.UPK_DumpTrigger={}
_g.UPK_EntityTrigger={}
_g.UPK_FillTrigger={}
_g.UPK_BalerTrigger={}
_g.UPK_Mover={}
_g.UPK_PalettSpawner={}
_g.UPK_PalettTrigger={}
_g.UPK_Processor={}
_g.UPK_Scaler={}
_g.UPK_Shower={}
_g.UPK_Storage={}
_g.UPK_Switcher={}
_g.UPK_TipTrigger={}
_g.UPK_TipTriggerActivatable={}
_g.PlaceableUPK={}

UPK_Storage.SEPARATE=1
UPK_Storage.SINGLE=2
UPK_Storage.FIFO=3
UPK_Storage.FILO=4

_g.g_upkTipTrigger={}

----------------------------------
-- __c ---------------------------
----------------------------------

-- adds arithmetic operations to tables

-- functionality for c() like in R, and a little more

-- examples:

-- same length
-- c(1) = {1}
-- c({1,2,3}) + c({4,5,6}) = {5,7,9}
-- c({1,2,3}) - c({4,5,6}) = {-3,-3,-3}
-- c({1,2,3}) * c({4,5,6}) = {4,10,18}
-- c({1,2,3}) / c({4,5,6}) = {0.25,0.4,0.5}
-- c({1,2,3}):min() = 1
-- c({1,2,3}):max() = 3

-- different length + - * /
-- c({1,2,3}) + c({2,3}) = {3,5,5}

-- with keys left (same like above with keys) + - * /
-- c({a=1,b=2,c=3}) + c({2,3}) = {a=3,b=5,c=5}

-- keys left and right (same, only take matching keys into account) + - * /
-- c({a=1,b=2,c=3}) + c({b=2,d=4}) = {b=4}

local c_mt={
	__index=function(arr,key)
		if type(key)=="number" and key>1 then
			return arr[(key-1) % length(arr) +1]
		end
		return nil
	end,
	__add = function(lhs,rhs)
		local arr={}
		if rhs~=nil and type(lhs)=="table" then
			if type(rhs)=="number" then
				for k,v in pairs(lhs) do
					if type(v)=="number" then
						arr[k]=v+rhs
					end
				end
			elseif type(rhs)=="table" then
				local i=1
				for k,v in pairs(lhs) do
					if type(v)=="number" then
						if type(rhs[k])=="number" then
							arr[k]=lhs[k]+rhs[k]
						elseif type(rhs[i])=="number" then
							arr[k]=lhs[k]+rhs[i]
							i=i+1
						end
					end
				end
			end
		end
		return __c(arr)
	end,
	__sub = function(lhs,rhs)
		local arr={}
		if rhs~=nil and type(lhs)=="table" then
			if type(rhs)=="number" then
				for k,v in pairs(lhs) do
					if type(v)=="number" then
						arr[k]=v-rhs
					end
				end
			elseif type(rhs)=="table" then
				local i=1
				for k,v in pairs(lhs) do
					if type(v)=="number" then
						if type(rhs[k])=="number" then
							arr[k]=lhs[k]-rhs[k]
						elseif type(rhs[i])=="number" then
							arr[k]=lhs[k]-rhs[i]
							i=i+1
						end
					end
				end
			end
		end
		return __c(arr)
	end,
	__mul = function(lhs,rhs)
		local arr={}
		if rhs~=nil and type(lhs)=="table" then
			if type(rhs)=="number" then
				for k,v in pairs(lhs) do
					if type(v)=="number" then
						arr[k]=v*rhs
					end
				end
			elseif type(rhs)=="table" then
				local i=1
				for k,v in pairs(lhs) do
					if type(v)=="number" then
						if type(rhs[k])=="number" then
							arr[k]=lhs[k]*rhs[k]
						elseif type(rhs[i])=="number" then
							arr[k]=lhs[k]*rhs[i]
							i=i+1
						end
					end
				end
			end
		end
		return __c(arr)
	end,
	__div = function(lhs,rhs)
		local arr={}
		if rhs~=nil and type(lhs)=="table" then
			if type(rhs)=="number" then
				for k,v in pairs(lhs) do
					if type(v)=="number" then
						arr[k]=v/rhs
					end
				end
			elseif type(rhs)=="table" then
				local i=1
				for k,v in pairs(lhs) do
					if type(v)=="number" then
						if type(rhs[k])=="number" then
							arr[k]=lhs[k]/rhs[k]
						elseif type(rhs[i])=="number" then
							arr[k]=lhs[k]/rhs[i]
							i=i+1
						end
					end
				end
			end
		end
		return __c(arr)
	end,
	__mod = function(lhs,rhs)
		local arr={}
		if rhs~=nil and type(lhs)=="table" then
			if type(rhs)=="number" then
				for k,v in pairs(lhs) do
					if type(v)=="number" then
						arr[k]=v%rhs
					end
				end
			elseif type(rhs)=="table" then
				local i=1
				for k,v in pairs(lhs) do
					if type(v)=="number" then
						if type(rhs[k])=="number" then
							arr[k]=lhs[k]%rhs[k]
						elseif type(rhs[i])=="number" then
							arr[k]=lhs[k]%rhs[i]
							i=i+1
						end
					end
				end
			end
		end
		return __c(arr)
	end,
	__call = function(func, ...)
		local t={}
		local args=...
		if type(args)~="table" then
			args={...}
		end
		for k,v in pairs(args) do
			table.insert(t,k,func[v])
		end
		return __c(t)
	end,
	__concat = function(lhs,rhs) -- not consistent logic yet
		local arr=lhs
		for i=1,length(rhs) do
			table.insert(arr,rhs[i])
		end
		return __c(arr) 
	end,
	__len=function(t)
		return length(t)
	end	
}

function _g.__c(...)
	local arr=...
	if type(arr)~="table" then
		arr={...}
	end
	setmetatable(arr,c_mt)
	function arr:min()
		local nr=math.huge
		local len=length(self)
		if len>0 then
			for i=1,len do
				nr=mathmin(nr,self[i])
			end
			return nr
		elseif len==0 then
			for k,v in pairs(self) do
				if type(self[k])=="number" then -- exclude functions
					nr=mathmin(nr,v)
				end
			end
			return nr
		end
		return nil
	end
	function arr:max(returnKey)
		local nr=-math.huge
		local key
		local len=length(self)
		if len>0 then
			for i=1,len do
				nr=mathmax(nr,self[i])
				key=i
			end
		elseif len==0 then
			for k,v in pairs(self) do
				if type(v)=="number" then -- exclude functions
					nr=mathmax(nr,v)
					key=k
				end
			end
		end
		if len>=0 then
			if returnKey then
				return key
			else
				return nr
			end
		end
		return nil
	end
	function arr:getValuesOf(keys)
		if type(keys)~="table" then
			keys={keys}
		end
		local values={}
		for i=1,length(keys) do
			values[keys[i]]=self[keys[i]]
		end
		return values
	end
	function arr:zeroToNil()
		local values=self
		for i=1,length(self) do
			if self[i]==0 then
				--values
			end
		end
		return values
	end
	function arr:getKeysAreTrue()
		local r={}
		for k,v in pairs(self) do
			if type(v)~="function" and v then
				table.insert(r,k)
			end
		end
		return r
	end
	return arr
end;

----------------------------------
-- ClassUPK ----------------------
----------------------------------

function _g.ClassUPK(members, baseClass)
	members = members or {}
	if baseClass ~= nil then
		setmetatable(members, {__index = baseClass})
	end
	
	local mt = {
		__index = function(t,k)
			if t.storageType==UPK_Storage.SEPARATE then
				if k=="capacity" then
					return math.huge
				elseif k=="fillLevel" then
					return 0
				elseif k=="fillType" then
					return Fillable.FILLTYPE_UNKNOWN
				end
			elseif t.storageType==UPK_Storage.SINGLE then
				if k=="capacity" then
					return t.p_capacity
				elseif k=="fillLevel" then
					return t.p_flbs[1].fillLevel
				elseif k=="fillType" then
					return t.p_flbs[1].fillType
				end
			elseif t.storageType==UPK_Storage.FIFO or t.storageType==UPK_Storage.FILO then
				if k=="capacity" then
					return t.p_capacity
				elseif k=="fillLevel" then
					return t.p_totalFillLevel
				elseif k=="fillType" then
					return t.p_flbs[1].fillType
				end
			end
			return members[k]
		end,
		__add = function(lhs,rhs)
			local added = 0
			if type(rhs)=="table" then
				if not rhs.isflb then
					rhs = FillLevelBubble:new(rhs)
				end
				if rhs.fillLevel<0 then
					return lhs - {-rhs.fillLevel, rhs.fillType}
				end
			
				if lhs.storageType==UPK_Storage.SEPARATE then
					local newFillType = lhs.fillTypesConversionMatrix[Fillable.FILLTYPE_UNKNOWN][rhs.fillType]
					if newFillType~=nil then
						added = lhs.p_flbs[newFillType] + rhs
					elseif lhs.parent ~= nil then
						added = lhs.parent + rhs
					end
				elseif lhs.storageType==UPK_Storage.SINGLE then
					added = lhs.p_flbs[1] + rhs
				elseif lhs.storageType==UPK_Storage.FIFO then
					local newFillType = lhs.p_flbs[lhs.p_flbs_fifo_lastkey].fillTypesConversionMatrix[lhs.p_flbs[lhs.p_flbs_fifo_lastkey].fillType][rhs.fillType]
					if newFillType~=nil then
						local newCapacity = lhs.p_capacity - lhs.p_totalFillLevel
						lhs.capacities[newFillType] = newCapacity
						added = lhs.p_flbs[lhs.p_flbs_fifo_lastkey] + rhs
					end
					if added==0 then
						local flb = FillLevelBubble:new()
						flb.capacities = lhs.capacities
						flb.fillTypesConversionMatrix = lhs.fillTypesConversionMatrix
						flb:registerOnFillLevelChangeFunc(lhs,"onFillLevelChange")
						local newFillType = flb.fillTypesConversionMatrix[flb.fillType][rhs.fillType]
						if newFillType~=nil then
							local newCapacity = lhs.p_capacity - lhs.p_totalFillLevel
							lhs.capacities[newFillType] = newCapacity
							added = flb + rhs
						end
						if added>0 then
							lhs.p_flbs_fifo_lastkey = lhs.p_flbs_fifo_lastkey + 1
							table.insert(lhs.p_flbs,lhs.p_flbs_fifo_lastkey,flb)
						end
					end
					lhs.p_totalFillLevel = lhs.p_totalFillLevel + added
				elseif lhs.storageType==UPK_Storage.FILO then
					local newFillType = lhs.p_flbs[1].fillTypesConversionMatrix[lhs.p_flbs[1].fillType][rhs.fillType]
					if newFillType~=nil then
						local newCapacity = lhs.p_capacity - lhs.p_totalFillLevel
						lhs.capacities[newFillType] = newCapacity
						added = lhs.p_flbs[1] + rhs
					end
					if added==0 then
						local flb = FillLevelBubble:new()
						flb.capacities = lhs.capacities
						flb.fillTypesConversionMatrix = lhs.fillTypesConversionMatrix
						flb:registerOnFillLevelChangeFunc(lhs,"onFillLevelChange")
						local newFillType = flb.fillTypesConversionMatrix[flb.fillType][rhs.fillType]
						if newFillType~=nil then
							local newCapacity = lhs.p_capacity - lhs.p_totalFillLevel
							lhs.capacities[newFillType] = newCapacity
							added = flb + rhs
						end
						if added>0 then
							table.insert(lhs.p_flbs,1,flb)
						end
					end
					lhs.p_totalFillLevel = lhs.p_totalFillLevel + added
				end
			end	
			return added
		end,
		__sub = function(lhs,rhs)
			local added = 0
			if type(rhs)=="table" then
				if not rhs.isflb then
					rhs = FillLevelBubble:new(rhs)
				end
				if rhs.fillLevel<0 then
					return lhs + {-rhs.fillLevel, rhs.fillType}
				end
			
				if lhs.storageType==UPK_Storage.SEPARATE then
					local newFillType = lhs.fillTypesConversionMatrix[Fillable.FILLTYPE_UNKNOWN][rhs.fillType]
					if newFillType~=nil then
						added = lhs.p_flbs[newFillType] - rhs
					elseif lhs.parent ~= nil then
						added = lhs.parent - rhs
					end
				elseif lhs.storageType==UPK_Storage.SINGLE then
					added = lhs.p_flbs[1] - rhs
				elseif lhs.storageType==UPK_Storage.FIFO then
					local newFillType = lhs.p_flbs[1].fillTypesConversionMatrix[lhs.p_flbs[1].fillType][rhs.fillType]
					if newFillType~=nil then
						local newCapacity = lhs.p_capacity - lhs.p_totalFillLevel + lhs.p_flbs[1].fillLevel
						lhs.capacities[newFillType] = newCapacity
						added = lhs.p_flbs[1] - rhs
					end
					if added<0 and lhs.p_flbs[1].fillLevel==0 and lhs.p_flbs[2]~=nil then
						table.remove(lhs.p_flbs,1)
						lhs.p_flbs_fifo_lastkey = lhs.p_flbs_fifo_lastkey - 1
					end
					lhs.p_totalFillLevel = lhs.p_totalFillLevel + added
				elseif lhs.storageType==UPK_Storage.FILO then
					local newFillType = lhs.p_flbs[1].fillTypesConversionMatrix[lhs.p_flbs[1].fillType][rhs.fillType]
					if newFillType~=nil then
						local newCapacity = lhs.p_capacity - lhs.p_totalFillLevel + lhs.p_flbs[1].fillLevel
						lhs.capacities[newFillType] = newCapacity
						added = lhs.p_flbs[1] - rhs
					end
					if added<0 and lhs.p_flbs[1].fillLevel==0 and lhs.p_flbs[2]~=nil then
						table.remove(lhs.p_flbs,1)
					end
					lhs.p_totalFillLevel = lhs.p_totalFillLevel + added
				end
			end	
			return added
		end
	}
	
	function members:class()
		return members
	end
	
	function members:superClass()
		return baseClass
	end
	
	function members:isa(other)
		local ret = false
		local curClass = members
		while curClass ~= nil and ret == false do
			if curClass == other then
				ret = true
			else
				curClass = curClass:superClass()
			end
		end
		return ret
	end
	
	return mt
end;

----------------------------------
-- debugMode ---------------------
----------------------------------

local debug_mt={
	__index=function(obj,key)
		local baseObj=rawget(obj,'baseObj')
		local result=baseObj[key]
		if type(result)=="function" then
			local oldFunc=result
			local function newFunc(...)
				local argsStr=""
				local args={...}
				if #args>0 then
					local mink, maxk = getMinMaxKeys(args)
					for i=mink, maxk do
						if(strlen(argsStr)>0)then -- strlen is utf8Strlen
							argsStr=argsStr..', '
						end
						if args[i]==obj then
							argsStr=argsStr..'self'
						else
							argsStr=argsStr..tostring(v)
						end
					end
				end
				obj:print('calling '..tostring(key)..'('..argsStr..'):')
				local printLevel=rawget(obj,'printLevel') or 0
				rawset(obj,'printLevel',printLevel+1)
				local results = {oldFunc(...)}
				rawset(obj,'printLevel',printLevel)
				local returnsStr=""
				if #results>0 then
					local mink, maxk = getMinMaxKeys(results)
					for i=mink, maxk do
						if(strlen(returnsStr)>0)then -- strlen is utf8Strlen
							returnsStr=returnsStr..', '
						end
						returnsStr=returnsStr..tostring(results[i])
					end
				end
				if returnsStr=="" then
					returnsStr="(nothing)"
				end
				obj:print('called '..tostring(key)..'() returns '..returnsStr)
				return unpack(results)
			end
			return newFunc
		end	
		obj:print('indexed '..tostring(key)..', got '..tostring(result))
		return result
	end,
	__newindex=function(obj,key,val)
		obj:print('set '..tostring(key)..' = '..tostring(val))
		local baseObj=rawget(obj,'baseObj')
		baseObj[key]=val
	end,
	__call=function(t, ...)
		local baseObj=rawget(t,'baseObj')
		return baseObj(...)
	end,
	__add=function(lhs,rhs)
		local baseObj=rawget(lhs,'baseObj')
		return baseObj + rhs
	end,
	__sub=function(lhs,rhs)
		local baseObj=rawget(lhs,'baseObj')
		return baseObj - rhs
	end,
	__mul=function(lhs,rhs)
		local baseObj=rawget(lhs,'baseObj')
		return baseObj * rhs
	end,
	__div=function(lhs,rhs)
		local baseObj=rawget(lhs,'baseObj')
		return baseObj / rhs
	end,
	__mod=function(lhs,rhs)
		local baseObj=rawget(lhs,'baseObj')
		return baseObj % rhs
	end,
	__pow=function(lhs,rhs)
		local baseObj=rawget(lhs,'baseObj')
		return baseObj ^ rhs
	end,
	__concat=function(lhs,rhs)
		local baseObj=rawget(lhs,'baseObj')
		return baseObj .. rhs
	end,
	__len=function(t)
		local baseObj=rawget(t,'baseObj')
		return #baseObj
	end,
	__gt=function(lhs,rhs)
		local baseObj=rawget(lhs,'baseObj')
		return baseObj > rhs
	end,
	__ge=function(lhs,rhs)
		local baseObj=rawget(lhs,'baseObj')
		return baseObj >= rhs
	end,
	__lt=function(lhs,rhs)
		local baseObj=rawget(lhs,'baseObj')
		return baseObj < rhs
	end,
	__le=function(lhs,rhs)
		local baseObj=rawget(lhs,'baseObj')
		return baseObj <= rhs
	end
}

-- USAGE
-- object = Class:new(x,y)
-- object = debugObject(object)
-- then use like normal

function _g.debugObject(baseObj) -- _g may not be needed
	local obj={}
	obj.baseObj=baseObj
	obj.printLevel=0
	function obj.print(obj, ...)
		local premsg=""
		local printLevel=rawget(obj,'printLevel') or 0
		for i=0,printLevel do
			premsg='-'..premsg
		end
		local msg=premsg..' '..tostring(...)
		local baseObj=rawget(obj,'baseObj')
		if baseObj.print~=nil then
			baseObj.print(baseObj,msg)
		else
			print(msg)
		end
	end
	setmetatable(obj,debug_mt)
	return obj
end;

