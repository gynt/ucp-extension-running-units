local settings = require("units.settings")

local SPEARMEN_AIC_KEY = "RunningUnits_Spearmen"

-- The detour replays the first comparison for the game's own decision.
-- The run and walk branches at +60 and +79 both set the movement state and destination field.
local DECISION = "66 39 BE ? ? ? ? 74 21 89 86 ? ? ? ? 66 83 BE ? ? ? ? 46 7E 3C 66 C7 86 ? ? ? ? FF FF "
    .. "89 BE ? ? ? ? EB 32 66 39 BE ? ? ? ? 75 1C 66 39 BE ? ? ? ? 74 13 C7 86 ? ? ? ? 81 00 00 00 "
    .. "66 89 86 ? ? ? ? EB 0D 89 86 ? ? ? ? 66 89 BE ? ? ? ?"

local PLAYER_ID = "0F ? ? ? ? ? ? 8B EF 69 ED F4 39 00 00 BA 01 00 00 00 01 ? ? ? ? ? 01 ? ? ? ? ? 51 B9 ? ? ? ? 66 ? ? ? ? ? ? E8 ? ? ? ? 8B ? ? ? ? ?"

return function(config)
    local defaultAction, allowAIC = settings.rule("spearmen", config.spearmen.running.ai, 0)

    local ok, beforeCmpLocation = pcall(core.AOBScan, DECISION)
    if not ok then
        log(ERROR, "Running spearmen is off: run decision not found.")
        return
    end
    if core.readInteger(beforeCmpLocation + 3) ~= core.readInteger(beforeCmpLocation + 18) then
        log(ERROR, "Running spearmen is off: run decision compares different unit fields.")
        return
    end
    if core.readInteger(beforeCmpLocation + 62) ~= core.readInteger(beforeCmpLocation + 81)
        or core.readInteger(beforeCmpLocation + 73) ~= core.readInteger(beforeCmpLocation + 88) then
        log(ERROR, "Running spearmen is off: run and walk branches write different unit fields.")
        return
    end
    local playerIDOk, playerID = pcall(core.AOBScan, PLAYER_ID)
    if not playerIDOk then
        log(ERROR, "Running spearmen is off: unit player field not found.")
        return
    end
    local ptrCurrentAIArray, reason = settings.currentAI()
    if ptrCurrentAIArray == nil then
        log(ERROR, "Running spearmen is off: current AI array " .. reason .. ".")
        return
    end
    local ptrUnitsArray_PlayerID = core.readInteger(playerID + 3)

    log(VERBOSE, "enable spearmen running")

    -- Location for the detour
    -- ESI contains units offset for current unit ID
    -- EDI contained player ID, but has been cleared
    -- EBX contains current unit ID
    -- ECX should be restored
    -- EAX should be restored
    -- EDI should be restored
    local detourSize = 7
    local setRunning = beforeCmpLocation + 60

    local setWalking = beforeCmpLocation + 79

    -- One byte per AI type, including index 0 for the human player.
    local aicRunningSpearmen = settings.allocate(defaultAction)

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
		cmp ECX, 2
		je walking
		cmp ECX, 1
		jne original

		; if action is 1
	  running:
    pop EDI
		pop EAX
		pop ECX
		; jumps away; original code isn't run
		jmp near setRunning

	  walking:
		pop EDI
		pop EAX
		pop ECX
		jmp near setWalking

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
            setWalking = setWalking,
            ptrUnitsArray_PlayerID = ptrUnitsArray_PlayerID,
        }),
    }, nil, 'after')

    -- Register in the aicloader that we provide an extra value, once the detour is in place
    settings.register(SPEARMEN_AIC_KEY, aicRunningSpearmen, allowAIC, defaultAction)
end
