return function(config)
	local status, ret = pcall(function()
		core.writeCode(
			core.AOBScan("74 13 C7 86 ? ? ? ?  81 00 00 00 66 89 86 ? ? ? ? EB 0D 89 86 ? ? ? ? 66 89 BE"),
			{ 0x90, 0x90, })

		return true
	end)

	if status ~= true then
		log(WARNING,
			"Setting spearmen running failed likely because the ucp2 legacy module also has this feature active.")
	end
end