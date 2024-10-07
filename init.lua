local macemen = require("units.macemen")

return {

    enable = function(self, config)
        if config.macemen.running.general == true then
            macemen(config)
        end

        if config.spearman and config.spearmen.running == true then
            spearmen(config)
        end
    end,
    disable = function(self) end,

}
