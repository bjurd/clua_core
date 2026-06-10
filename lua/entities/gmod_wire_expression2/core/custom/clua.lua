E2Lib.RegisterExtension("clua_core", true, "Allows E2 chips to run clientside Lua code")

util.AddNetworkString("SendLongLua")

local function ChipOwnedByPlayer(Chip, Player)
	if not isentity(Chip) or not Chip:IsValid() then return false end
	if not isentity(Player) or not Player:IsPlayer() then return false end

	if Chip:GetClass() ~= "gmod_wire_expression2" then return false end

	local Context = Chip.context
	if not istable(Context) or Context.player ~= Player then return false end

	return true
end

net.Receive("SendLongLua", function(_, Sender)
	local ChipIndex = net.ReadUInt(MAX_EDICT_BITS)
	local Chip = Entity(ChipIndex)

	if not ChipOwnedByPlayer(Chip, Sender) then
		return
	end

	local ID = net.ReadUInt(32)

	if not Chip.m_pCLUACallbacks then
		return
	end

	local Data = Chip.m_pCLUACallbacks[ID]
	if not Data then
		return
	end
	Chip.m_pCLUACallbacks[ID] = nil

	local Returns = net.ReadTable(true)

	for k, v in ipairs(Returns) do
		if isbool(v) then
			Returns[k] = v and 1 or 0
		elseif not isnumber(v) and not isstring(v) then
			-- TODO: Tables
			Returns[k] = tostring(v)
		end
	end

	Data[1]:UnsafeExtCall({ Returns }, Data[2])
end)



e2function void sendLuaString(string code)
	if string.len(code) > 255 then
		return self:throw("Lua code exceeds the maximum length of 255 characters, use sendLongLuaString.")
	end

	local Compiled = CompileString(code, "", false)

	if isstring(Compiled) then
		return self:throw(Format("Lua compilation error: %s", Compiled))
	end

	self.player:SendLua(code)
end

e2function void sendLongLuaString(string code)
	if string.len(code) > 65535 then
		return self:throw("Lua code exceeds the maximum length of 65535 characters.")
	end

	local Compiled = CompileString(code, "", false)

	if isstring(Compiled) then
		return self:throw(Format("Lua compilation error: %s", Compiled))
	end

	local Compressed = util.Compress(code)
	local Length = string.len(Compressed)

	net.Start("SendLongLua")
		net.WriteUInt(self.entity:EntIndex(), MAX_EDICT_BITS)
		net.WriteBool(false)
		net.WriteUInt(0, 32)
		net.WriteUInt(Length, 16)
		net.WriteData(Compressed, Length)
	net.Send(self.player)
end

e2function void sendLongLuaString(string code, function callback)
	if string.len(code) > 65535 then
		return self:throw("Lua code exceeds the maximum length of 65535 characters.")
	end

	local Compiled = CompileString(code, "", false)

	if isstring(Compiled) then
		return self:throw(Format("Lua compilation error: %s", Compiled))
	end

	callback:Unwrap("r", self)

	-- Store these on the chip entity so we don't have to CallOnRemove
	local CurrentID = self.entity.m_nCLUACallbackID or 0
	local NextID = CurrentID

	CurrentID = CurrentID + 1
	if CurrentID >= (2^31) then
		CurrentID = 0
	end
	self.entity.m_nCLUACallbackID = CurrentID

	if not self.entity.m_pCLUACallbacks then
		self.entity.m_pCLUACallbacks = {}
	end
	self.entity.m_pCLUACallbacks[NextID] = { callback, self }

	local Compressed = util.Compress(code)
	local Length = string.len(Compressed)

	net.Start("SendLongLua")
		net.WriteUInt(self.entity:EntIndex(), MAX_EDICT_BITS)
		net.WriteBool(true)
		net.WriteUInt(NextID, 32)
		net.WriteUInt(Length, 16)
		net.WriteData(Compressed, Length)
	net.Send(self.player)
end
