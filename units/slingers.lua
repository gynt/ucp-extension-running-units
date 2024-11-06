-- 17 bytes for storing which aic wants running slingers, 0 is the human
-- for others, this is the logic: array[aiType] == 1 means run
-- array[aiType] == 2 means walk
-- array[aiType] == 0 means vanilla (aka don't set)
local aicRunningSlingers = core.allocate(17 * 1, true) -- 17 bytes

local SLINGERS_AIC_KEY = "RunningUnits_Slingers"
local SLINGERS_AIC_VALUES = {
    [0] = "vanilla",
    [1] = "run",
    [2] = "walk",
}
local slingersMode = core.allocate(1, true)

return function(config)
	log(VERBOSE, "enable slingers running")
	-- Register in the aicloader that we provide an extra value
	modules.aicloader:setAdditionalAICValue(
		SLINGERS_AIC_KEY,
		-- set
		function(aiType, aicValue)
			if type(aicValue) ~= "number" then
				log(WARNING,
					string.format("Cannot set AIC '%s', invalid value: %s", SLINGERS_AIC_KEY, tostring(aicValue)))
			else
				if config.slingers.running.ai ~= "aic_ignore_run" and config.slingers.running.ai ~= "aic_ignore_walk" then
					log(VERBOSE,
						string.format("Setting %s for ai #%s to value '%s'", SLINGERS_AIC_KEY, aiType,
							tostring(SLINGERS_AIC_VALUES[aicValue])))
					core.writeByte(aicRunningSlingers + aiType, aicValue)
				else
					log(WARNING,
						string.format("Did not set AIC '%s', aic value is ignored", SLINGERS_AIC_KEY))
				end
			end
		end,
		-- reset
		function(aiType)
			core.writeByte(aicRunningSlingers + aiType, 0)
		end
	)

	-- Location for the detour
	-- ESI contains units offset for current unit ID
	-- EBP contains player ID
	-- EBX contains current unit ID
	-- ECX should be restored
	-- EAX should be restored
	-- 0x00573182
	local beforeCmpLocation = core.AOBScan("66 ? ? ? ? ? ? 75 1E 0F ? ? ? ? ? ? 69 C0 ? ? ? ? 66 ? ? ? ? ? ? 75 08 38 ? ? ? ? ? 74 13 C7 ? ? ? ? ? ? ? ? ? 66 ? ? ? ? ? ? EB 1A 66 ? ? ? ? ? ? C7 ? ? ? ? ? ? ? ? ? 66 ? ? ? ? ? ? ? ? 0F ? ? ? ? ? ? 69 C0 ? ? ? ? 66 ? ? ? ? ? ? 75 0B")
	local detourSize = 7
	local setRunning = beforeCmpLocation + 65 -- 0x005731c3

	if config.slingers.running.ai == "aic_ignore_run" then
		-- Set to always run without caring about AIC
		core.writeBytes(aicRunningSlingers, {
			1, 1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1,
		})
	elseif config.slingers.running.ai == "aic_ignore_walk" then
		-- Do nothing?, this is the vanilla situation
		core.writeBytes(aicRunningSlingers, {
			2, 2, 2, 2, 2,
			2, 2, 2, 2, 2,
			2, 2, 2, 2, 2,
			2, 2,
		})
	elseif config.slingers.running.ai == "aic_run_if_not_defined" then
		-- If AIC didn't define, assume run
		core.writeBytes(aicRunningSlingers, {
			1, 1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1, 1, 1, 1,
			1, 1,
		})
	elseif config.slingers.running.ai == "aic_walk_if_not_defined" then
		-- If AIC didn't define, assume walk
		core.writeBytes(aicRunningSlingers, {
			2, 2, 2, 2, 2,
			2, 2, 2, 2, 2,
			2, 2, 2, 2, 2,
			2, 2,
		})
	else
		error(string.format("Invalid option: %s", config.slingers.running.ai))
	end


	local _, ptrCurrentAIArray = utils.AOBExtract(
		"8D ? ? I(? ? ? ?) 6A 04 51 B9 ? ? ? ? E8 ? ? ? ? 8B ? ? ? ? ? 6A 00 6A 00")
	local asm = [[
		push ECX
		push EAX

		cmp EBX, 0
		; unitID is invalid
		jle original
		; playerID is 0
		cmp EBP, 0
		jle original

	  isAI:
		; CurrentAIArray, gets aiType, or 0 if human
		mov EAX, DWORD [EBP*4 + ptrCurrentAIArray]

		; get configured action for aiType
		xor ECX, ECX
		mov CL, BYTE [EAX*1 + aicRunningSlingers]
		cmp ECX, 0
		je original
		cmp ECX, 2
		je original
		cmp ECX, 1
		jne original

		; if action is 1
	  running:
		pop EAX
		pop ECX
		; jumps away; original code isn't run
		jmp setRunning

	  original:
		pop EAX
		pop ECX
		; resume original code
	]]

	-- Detour at the location, place original code at the end of the custom assembly
	core.insertCode(beforeCmpLocation, detourSize, {
		core.AssemblyLambda(asm, {
			ptrCurrentAIArray = ptrCurrentAIArray,
			aicRunningSlingers = aicRunningSlingers,
			setRunning = setRunning,
		}),
	}, nil, 'after')
end