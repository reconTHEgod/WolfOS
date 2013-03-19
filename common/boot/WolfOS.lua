-- WolfOS BIOS

-- WolfOS version
local _WOLFOS_VERSION = "2.0.0_a1"

function os.getVersion()
	return _WOLFOS_VERSION
end

-- WolfOS directory mappings
local _root = "/WolfOS/"
local _apis, _client, _server, _data, _lang, _apps = _root.."apis/", _root.."client/", _root.."server/", _root.."data/", _root.."lang/", _root.."applications/"
local _controlPanel, _users = _client.."controlPanel/", _data.."users/"
local _WOLFOS_DIRS = {
	root = _root,
	apis = _apis,
	client = _client,
	server = _server,
	data = _data,
	lang = _lang,
	applications = _apps,
	controlPanel = _controlPanel,
	users = _users,
}

function os.getSystemDir(k)
	if not k then
		return _WOLFOS_DIRS
	end
	return _WOLFOS_DIRS[k]
end

-- Install safe versions of various library functions (These will not put cfunctions on the stack, so don't break serialisation)
do
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
			if first == nil then
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
	
	local nativegetmetatable = getmetatable
	local nativetype = type
	local nativeerror = error
	function getmetatable(_t)
		if nativetype(_t) == "string" then
			nativeerror("Attempt to access string metatable")
			return nil
		end
		return nativegetmetatable(_t)
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
end

-- Install loadreq
do
	local function getNameExpansion(s)
		local _, _, name, ext = string.find(s, "([^%./\\]*)%.(.*)$")
		return name or s, ext
	end
	
	local function getDir(s)
		return string.match(s, "^(.*)/") or "/"
	end
	
	local function suffix(s)
		return string.gsub("@/?;@/?.lua;@/?/init.lua;@/?/?.lua;@/?/?;@','@", s)
	end
	
	local function direct(g, s)
		g = string.gsub(g, "%?", s)
		return function()
			if g and fs.exists(g) and not fs.isDir(g) then
				local a = g
				g = nil
				return a
			end
		end
	end
	
	local loadreq = {
		loaded = {},
		finders = {
			direct
		},
		paths = "?;?.lua;?/init.lua;APIS/?;APIS/?.lua;APIS/?/init.lua;packages/?;packages/?.lua;packages/?/init.lua;packages/?/?;packages/?/?.lua;/",
		lua_requirer = {
			required = {},
			required_envs = {},
			requiring = {},
		},
	}
	
	local function lua_requirer(path, cenv, env, renv, rerun, args)
		local err_prefix = "lua_requirer:"
		local vars = loadreq.lua_requirer
		local _, ext = getNameExpansion(path)
		
		if not (ext == "" or ext == "lua" or ext == nil) then
			return nil, err_prefix.."wrong extension:"..ext
		end
		if vars.requiring[path] then
			return nil, err_prefix.."file is being loaded"
		end
		if not rerun and vars.required[path] then
			return vars.required[path]
		end
		
		local func, err = loadfile(path)
		if not func then
			return nil, err_prefix.."loadfile:"..err
		end
		
		env = env or {}
		env.FILE_PATH = path
		vars.required_envs[path] = env
		setfenv(func, env)
		
		renv = renv or _G
		setmetatable(env, {__index = renv})
		
		vars.requiring[path] = true
		local r = func(args and unpack(args))
		vars.requiring[path] = nil
		
		if r then
			vars.required[path] = r
			return r
		else
			local t = {}
			for k, v in pairs(env) do
				t[k] = v
			end
			vars.required[path] = t
			return t
		end
	end
	loadreq.requirers = {lua = lua_requirer}
	
	local function _find(s, paths, caller_env)
		local err = {"_find: finding "..tostring(s)}
		
		if paths then
			-- do nothing
		elseif caller_env.REQUIRE_PATH then
			paths = caller_env.REQUIRE_PATH
		elseif caller_env.PACKAGE_NAME and caller_env.FILE_PATH then
			paths = suffix(string.match(caller_env.FILE_PATH, "^(.*"..caller_env.PACKAGE_NAME..")"))..";"..loadreq.paths
		elseif caller_env.FILE_PATH then
			paths = suffix(getDir(caller_env.FILE_PATH))..";"..loadreq.paths
		else
			paths = loadreq.paths
		end
		
		s = string.gsub(s, "([^%.])%.([^%.])", "%1/%2")
		s = string.gsub(s, "^%.([^%.])", "/%1")
		s = string.gsub(s, "%.%.", ".")
		
		local finders = loadreq.finders
		
		for i = 1, #finders do
			local finder = finders[i]
			
			for search_path in string.gmatch(paths, ";?([^;]+);?") do
				local path = finder(search_path, s)()
				if path then
					return path
				end
			end
		end
		
		table.insert(err, "_find:file not found:"..s.."\ncaller path = "..(caller_env.FILE_PATH or "not available"))
		local serr = table.concat(err, "\n")
		return nil, serr
	end
	
	local function _require(s, paths, caller_env, ...)
		local err = {}
		table.insert(err, "loadreq:require: while requiring "..tostring(s))
		
		local path, e = _find(s, paths, caller_env)
		if path == nil then
			table.insert(err, e)
			local serr = table.concat(err, "\n")
			return nil, serr
		end
		
		for req_name, requirer in pairs(loadreq.requirers) do
			local r, e = requirer(path, caller_env, ...)
			
			if not r then
				table.insert(err, e)
			end
			return r
		end
		return nil, table.concat(err, "\n")
	end
	
	function require(s, paths, ...)
		local t, e = _require(s, paths, getfenv(2), ...)
		
		if not t then
			error(e, 2)
		end
		return t
	end
	
	function include(s, paths, ...)
		local caller_env = getfenv(2)
		local te, e = _require(s, paths, caller_env, ...)
		
		if not t then
			error(e, 2)
		end
		
		for k, v in pairs(t) do
			caller_env[k] = v
		end
	end
end

-- Install debug API
do
	debug = {}
	
	local term = require("rom.apis.term")
	local keys = require("rom.apis.keys")
	local peripheral = require("rom.apis.peripheral")
	
	local function clear(x, y)
		if not x then
			x = 1
		end
		if not y then
			y = 1
		end
		
		term.clear()
		term.setCursorPos(x, y)
	end
	debug.clear = clear
	
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
				term.write(whitespace)
				x, y = term.getCursorPos()
				text = string.sub(text, string.len(whitespace) + 1)
			end
			
			local newline = string.match(text, "^\n")
			if newline then
				newLine()
				text = string.sub(text, string.len(newline) + 1)
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
			term.setTextColour(16384) -- Red
			term.setBackgroundColour(32768) -- Black
		end
		print(...)
		term.setTextColour(1) -- White
	end
	debug.printError = printError
	
	local function printToMonitor(side, text)
		if peripheral.getType(side) == "monitor" then
			m = peripheral.wrap(side)
			m.clearLine()
			m.write(text)
			
			x, y = m.getCursorPos()
			w, h = m.getSize()
			if y < h then
				m.setCursorPos(1, y + 1)
			else
				m.scroll(1)
				m.setCursorPos(1, h)
			end
		end
	end
	debug.printToMonitor = printToMonitor
	
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
					break
				elseif param == keys.left then
					if pos > 0 then
						pos = pos - 1
						redraw()
					end
				elseif param == keys.right then
					if pos < string.len(line) then
						pos = pos + 1
						redraw()
					end
				elseif param == keys.up or param == keys.down then
					if _history then
						redraw(" ");
						if param == keys.up then
							if historyPos == nil then
								if #_history > 0 then
									historyPos = #_history
								end
							elseif historyPos > 1 then
								historyPos = historyPos - 1
							end
						else
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
					if pos > 0 then
						redraw(" ");
						line = string.sub(line, 1, pos - 1) .. string.sub(line, pos + 1)
						pos = pos - 1					
						redraw()
					end
				elseif param == keys.home then
					pos = 0
					redraw()		
				elseif param == keys.delete then
					if pos < string.len(line) then
						redraw(" ");
						line = string.sub(line, 1, pos ) .. string.sub(line, pos + 2)				
						redraw()
					end
				elseif param == keys["end"] then
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
end

-- Install Globals
do
	function sleep(_time)
		local timer = os.startTimer(_time)
		repeat
			local event, param = os.pullEvent("timer")
		until param == timer
	end
	
	local function check (t, a)
		return (t:sub(1, 1) == "?" and (a == nil or check(t:sub(2, -1), a)))
		or (t:sub(1, 1) == "!" and a ~= nil and not check(t:sub(2, -1), a))
		or (type(a) == t and t:sub(1, 1) ~= "?" and t:sub(1, 1) ~= "!")
		or (type(a) == "number" and t == "+number" and a > -1)
		or (type(a) == "number" and t == "-number" and a < 0)
		or (type(a) == "table" and getmetatable(a) and getmetatable(a).__type == t)
	end
	
	function ftype (s, ...)
		if type(s) ~= "string" then
			error("bad argument #1 to ftype (string expected, got "..type(s)..")", 2)
		end
		
		local i = 0
		local b = false
		for j in string.gmatch(s, "[^,%s]+") do
			i = i + 1
			b = false
			for t in string.gmatch(j, "[^|]+") do
				if check(t, select(i, ...)) then
					b = true
					break
				end
			end
			if not b then
				local badType = type(select(i, ...) or nil)
				if badType == "number" then
					if select(i, ...) > -1 then
						badType = "+number"
					elseif select(i, ...) < 0 then
						badType = "-number"
					end
				end
				return false, "bad argument #"..i..": "..j.." expected, got "..badType
			end
		end
		return true
	end
end

-- Install the rest of the OS API
do
	function os.pullEventRaw(_filter)
		return coroutine.yield(_filter)
	end
	
	function os.pullEvent(_filter)
		local eventData = {os.pullEventRaw(_filter)}
		if eventData[1] == "terminate" then
			error("Terminated", 0)
		end
		return unpack(eventData)
	end
	
	local processes = {}
	local processCount = 0
	local function createProcess(process)
		return coroutine.create(process)
	end
	
	function os.addProcess(key, process)
		ok, err = ftype("string, function", key, process)
		if not ok then
			error(err, 2)
		end
		
		table.insert(processes, {["key"] = key, ["thread"] = createProcess(process)})
		processCount = processCount + 1
		
		os.queueEvent("added_process")
	end
	
	function os.removeProcess(key)
		if ftype("string", key) then
			os.queueEvent("terminate_process", key)
		end
	end
	
	function os.getProcesses()
		local _processes = {}
		for k, v in ipairs(processes) do
			table.insert(_processes, v.key)
		end
		return _processes
	end
	
	function os.startProcesses()
		local filters = {}
		local eventData = {}
		while true do
			for i = 1, processCount do
				v = processes[i]
				if v then
					if filters[v.thread] == nil or filters[v.thread] == "terminate" then
						ok, param = coroutine.resume(v.thread, unpack(eventData))
						if not ok then
							return false, "Process: "..v.key..": "..param
						else
							filters[v.thread] = param
						end
					end
				end
			end
			for i = 1, processCount do
				v = processes[i]
				if v and (coroutine.status(v.thread) == "dead" or (eventData[1] == "terminate_process" and eventData[2] == v.key)) then
					table.remove(processes, i)
					processCount = processCount - 1
					if processCount < 1 then
						return true, nil
					end
				end
			end
			eventData = {os.pullEventRaw()}
		end
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
					error(err, 2)
				end
				return false
			end
			return true
		end
		if err and err ~= "" then
			error(err..": ".._path, 2)
		end
		return false
	end
	
	function os.loadAPI() -- @DEPRECATED in favour of require() and include()
		error("Deprecated: os.loadAPI, use require() or include() instead", 2)
	end
	
	function os.unloadAPI() -- @DEPRECATED for redundancy due to use of require() and include()
		error("Deprecated: os.unloadAPI, no replacement needed [see require() and include()]", 2)
	end
	
	local nativeShutdown = os.shutdown
	function os.shutdown()
		nativeShutdown()
		while true do
			coroutine.yield()
		end
	end
	
	local nativeReboot = os.reboot
	function os.reboot()
		nativeReboot()
		while true do
			coroutine.yield()
		end
	end
end

-- Install the lua part of the HTTP API (if enabled)
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

-- Run the shell
local ok, err = pcall(function()
	os.run({}, os.getSystemDir("root").."shell.lua")
end)

-- If the shell errored, let the user read it.
if not ok then
	debug.printError(err)
end

pcall(function()
	term.setCursorBlink(false)
	debug.print("Press any key to continue")
	os.pullEvent("key") 
end)
os.shutdown()
