-- AzurDLLDiplomaticAction_NewJersey
-- Author: HSbF6HSO3F
-- DateCreated: 2025/8/12 17:29:44
--------------------------------------------------------------
--||=======================include========================||--
include('EagleCore')

--||===================local variables====================||--

local Liberation = GameInfo.Wars['LIBERATION_WAR'].Index                                      -- 解放战争
local Reconquest = GameInfo.Wars['RECONQUEST_WAR'].Index                                      -- 收复战争
local DefenseMin = GameInfo.Wars['PROTECTORATE_WAR'].Index                                    -- 保卫城邦战争

local LiberationCB = GameInfo.DiplomaticActions['DIPLOACTION_DECLARE_LIBERATION_WAR'].Index   -- 宣布解放战争
local ReconquestCB = GameInfo.DiplomaticActions['DIPLOACTION_DECLARE_RECONQUEST_WAR'].Index   -- 宣布收复战争
local DefenseMinCB = GameInfo.DiplomaticActions['DIPLOACTION_DECLARE_PROTECTORATE_WAR'].Index -- 宣布保卫城邦战争

--||=================GameEvents functions=================||--

-- New Jersey Can Declare War on Liberation, Reconquest and Defense of the City-State
function NewJerseyFreeCanDeclareWar(player, target, warType, oldresult)
    if EagleCore.CheckLeaderMatched(player, 'LEADER_NEW_JERSEY_BB62') and
        (warType == Liberation or warType == Reconquest or warType == DefenseMin) then
        -- 获取玩家外交
        -- local diplomacy = Players[player]:GetDiplomacy()
        -- if not diplomacy:IsAtWarWith(target) then return true end
        -- if diplomacy:HasDeclaredFriendship(target) then return false end
        return true
    end
end

-- New Jersey Free Liberation, Reconquest and Defense of the City-State Casus Belli
function NewJerseyFreeWarCasusBelli(player, target, actionType, oldresult)
    -- 是新泽西，且外交行动为宣布解放战争、收复战争或保卫城邦战争
    if EagleCore.CheckLeaderMatched(player, 'LEADER_NEW_JERSEY_BB62') and
        (actionType == LiberationCB or actionType == ReconquestCB or actionType == DefenseMinCB) then
        -- 获取玩家外交
        -- local diplomacy = Players[player]:GetDiplomacy()
        -- if not diplomacy:IsAtWarWith(target) then return true end
        -- if diplomacy:HasDeclaredFriendship(target) then return false end
        return true
    end
end

AzurDLLDiplomacy:AddLeaderWarsTrait(NewJerseyFreeCanDeclareWar)
AzurDLLDiplomacy:AddLeaderActionsTrait(NewJerseyFreeWarCasusBelli)
