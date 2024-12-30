-- EagleUnionPoint
-- Author: HSbF6HSO3F
-- DateCreated: 2024/12/26 14:48:50
--------------------------------------------------------------
--||=======================include========================||--
include('EagleUnionCore')

--||======================MetaTable=======================||--

EaglePointManager = {}

--||=======================Constants======================||--

local EaglePointKey = 'EaglePoint'

--||===================local variables====================||--

local perYieldPercent = 0.2
local SantaClaraValley = GameInfo.Districts['DISTRICT_SANTA_CLARA_VALLEY'].Index

local campusIndex = GameInfo.Districts['DISTRICT_CAMPUS'].Index
local perCampus = 5

--||====================GamePlay, UI======================||--

--获取研究点数 (GamePlay, UI)
function EaglePointManager.GetEaglePoint(playerID, floor)
    local pPlayer = Players[playerID]
    if not pPlayer then return 0 end
    local points = pPlayer:GetProperty(EaglePointKey) or 0
    return floor and EagleCore.Floor(points) or points
end

--研究点数相关
EaglePointManager.Points = {
    --来自城市
    City = {
        Yield = {
            GetPointYield = function(playerID, cityID)
                local yieldPoint = 0
                --获取城市
                local pCity = CityManager.GetCity(playerID, cityID)
                if not pCity then return 0 end
                local cityDistricts = pCity:GetDistricts()
                if cityDistricts:HasDistrict(SantaClaraValley, true) then
                    --获取各项产出
                    yieldPoint = yieldPoint + pCity:GetYield(YieldTypes.SCIENCE)
                    yieldPoint = yieldPoint + pCity:GetYield(YieldTypes.CULTURE)
                    yieldPoint = yieldPoint + pCity:GetYield(YieldTypes.PRODUCTION)
                end
                --百分比处理
                return EagleCore.Floor(yieldPoint * perYieldPercent)
            end
        }
    },
    --来自其他
    Extra = {
        -- If you want to add research points from other sources, please add code here.
        -- 想要新增其他来源的研究点数，请在此处添加代码
        -- Just add a table structure like the one below to the Extra table to add research points from other sources.
        -- 只需在Extra表中添加一个类似下面的表结构，即可添加其他来源的研究点数
        -- For example:
        -- 例如：
        -- SantaClara = {
        --     --Tooltip prompt
        --     --功能性文本提示
        --     Tooltip = 'LOC_EAGLE_POINT_FROM_SANTA_CLARA',
        --     --Function to get point
        --     --获取点数函数
        --     GetPointYield = function(playerID)
        --         --获取玩家
        --         local pPlayer = Players[playerID]
        --         if not pPlayer then return 0 end
        --         --获取区域
        --         local districts = pPlayer:GetDistricts()
        --         --获取圣塔克拉拉谷的数量
        --         local count = 0
        --         for _, district in districts:Members() do
        --             if district:GetType() == SantaClaraValley
        --                 and district:IsComplete() and (not district:IsPillaged())
        --             then
        --                 count = count + 1
        --             end
        --         end
        --         --返回最终的点数
        --         return EagleCore.Floor(count * 10)
        --     end,
        --     --Function to get tooltip, must include self parameter
        --     --获取tooltip函数，必须加入self参数
        --     --If the number of points obtained from this source is 0, the tooltip will not be displayed.
        --     --若从此来源获得的点数为0，则不显示tooltip
        --     --So, if you meet any of the above situations, please return an empty string.
        --     --所以你如果遇到上述情况，请返回空字符串
        --     GetTooltip = function(self, playerID)
        --         local yield = self.GetPointYield(playerID)
        --         return yield ~= 0 and Locale.Lookup(self.Tooltip, yield) or ''
        --     end
        -- }
    },
    --百分比增益
    Moddifier = {
        Example = {
            Tooltip = 'LOC_EAGLE_POINT_MODIFIER_EXAMPLE',
            GetModifier = function(playerID)
                return 10
            end,
            GetTooltip = function(self, playerID)
                local modifier = self.GetModifier(playerID)
                return modifier ~= 0 and Locale.Lookup(self.Tooltip, modifier) or ''
            end
        }
    }
}

