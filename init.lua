-- 17 bytes for storing which aic wants running macemen, 0 is the human
-- for others, this is the logic: array[aiType] == 1 means run
-- array[aiType] == 2 means walk
-- array[aiType] == 0 means vanilla (aka don't set)
local aicRunningMacemen = core.allocate(17 * 1, true) -- 17 bytes

local MACEMEN_AIC_KEY = "RunningUnits_Macemen"
local MACEMEN_AIC_VALUES = {
    [0] = "vanilla",
    [1] = "run",
    [2] = "walk",
}
local macemenMode = core.allocate(1, true)

return {

    enable = function(self, config)
        if config.macemen.running.general == true then
            log(VERBOSE, "enable macemen running")
            -- Register in the aicloader that we provide an extra value
            modules.aicloader:setAdditionalAICValue(
                MACEMEN_AIC_KEY,
                -- set
                function(aiType, aicValue)
                    if type(aicValue) ~= "number" then
                        log(WARNING,
                            string.format("Cannot set AIC '%s', invalid value: %s", MACEMEN_AIC_KEY, tostring(aicValue)))
                    else
                        if config.macemen.running.ai ~= "aic_ignore_run" and config.macemen.running.ai ~= "aic_ignore_walk" then
                            log(VERBOSE,
                                string.format("Setting %s for ai #%s to value '%s'", MACEMEN_AIC_KEY, aiType,
                                    tostring(MACEMEN_AIC_VALUES[aicValue])))
                            core.writeByte(aicRunningMacemen + aiType, aicValue)
                        else
                            log(WARNING,
                                string.format("Did not set AIC '%s', aic value is ignored", MACEMEN_AIC_KEY))
                        end
                    end
                end,
                -- reset
                function(aiType)
                    core.writeByte(aicRunningMacemen + aiType, 0)
                end
            )

            -- Location for the detour
            -- ESI contains units offset for current unit ID
            -- EDI contains player ID
            -- EBX contains current unit ID
            -- ECX should be restored
            -- EAX should be restored
            -- 00560b56
            local beforeCmpLocation = core.AOBScan("75 37 66 ? ? ? ? ? ? 75 1B") - 7
            local detourSize = 7
            local setRunning = beforeCmpLocation + 7 + 2 + 36 -- 0x00560b7c

            if config.macemen.running.ai == "aic_ignore_run" then
                -- Set to always run without caring about AIC
                -- core.writeCode(core.AOBScan("75 37 66 ? ? ? ? ? ? 75 1B"), { 0xEB, 0x24 })
                core.writeBytes(aicRunningMacemen, {
                    1, 1, 1, 1, 1,
                    1, 1, 1, 1, 1,
                    1, 1, 1, 1, 1,
                    1, 1,
                })
            elseif config.macemen.running.ai == "aic_ignore_walk" then
                -- Do nothing?, this is the vanilla situation
                core.writeBytes(aicRunningMacemen, {
                    2, 2, 2, 2, 2,
                    2, 2, 2, 2, 2,
                    2, 2, 2, 2, 2,
                    2, 2,
                })
            elseif config.macemen.running.ai == "aic_run_if_not_defined" then
                -- If AIC didn't define, assume run
                core.writeBytes(aicRunningMacemen, {
                    1, 1, 1, 1, 1,
                    1, 1, 1, 1, 1,
                    1, 1, 1, 1, 1,
                    1, 1,
                })
            elseif config.macemen.running.ai == "aic_walk_if_not_defined" then
                -- If AIC didn't define, assume walk
                core.writeBytes(aicRunningMacemen, {
                    2, 2, 2, 2, 2,
                    2, 2, 2, 2, 2,
                    2, 2, 2, 2, 2,
                    2, 2,
                })
            else
                error(string.format("Invalid option: %s", config.macemen.running.ai))
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
        end

        if config.spearman and config.spearmen.running == true then
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
    end,
    disable = function(self) end,

}
