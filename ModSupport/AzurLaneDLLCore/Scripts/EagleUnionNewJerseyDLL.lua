-- EagleUnionNewJerseyDLL
-- Author: HSbF6HSO3F
-- DateCreated: 2025/8/11 16:52:59
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
function NewJerseyFreeCanDeclareWar(initiatorPlayerType, targetPlayerType, warType, oldresult)
    if EagleCore.CheckLeaderMatched(initiatorPlayerType, 'LEADER_NEW_JERSEY_BB62') and
        (warType == Liberation or warType == Reconquest or warType == DefenseMin) then
        return true
    else
        return oldresult
    end
end

-- New Jersey Free Liberation, Reconquest and Defense of the City-State Casus Belli
function NewJerseyFreeWarCasusBelli(initiatorPlayerType, targetPlayerType, diplomaticActionType, oldresult)
    -- 是新泽西，且外交行动为宣布解放战争、收复战争或保卫城邦战争
    if EagleCore.CheckLeaderMatched(initiatorPlayerType, 'LEADER_NEW_JERSEY_BB62') and
        (diplomaticActionType == LiberationCB or diplomaticActionType == ReconquestCB or diplomaticActionType == DefenseMinCB) then
        print('New Jersey ' .. diplomaticActionType .. ' is Vaild')
        return true
    else
        return oldresult
    end
end

--||======================initialize======================||--

--Initialize
function Initialize()
    -----------------GameEvents-----------------
    GameEvents.ALCanDeclareWarOn.Add(NewJerseyFreeCanDeclareWar)
    GameEvents.ALIsDiplomaticActionValid.Add(NewJerseyFreeWarCasusBelli)
    print('LiberationCB: ' .. LiberationCB)
    print('ReconquestCB: ' .. ReconquestCB)
    print('DefenseMinCB: ' .. DefenseMinCB)
    --------------------------------------------
    print('Initial success!')
end

include('EagleUnionNewJerseyDLL_', true)

Initialize()
