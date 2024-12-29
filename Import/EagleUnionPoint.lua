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

--获取每回合获得的研究点数 (GamePlay, UI)
function EaglePointManager:GetPerTurnPoint(playerID, floor)
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
    --返回最终的点数
    return floor and EagleCore.Floor(perTurnPoint) or perTurnPoint
end

--获取每回合获得的研究点数的tooltip (GamePlay, UI)
function EaglePointManager:GetPerTurnPointTooltip(playerID)
    local perTurnPointTooltip = ''
    --获取玩家
    local pPlayer = Players[playerID]
    if not pPlayer then return '' end
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
    if citiesPoint ~= 0 then
        perTurnPointTooltip = perTurnPointTooltip ..
            Locale.Lookup('LOC_EAGLE_POINT_FROM_CITIES', citiesPoint) .. citiesTooltip
    end
    --来自其他
    local extra = self.Points.Extra
    for _, source in pairs(extra) do
        perTurnPointTooltip = perTurnPointTooltip .. source:GetTooltip(playerID)
    end
    --返回tooltip
    return perTurnPointTooltip
end

--研究点数花费减免
EaglePointManager.Reduction = {
    --上限
    Limit = 50,
    --减免来源
    Sources = {
        Campus = {
            Tooltip = 'LOC_EAGLE_POINT_REDUCTION_CAMPUS',
            GetModifier = function(playerID)
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
                --返回最终的减免
                return EagleCore.Floor(count * perCampus)
            end,
            GetTooltip = function(self, playerID)
                local modifier = -self.GetModifier(playerID)
                return modifier ~= 0 and Locale.Lookup(self.Tooltip, modifier) or ''
            end
        }
    }
}

--获取研究点数花费减免上限 (GamePlay, UI)
function EaglePointManager:GetReductionLimit()
    return self.Reduction.Limit
end

--获取研究点数减免 (GamePlay, UI)
function EaglePointManager:GetReduction(playerID)
    --获取玩家
    local pPlayer = Players[playerID]
    if not pPlayer then return 0 end
    --花费减免与上限
    local reduction, limit = 0, self.Reduction.Limit
    --遍历来源
    local reductionSources = self.Reduction.Sources
    for _, source in pairs(reductionSources) do
        reduction = reduction + source.GetModifier(playerID)
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
