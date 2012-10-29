-- WolfOS Peripheral Handling

export getValidPorts = ->
	{"top", "bottom", "front", "back", "left", "right"}

export getType = peripheral.getType

export getAllPeripherals = (t) ->
	peripherals = {}
	for _, p in ipairs getValidSides!
		if peripheral.isPresent(p) and (getType(p) == t or t == nil)
			table.insert peripherals, {port: p, type: getType p}
	
	tPeripherals
