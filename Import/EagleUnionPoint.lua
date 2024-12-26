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

local perPopEaglePoint = 0.5
local SantaClaraValley = GameInfo.Districts['DISTRICT_SANTA_CLARA_VALLEY'].Index

--||====================GamePlay, UI======================||--

--获取研究点数 (GamePlay, UI)
function EaglePointManager.GetEaglePoint(playerID)
    local pPlayer = Players[playerID]
    if not pPlayer then return 0 end
    return pPlayer:GetProperty(EaglePointKey) or 0
end

EaglePointManager.Points = {
    --来自城市
    City = {
        Population = {
            GetPointYield = function(playerID, cityID)
                --获取城市
                local pCity = CityManager.GetCity(playerID, cityID)
                if not pCity then return 0 end
                --获取人口
                local pop = pCity:GetPopulation()
                --计算研究点数
                return EagleCore.Round(pop * perPopEaglePoint)
            end
        }
    },
    --来自其他
    Extra = {
        SantaClara = {

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
function EaglePointManager:GetPerTurnPoint(playerID)
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
    return perTurnPoint
end

--||======================GamePlay========================||--

--设置研究点数，返回新的研究点数 (GamePlay)
function EaglePointManager.SetEaglePoint(playerID, point)
    local pPlayer = Players[playerID]
    if not pPlayer then return end
    pPlayer:SetProperty(EaglePointKey, point)
    return point
end

--改变研究点数，返回新的研究点数 (GamePlay)
function EaglePointManager:ChangeEaglePoint(playerID, num)
    local newpoint = self.GetEaglePoint(playerID) + num
    self.SetEaglePoint(playerID, newpoint)
    return newpoint
end

--||==========================UI==========================||--


--获取每回合获得的研究点数的tooltip (UI)
function EaglePointManager:GetPerTurnPointTooltip(playerID)
    local perTurnPointTooltip = ''
    --获取玩家
    local pPlayer = Players[playerID]
    if not pPlayer then return '' end
    --来自城市
    local cities = pPlayer:GetCities()
    for _, city in cities:Members() do
        local cityID = city:GetID()
        local cityPoint = self:GetCityYieldPoint(playerID, cityID)
        if cityPoint ~= 0 then
            local cityName = city:GetName()
            perTurnPointTooltip = perTurnPointTooltip ..
                Locale.Lookup('LOC_EAGLE_POINT_FROM_CITY', cityPoint, cityName)
        end
    end
    --来自其他

    --返回tooltip
    return perTurnPointTooltip
end

--||=======================include========================||--
include('EagleUnionPoint_', true)
