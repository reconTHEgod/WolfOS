-- WolfOS Peripheral Handling

export getValidSides = ->
	{"top", "bottom", "front", "back", "left", "right"}

export getType = peripheral.getType

export getAllPeripherals = (sFilter) ->
	tPeripherals = {}
	for _, sSide in ipairs getValidSides!
		if peripheral.isPresent(sSide) and (getType(sSide) == sFilter or sFilter == nil)
			table.insert tPeripherals, {port: sSide, type: getType sSide}
	
	return tPeripherals
