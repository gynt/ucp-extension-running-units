local macemen = require("units.macemen")
local slingers = require("units.slingers")
local slaves = require("units.slaves")
local spearmen = require("units.spearmen")

return {

    enable = function(self, config)
        if config.macemen.running.general == true then
            macemen(config)
        end

        if config.slingers.running.general == true then
            slingers(config)
        end

        if config.slaves.running.general == true then
            slaves(config)
        end

        if config.spearmen.running.general == true then
            spearmen(config)
        end
    end,

    disable = function(self)

    end,

}
