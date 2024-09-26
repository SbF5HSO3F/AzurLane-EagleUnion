-- EagleUnion_Essex
-- Author: jjj
-- DateCreated: 2023/10/31 21:28:55
--------------------------------------------------------------
--||=======================include========================||--
include('EagleUnion_Core.lua')

--||===================Events functions===================||--

--Production Navy Get Culture
function EssexCityProductionNavyComplete(playerID, cityID, iConstructionType, itemID)
    --is Essex?
    if not EagleUnionLeaderTypeMatched(playerID, 'LEADER_ESSEX_CV9') then
        return
    end

    --if construction is Unit
    if iConstructionType == 0 then
        --get unit information
        local unitInfo = GameInfo.Units[itemID]
        if unitInfo and unitInfo.FormationClass == 'FORMATION_CLASS_NAVAL' then
            --get culture which gained
            local baseNum = EagleUnionSpeedModifier(unitInfo.Cost * 0.4)
            local pPlayer = Players[playerID]
            --Add the culture
            pPlayer:GetCulture():ChangeCurrentCulturalProgress(baseNum)
        end
    end
end

--||======================initialize======================||--

--initialization function
function Initialize()
    -----------------Events-----------------
    Events.CityProductionCompleted.Add(EssexCityProductionNavyComplete)
    ----------------------------------------
    print('EagleUnion_Essex Initial success!')
end

Initialize()
