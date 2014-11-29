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
UniversalProcessKit.VEHICLE_MANURESPREADER=getNextBit() -- 2048

UniversalProcessKit.VEHICLE_FORAGEWAGON=getNextBit() -- 4096
UniversalProcessKit.VEHICLE_BALER=getNextBit() -- 8192

UniversalProcessKit.VEHICLE_TRAFFICVEHICLE=getNextBit() -- 16384
UniversalProcessKit.VEHICLE_MILKTRUCK=getNextBit() -- 32768


function UniversalProcessKit.getVehicleType(vehicle)
	if type(vehicle)~="table" then
		return 0
	end
	if vehicle.upk_vehicleType==nil then
		local vehicleType=0
		
		print('checking vehicle')
		if SpecializationUtil.hasSpecialization(Motorized, vehicle.specializations) then
			print('its motorized')
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_MOTORIZED
		end
		if SpecializationUtil.hasSpecialization(SowingMachine, vehicle.specializations) then
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_SOWINGMACHINE
		end
		if SpecializationUtil.hasSpecialization(WaterTrailer, vehicle.specializations) then
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_WATERTRAILER
		end
		if SpecializationUtil.hasSpecialization(Sprayer, vehicle.specializations) and not SpecializationUtil.hasSpecialization(ManureSpreader, vehicle.specializations) then
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_SPRAYER
		end
		if SpecializationUtil.hasSpecialization(ManureSpreader, vehicle.specializations) then
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_MANURESPREADER
		end
		if SpecializationUtil.hasSpecialization(FuelTrailer, vehicle.specializations) then
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_FUELTRAILER
		end
		if SpecializationUtil.hasSpecialization(Fillable, vehicle.specializations) and vehicle:allowFillType(Fillable.FILLTYPE_MILK) then
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_MILKTRAILER
		end
		if SpecializationUtil.hasSpecialization(Fillable, vehicle.specializations) and vehicle:allowFillType(Fillable.FILLTYPE_LIQUIDMANURE) then
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER
		end
		if SpecializationUtil.hasSpecialization(Shovel, vehicle.specializations) then
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_SHOVEL
		end
		if SpecializationUtil.hasSpecialization(Trailer, vehicle.specializations) then
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_TIPPER
		end
		if SpecializationUtil.hasSpecialization(ForageWagon, vehicle.specializations) then
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_FORAGEWAGON
		end
		if SpecializationUtil.hasSpecialization(Baler, vehicle.specializations) then
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_BALER
		end
		if SpecializationUtil.hasSpecialization(Combine, vehicle.specializations) then -- doenst seem to recognize combines
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_COMBINE
		end
		if SpecializationUtil.hasSpecialization(Fillable, vehicle.specializations) then
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_FILLABLE
		end
		if SpecializationUtil.hasSpecialization(TrafficVehicle, vehicle.specializations) and not SpecializationUtil.hasSpecialization(Milktruck, vehicle.specializations) then
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_TRAFFICVEHICLE
		end
		if SpecializationUtil.hasSpecialization(Milktruck, vehicle.specializations) then
			vehicleType=vehicleType+UniversalProcessKit.VEHICLE_MILKTRUCK
		end
		
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
			