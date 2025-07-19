-- EagleYields
-- Author: HSbF6HSO3F
-- DateCreated: 2025/7/19 22:09:16
--------------------------------------------------------------
--||=======================include========================||--
include('EagleUnionCore')

--||======================MetaTable=======================||--

EagleYields = {
    -- 默认
    ['DEFAULT'] = {
        Tooltip = 'LOC_AZURLANE_YIELD_GOLD',
        GrantYield = function(playerId, amount, x, y)
            local player = Players[playerId]
            if player == nil then return end
            -- 获得产出
            local treasury = player:GetTreasury()
            treasury:ChangeGoldBalance(amount)
        end
    },
    -- 科技值
    ['YIELD_SCIENCE'] = {
        Tooltip = 'LOC_AZURLANE_YIELD_SCIENCE',
        GrantYield = function(playerId, amount, x, y)
            local player = Players[playerId]
            if player == nil then return end
            -- 获得产出
            local tech = player:GetTechs()
            tech:ChangeCurrentResearchProgress(amount)
        end
    },
    -- 文化值
    ['YIELD_CULTURE'] = {
        Tooltip = 'LOC_AZURLANE_YIELD_CULTURE',
        GrantYield = function(playerId, amount, x, y)
            local player = Players[playerId]
            if player == nil then return end
            -- 获得产出
            local culture = player:GetCulture()
            culture:ChangeCurrentCulturalProgress(amount)
        end
    },
    -- 金币
    ['YIELD_GOLD'] = {
        Tooltip = 'LOC_AZURLANE_YIELD_GOLD',
        GrantYield = function(playerId, amount, x, y)
            local player = Players[playerId]
            if player == nil then return end
            -- 获得产出
            local treasury = player:GetTreasury()
            treasury:ChangeGoldBalance(amount)
        end
    },
    -- 信仰值
    ['YIELD_FAITH'] = {
        Tooltip = 'LOC_AZURLANE_YIELD_FAITH',
        GrantYield = function(playerId, amount, x, y)
            local player = Players[playerId]
            if player == nil then return end
            -- 获得产出
            local religion = player:GetReligion()
            religion:ChangeFaithBalance(amount)
        end
    },
    -- 生产力
    ['YIELD_PRODUCTION'] = {
        Tooltip = 'LOC_AZURLANE_YIELD_PRODUCTION',
        GrantYield = function(playerId, amount, x, y)
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
            city:GetBuildQueue():AddProgress(amount)
        end
    }
}

--||====================Based functions===================||--

-- 获得产出对象
function EagleYields:GetYield(yieldType)
    if type(yieldType) ~= 'string' then
        return self['DEFAULT']
    end
    return self[yieldType] or self['DEFAULT']
end

-- 玩家获得特定产出
function EagleYields:GrantYield(playerId, yieldType, amount, x, y)
    self:GetYield(yieldType).GrantYield(playerId, amount, x, y)
end

--||=======================include========================||--
include('EagleYields_', true)
