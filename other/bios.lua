local version = "Silverfish Bootloader 0.2"

local bootPaths = {
"rom/boot",
"boot"
}

local dataPath = "boot/.system"

local function writeBootPath(path)
	local file = fs.open(dataPath, "w")
	file.write(path)
	file.close()
end

local function readBootPath()
	local file = fs.open(dataPath, "r")
	local s = nil
	if file then
		s = file.readAll()
		file.close()
	end
	return s
end

if not fs.isDir("/boot") then
	fs.makeDir("/boot")
end
if not fs.exists(dataPath) then
	writeBootPath("")
end

local function clear()
    term.setTextColour(1) -- white
	term.setBackgroundColour(32768) -- black
	term.clear()
    term.setCursorPos(1, 1)
end

local function write(s, y)
    term.setCursorPos(1, y)
    term.write(s)
end

local function writeCenter(s, y)
	w = term.getSize()
	x = (w / 2) - (#s / 2) + 1
	
	term.setCursorPos(x, y)
	term.write(s)
end

local function boot(path)
    local file = fs.open(path, "r")
    if file then
		writeBootPath(path)
        local func, err = loadstring(file.readAll(), fs.getName(path))
        file.close()
        if func then
            return pcall(func)
        else
            return false, err
        end
    end
    return false, "Error opening file "..path
end

local function getBootFiles(path, list)
    for _, name in ipairs(fs.list(path)) do
        local _path = fs.combine(path, name)
        if _path ~= dataPath and not fs.isDir(_path) then
            table.insert(list, _path)
        end
    end
end

local bootList = {}

for _, path in ipairs(bootPaths) do
    if fs.exists(path) and fs.isDir(path) then
        getBootFiles(path, bootList)
    end
end

if #bootList == 0 then
    write("No boot file found.", 1)
    write("Press any key to shutdown", 2)
    coroutine.yield("key")
elseif #bootList == 1 then
    boot(bootList[1])
else
	write("[F1] = MENU", 1)
	timer = os.startTimer(1)
	eventData = {coroutine.yield()}
	clear()
	
	local loop = true
    local selected = 1
    local scroll = 0
    local w, h = term.getSize()
    
	if not (eventData[1] == "key" and eventData[2] == 59) then
		local ok, err = boot(readBootPath())
		if ok then loop = false end
	end
	
    local function redraw()
        clear()
		
		term.setTextColour(32768) -- black
		term.setBackgroundColour(1) -- white
        writeCenter(" -- "..version.." -- ", 1)
		
        for i = 1, math.min(#bootList, h - 1) do
            if i + scroll == selected then
                term.setTextColour(32768) -- black
				term.setBackgroundColour(1) -- white
            else
                term.setTextColour(1) -- white
				term.setBackgroundColour(32768) -- black
            end
			local s = bootList[i + scroll]
			writeCenter(" "..string.gmatch(fs.getName(s), "(%w+)")().." ("..s..") ", i + 2)
        end
    end
    while loop do
        redraw()
        local event, key = coroutine.yield("key")
        if key == 28 then -- Enter
            clear()
            local ok, err = boot(bootList[selected])
            if not ok then
                write(err, 1)
                write("Press any key to continue", 2)
                coroutine.yield("key")
            end
            break
        elseif key == 200 then -- Up
            if selected > 1 then
                selected = selected - 1
                if selected == scroll then
                    scroll = scroll - 1
                end
            end
        elseif key == 208 then -- Down
            if selected < #bootList then
                selected = selected + 1
                if selected - scroll >= h then
                    scroll = scroll + 1
                end
            end
        end
    end
end

os.shutdown()
