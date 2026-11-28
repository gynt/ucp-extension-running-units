local units = {
    {"macemen", require("units.macemen")},
    {"slingers", require("units.slingers")},
    {"slaves", require("units.slaves")},
    {"spearmen", require("units.spearmen")},
}

return {
    enable = function(self, config)
        for _, unit in ipairs(units) do
            local name, install = unit[1], unit[2]
            local section = config[name]
            local running = type(section) == "table" and section.running
            if section ~= nil and (type(section) ~= "table" or (running ~= nil and type(running) ~= "table")) then
                log(ERROR, "Running " .. name .. " settings must be a table.")
            elseif running and running.general == true then
                local ok, reason = pcall(install, config)
                if not ok then log(ERROR, "Running " .. name .. " is off: " .. tostring(reason)) end
            elseif running and running.general ~= nil and type(running.general) ~= "boolean" then
                log(ERROR, "Running " .. name .. " enabled setting must be a boolean.")
            end
        end
    end,

    disable = function(self)
    end,
}
