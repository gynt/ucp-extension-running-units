local RUN = {aic_ignore_run = true, aic_run_if_not_defined = true}
local WALK = {aic_ignore_walk = true, aic_walk_if_not_defined = true}
local CURRENT_AI = "8D ? ? ? ? ? ? 6A 04 51 B9 ? ? ? ? E8 ? ? ? ? 8B ? ? ? ? ? 6A 00 6A 00"
local aiArray, aiReason

local function rule(unit, value, walkAction)
    if type(value) ~= "string" then
        log(ERROR, "Running " .. unit .. ": the AI running rule must be a string. Using the game decision.")
        return 0, true
    end
    local allowAIC = value ~= "aic_ignore_run" and value ~= "aic_ignore_walk"
    if RUN[value] then return 1, allowAIC end
    if WALK[value] then return walkAction, allowAIC end
    log(WARNING, "Running " .. unit .. ": unknown AI running rule " .. value .. ". Using the game decision.")
    return 0, allowAIC
end

local function currentAI()
    if not aiArray and not aiReason then
        local ok, site = pcall(core.AOBScan, CURRENT_AI)
        if ok then aiArray = core.readInteger(site + 3) else aiReason = "not found" end
    end
    return aiArray, aiReason
end

local function allocate(defaultAction)
    local address = core.allocate(17, true)
    local actions = {}
    for index = 1, 17 do actions[index] = defaultAction end
    core.writeBytes(address, actions)
    return address
end

local function register(key, address, allowAIC, resetAction)
    modules.aicloader:setAdditionalAICValue(key,
        function(aiType, value)
            if value == nil then return core.readByte(address + aiType) end
            if type(value) ~= "number" then
                log(ERROR, "AIC '" .. key .. "' must be a number.")
                value = resetAction
            elseif value ~= 0 and value ~= 1 and value ~= 2 then
                log(WARNING, "Invalid AIC '" .. key .. "': " .. tostring(value))
                value = resetAction
            end
            if allowAIC then
                core.writeByte(address + aiType, value)
            end
        end,
        function(aiType)
            core.writeByte(address + aiType, resetAction)
        end)
end

return {rule = rule, currentAI = currentAI, allocate = allocate, register = register}
