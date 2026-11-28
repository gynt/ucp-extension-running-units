local settings = require("units.settings")

local MACEMEN_AIC_KEY = "RunningUnits_Macemen"

return function(config)
    local defaultAction, allowAIC = settings.rule("macemen", config.macemen.running.ai, 2)

    local ok, beforeCmpLocation = pcall(core.AOBScan, "66 39 8E ? ? ? ? 75 37 66 ? ? ? ? ? ? 75 1B")
    if not ok then
        log(ERROR, "Running macemen is off: run decision not found.")
        return
    end
    local ptrCurrentAIArray, aiReason = settings.currentAI()
    if not ptrCurrentAIArray then
        log(ERROR, "Running macemen is off: AI type array " .. aiReason .. ".")
        return
    end
    local detourSize = 7
    local setRunning = beforeCmpLocation + 7 + 2 + 36 -- 0x00560b7c

    local aicRunningMacemen = settings.allocate(defaultAction)

    local asm = [[
        push ECX
        push EAX

        cmp EBX, 0
        ; unitID is invalid
        jle original
        ; playerID is 0
        cmp EDI, 0
        jle original

      isAI:
        ; CurrentAIArray, gets aiType, or 0 if human
        mov EAX, DWORD [EDI*4 + ptrCurrentAIArray]

        ; get configured action for aiType
        xor ECX, ECX
        mov CL, BYTE [EAX*1 + aicRunningMacemen]
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
            aicRunningMacemen = aicRunningMacemen,
            setRunning = setRunning,
        }),
    }, nil, 'after')

    settings.register(MACEMEN_AIC_KEY, aicRunningMacemen, allowAIC, defaultAction)
end
