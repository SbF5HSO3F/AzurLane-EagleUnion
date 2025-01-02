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
local IvyLeagueIndex = GameInfo.Districts['DISTRICT_IVY_LEAGUE'].Index
local perIvyLeagueReduction = 5
local perIvyLeagueModifier = 10
--星火之光
local gunStarPercent = 0.2

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
        -- Debug = {
        --     Tooltip = 'LOC_EAGLE_POINT_FROM_DEBUG',
        --     GetPointYield = function(playerID)
        --         return 10000
        --     end,
        --     GetTooltip = function(self, playerID)
        --         return Locale.Lookup(self.Tooltip, self.GetPointYield(playerID))
        --     end
        -- }
        GunStar = {
            Tooltip = 'LOC_EAGLE_POINT_FROM_SHOOTING_GUN_STAR',
            GetPointYield = function(playerID)
                local point = 0
                --是否是艾伦·萨姆纳
                if EagleCore.CheckLeaderMatched(playerID, 'LEADER_ALLEN_M_SUMNER_DD692') then
                    --获取玩家人口
                    local culture = Players[playerID]:GetCulture()
                    point = culture:GetCultureYield() * gunStarPercent
                end
                return EagleCore.Floor(point)
            end,
            GetTooltip = function(self, playerID)
                local point = self.GetPointYield(playerID)
                return point ~= 0 and Locale.Lookup(self.Tooltip, point) or ''
            end
        }
    },
    --百分比增益
    Modifier = {
        IvyLeague = {
            Tooltip = 'LOC_EAGLE_POINT_MODIFIER_IVY_LEAGUE',
            GetModifier = function(playerID)
                --获取数量
                local count = EagleCore.GetPlayerDistrictCount(playerID, IvyLeagueIndex)
                --获取点数减免
                local modifier = count * perIvyLeagueModifier
                return EagleCore.Round(modifier)
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

--获取每回合玩家城市产出的研究点数 (GamePlay, UI)
function EaglePointManager:GetPerTurnPointFromCities(playerID, floor)
    --获取玩家
    local pPlayer = Players[playerID]
    if not pPlayer then return 0 end
    local yieldPoint = 0
    --遍历城市
    local cities = pPlayer:GetCities()
    for _, city in cities:Members() do
        local cityID = city:GetID()
        local cityPoint = self:GetCityYieldPoint(playerID, cityID)
        yieldPoint = yieldPoint + cityPoint
    end
    --返回最终的点数
    return floor and EagleCore.Floor(yieldPoint) or yieldPoint
end

--获取每回合玩家城市产出的研究点数的tooltip (GamePlay, UI)
function EaglePointManager:GetPerTurnPointFromCitiesTooltip(playerID)
    local citiesTooltip = ''
    --获取玩家
    local pPlayer = Players[playerID]
    if not pPlayer then return '' end
    --获取每个城市的tooltip和城市产出的研究点数
    local cityTooltip, yieldPoint = '', 0
    local cities = pPlayer:GetCities()
    for _, city in cities:Members() do
        local cityID = city:GetID()
        --获取城市产出的研究点数
        local cityPoint = self:GetCityYieldPoint(playerID, cityID)
        yieldPoint = yieldPoint + self:GetCityYieldPoint(playerID, cityID)
        if cityPoint ~= 0 then
            --获取城市名称
            local cityName = city:GetName()
            --设置tooltip
            cityTooltip = cityTooltip ..
                Locale.Lookup('LOC_EAGLE_POINT_FROM_CITY', cityPoint, cityName)
        end
    end
    yieldPoint = EagleCore.Floor(yieldPoint)
    --来自城市的tooltip
    if cityTooltip ~= '' then
        citiesTooltip = Locale.Lookup('LOC_EAGLE_POINT_FROM_CITIES', yieldPoint) .. cityTooltip
    end
    return citiesTooltip
end

--获取每回合玩家其他来源的研究点数 (GamePlay, UI)
function EaglePointManager:GetPerTurnPointFromExtra(playerID, floor)
    --获取玩家
    local pPlayer = Players[playerID]
    if not pPlayer then return 0 end
    local yieldPoint = 0
    local extra = self.Points.Extra
    --来自其他
    for _, source in pairs(extra) do
        yieldPoint = yieldPoint + source.GetPointYield(playerID)
    end
    return floor and EagleCore.Floor(yieldPoint) or yieldPoint
end

--获取每回合玩家其他来源的研究点数的tooltip (GamePlay, UI)
function EaglePointManager:GetPerTurnPointFromExtraTooltip(playerID)
    local extraTooltip = ''
    --获取玩家
    local pPlayer = Players[playerID]
    if not pPlayer then return '' end
    --获取每个来源的tooltip和来源的研究点数
    local extra = self.Points.Extra
    for _, source in pairs(extra) do
        extraTooltip = extraTooltip .. source:GetTooltip(playerID)
    end
    --返回tooltip
    return extraTooltip
end

--获取每回合获得的研究点数，无增益 (GamePlay, UI)
function EaglePointManager:GetPerTurnPointWithoutModifier(playerID, floor)
    --来自城市
    local perTurnPoint = self:GetPerTurnPointFromCities(playerID)
    --来自其他
    perTurnPoint = perTurnPoint + self:GetPerTurnPointFromExtra(playerID)
    --返回最终的点数
    return floor and EagleCore.Floor(perTurnPoint) or perTurnPoint
end

--获取获得的研究点数增益 (GamePlay, UI)
function EaglePointManager:GetPointModifier(playerID)
    local modifier = 0
    --遍历来源
    local moddifier = self.Points.Modifier
    for _, source in pairs(moddifier) do
        modifier = modifier + source.GetModifier(playerID)
    end
    return modifier
end

--获取每回合获得的额外增益研究点数 (GamePlay, UI)
function EaglePointManager:GetPerTurnPointWithModifier(playerID, floor)
    local perTurnPoint = self:GetPerTurnPointWithoutModifier(playerID)
    --获取点数增益
    local modifier = self:GetPointModifier(playerID)
    --点数增益处理
    local percentPoint = perTurnPoint * modifier / 100
    return floor and EagleCore.Floor(percentPoint) or percentPoint
end

--获取获得的研究点数增益的tooltip (GamePlay, UI)
function EaglePointManager:GetPointModifierTooltip(playerID)
    local modifierTooltip = ''
    --遍历来源
    local Modifier = self.Points.Modifier
    local detailTooltip = ''
    for _, source in pairs(Modifier) do
        detailTooltip = detailTooltip .. source:GetTooltip(playerID)
    end
    if detailTooltip ~= '' then
        local modifierPoint = self:GetPerTurnPointWithModifier(playerID, true)
        local modifier = self:GetPointModifier(playerID)
        modifierTooltip = Locale.Lookup('LOC_EAGLE_POINT_FROM_MODIFIER', modifier, modifierPoint)
            .. detailTooltip
    end
    --返回tooltip
    return modifierTooltip
end

--获取每回合获得的研究点数 (GamePlay, UI)
function EaglePointManager:GetPerTurnPoint(playerID, floor)
    --无增益
    local perTurnPoint = self:GetPerTurnPointWithModifier(playerID)
    --有增益
    local percentPoint = self:GetPerTurnPointWithoutModifier(playerID)
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
    local perTurnPoint = self:GetPerTurnPoint(playerID, true)
    perTurnPointTooltip = Locale.Lookup('LOC_EAGLE_POINT_PER_TURN', perTurnPoint)
    --来自城市的tooltip
    local citiesTooltip = self:GetPerTurnPointFromCitiesTooltip(playerID)
    --来自其他的tooltip
    local extraTooltip = self:GetPerTurnPointFromExtraTooltip(playerID)
    --来自点数增益的tooltip
    local modifierTooltip = self:GetPointModifierTooltip(playerID)
    --合并tooltip
    local totalTooltip = citiesTooltip .. extraTooltip .. modifierTooltip
    if totalTooltip ~= '' then
        perTurnPointTooltip = perTurnPointTooltip .. '[NEWLINE]' .. totalTooltip
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
        IvyLeague = {
            --该来源的上限
            --Limit = 50,
            --功能性文本提示
            Tooltip = 'LOC_EAGLE_POINT_REDUCTION_IVY_LEAGUE',
            GetModifier = function(self, playerID)
                --获取数量
                local count = EagleCore.GetPlayerDistrictCount(playerID, IvyLeagueIndex)
                --获取点数减免
                local modifier = count * perIvyLeagueReduction
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
