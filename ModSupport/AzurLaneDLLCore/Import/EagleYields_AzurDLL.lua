-- EagleYields_AzurDLL
-- Author: HSbF6HSO3F
-- DateCreated: 2025/7/20 9:02:40
--------------------------------------------------------------

-- 添加食物产出
EagleYields['YIELD_FOOD'] = {
    Tooltip = 'LOC_AZURLANE_YIELD_FOOD',
    Floater = 'LOC_AZURLANE_YIELD_FOOD_FLOAT',
    GrantYieldAtXY = function(self, playerId, amount, x, y)
        local player = Players[playerId]
        if player == nil then return end
        -- 获得产出
        local cities, city = player:GetCities(), nil
        if x == nil or y == nil then
            city = cities:GetCapitalCity()
        else
            city = cities:FindClosest(x, y)
        end
        if city == nil then return end
        city:GetGrowth():AddGrowth(amount)
        -- 世界文本
        local float = Locale.Lookup(self.Floater, amount)
        local messageData = {
            MessageType = 0,
            MessageText = float,
            PlotX       = x,
            PlotY       = y,
            Visibility  = RevealedState.VISIBLE,
        }; Game.AddWorldViewText(messageData)
    end,
    GetTooltip = function(self, amount)
        return Locale.Lookup(self.Tooltip, amount)
    end
}
