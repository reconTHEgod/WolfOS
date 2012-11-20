getValidPorts = function()
  return {
    "top",
    "bottom",
    "front",
    "back",
    "left",
    "right"
  }
end
getType = peripheral.getType
getAllPeripherals = function(t)
  local peripherals = { }
  for _, p in ipairs(getValidSides()) do
    if peripheral.isPresent(p) and (getType(p) == t or t == nil) then
      table.insert(peripherals, {
        port = p,
        type = getType(p)
      })
    end
  end
  return peripherals
end
