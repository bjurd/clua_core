E2Lib.RegisterExtension("clua_core", true, "Allows E2 chips to run clientside Lua code")

util.AddNetworkString("SendLongLua")

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
		net.WriteUInt(Length, 16)
		net.WriteData(Compressed, Length)
	net.Send(self.player)
end
