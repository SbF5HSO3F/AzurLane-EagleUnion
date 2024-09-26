-- EagleUnion_Core
-- Author: jjj
-- DateCreated: 2024/1/2 19:17:02
--------------------------------------------------------------
--||====================GamePlay, UI======================||--

--Leader type judgment. if macth, return true (GamePlay, UI)
function EagleUnionLeaderTypeMatched(playerID, LeaderTpye)
    local pPlayerConfig = playerID and PlayerConfigurations[playerID]
    return pPlayerConfig and pPlayerConfig:GetLeaderTypeName() == LeaderTpye
end

--process rounding (GamePlay, UI)
function EagleUnionNumRound(num)
    return math.floor((num + 0.05) * 10) / 10
end

--Game Speed Modifier (GamePlay, UI)
function EagleUnionSpeedModifier(num)
    local gameSpeed = GameInfo.GameSpeeds[GameConfiguration.GetGameSpeedType()]
    if gameSpeed then
        num = EagleUnionNumRound(num * gameSpeed.CostMultiplier / 100)
    end
    return num
end

--Random number generator [1,num+1] (GamePlay, UI)
function EagleUnionGetRandNum(num)
    return Game.GetRandNum and (Game.GetRandNum(num) + 1) or 1
end
