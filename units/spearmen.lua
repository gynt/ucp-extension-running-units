local function isLegacyOptionSet()
    local status, ret = pcall(function()
        return core.AOBScan("74 13 C7 86 ? ? ? ?  81 00 00 00 66 89 86 ? ? ? ? EB 0D 89 86 ? ? ? ? 66 89 BE")
    end)

    if status ~= true then
        return true
    end
    return false
end

-- 17 bytes for storing which aic wants running spearmen, 0 is the human
-- for others, this is the logic: array[aiType] == 1 means run
-- array[aiType] == 2 means walk
-- array[aiType] == 0 means vanilla (aka don't set)
local aicRunningSpearmen = core.allocate(17 * 1, true) -- 17 bytes

local SPEARMEN_AIC_KEY = "RunningUnits_Spearmen"
local SPEARMEN_AIC_VALUES = {
    [0] = "vanilla",
    [1] = "run",
    [2] = "walk",
}
local spearmenMode = core.allocate(1, true)

return function(config)
    if isLegacyOptionSet() then
        error(
            "Running-Units detected the ucp2-legacy spearmen running feature is enabled and the spearmen running feature from Running-Units is enabled. Choose one.")
    end

    log(VERBOSE, "enable spearmen running")
    -- Register in the aicloader that we provide an extra value
    modules.aicloader:setAdditionalAICValue(
        SPEARMEN_AIC_KEY,
        -- set
        function(aiType, aicValue)
            if type(aicValue) ~= "number" then
                log(WARNING,
                    string.format("Cannot set AIC '%s', invalid value: %s", SPEARMEN_AIC_KEY, tostring(aicValue)))
            else
                if config.spearmen.running.ai ~= "aic_ignore_run" and config.spearmen.running.ai ~= "aic_ignore_walk" then
                    log(VERBOSE,
                        string.format("Setting %s for ai #%s to value '%s'", SPEARMEN_AIC_KEY, aiType,
                            tostring(SPEARMEN_AIC_VALUES[aicValue])))
                    core.writeByte(aicRunningSpearmen + aiType, aicValue)
                else
                    log(WARNING,
                        string.format("Did not set AIC '%s', aic value is ignored", SPEARMEN_AIC_KEY))
                end
            end
        end,
        -- reset
        function(aiType)
            core.writeByte(aicRunningSpearmen + aiType, 0)
        end
    )

    -- Location for the detour
    -- ESI contains units offset for current unit ID
    -- EDI contained player ID, but has been cleared
    -- EBX contains current unit ID
    -- ECX should be restored
    -- EAX should be restored
    -- EDI should be restored
    -- 0x0055e044
    local beforeCmpLocation = core.AOBScan("66 ? ? ? ? ? ? 74 21 89 ? ? ? ? ? 66 ? ? ? ? ? ? ? 7E 3C")
    local detourSize = 7
    local setRunning = beforeCmpLocation + 60 -- 0x0055e080

    if config.spearmen.running.ai == "aic_ignore_run" then
        -- Set to always run without caring about AIC
        core.writeBytes(aicRunningSpearmen, {
            1, 1, 1, 1, 1,
            1, 1, 1, 1, 1,
            1, 1, 1, 1, 1,
            1, 1,
        })
    elseif config.spearmen.running.ai == "aic_ignore_walk" then
        -- Do nothing?, this is the vanilla situation
        core.writeBytes(aicRunningSpearmen, {
            2, 2, 2, 2, 2,
            2, 2, 2, 2, 2,
            2, 2, 2, 2, 2,
            2, 2,
        })
    elseif config.spearmen.running.ai == "aic_run_if_not_defined" then
        -- If AIC didn't define, assume run
        core.writeBytes(aicRunningSpearmen, {
            1, 1, 1, 1, 1,
            1, 1, 1, 1, 1,
            1, 1, 1, 1, 1,
            1, 1,
        })
    elseif config.spearmen.running.ai == "aic_walk_if_not_defined" then
        -- If AIC didn't define, assume walk
        core.writeBytes(aicRunningSpearmen, {
            2, 2, 2, 2, 2,
            2, 2, 2, 2, 2,
            2, 2, 2, 2, 2,
            2, 2,
        })
    else
        error(string.format("Invalid option: %s", config.spearmen.running.ai))
    end

    local _, ptrUnitsArray_PlayerID = utils.AOBExtract(
        "0F ? ? I(? ? ? ?) 8B EF 69 ED F4 39 00 00 BA 01 00 00 00 01 ? ? ? ? ? 01 ? ? ? ? ? 51 B9 ? ? ? ? 66 ? ? ? ? ? ? E8 ? ? ? ? 8B ? ? ? ? ?"
    )
    local _, ptrCurrentAIArray = utils.AOBExtract(
        "8D ? ? I(? ? ? ?) 6A 04 51 B9 ? ? ? ? E8 ? ? ? ? 8B ? ? ? ? ? 6A 00 6A 00")
    local asm = [[
		push ECX
		push EAX
    push EDI

		cmp EBX, 0
		; unitID is invalid
		jle original
		; playerID is 0
    movsx EDI, WORD [ESI + ptrUnitsArray_PlayerID]
		cmp EDI, 0
		jle original

	  isAI:
		; CurrentAIArray, gets aiType, or 0 if human
		mov EAX, DWORD [EDI*4 + ptrCurrentAIArray]

		; get configured action for aiType
		xor ECX, ECX
		mov CL, BYTE [EAX*1 + aicRunningSpearmen]
		cmp ECX, 0
		je original
		cmp ECX, 2
		je original
		cmp ECX, 1
		jne original

		; if action is 1
	  running:
    pop EDI
		pop EAX
		pop ECX
		; jumps away; original code isn't run
		jmp setRunning

	  original:
    pop EDI
		pop EAX
		pop ECX
		; resume original code
	]]

    -- Detour at the location, place original code at the end of the custom assembly
    core.insertCode(beforeCmpLocation, detourSize, {
        core.AssemblyLambda(asm, {
            ptrCurrentAIArray = ptrCurrentAIArray,
            aicRunningSpearmen = aicRunningSpearmen,
            setRunning = setRunning,
            ptrUnitsArray_PlayerID = ptrUnitsArray_PlayerID,
        }),
    }, nil, 'after')
end
