-- by mor2000

local power=0
local maxPower=0
local function getNextBit()
	local bit=2^power
	maxPower=power
	power=power+1
	return bit
end

UniversalProcessKit.VEHICLE_MOTORIZED=getNextBit() -- 1
UniversalProcessKit.VEHICLE_COMBINE=getNextBit() -- 2
UniversalProcessKit.VEHICLE_FILLABLE=getNextBit() -- 4

UniversalProcessKit.VEHICLE_TIPPER=getNextBit() -- 8
UniversalProcessKit.VEHICLE_SHOVEL=getNextBit() -- 16

UniversalProcessKit.VEHICLE_WATERTRAILER=getNextBit() -- 32
UniversalProcessKit.VEHICLE_FUELTRAILER=getNextBit() -- 64
UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER=getNextBit() -- 128
UniversalProcessKit.VEHICLE_MILKTRAILER=getNextBit() -- 256

UniversalProcessKit.VEHICLE_SOWINGMACHINE=getNextBit() -- 512
UniversalProcessKit.VEHICLE_SPRAYER=getNextBit() -- 1024

UniversalProcessKit.VEHICLE_FORAGEWAGON=getNextBit() -- 2048
UniversalProcessKit.VEHICLE_BALER=getNextBit() -- 4096


function UniversalProcessKit.getVehicleType(vehicle)
	if type(vehicle)~="table" then
		return 0
	end
	if vehicle.upk_vehicleType==nil then
		local vehicleType=0
		
		-- redo with hasSpec()
		
		if vehicle.addSowingMachineFillTrigger ~= nil and vehicle.removeSowingMachineFillTrigger ~= nil then
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_SOWINGMACHINE
		end
		if vehicle.addWaterTrailerFillTrigger ~= nil and vehicle.removeWaterTrailerFillTrigger ~= nil then
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_WATERTRAILER
		end
		if vehicle.addSprayerFillTrigger ~= nil and vehicle.removeSprayerFillTrigger ~= nil then
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_SPRAYER
		end
		if vehicle.addFuelFillTrigger ~= nil and vehicle.removeFuelFillTrigger ~= nil and vehicle.startMotor==nil then
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_FUELTRAILER
		end
		if vehicle.allowFillType~=nil and vehicle:allowFillType(Fillable.FILLTYPE_MILK) then
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_MILKTRAILER
		end
		if vehicle.allowFillType~=nil and vehicle:allowFillType(Fillable.FILLTYPE_LIQUIDMANURE) then
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER
		end
		if vehicle.getAllowFillShovel ~= nil then
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_SHOVEL
		end
		if vehicle.allowTipDischarge ~= nil then
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_TIPPER
		end
		if vehicle.forageWgnSoundEnabled ~= nil then
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_FORAGEWAGON
		end
		if vehicle.hasBaler ~= nil then
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_BALER
		end
		if vehicle.addFuelFillTrigger ~= nil and vehicle.removeFuelFillTrigger ~= nil and vehicle.startMotor~=nil then
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_MOTORIZED
		end
		if vehicle.setFillLevel ~= nil and vehicle.getFillLevel ~= nil then
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_FILLABLE
		end
		
		-- Combines?
		
		vehicle.upk_vehicleType=vehicleType
		return vehicleType
	end
	return vehicle.upk_vehicleType
end;

function UniversalProcessKit.isVehicleType(vehicle, vehicleTypeTest)
	return bitAND(UniversalProcessKit.getVehicleType(vehicle), vehicleTypeTest)~=0
end;

function UniversalProcessKit.getVehicleTypes(vehicle)
	local r={}
	for power=0,maxPower do
		local bit=2^power
		if UniversalProcessKit.isVehicleType(vehicle,bit) then
			table.insert(r,bit,true)
		end
	end
	return r
end
			