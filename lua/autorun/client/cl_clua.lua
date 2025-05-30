net.Receive("SendLongLua", function()
	local Length = net.ReadUInt(16)
	local Compressed = net.ReadData(Length)
	local Code = util.Decompress(Compressed)

	RunString(Code, "", true)
end)
