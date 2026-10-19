gelian_market_module = gelian_market_module or {}
gelian_market_module._cname = "gelian_market_module"
gelian_market_module.view_model = require("UI/GeLianMarket/GeLianMarketViewModel")
gelian_market_module.up_helper = require("UI/GeLianMarket/GeLianMarketUpHelper")
gelian_market_module.sell_adapter = require("UI/GeLianMarket/GeLianMarketSellAdapter")
gelian_market_module.color_util = require("UI/GeLianMarket/GeLianMarketColorUtil")

function gelian_market_module:init()
end

function gelian_market_module:close()
end

return gelian_market_module
