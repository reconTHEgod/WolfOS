-- WolfOS BIOS

--[[
-- Install safe versions of various library functions
-- These will not put cfunctions on the stack, so don't break serialisation
xpcall = function(_fn, _fnErrorHandler)
	local typeT = type(_fn)
	assert(typeT == "function", "bad argument #1 to xpcall (function expected, got "..typeT..")")
	local co = coroutine.create(_fn)
	local results = {coroutine.resume(co)}
	while coroutine.status(co) ~= "dead" do
		results = {coroutine.resume(co, coroutine.yield())}
	end
	if results[1] == true then
		return true, unpack(results, 2)
	else
		return false, _fnErrorHandler(results[2])
	end
end

pcall = function(_fn, ...)
	local typeT = type(_fn)
	assert(typeT == "function", "bad argument #1 to pcall (function expected, got "..typeT..")")
	local args = {...}
	return xpcall( 
		function()
			return _fn(unpack(args))
		end,
		function(_error)
			return _error
		end)
end
]]

function pairs(_t)
	local typeT = type(_t)
	if typeT ~= "table" then
		error("bad argument #1 to pairs (table expected, got "..typeT..")", 2)
	end
	return next, _t, nil
end

function ipairs(_t)
	local typeT = type(_t)
	if typeT ~= "table" then
		error("bad argument #1 to ipairs (table expected, got "..typeT..")", 2)
	end
	return function(t, var)
		var = var + 1
		local value = t[var] 
		if value == nil then
			return
		end
		return var, value
	end, _t, 0
end

function coroutine.wrap(_fn)
	local typeT = type(_fn)
	if typeT ~= "function" then
		error("bad argument #1 to coroutine.wrap (function expected, got "..typeT..")", 2)
	end
	local co = coroutine.create(_fn)
	return function(...)
		local results = {coroutine.resume(co, ...)}
		if results[1] then
			return unpack(results, 2)
		else
			error(results[2], 2)
		end
	end
end

function string.gmatch(_s, _pattern)
	local type1 = type(_s)
	if type1 ~= "string" then
		error("bad argument #1 to string.gmatch (string expected, got "..type1..")", 2)
	end
	local type2 = type(_pattern)
	if type2 ~= "string" then
		error("bad argument #2 to string.gmatch (string expected, got "..type2..")", 2)
	end
	
	local pos = 1
	return function()
		local first, last = string.find(_s, _pattern, pos)
		if nFirst == nil then
			return
		end		
		pos = last + 1
		return string.match(_s, _pattern, first)
	end
end

local nativesetmetatable = setmetatable
function setmetatable(_o, _t)
	if _t and type(_t) == "table" then
		local idx = rawget(_t, "__index")
		if idx and type(idx) == "table" then
			rawset(_t, "__index", function(t, k) return idx[k] end)
		end
		local newidx = rawget(_t, "__newindex")
		if newidx and type(newidx) == "table" then
			rawset(_t, "__newindex", function(t, k, v) newidx[k] = v end)
		end
	end
	return nativesetmetatable(_o, _t)
end

-- Install Debug API

debug = {}

local function write(text)
	local w, h = term.getSize()		
	local x, y = term.getCursorPos()
	
	local linesPrinted = 0
	local function newLine()
		if y + 1 <= h then
			term.setCursorPos(1, y + 1)
		else
			term.setCursorPos(1, h)
			term.scroll(1)
		end
		x, y = term.getCursorPos()
		linesPrinted = linesPrinted + 1
	end
	
	-- Print the line with proper word wrapping
	while string.len(text) > 0 do
		local whitespace = string.match(text, "^[ \t]+")
		if whitespace then
			-- Print whitespace
			term.write(whitespace)
			x, y = term.getCursorPos()
			text = string.sub(text, string.len(whitespace) + 1)
		end
		
		local newline = string.match(text, "^\n")
		if newline then
			-- Print newlines
			newLine()
			text = string.sub(text, 2)
		end
		
		local _text = string.match(text, "^[^ \t\n]+")
		if _text then
			text = string.sub(text, string.len(_text) + 1)
			if string.len(_text) > w then
				-- Print a multiline word				
				while string.len(_text) > 0 do
					if x > w then
						newLine()
					end
					term.write(_text)
					_text = string.sub(_text, (w - x) + 2)
					x, y = term.getCursorPos()
				end
			else
				-- Print a word normally
				if x + string.len(_text) - 1 > w then
					newLine()
				end
				term.write(_text)
				x, y = term.getCursorPos()
			end
		end
	end
	
	return linesPrinted
