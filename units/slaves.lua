local settings = require("units.settings")

local SLAVES_AIC_KEY = "RunningUnits_Slaves"

return function(config)
    local defaultAction, allowAIC = settings.rule("slaves", config.slaves.running.ai, 2)

    local ok, beforeCmpLocation = pcall(core.AOBScan, "0F B7 86 ? ? ? ? 66 3B C7 74 17")
    if not ok then
        log(ERROR, "Running slaves is off: run decision not found.")
        return
    end
    local ptrCurrentAIArray, aiReason = settings.currentAI()
    if not ptrCurrentAIArray then
        log(ERROR, "Running slaves is off: AI type array " .. aiReason .. ".")
        return
    end
    local detourSize = 7
    -- Actually the default is run, then slowdown is applied, so we skip slowdown logic
    local setRunning = beforeCmpLocation + 51 -- 0x00572029

    local aicRunningSlaves = settings.allocate(defaultAction)

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
        mov CL, BYTE [EAX*1 + aicRunningSlaves]
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
            aicRunningSlaves = aicRunningSlaves,
            setRunning = setRunning,
        }),
    }, nil, 'after')

    settings.register(SLAVES_AIC_KEY, aicRunningSlaves, allowAIC, defaultAction)
end
