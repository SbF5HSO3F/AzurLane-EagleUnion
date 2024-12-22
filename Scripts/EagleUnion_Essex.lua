-- EagleUnion_Essex
-- Author: jjj
-- DateCreated: 2023/10/31 21:28:55
--------------------------------------------------------------
--||=======================include========================||--
include('EagleUnion_Core.lua')

--||===================local variables====================||--

local percent   = 0.4
local key       = 'EssexGrantCulture'
local corpsType = MilitaryFormationTypes.CORPS_FORMATION
local armyType  = MilitaryFormationTypes.ARMY_FORMATION

--||===================Events functions===================||--

--when city production a unit
function EssexUnitAddedToMap(playerID, unitID)
    --is Essex?
    if not EagleCore.CheckLeaderMatched(playerID, 'LEADER_ESSEX_CV9') then
        return
    end
    --get the unit
    local pUnit = UnitManager.GetUnit(playerID, unitID)
    --get unit information
    local unitInfo = GameInfo.Units[pUnit:GetType()]
    --if unit is Naval
    if unitInfo and unitInfo.FormationClass == 'FORMATION_CLASS_NAVAL' then
        --get the mulitplier
        local multiplier, military = 1, pUnit:GetMilitaryFormation()
        if military == corpsType then
            multiplier = 2
        elseif military == armyType then
            multiplier = 3
        end
        --get the culture which gained
        local reward = EagleCore:ModifyBySpeed(unitInfo.Cost * multiplier * percent)
        --get the player
        local pPlayer = Players[playerID]
        --set the property
        pPlayer:SetProperty(key, reward)
    end
end

--Production Navy Get Culture
function EssexCityProductionNavyComplete(playerID, cityID, iConstructionType, itemID)
    --is Essex?
    if not EagleCore.CheckLeaderMatched(playerID, 'LEADER_ESSEX_CV9') then
        return
    end

    --if construction is Unit
    if iConstructionType == 0 then
        --get the player
        local pPlayer = Players[playerID]
        --get the reward
        local reward = pPlayer:GetProperty(key) or 0
        --if reward is not nil
        if reward == 0 then return end
        --add the culture
        pPlayer:GetCulture():ChangeCurrentCulturalProgress(reward)
    end
end

--||======================initialize======================||--

--initialization function
function Initialize()
    -----------------Events-----------------
    Events.UnitAddedToMap.Add(EssexUnitAddedToMap)
    Events.CityProductionCompleted.Add(EssexCityProductionNavyComplete)
    ----------------------------------------
    print('Initial success!')
end

Initialize()
