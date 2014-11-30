-- by mor2000

-- enables more fillTypes, ie. bales, animals or including dummies
-- works on the fly, just use UniversalProcessKit.fillTypeNameToInt("yourFillType") to initialize fillType

UniversalProcessKit.fillTypeNameToInt={}
UniversalProcessKit.fillTypeIntToName={}
for k,v in pairs(Fillable.fillTypeNameToInt) do
	UniversalProcessKit.fillTypeNameToInt[k]=v
	UniversalProcessKit.fillTypeIntToName[v]=k
end
UniversalProcessKit.NUM_FILLTYPES = 32768 -- may collide with huge pile of FIFO or FILO storage

local fillTypeNameToInt_mt={
	__index=Fillable.fillTypeNameToInt,
	__call=function(func,...)
		local t={}
		local args=...
		if type(args)~="table" then
			args={...}
		end
		for k,v in pairs(args) do
			local type=type(v)
			if type=="string" then
				if rawget(UniversalProcessKit.fillTypeNameToInt,v)==nil and Fillable.fillTypeNameToInt[v]==nil then
					UniversalProcessKit.addFillType(v) -- add fillTypes as used
				end
				table.insert(t,UniversalProcessKit.fillTypeNameToInt[v])
			end
		end
		return t
		end,
	__newindex=function(t,k,v)
		UniversalProcessKit.addFillType(k)
		end
	};

local fillTypeIntToName_mt={
	__index=Fillable.fillTypeIntToName,
	__call=function(func,...)
		local t={}
		local args=...
		if type(args)~="table" then
			args={...}
		end
		for k,v in pairs(args) do
			local type=type(v)
			if type=="number" then
				if UniversalProcessKit.fillTypeIntToName[v]~=nil then
					table.insert(t,UniversalProcessKit.fillTypeIntToName[v])
				end
			end
		end
		return t
		end
	};

setmetatable(UniversalProcessKit.fillTypeNameToInt,fillTypeNameToInt_mt)
setmetatable(UniversalProcessKit.fillTypeIntToName,fillTypeIntToName_mt)

local specialFillTypes = {"money","void","sun","rain","temperature"}

function UniversalProcessKit.addFillType(name,index)
	if type(name)=="table" then
		for k,v in pairs(name) do
			UniversalProcessKit.addFillType(v)
		end
	elseif type(name)=="string" then
		if name=="single" or name=="fifo" or name=="filo" then
			print('Warning: filltypes cannot be named single, fifo or filo')
		elseif UniversalProcessKit.fillTypeNameToInt[name]==nil then
			local index=index or UniversalProcessKit.NUM_FILLTYPES
			if UniversalProcessKit.fillTypeIntToName[index]~=nil then
				UniversalProcessKit.addFillType(name,index+1)
			else
				if isInTable(specialFillTypes,name) then
					print("Notice: filltype labeled \""..tostring(name).."\" is not part of the game economy")
				end
				UniversalProcessKit['FILLTYPE_'..string.upper(name)]=index
				print("Notice: adding "..tostring(name).." ("..tostring(index)..") to fillTypes")
				rawset(UniversalProcessKit.fillTypeIntToName,index,name)
				rawset(UniversalProcessKit.fillTypeNameToInt,name,index)
				UniversalProcessKit.NUM_FILLTYPES=UniversalProcessKit.NUM_FILLTYPES+1
				return index
			end
		end
	end
end;

function UniversalProcessKit.registerFillType(name, hudFilename)
	Fillable.registerFillType(name, nil, nil, true, hudFilename)
	UniversalProcessKit.addFillType(name)
end;

local isSpecialFillType_mt = {
	__index = function(t,k)
		if type(k)=="number" then
			t[k] = false
		end
		return false
	end,
	__call = function(t,k)
		if type(k)=="number" then
			return t[k]
		end
		return nil
	end
}
UniversalProcessKit.isSpecialFillType = {}
setmetatable(UniversalProcessKit.isSpecialFillType,isSpecialFillType_mt)

