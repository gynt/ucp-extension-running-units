local settings = require("units.settings")

local SLINGERS_AIC_KEY = "RunningUnits_Slingers"

return function(config)
    local defaultAction, allowAIC = settings.rule("slingers", config.slingers.running.ai, 2)

    local ok, beforeCmpLocation = pcall(core.AOBScan, "66 39 8E ? ? ? ? 75 1E 0F ? ? ? ? ? ? 69 C0 ? ? ? ? 66 ? ? ? ? ? ? 75 08 38 ? ? ? ? ? 74 13 C7 ? ? ? ? ? ? ? ? ? 66 ? ? ? ? ? ? EB 1A 66 ? ? ? ? ? ? C7 ? ? ? ? ? ? ? ? ? 66 ? ? ? ? ? ? ? ? 0F ? ? ? ? ? ? 69 C0 ? ? ? ? 66 ? ? ? ? ? ? 75 0B")
    if not ok then
        log(ERROR, "Running slingers is off: run decision not found.")
        return
    end
    local ptrCurrentAIArray, aiReason = settings.currentAI()
    if not ptrCurrentAIArray then
        log(ERROR, "Running slingers is off: AI type array " .. aiReason .. ".")
        return
    end
    local detourSize = 7
    local setRunning = beforeCmpLocation + 65 -- 0x005731c3

    local aicRunningSlingers = settings.allocate(defaultAction)

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

    settings.register(SLINGERS_AIC_KEY, aicRunningSlingers, allowAIC, defaultAction)
end
