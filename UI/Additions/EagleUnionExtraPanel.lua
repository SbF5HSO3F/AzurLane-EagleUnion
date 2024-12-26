-- EagleUnion_ExtraPanel
-- Author: HSbF6HSO3F
-- DateCreated: 2024/12/26 8:27:59
--------------------------------------------------------------
--||=======================include========================||--
include('InstanceManager')
include('TechAndCivicSupport')
include('AnimSidePanelSupport')
include('ToolTipHelper')
include('EagleUnionCore')

--||=======================Constants======================||--

local SIZE_ICON_SMALL = 38

--||====================loacl variables===================||--

local Utils = ExposedMembers.EagleUnion

--||====================base functions====================||--

--获取科技、市政和城市生产的数据
function GetData()
    --设置Data表
    local data = { Techs = {}, Civics = {}, Cities = {} }
    --获取玩家
    local loaclId = Game.GetLocalPlayer()
    local player = Players[loaclId]
    if not player then return data end
    --简单的自定义函数，获取成本与进度之差
    local function GetNeed(table)
        return table.Cost - table.Progress
    end
    --获取科技数据
    local techs = player:GetTechs()
    for row in GameInfo.Technologies() do
        if (not techs:HasCivic(row.Index)) or row.Repeatable == true then
            local index = row.Index
            --设置科技表
            local techDetail = {
                Index = index,
                CanTrigger = false,
                HasTrigger = false,
                Cost = techs:GetResearchCost(index),
                Progress = techs:GetResearchProgress(index),
                Need = 0
            }; techDetail.Need = GetNeed(techDetail)
            --设置提升
            local techType = row.TechnologyType
            for boost in GameInfo.Boosts() do
                --获取科技是否可以触发提升
                if techType == boost.TechnologyType then
                    techDetail.CanTrigger = true
                    --获取科技是否触发过提升
                    if techs:HasBoostBeenTriggered(index) then
                        techDetail.HasTrigger = true
                    end
                    break
                end
            end
            --添加科技数据
            table.insert(data.Techs, techDetail)
        end
    end
    --获取市政数据
    local civics = player:GetCulture()
    for row in GameInfo.Civics() do
        if (not civics:HasTech(row.Index)) or row.Repeatable == true then
            local index = row.Index
            --设置市政表
            local civicDetail = {
                Index = index,
                CanTrigger = false,
                HasTrigger = false,
                Cost = civics:GetCultureCost(index),
                Progress = civics:GetCulturalProgress(index),
                Need = 0
            }; civicDetail.Need = GetNeed(civicDetail)
            --设置提升
            local civicType = row.CivicType
            for boost in GameInfo.Boosts() do
                --获取市政是否可以触发提升
                if civicType == boost.CivicType then
                    civicDetail.CanTrigger = true
                    --获取市政是否触发过提升
                    if civics:HasBoostBeenTriggered(index) then
                        civicDetail.HasTrigger = true
                    end
                    break
                end
            end
            --添加市政数据
            table.insert(data.Civics, civicDetail)
        end
    end
    --获取城市生产数据
    local cities = player:GetCities()
    for _, city in cities:Members() do
        --获取城市生产细节
        local cityData = EagleCore.GetProductionDetail(city)
        --计算所需生产力
        if cityData.Producting then
            --获取城市ID，设置细节表
            local cityID = city:GetID()
            local cityDetail = {}
            --添加城市生产数据
            cityDetail.ID = cityID
            cityDetail.Cost = cityData.TotalCost
            cityDetail.Progress = cityData.Progress
            cityDetail.Need = GetNeed(cityDetail)
            --获取城市溢出生产力可用
            if Utils:GetMultiplierUsable(loaclId, cityID) then
                --获取生产力倍率
                local multiplier = 1
                if cityData.IsBuilding then
                    multiplier = Utils:GetBuildingMultiplier(loaclId, cityID, cityData.ItemIndex)
                elseif cityData.IsDistrict then
                    multiplier = Utils:GetDistrictMultiplier(loaclId, cityID, cityData.ItemIndex)
                elseif cityData.IsUnit then
                    multiplier = Utils:GetUnitMultiplier(loaclId, cityID, cityData.ItemIndex)
                elseif cityData.IsProject then
                    multiplier = Utils:GetProjectMultiplier(loaclId, cityID, cityData.ItemIndex)
                end
                --获取城市溢出生产力
                local salvage = Utils:GetSalvageProgress(loaclId, cityID)
                --重新计算所需生产力
                cityDetail.Need = math.ceil((cityDetail.Need / multiplier) - salvage)
            end
            --添加城市生产细节
            table.insert(data.Cities, cityDetail)
        end
    end
    --排序科技、市政、城市生产数据
    table.sort(data.Techs, function(a, b) return a.Need < b.Need end)
    table.sort(data.Civics, function(a, b) return a.Need < b.Need end)
    table.sort(data.Cities, function(a, b) return a.Need < b.Need end)
    --返回数据
    return data
end

include('EagleUnionExtraPanel_', true)