--获取某一城市产出的研究点数 (GamePlay, UI)
function EaglePointManager:GetCityYieldPoint(playerID, cityID)
    --产出
    local yield = 0
    --遍历来源
    local cityPoint = self.Points.City
    for _, source in pairs(cityPoint) do
        yield = yield + source.GetPointYield(playerID, cityID)
    end
    return yield
end

--获取获得的研究点数增益 (GamePlay, UI)
function EaglePointManager:GetPointModifier(playerID)
    local modifier = 0
    --遍历来源
    local moddifier = self.Points.Moddifier
    for _, source in pairs(moddifier) do
        modifier = modifier + source.GetModifier(playerID)
    end
    return modifier
end

--获取获得的研究点数增益的tooltip (GamePlay, UI)
function EaglePointManager:GetPointModifierTooltip(playerID)
    local modifierTooltip = ''
    --遍历来源
    local moddifier = self.Points.Moddifier
    for _, source in pairs(moddifier) do
        modifierTooltip = modifierTooltip .. source:GetTooltip(playerID)
    end
    --返回tooltip
    return modifierTooltip
end

--获取每回合获得的研究点数，无增益 (GamePlay, UI)
function EaglePointManager:GetPerTurnPointWithoutModifier(playerID, floor)
    --获取玩家
    local pPlayer = Players[playerID]
    if not pPlayer then return 0 end
    local perTurnPoint = 0
    --来自城市
    local cities = pPlayer:GetCities()
    for _, city in cities:Members() do
        local cityID = city:GetID()
        local cityPoint = self:GetCityYieldPoint(playerID, cityID)
        perTurnPoint = perTurnPoint + cityPoint
    end
    --来自其他
    local extra = self.Points.Extra
    for _, source in pairs(extra) do
        perTurnPoint = perTurnPoint + source.GetPointYield(playerID)
    end
    return floor and EagleCore.Floor(perTurnPoint) or perTurnPoint
end

--获取每回合获得的额外增益研究点数 (GamePlay, UI)
function EaglePointManager:GetPerTurnPointWithModifier(playerID, floor)
    local perTurnPoint = self:GetPerTurnPointWithoutModifier(playerID, true)
    --获取点数增益
    local modifier = self:GetPointModifier(playerID)
    --点数增益处理
    local percentPoint = perTurnPoint * modifier / 100
    return floor and EagleCore.Floor(percentPoint) or percentPoint
end

--获取每回合获得的研究点数 (GamePlay, UI)
function EaglePointManager:GetPerTurnPoint(playerID, floor)
    --无增益
    local perTurnPoint = self:GetPerTurnPointWithModifier(playerID, true)
    --有增益
    local percentPoint = self:GetPerTurnPointWithoutModifier(playerID, true)
    perTurnPoint = perTurnPoint + percentPoint
    --返回最终的点数
    return floor and EagleCore.Floor(perTurnPoint) or perTurnPoint
end

--获取每回合获得的研究点数的tooltip (GamePlay, UI)
function EaglePointManager:GetPerTurnPointTooltip(playerID)
    local perTurnPointTooltip = ''
    --获取玩家
    local pPlayer = Players[playerID]
    if not pPlayer then return '' end
    --获取每回合获得的研究点数
    local perTurnPoint = self:GetPerTurnPoint(playerID)
    perTurnPointTooltip = Locale.Lookup('LOC_EAGLE_POINT_PER_TURN', perTurnPoint)
    --来自城市
    local cities = pPlayer:GetCities()
    local citiesPoint = 0
    local citiesTooltip = ''
    for _, city in cities:Members() do
        --获取城市ID
        local cityID = city:GetID()
        --获取城市产出的研究点数
        local cityPoint = self:GetCityYieldPoint(playerID, cityID)
        if cityPoint ~= 0 then
            --增加城市研究点数
            citiesPoint = citiesPoint + cityPoint
            --获取城市名称
            local cityName = city:GetName()
            --设置tooltip
            citiesTooltip = citiesTooltip ..
                Locale.Lookup('LOC_EAGLE_POINT_FROM_CITY', cityPoint, cityName)
        end
    end
    --来自城市的tooltip
    if citiesTooltip ~= '' then
        perTurnPointTooltip = perTurnPointTooltip ..
            Locale.Lookup('LOC_EAGLE_POINT_FROM_CITIES', citiesPoint) .. citiesTooltip
    end
    --来自其他
    local extra = self.Points.Extra
    for _, source in pairs(extra) do
        perTurnPointTooltip = perTurnPointTooltip .. source:GetTooltip(playerID)
    end
    --获取点数增益
    local modifier = self:GetPointModifier(playerID)
    local modifierTooltip = self:GetPointModifierTooltip(playerID)
    if modifierTooltip ~= '' then
        local modifierPoint = self:GetPerTurnPointWithModifier(playerID, true)
        perTurnPointTooltip = perTurnPointTooltip ..
            Locale.Lookup('LOC_EAGLE_POINT_FROM_MODIFIER', modifierPoint, modifier) .. modifierTooltip
    end
    --返回tooltip
    return perTurnPointTooltip