end
debug.write = write

local function print(...)
	local linesPrinted = 0
	for n, v in ipairs({...}) do
		linesPrinted = linesPrinted + write(tostring(v))
	end
	linesPrinted = linesPrinted + write("\n")
	return linesPrinted
end
debug.print = print

local function printError(...)
	if term.isColour() then
		term.setTextColour(colours.red)
	end
	print(...)
	term.setTextColour(colours.white)
end
debug.printError = printError

local function read(_replaceChar, _history)
	term.setCursorBlink(true)

    local line = ""
	local historyPos = nil
	local pos = 0
    if _replaceChar then
		_replaceChar = string.sub(_replaceChar, 1, 1)
	end
	
	local w, h = term.getSize()
	local sx, sy = term.getCursorPos()	
	
	local function redraw(_customReplaceChar)
		local scroll = 0
		if sx + pos >= w then
			scroll = (sx + pos) - w
		end
			
		term.setCursorPos(sx, sy)
		local replace = _customReplaceChar or _replaceChar
		if replace then
			term.write(string.rep(replace, string.len(line) - scroll))
		else
			term.write(string.sub(line, scroll + 1))
		end
		term.setCursorPos(sx + pos - scroll, sy)
	end
	
	while true do
		local event, param = os.pullEvent()
		if event == "char" then
			line = string.sub(line, 1, pos) .. param .. string.sub(line, pos + 1)
			pos = pos + 1
			redraw()
			
		elseif event == "key" then
		    if param == keys.enter then
				-- Enter
				break
				
			elseif param == keys.left then
				-- Left
				if pos > 0 then
					pos = pos - 1
					redraw()
				end
				
			elseif param == keys.right then
				-- Right				
				if pos < string.len(line) then
					pos = pos + 1
					redraw()
				end
			
			elseif param == keys.up or param == keys.down then
                -- Up or down
				if _history then
					redraw(" ");
					if param == keys.up then
						-- Up
						if historyPos == nil then
							if #_history > 0 then
								historyPos = #_history
							end
						elseif historyPos > 1 then
							historyPos = historyPos - 1
						end
					else
						-- Down
						if historyPos == #_history then
							historyPos = nil
						elseif historyPos ~= nil then
							historyPos = historyPos + 1
						end						
					end
					
					if historyPos then
                    	line = _history[historyPos]
                    	pos = string.len(line) 
                    else
						line = ""
						pos = 0
					end
					redraw()
                end
			elseif param == keys.backspace then
				-- Backspace
				if pos > 0 then
					redraw(" ");
					line = string.sub(line, 1, pos - 1) .. string.sub(line, pos + 1)
					pos = pos - 1					
					redraw()
				end
			elseif param == keys.home then
				-- Home
				pos = 0
				redraw()		
			elseif param == keys.delete then
				if pos < string.len(line) then
					redraw(" ");
					line = string.sub(line, 1, pos ) .. string.sub(line, pos + 2)				
					redraw()
				end
			elseif param == keys["end"] then
				-- End
				pos = string.len(line)
				redraw()
			end
		end
	end
	
	term.setCursorBlink(false)
	term.setCursorPos(w + 1, sy)
	print()
	return line
end
debug.read = read

-- Install Globals

function sleep(_time)
	local timer = os.startTimer(_time)
	repeat
		local event, param = os.pullEvent("timer")
	until param == timer
end

loadfile = function(_file)
	local file = fs.open(_file, "r" )
	if file then
		local func, err = loadstring(file.readAll(), fs.getName(_file))
		file.close()
		return func, err
	end
	return nil, "File not found"
end

dofile = function(_file)
	local fnFile, e = loadfile(_file)
	if fnFile then
		setfenv(fnFile, getfenv(2))
		return fnFile()
	else
		error(e, 2)
	end
end

-- Install the rest of the OS api

function os.pullEventRaw(_filter)
	return coroutine.yield(_filter)
end

function os.pullEvent(_filter)
	local event, p1, p2, p3, p4, p5 = os.pullEventRaw(_filter)
	if event == "terminate" then
		printError("Terminated")
		error()
	end
	return event, p1, p2, p3, p4, p5
end

function os.run(_env, _path, ...)
    local args = {...}
    local fnFile, err = loadfile(_path)
    if fnFile then
        local env = _env
        --setmetatable(env, {__index = function(t,k) return _G[k] end})
		setmetatable(env, {__index = _G })
        setfenv(fnFile, env)
        local ok, err = pcall(function()
        	fnFile(unpack(args))
        end)
        if not ok then
        	if err and err ~= "" then
	        	printError(err)
	        end
        	return false
        end
        return true
    end
    if err and err ~= "" then
		printError(err)
	end
    return false
