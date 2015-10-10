-- by mor2000

local streamReadWriteAuto = {}

local TYPE_NIL = 0
local TYPE_TRUE = 1
local TYPE_FALSE = 2
local TYPE_INT6 = 3
local TYPE_INT12 = 4
local TYPE_INT18 = 5
local TYPE_INT32 = 6
local TYPE_INT64 = 7
local TYPE_FLOAT6 = -1
local TYPE_FLOAT12 = -2
local TYPE_FLOAT18 = -3
local TYPE_FLOAT32 = -4
local TYPE_FLOAT64 = -5
local TYPE_STRING = -6
local TYPE_LIST = -7

local STREAMTYPEBITS = 4 -- max type <= 2^X +1

function _m.streamWriteAuto(streamId, ...)
	local args={...}
	local _,argslen=getMinMaxKeys(args)
	if (argslen or 0)>1 then
		streamWriteIntN(streamId, TYPE_LIST, STREAMTYPEBITS)
		streamWriteAuto(streamId, argslen)
		for i=1,argslen do
			streamWriteAuto(streamId, args[i])
		end
		return
	end
	arg = args[1]
	printFn('streamWriteAuto(',streamId,', ',arg,')')
	local argtype = type(arg)
	if arg==true then
		-- true
		--printAll(i,': writing true to stream')
		streamWriteIntN(streamId, TYPE_TRUE, STREAMTYPEBITS)
	elseif arg==false then
		-- false
		--printAll(i,': writing false to stream')
		streamWriteIntN(streamId, TYPE_FALSE, STREAMTYPEBITS)
	elseif argtype=="number" then
		local arground=round(arg,8)
		local argabs=mathabs(arground)
		if arground%1==0 then
			-- int
			if argabs<32 then
				--printAll(i,': writing ',arground,' as int6 to stream')
				streamWriteIntN(streamId, TYPE_INT6, STREAMTYPEBITS)
				streamWriteIntN(streamId, arground, 6)
			elseif argabs<2048 then
				--printAll(i,': writing ',arground,' as int12 to stream')
				streamWriteIntN(streamId, TYPE_INT12, STREAMTYPEBITS)
				streamWriteIntN(streamId, arground, 12)
			elseif argabs<131072 then
				--printAll(i,': writing ',arground,' as int18 to stream')
				streamWriteIntN(streamId, TYPE_INT18, STREAMTYPEBITS)
				streamWriteIntN(streamId, arground, 18)
			elseif argabs<2147483648 then
				--printAll(i,': writing ',arground,' as int32 to stream')
				streamWriteIntN(streamId, TYPE_INT32, STREAMTYPEBITS)
				streamWriteInt32(streamId, arground)
			else
				local first=mathfloor(arground/(2^31)) -- 32-1
				local second=arground-first*2^31
				--printAll(i,': a) writing ',first,' as int32 to stream')
				streamWriteIntN(streamId, TYPE_INT64, STREAMTYPEBITS)
				streamWriteInt32(streamId, first)
				--printAll(i,': b) writing ',second,' as int32 to stream')
				streamWriteInt32(streamId, second)
			end
		else
			-- float
			local intval = mathfloor(arground)
			local intvalabs=mathabs(intval)
			if intvalabs<32 then
				--printAll(i,': a) writing ',intval,' as float6 to stream')
				streamWriteIntN(streamId, TYPE_FLOAT6, STREAMTYPEBITS)
				streamWriteIntN(streamId, intval, 6)
			elseif intvalabs<2048 then
				--printAll(i,': writing ',intval,' as float12 to stream')
				streamWriteIntN(streamId, TYPE_FLOAT12, STREAMTYPEBITS)
				streamWriteIntN(streamId, intval, 12)
			elseif intvalabs<131072 then
				--printAll(i,': a) writing ',intval,' as float18 to stream')
				streamWriteIntN(streamId, TYPE_FLOAT18, STREAMTYPEBITS)
				streamWriteIntN(streamId, intval, 18)
			elseif intvalabs<2147483648 then
				--printAll(i,': a) writing ',intval,' as int32 to stream')
				streamWriteIntN(streamId, TYPE_FLOAT32, STREAMTYPEBITS)
				streamWriteInt32(streamId, intval)
			else
				local first=mathfloor(intval/(2^31)) -- 32-1
				local second=intval-first*2^31
				--printAll(i,': a) writing ',first,' as int32 to stream')
				streamWriteIntN(streamId, TYPE_FLOAT64, STREAMTYPEBITS)
				streamWriteInt32(streamId, first)
				--printAll(i,': b) writing ',second,' as int32 to stream')
				streamWriteInt32(streamId, second)
			end
			local decimalplaces=mathfloor(arground*times10[8]-intval*times10[8])
			--printAll(i,': b) writing ',decimalplaces,' as int32 to stream')
			streamWriteInt32(streamId, decimalplaces)
		end
	elseif argtype=="string" then
		-- string
		--printAll(i,': writing "',arg,'"  as string to stream')
		streamWriteIntN(streamId, TYPE_STRING, STREAMTYPEBITS)
		streamWriteString(streamId, arg)
	else
		-- nil or else
		--printAll(i,': writing nil to stream')
		streamWriteIntN(streamId, TYPE_NIL, STREAMTYPEBITS)
	end
