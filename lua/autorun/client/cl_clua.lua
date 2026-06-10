net.Receive("SendLongLua", function()
	local Chip = net.ReadUInt(MAX_EDICT_BITS)
	local Callback = net.ReadBool()
	local ID = net.ReadUInt(32)
	local Length = net.ReadUInt(16)
	local Compressed = net.ReadData(Length)
	local Code = util.Decompress(Compressed)

	local Fn = CompileString(Code, "[E2]", true)

	if not isfunction(Fn) then
		error("Compiled code is not a function!")
		return
	end

	local Results = { xpcall(Fn, ErrorNoHaltWithStack) }
	local Success = table.remove(Results, 1)

	if not Success then
		return
	end

	if Callback then
		net.Start("SendLongLua")
			net.WriteUInt(Chip, MAX_EDICT_BITS)
			net.WriteUInt(ID, 32)
			net.WriteTable(Results, true)
		net.SendToServer()
	end
end)