for _,name in pairs(specialFillTypes) do
	local index = UniversalProcessKit.addFillType(name)
	UniversalProcessKit.isSpecialFillType[index] = true
end

----------------------------------
-- special fill level bubbles ----
----------------------------------

UniversalProcessKitEnvironment.flbs = {}

-- fill level bubble sun

local upk_fillLevel_sun_mt = {
	__index = function(t,k)
		if k=="fillLevel" then
			return UniversalProcessKitEnvironment.sun or 0
		end
		return nil
	end,
	__newindex = function(t,k,v)
	end,
	__add = function(lhs,rhs)
		return 0
	end,
	__sub = function(lhs,rhs)
		return 0
	end
}

UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_SUN] = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_SUN].isflb = true
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_SUN].fillType = UniversalProcessKit.FILLTYPE_SUN
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_SUN].capacity = math.huge
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_SUN].onFillLevelChangeFuncs = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_SUN].onFillLevelChange = FillLevelBubble.onFillLevelChange
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_SUN].registerOnFillLevelChangeFunc = FillLevelBubble.registerOnFillLevelChangeFunc
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_SUN].unregisterOnFillLevelChangeFunc = FillLevelBubble.unregisterOnFillLevelChangeFunc

setmetatable(UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_SUN], upk_fillLevel_sun_mt)

-- fill level bubble rain

local upk_fillLevel_rain_mt = {
	__index = function(t,k)
		if k=="fillLevel" then
			return UniversalProcessKitEnvironment.rain or 0
		end
		return nil
	end,
	__newindex = function(t,k,v)
	end,
	__add = function(lhs,rhs)
		return 0
	end,
	__sub = function(lhs,rhs)
		return 0
	end
}

UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_RAIN] = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_RAIN].isflb = true
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_RAIN].fillType = UniversalProcessKit.FILLTYPE_RAIN
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_RAIN].capacity = math.huge
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_RAIN].onFillLevelChangeFuncs = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_RAIN].onFillLevelChange = FillLevelBubble.onFillLevelChange
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_RAIN].registerOnFillLevelChangeFunc = FillLevelBubble.registerOnFillLevelChangeFunc
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_RAIN].unregisterOnFillLevelChangeFunc = FillLevelBubble.unregisterOnFillLevelChangeFunc

setmetatable(UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_RAIN], upk_fillLevel_rain_mt)

-- fill level bubble temperature

local upk_fillLevel_temperature_mt = {
	__index = function(t,k)
		if k=="fillLevel" then
			return UniversalProcessKitEnvironment.temperature or 0
		end
		return nil
	end,
	__newindex = function(t,k,v)
	end,
	__add = function(lhs,rhs)
		return 0
	end,
	__sub = function(lhs,rhs)
		return 0
	end
}

UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_TEMPERATURE] = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_TEMPERATURE].isflb = true
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_TEMPERATURE].fillType = UniversalProcessKit.FILLTYPE_TEMPERATURE
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_TEMPERATURE].capacity = math.huge
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_TEMPERATURE].onFillLevelChangeFuncs = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_TEMPERATURE].onFillLevelChange = FillLevelBubble.onFillLevelChange
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_TEMPERATURE].registerOnFillLevelChangeFunc = FillLevelBubble.registerOnFillLevelChangeFunc
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_TEMPERATURE].unregisterOnFillLevelChangeFunc = FillLevelBubble.unregisterOnFillLevelChangeFunc

setmetatable(UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_TEMPERATURE], upk_fillLevel_temperature_mt)

-- fill level bubble money

