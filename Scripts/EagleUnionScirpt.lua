-- EagleUnion_Scirpt
-- Author: HSbF6HSO3F
-- DateCreated: 2024/9/28 15:21:49
--------------------------------------------------------------
--||=======================include========================||--
include('EagleUnionCore')
include('EagleUnionPoint')

--||===================local variables====================||--

local modifier = 'EAGLE_UNION_PER_ACTIVE_GREATPERSON_BUFF'

--||====================ExposedMembers====================||--

ExposedMembers.EagleUnion = ExposedMembers.EagleUnion or {}

ExposedMembers.EagleUnion = {
    GetBuildQueue = function(playerID, cityID)
        local city = CityManager.GetCity(playerID, cityID)
        return city:GetBuildQueue()
    end,
    GetMultiplierUsable = function(self, playerID, cityID)
        local buildQueue = self.GetBuildQueue(playerID, cityID)
        return type(buildQueue.GetSalvageProgress) == 'function'
    end,
    GetBuildingMultiplier = function(self, playerID, cityID, index)
        local buildQueue = self.GetBuildQueue(playerID, cityID)
        return buildQueue:GetBuildingProductionMultiplier(index)
    end,
    GetDistrictMultiplier = function(self, playerID, cityID, index)
        local buildQueue = self.GetBuildQueue(playerID, cityID)
        return buildQueue:GetDistrictProductionMultiplier(index)
    end,
    GetUnitMultiplier = function(self, playerID, cityID, index)
        local buildQueue = self.GetBuildQueue(playerID, cityID)
        return buildQueue:GetUnitProductionMultiplier(index)
    end,
    GetProjectMultiplier = function(self, playerID, cityID, index)
        local buildQueue = self.GetBuildQueue(playerID, cityID)
        return buildQueue:GetProjectProductionMultiplier(index)
    end,
    GetSalvageProgress = function(self, playerID, cityID)
        local buildQueue = self.GetBuildQueue(playerID, cityID)
        return buildQueue:GetSalvageProgress()
    end
}

--||===================Events functions===================||--

--when a great person is activated
function EagleUnionActiveGreatPerson(playerID)
    --check the player civilization
    if EagleCore.CheckCivMatched(playerID, 'CIVILIZATION_EAGLE_UNION') then
        --attach the modifier to the player
        Players[playerID]:AttachModifierByID(modifier)
    end
end

function EagleUnionTurnStart(playerID, isFirst)
    if isFirst and EagleCore.CheckCivMatched(playerID, 'CIVILIZATION_EAGLE_UNION') then
        --get the per turn point
        local perpoint = EaglePointManager:GetPerTurnPoint(playerID)
        EaglePointManager:GetPerTurnPointTooltip(playerID)
        --add the per turn point to the player
        EaglePointManager:ChangeEaglePoint(playerID, perpoint)
    end
end

--||=================GameEvents functions=================||--

function EagleUnionPointUnlockAll(playerID, param)
    --get the player
    local player = Players[playerID]
    if not player then return end
    --cost the point
    EaglePointManager:ChangeEaglePoint(playerID, -param.Cost)
    --the tech
    local playerTechs = player:GetTechs()
    for index, _ in pairs(param.Techs) do
        playerTechs:SetResearchProgress(index, playerTechs:GetResearchCost(index))
    end
    --the civic
    local playerCulture = player:GetCulture()
    for index, _ in pairs(param.Civics) do
        playerCulture:SetCulturalProgress(index, playerCulture:GetCultureCost(index))
    end
    --the cites
    for index, value in pairs(param.Cities) do
        --get the city
        local city = CityManager.GetCity(playerID, index)
        if city then
            city:GetBuildQueue():AddProgress(value)
        end
    end
end

--||======================initialize======================||--

--Initialize
function Initialize()
    Events.PlayerTurnActivated.Add(EagleUnionTurnStart)
    -------------------Events-------------------
    Events.UnitGreatPersonActivated.Add(EagleUnionActiveGreatPerson)
    -----------------GameEvents-----------------
    GameEvents.EagleUnionPointUnlock.Add(EagleUnionPointUnlockAll)
    --------------------------------------------
    print('Initial success!')
end

include('EagleUnionScirpt_', true)

Initialize()
