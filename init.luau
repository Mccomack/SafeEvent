--!strict
local SafeEvent = {}
local CalledTimes = {}

local MAX_CALL_TIMES_IN_SECOND = 100
local KICK_MESSAGE = "event flood. "

local function CheckCalledTimes(Player: Player)
	if CalledTimes[Player] == nil then
		CalledTimes[Player] = 0
		
		return
	end
	
	if CalledTimes[Player] <  0 then
		CalledTimes[Player] = 0
		
		return
	end
	
	if CalledTimes[Player] >= MAX_CALL_TIMES_IN_SECOND then
		Player:Kick(KICK_MESSAGE)
	end
end

local function packedCallback(Player: Player, Success: boolean, ...)
	if Success then
		CalledTimes[Player] -= 1
		
		return ...
	end	
	
	task.delay(1, function()
		CalledTimes[Player] -= 1
	end)
	
	return ...
end

local function safeEvent<funcIn, funcOut>(callback: ((Player, funcIn) -> (boolean, funcOut)), Player: Player, ...: funcIn): funcOut
	CheckCalledTimes(Player)
	
	CalledTimes[Player] += 1
	
	return packedCallback(Player, callback(Player, ...))
end

function SafeEvent.bind<funcIn, funcOut>(Event: RemoteEvent|RemoteFunction, callback: ((Player, funcIn) -> (boolean, funcOut))): RBXScriptConnection?
	local function conn(Player: Player, ...)
		return safeEvent(callback, Player, ...)
	end
	
	if Event:IsA("RemoteEvent") then
		return Event.OnServerEvent:Connect(conn)
	elseif Event:IsA("RemoteFunction") then
		Event.OnServerInvoke = conn
	end
	
	return
end

function SafeEvent.TypeCheck(var: any, Type: string): boolean
	if Type == "string" then
		return typeof(var) == Type and #var ~= 0
	elseif Type == "number" then
		return typeof(var) == Type and var == var
	end
	
	return typeof(var) == Type
end

function SafeEvent.InstanceTypeCheck(var: any, Type: string): boolean
	return typeof(var) == "Instance" and var:IsA(Type)
end

return SafeEvent