local upk_fillLevel_money_mt = {
	__index = function(t,k)
		if k=="fillLevel" then
			return g_currentMission:getTotalMoney()
		end
		return nil
	end,
	__newindex = function(t,k,v)
	end,
	__add = function(lhs,rhs)
		if type(rhs)=="number" then
			if rhs<0 then
				return lhs - (-rhs)
			end
			if g_server ~= nil then
				print('adding money 2 '..tostring(rhs))
				g_currentMission:addSharedMoney(rhs, "other")
				return rhs
			end
			return 0
		elseif type(rhs)=="table" then
			if not rhs.isflb then
				rhs = FillLevelBubble:new(rhs)
			end
			if rhs.fillLevel<0 then
				return lhs - {-rhs.fillLevel, rhs.fillType}
			end
			if g_server ~= nil then
				print('adding money 1 '..tostring(rhs.fillLevel))
				g_currentMission:addSharedMoney(rhs.fillLevel, "other")
				return rhs.fillLevel
			end
			return 0
		end
		return 0
	end,
	__sub = function(lhs,rhs)
		if type(rhs)=="number" then
			if rhs<0 then
				return lhs + (-rhs)
			end
			if g_server ~= nil then
				--print('substr money 2 '..tostring(rhs))
				g_currentMission:addSharedMoney(-rhs, "other")
				return -rhs
			end
		elseif type(rhs)=="table" then
			if not rhs.isflb then
				rhs = FillLevelBubble:new(rhs)
			end
			if rhs.fillLevel<0 then
				return lhs + {-rhs.fillLevel, rhs.fillType}
			end
			if g_server ~= nil then
				--print('substr money 1 '..tostring(rhs.fillLevel))
				g_currentMission:addSharedMoney(-rhs.fillLevel, "other")
				return -rhs.fillLevel
			end
			return 0
		end
		return 0
	end
}

UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MONEY] = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MONEY].isflb = true
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MONEY].fillType = UniversalProcessKit.FILLTYPE_MONEY
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MONEY].capacity = math.huge
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MONEY].onFillLevelChangeFuncs = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MONEY].onFillLevelChange = FillLevelBubble.onFillLevelChange
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MONEY].registerOnFillLevelChangeFunc = FillLevelBubble.registerOnFillLevelChangeFunc
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MONEY].unregisterOnFillLevelChangeFunc = FillLevelBubble.unregisterOnFillLevelChangeFunc

setmetatable(UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MONEY], upk_fillLevel_money_mt)

-- fill level bubble void

local upk_fillLevel_void_mt = {
	__index = function(t,k)
		if k=="fillLevel" then
			return 999999 -- just a big number, not math.huge
		end
		return nil
	end,
	__newindex = function(t,k,v)
	end,
	__add = function(lhs,rhs)
		if type(rhs)=="number" then
			if rhs<0 then
				return lhs - (-rhs)
			end
			return rhs
		elseif type(rhs)=="table" then
			if not rhs.isflb then
				rhs = FillLevelBubble:new(rhs)
			end
			if rhs.fillLevel<0 then
				return lhs - {-rhs.fillLevel, rhs.fillType}
			end
			return rhs.fillLevel
		end
		return 0
	end,
	__sub = function(lhs,rhs)
		if type(rhs)=="number" then
			if rhs<0 then
				return lhs + (-rhs)
			end
			return rhs
		elseif type(rhs)=="table" then
			if not rhs.isflb then
				rhs = FillLevelBubble:new(rhs)
			end
			if rhs.fillLevel<0 then
				return lhs + {-rhs.fillLevel, rhs.fillType}
			end
			return rhs.fillLevel
		end
		return 0
	end
}

UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_VOID] = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_VOID].isflb = true
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_VOID].fillType = UniversalProcessKit.FILLTYPE_VOID
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_VOID].capacity = math.huge
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_VOID].onFillLevelChangeFuncs = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_VOID].onFillLevelChange = FillLevelBubble.onFillLevelChange
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_VOID].registerOnFillLevelChangeFunc = FillLevelBubble.registerOnFillLevelChangeFunc
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_VOID].unregisterOnFillLevelChangeFunc = FillLevelBubble.unregisterOnFillLevelChangeFunc

setmetatable(UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_VOID], upk_fillLevel_void_mt)
