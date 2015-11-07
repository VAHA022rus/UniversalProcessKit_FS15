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


local fillTypeIntServerToClient_mt = {
	__index = function(t,k)
		return k
	end
	}
UniversalProcessKit.fillTypeIntServerToClient = {}
UniversalProcessKit.fillTypeIntClientToServer = {}
setmetatable(UniversalProcessKit.fillTypeIntServerToClient, fillTypeIntServerToClient_mt)
setmetatable(UniversalProcessKit.fillTypeIntClientToServer, fillTypeIntServerToClient_mt)

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

UniversalProcessKit.specialFillTypes = {"money", -- "other"
						"newVehiclesCost",
						"newAnimalsCost",
						"constructionCost",
						"vehicleRunningCost",
						"propertyMaintenance",
						"wagePayment",
						"harvestIncome",
						"missionIncome",
						"loanInterest",
						"void","sun","rain","temperature"}

						

function UniversalProcessKit.addFillType(name,index)
	printFn('UniversalProcessKit.addFillType('..tostring(name)..', '..tostring(index)..')')
	if type(name)=="table" then
		for k,v in pairs(name) do
			UniversalProcessKit.addFillType(v)
		end
	elseif type(name)=="string" then
		if name=="single" or name=="fifo" or name=="filo" then
			printErr('Warning: filltypes cannot be named single, fifo or filo')
		elseif UniversalProcessKit.fillTypeNameToInt[name]==nil then
			local index=index or UniversalProcessKit.NUM_FILLTYPES
			if UniversalProcessKit.fillTypeIntToName[index]~=nil then
				UniversalProcessKit.addFillType(name,index+1)
			else
				if isInTable(specialFillTypes,name) then
					printInfo("Notice: filltype labeled \""..tostring(name).."\" is not part of the game economy")
				end
				UniversalProcessKit['FILLTYPE_'..string.upper(name)]=index
				printInfo("Notice: adding "..tostring(name).." ("..tostring(index)..") to fillTypes")
				rawset(UniversalProcessKit.fillTypeIntToName,index,name)
				rawset(UniversalProcessKit.fillTypeNameToInt,name,index)
				UniversalProcessKit.NUM_FILLTYPES=UniversalProcessKit.NUM_FILLTYPES+1
				if g_server ~= nil and UniversalProcessKitListener.fillTypesSyncingObject ~= nil then
					UniversalProcessKitListener.fillTypesSyncingObject:addFillTypeNameToSync(name)
				end	
				return index
			end
		end
	end
end;

function UniversalProcessKit.registerFillType(name, hudFilename)
	printFn('UniversalProcessKit.registerFillType('..tostring(name)..', '..tostring(hudFilename)..')')
	hudFilename = string.gsub(hudFilename,'//','/')
	hudFilename = string.gsub(hudFilename,'\\\\','\\')
	if fileExists(hudFilename) then
		Fillable.registerFillType(name, nil, nil, true, hudFilename)
		UniversalProcessKit.addFillType(name)
	else
		printErr('Error: file '..tostring(hudFilename)..' does not exists - fill type '..tostring(name)..' not added')
	end
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

for _,name in pairs(UniversalProcessKit.specialFillTypes) do
	local index = UniversalProcessKit.addFillType(name)
	UniversalProcessKit.isSpecialFillType[index] = true
end

----------------------------------
-- special fill level bubbles ----
----------------------------------

UniversalProcessKitEnvironment.flbs = {}

-- fill level bubble rain

local upk_fillLevel_rain_mt = {
	__index = function(t,k)
		if k=="fillLevel" then
			return t.p_fillLevel or 0
		end
		return FillLevelBubble[k]
	end,
	__newindex = function(t,k,v)
		if k=="fillLevel" then
			if v~=t.p_fillLevel then
				local diff = v-t.p_fillLevel
				t.p_fillLevel = v
				t:onFillLevelChange(diff,v,t.fillType)
			end
		end
	end,
	__add = function(lhs,rhs)
		return 0
	end,
	__sub = function(lhs,rhs)
		return 0
	end
}

UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_RAIN] = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_RAIN].p_fillLevel = 0
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_RAIN].isflb = true
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_RAIN].fillType = UniversalProcessKit.FILLTYPE_RAIN
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_RAIN].capacity = math.huge
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_RAIN].onFillLevelChangeFuncs = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_RAIN].onFillLevelChange = FillLevelBubble.onFillLevelChange
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_RAIN].registerOnFillLevelChangeFunc = FillLevelBubble.registerOnFillLevelChangeFunc
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_RAIN].unregisterOnFillLevelChangeFunc = FillLevelBubble.unregisterOnFillLevelChangeFunc

setmetatable(UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_RAIN], upk_fillLevel_rain_mt)

-- fill level bubble sun

UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_SUN] = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_SUN].p_fillLevel = 0
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_SUN].isflb = true
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_SUN].fillType = UniversalProcessKit.FILLTYPE_SUN
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_SUN].capacity = math.huge
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_SUN].onFillLevelChangeFuncs = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_SUN].onFillLevelChange = FillLevelBubble.onFillLevelChange
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_SUN].registerOnFillLevelChangeFunc = FillLevelBubble.registerOnFillLevelChangeFunc
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_SUN].unregisterOnFillLevelChangeFunc = FillLevelBubble.unregisterOnFillLevelChangeFunc

setmetatable(UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_SUN], upk_fillLevel_rain_mt)

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
				g_currentMission:addSharedMoney(rhs, lhs.statName)
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
				g_currentMission:addSharedMoney(rhs.fillLevel, lhs.statName)
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
				g_currentMission:addSharedMoney(-rhs, lhs.statName)
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
				g_currentMission:addSharedMoney(-rhs.fillLevel, lhs.statName)
				return -rhs.fillLevel
			end
			return 0
		end
		return 0
	end
}

UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MONEY] = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MONEY].statName = "other"
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MONEY].isflb = true
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MONEY].fillType = UniversalProcessKit.FILLTYPE_MONEY
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MONEY].capacity = math.huge
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MONEY].onFillLevelChangeFuncs = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MONEY].onFillLevelChange = FillLevelBubble.onFillLevelChange
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MONEY].registerOnFillLevelChangeFunc = FillLevelBubble.registerOnFillLevelChangeFunc
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MONEY].unregisterOnFillLevelChangeFunc = FillLevelBubble.unregisterOnFillLevelChangeFunc
setmetatable(UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MONEY], upk_fillLevel_money_mt)

UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_NEWVEHICLESCOST] = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_NEWVEHICLESCOST].statName = "newVehiclesCost"
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_NEWVEHICLESCOST].isflb = true
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_NEWVEHICLESCOST].fillType = UniversalProcessKit.FILLTYPE_NEWVEHICLESCOST
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_NEWVEHICLESCOST].capacity = math.huge
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_NEWVEHICLESCOST].onFillLevelChangeFuncs = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_NEWVEHICLESCOST].onFillLevelChange = FillLevelBubble.onFillLevelChange
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_NEWVEHICLESCOST].registerOnFillLevelChangeFunc = FillLevelBubble.registerOnFillLevelChangeFunc
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_NEWVEHICLESCOST].unregisterOnFillLevelChangeFunc = FillLevelBubble.unregisterOnFillLevelChangeFunc
setmetatable(UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_NEWVEHICLESCOST], upk_fillLevel_money_mt)

UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_NEWANIMALSCOST] = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_NEWANIMALSCOST].statName = "newAnimalsCost"
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_NEWANIMALSCOST].isflb = true
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_NEWANIMALSCOST].fillType = UniversalProcessKit.FILLTYPE_NEWANIMALSCOST
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_NEWANIMALSCOST].capacity = math.huge
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_NEWANIMALSCOST].onFillLevelChangeFuncs = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_NEWANIMALSCOST].onFillLevelChange = FillLevelBubble.onFillLevelChange
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_NEWANIMALSCOST].registerOnFillLevelChangeFunc = FillLevelBubble.registerOnFillLevelChangeFunc
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_NEWANIMALSCOST].unregisterOnFillLevelChangeFunc = FillLevelBubble.unregisterOnFillLevelChangeFunc
setmetatable(UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_NEWANIMALSCOST], upk_fillLevel_money_mt)

UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_CONSTRUCTIONCOST] = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_CONSTRUCTIONCOST].statName = "constructionCost"
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_CONSTRUCTIONCOST].isflb = true
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_CONSTRUCTIONCOST].fillType = UniversalProcessKit.FILLTYPE_CONSTRUCTIONCOST
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_CONSTRUCTIONCOST].capacity = math.huge
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_CONSTRUCTIONCOST].onFillLevelChangeFuncs = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_CONSTRUCTIONCOST].onFillLevelChange = FillLevelBubble.onFillLevelChange
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_CONSTRUCTIONCOST].registerOnFillLevelChangeFunc = FillLevelBubble.registerOnFillLevelChangeFunc
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_CONSTRUCTIONCOST].unregisterOnFillLevelChangeFunc = FillLevelBubble.unregisterOnFillLevelChangeFunc
setmetatable(UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_CONSTRUCTIONCOST], upk_fillLevel_money_mt)

UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_VEHICLERUNNINGCOST] = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_VEHICLERUNNINGCOST].statName = "vehicleRunningCost"
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_VEHICLERUNNINGCOST].isflb = true
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_VEHICLERUNNINGCOST].fillType = UniversalProcessKit.FILLTYPE_VEHICLERUNNINGCOST
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_VEHICLERUNNINGCOST].capacity = math.huge
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_VEHICLERUNNINGCOST].onFillLevelChangeFuncs = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_VEHICLERUNNINGCOST].onFillLevelChange = FillLevelBubble.onFillLevelChange
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_VEHICLERUNNINGCOST].registerOnFillLevelChangeFunc = FillLevelBubble.registerOnFillLevelChangeFunc
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_VEHICLERUNNINGCOST].unregisterOnFillLevelChangeFunc = FillLevelBubble.unregisterOnFillLevelChangeFunc
setmetatable(UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_VEHICLERUNNINGCOST], upk_fillLevel_money_mt)

UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_PROPERTYMAINTENANCE] = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_PROPERTYMAINTENANCE].statName = "propertyMaintenance"
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_PROPERTYMAINTENANCE].isflb = true
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_PROPERTYMAINTENANCE].fillType = UniversalProcessKit.FILLTYPE_PROPERTYMAINTENANCE
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_PROPERTYMAINTENANCE].capacity = math.huge
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_PROPERTYMAINTENANCE].onFillLevelChangeFuncs = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_PROPERTYMAINTENANCE].onFillLevelChange = FillLevelBubble.onFillLevelChange
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_PROPERTYMAINTENANCE].registerOnFillLevelChangeFunc = FillLevelBubble.registerOnFillLevelChangeFunc
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_PROPERTYMAINTENANCE].unregisterOnFillLevelChangeFunc = FillLevelBubble.unregisterOnFillLevelChangeFunc
setmetatable(UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_PROPERTYMAINTENANCE], upk_fillLevel_money_mt)

UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_WAGEPAYMENT] = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_WAGEPAYMENT].statName = "wagePayment"
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_WAGEPAYMENT].isflb = true
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_WAGEPAYMENT].fillType = UniversalProcessKit.FILLTYPE_WAGEPAYMENT
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_WAGEPAYMENT].capacity = math.huge
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_WAGEPAYMENT].onFillLevelChangeFuncs = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_WAGEPAYMENT].onFillLevelChange = FillLevelBubble.onFillLevelChange
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_WAGEPAYMENT].registerOnFillLevelChangeFunc = FillLevelBubble.registerOnFillLevelChangeFunc
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_WAGEPAYMENT].unregisterOnFillLevelChangeFunc = FillLevelBubble.unregisterOnFillLevelChangeFunc
setmetatable(UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_WAGEPAYMENT], upk_fillLevel_money_mt)

UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_HARVESTINCOME] = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_HARVESTINCOME].statName = "harvestIncome"
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_HARVESTINCOME].isflb = true
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_HARVESTINCOME].fillType = UniversalProcessKit.FILLTYPE_HARVESTINCOME
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_HARVESTINCOME].capacity = math.huge
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_HARVESTINCOME].onFillLevelChangeFuncs = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_HARVESTINCOME].onFillLevelChange = FillLevelBubble.onFillLevelChange
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_HARVESTINCOME].registerOnFillLevelChangeFunc = FillLevelBubble.registerOnFillLevelChangeFunc
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_HARVESTINCOME].unregisterOnFillLevelChangeFunc = FillLevelBubble.unregisterOnFillLevelChangeFunc
setmetatable(UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_HARVESTINCOME], upk_fillLevel_money_mt)

UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MISSIONINCOME] = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MISSIONINCOME].statName = "missionIncome"
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MISSIONINCOME].isflb = true
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MISSIONINCOME].fillType = UniversalProcessKit.FILLTYPE_MISSIONINCOME
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MISSIONINCOME].capacity = math.huge
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MISSIONINCOME].onFillLevelChangeFuncs = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MISSIONINCOME].onFillLevelChange = FillLevelBubble.onFillLevelChange
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MISSIONINCOME].registerOnFillLevelChangeFunc = FillLevelBubble.registerOnFillLevelChangeFunc
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MISSIONINCOME].unregisterOnFillLevelChangeFunc = FillLevelBubble.unregisterOnFillLevelChangeFunc
setmetatable(UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_MISSIONINCOME], upk_fillLevel_money_mt)

UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_LOANINTEREST] = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_LOANINTEREST].statName = "loanInterest"
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_LOANINTEREST].isflb = true
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_LOANINTEREST].fillType = UniversalProcessKit.FILLTYPE_LOANINTEREST
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_LOANINTEREST].capacity = math.huge
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_LOANINTEREST].onFillLevelChangeFuncs = {}
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_LOANINTEREST].onFillLevelChange = FillLevelBubble.onFillLevelChange
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_LOANINTEREST].registerOnFillLevelChangeFunc = FillLevelBubble.registerOnFillLevelChangeFunc
UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_LOANINTEREST].unregisterOnFillLevelChangeFunc = FillLevelBubble.unregisterOnFillLevelChangeFunc
setmetatable(UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_LOANINTEREST], upk_fillLevel_money_mt)


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
