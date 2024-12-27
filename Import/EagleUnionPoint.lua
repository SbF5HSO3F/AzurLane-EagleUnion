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

--||====================GamePlay, UI======================||--

--获取研究点数 (GamePlay, UI)
function EaglePointManager.GetEaglePoint(playerID, floor)
    local pPlayer = Players[playerID]
    if not pPlayer then return 0 end
    local points = pPlayer:GetProperty(EaglePointKey) or 0
    return floor and EagleCore.Floor(points) or points
end

EaglePointManager.Points = {
    --来自城市
    City = {
        Yield = {
            GetPointYield = function(playerID, cityID)
                --获取城市
                local pCity = CityManager.GetCity(playerID, cityID)
                if not pCity then return 0 end
                --获取各项产出
                local yield = pCity:GetYield(YieldTypes.SCIENCE)
                yield = yield + pCity:GetYield(YieldTypes.CULTURE)
                yield = yield + pCity:GetYield(YieldTypes.PRODUCTION)
                --百分比处理
                return EagleCore.Floor(yield * perYieldPercent)
            end
        }
    },
    --来自其他
    Extra = {
        SantaClara = {
            Tooltip = 'LOC_EAGLE_POINT_FROM_SANTA_CLARA',
            GetPointYield = function(playerID)
                --获取玩家
                local pPlayer = Players[playerID]
                if not pPlayer then return 0 end
                --获取区域
                local districts = pPlayer:GetDistricts()
                --获取圣塔克拉拉谷的数量
                local count = 0
                for _, district in districts:Members() do
                    if district:GetType() == SantaClaraValley
                        and district:IsComplete() and (not district:IsPillaged())
                    then
                        count = count + 1
                    end
                end
                --返回最终的点数
                return EagleCore.Floor(count * 10)
            end,
            GetTooltip = function(self, playerID)
                local yield = self.GetPointYield(playerID)
                return yield ~= 0 and Locale.Lookup(self.Tooltip, yield) or ''
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