end

local nativegetmetatable = getmetatable
local nativetype = type
local nativeerror = error
function getmetatable(_t)
	if nativetype(_t) == "string" then
		nativeerror("Attempt to access string metatable", 2)
		return nil
	end
	return nativegetmetatable(_t)
end

local function loadModule(_path)
	local name = fs.getName(_path)
	name = name:sub(1, (string.find(name, "%.") or #name + 1) - 1)
		
	local env = {}
	setmetatable(env, {__index = _G})
	local fnModule, err = loadfile(_path)
	if fnModule then
		setfenv(fnModule, env)
		fnModule()
	else
		printError(err)
		return false
	end
	
	local module = {}
	for k, v in pairs(env) do
		module[k] =  v
	end
	
	return module
end

local APIsLoading = {}
function os.loadAPI(_path)
	local name = fs.getName(_path)
	name = name:sub(1, (string.find(name, "%.") or #name + 1) - 1)
	if APIsLoading[name] == true then
		printError("API "..name.." is already being loaded")
		return false
	end
	APIsLoading[name] = true
		
	local env = {}
	setmetatable(env, {__index = _G})
	local fnAPI, err = loadfile(_path)
	if fnAPI then
		setfenv(fnAPI, env)
		fnAPI()
	else
		printError(err)
        APIsLoading[name] = nil
		return false
	end
	
	local API = {}
	for k, v in pairs(env) do
		API[k] =  v
	end
	
	_modulePath = _path:sub(1, (string.find(_path, "%.") or #_path + 1) - 1)
	if fs.isDir(_modulePath) then
		for _, module in ipairs(fs.list(_modulePath)) do
			if not fs.isDir(module) and not string.find(module, ".moon") then
				moduleName = module:sub(1, (string.find(module, "%.") or #moduleName + 1) - 1)
				API[moduleName] = {}
				
				for k, v in pairs(loadModule(fs.combine(_modulePath, module))) do
					API[moduleName][k] = v
				end
			end
		end
	end
	
	_G[name] = API	
	APIsLoading[name] = nil
	return true
end

function os.unloadAPI(_name)
	if _name ~= "_G" and type(_G[_name]) == "table" then
		_G[_name] = nil
	end
end

local nativeShutdown = os.shutdown
function os.shutdown()
	nativeShutdown()
	while true do
		coroutine.yield()
	end
end

-- Install the lua part of the HTTP api (if enabled)
if http then
	local function wrapRequest(_url, _post)
		local requestID = http.request(_url, _post)
		while true do
			local event, param1, param2 = os.pullEvent()
			if event == "http_success" and param1 == _url then
				return param2
			elseif event == "http_failure" and param1 == _url then
				return nil
			end
		end		
	end
	
	http.get = function(_url)
		return wrapRequest(_url, nil)
	end

	http.post = function(_url, _post)
		return wrapRequest(_url, _post or "")
	end
end

-- Install the lua part of the peripheral api
peripheral.wrap = function(_side)
	if peripheral.isPresent(_side) then
		local methods = peripheral.getMethods(_side)
		local result = {}
		for n, method in ipairs(methods) do
			result[method] = function(...)
				return peripheral.call(_side, method, ...)
			end
		end
		return result
	end
	return nil
end

-- Load ComputerCraft APIs
local apis = fs.list("rom/apis")
for n, file in ipairs(apis) do
	if string.sub(file, 1, 1) ~= "." then
		local path = fs.combine("rom/apis", file)
		if not fs.isDir(path) then
			os.loadAPI(path)
		end
	end
end

if turtle then
	local apis = fs.list("rom/apis/turtle")
	for n, file in ipairs(apis) do
		if string.sub(file, 1, 1) ~= "." then
			local path = fs.combine("rom/apis/turtle", file)
			if not fs.isDir(path) then
				os.loadAPI(path)
			end
		end
	end
end

-- Run the shell
local ok, err = pcall(function()
	parallel.waitForAny(
		function()
			rednet.run()
		end,
		function()
			os.run({}, "/WolfOS/shell.lua")
		end)
end)

-- If the shell errored, let the user read it.
if not ok then
	printError(err)
end

pcall(function()
	term.setCursorBlink( false )
	print("Press any key to continue")
	os.pullEvent("key") 
end)
os.shutdown()