end

--研究点数花费减免
EaglePointManager.Reduction = {
    --总上限相关
    Limit = {
        --基础
        Base = 50,
        --上限改变因素
        Factor = {
            -- Example = {
            --     GetLimitChange = function(playerID)
            --         return 10
            --     end
            -- }
        },
        --获取总上限
        GetTotalLimit = function(self, playerID)
            local limit = self.Base
            for _, factor in pairs(self.Factor) do
                limit = limit + factor.GetLimitChange(playerID)
            end
            return limit
        end
    },
    --减免来源
    Sources = {
        Campus = {
            --该来源的上限
            Limit = 50,
            --功能性文本提示
            Tooltip = 'LOC_EAGLE_POINT_REDUCTION_CAMPUS',
            GetModifier = function(self, playerID)
                --获取玩家
                local pPlayer = Players[playerID]
                if not pPlayer then return 0 end
                --获取区域
                local districts = pPlayer:GetDistricts()
                --获取圣塔克拉拉谷的数量
                local count = 0
                for _, district in districts:Members() do
                    if district:GetType() == campusIndex
                        and district:IsComplete() and (not district:IsPillaged())
                    then
                        count = count + 1
                    end
                end
                --获取点数减免
                local modifier = count * perCampus
                --获取点数减免上限
                local limit = self.Limit
                if limit ~= nil then modifier = math.min(modifier, limit) end
                --返回最终的减免
                return EagleCore.Round(modifier)
            end,
            GetTooltip = function(self, playerID)
                local modifier = -self:GetModifier(playerID)
                return modifier ~= 0 and Locale.Lookup(self.Tooltip, modifier) or ''
            end
        }
    }
}

--获取研究点数花费减免上限 (GamePlay, UI)
--这个函数是为了便于调用，实际上这个函数其实没必要
function EaglePointManager:GetReductionLimit(playerID)
    local limitManager = self.Reduction.Limit
    return limitManager:GetTotalLimit(playerID)
end

--获取研究点数减免 (GamePlay, UI)
function EaglePointManager:GetReduction(playerID)
    --获取玩家
    local pPlayer = Players[playerID]
    if not pPlayer then return 0 end
    --花费减免与上限
    local reduction, limit = 0, self:GetReductionLimit(playerID)
    --遍历来源
    local reductionSources = self.Reduction.Sources
    for _, source in pairs(reductionSources) do
        reduction = reduction + source:GetModifier(playerID)
    end
    --返回最终的减免
    return EagleCore.Round(math.min(reduction, limit))
end

--获取研究点数减免的tooltip (GamePlay, UI)
function EaglePointManager:GetReductionTooltip(playerID)
    local reductionTooltip = ''
    --遍历来源
    local reductionSources = self.Reduction.Sources
    for _, source in pairs(reductionSources) do
        reductionTooltip = reductionTooltip .. source:GetTooltip(playerID)
    end
    --返回tooltip
    return reductionTooltip
end

--||======================GamePlay========================||--

--设置研究点数 (GamePlay)
function EaglePointManager.SetEaglePoint(playerID, point)
    local pPlayer = Players[playerID]
    if not pPlayer then return end
    pPlayer:SetProperty(EaglePointKey, point)
end

--改变研究点数，返回新的研究点数 (GamePlay)
function EaglePointManager:ChangeEaglePoint(playerID, num)
    local newpoint = self.GetEaglePoint(playerID) + num
    self.SetEaglePoint(playerID, newpoint)
    return EagleCore.Floor(newpoint)
end

--||==========================UI==========================||--



--||=======================include========================||--
include('EagleUnionPoint_', true)