end

function _m.streamReadAuto(streamId)
	local rettype = streamReadIntN(streamId, STREAMTYPEBITS)
	local ret = nil
	if rettype==TYPE_LIST then
		local rets={}
		local retslen=streamReadAuto(streamId)
		for i=1,retslen do
			rets[i]=streamReadAuto(streamId)
		end
		return unpack(rets)
	elseif rettype==TYPE_TRUE then
		--printAll(i,': reading true from stream')
		ret = true
	elseif rettype==TYPE_FALSE then
		--printAll(i,': reading false from stream')
		ret = false
	elseif rettype==TYPE_INT6 then
		ret = streamReadIntN(streamId, 6)
		--printAll(i,': reading ',ret,' from stream')
	elseif rettype==TYPE_INT12 then
		ret = streamReadIntN(streamId,12)
		--printAll(i,': reading ',ret,' from stream')
	elseif rettype==TYPE_INT18 then
		ret = streamReadIntN(streamId, 18)
		--printAll(i,': reading ',ret,' from stream')
	elseif rettype==TYPE_INT32 then
		ret = streamReadInt32(streamId)
		--printAll(i,': reading ',ret,' from stream')
	elseif rettype==TYPE_INT64 then
		local first = streamReadInt32(streamId)
		local second = streamReadInt32(streamId)
		ret = first*2^31+second
		--printAll(i,': reading ',first,'*2^31+',second,'=',ret,' from stream')
	elseif rettype==TYPE_FLOAT6 then
		local intval = streamReadIntN(streamId,6)
		local decimalplaces = streamReadInt32(streamId)
		ret = intval + decimalplaces/times10[8]
		--printAll(i,': reading ',ret,' from stream')
	elseif rettype==TYPE_FLOAT12 then
		local intval = streamReadIntN(streamId,12)
		local decimalplaces = streamReadInt32(streamId)
		ret = intval + decimalplaces/times10[8]
		--printAll(i,': reading ',ret,' from stream')
	elseif rettype==TYPE_FLOAT18 then
		local intval = streamReadIntN(streamId,18)
		local decimalplaces = streamReadInt32(streamId)
		ret = intval + decimalplaces/times10[8]
		--printAll(i,': reading ',ret,' from stream')
	elseif rettype==TYPE_FLOAT32 then
		local intval = streamReadInt32(streamId)
		local decimalplaces = streamReadInt32(streamId)
		ret = intval + decimalplaces/times10[8]
		--printAll(i,': reading ',ret,' from stream')
	elseif rettype==TYPE_FLOAT64 then
		local first = streamReadInt32(streamId)
		local second = streamReadInt32(streamId)
		local intval = first*2^31+second
		local decimalplaces = streamReadInt32(streamId)
		ret = intval + decimalplaces/times10[8]
		--printAll(i,': reading ',ret,' from stream')
	elseif rettype==TYPE_STRING then
		ret = streamReadString(streamId)
		--printAll(i,': reading "',ret,'" from stream')
	else
		--printAll(i,': reading nil from stream')
	end
	printFn('streamReadAuto(',streamId,') = ',ret)
	return ret
end