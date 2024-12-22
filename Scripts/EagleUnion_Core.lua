-- EagleUnion_Core
-- Author: jjj
-- DateCreated: 2024/1/2 19:17:02
--------------------------------------------------------------

EagleCore = {}

--||====================GamePlay, UI======================||--

--判断领袖，玩家不为指定领袖类型则返回false (GamePlay, UI)
function EagleCore.CheckLeaderMatched(playerID, leaderType)
    local pPlayerConfig = playerID and PlayerConfigurations[playerID]
    return pPlayerConfig and pPlayerConfig:GetLeaderTypeName() == leaderType
end

--判断文明，玩家文明不为指定文明类型则返回false (GamePlay, UI)
function EagleCore.CheckCivMatched(playerID, civilizationType)
    local pPlayerConfig = playerID and PlayerConfigurations[playerID]
    return pPlayerConfig and pPlayerConfig:GetCivilizationTypeName() == civilizationType
end

--数字四舍五入处理 (GamePlay, UI)
function EagleCore.Round(num)
    return math.floor((num + 0.05) * 10) / 10
end

--将输入的数字按照当前游戏速度进行修正 (GamePlay, UI)
function EagleCore:ModifyBySpeed(num)
    local gameSpeed = GameInfo.GameSpeeds[GameConfiguration.GetGameSpeedType()]
    if gameSpeed then num = self.Round(num * gameSpeed.CostMultiplier / 100) end
    return num
end

--检查科技或者市政是否拥有提升 (GamePlay, UI)
function EagleCore.HasBoost(techOrCivic)
    for boost in GameInfo.Boosts() do
        if techOrCivic == boost.TechnologyType or techOrCivic == boost.CivicType then
            return true
        end
    end
    return false
end

--||=====================GamePlay=======================||--

--随机数生成器，范围为[1,num+1] (GamePlay)
function EagleCore.tableRandom(num)
    return Game.GetRandNum and (Game.GetRandNum(num) + 1) or 1
end

--||=========================UI=========================||--

--mouse enter the button (UI)
function EagleUnionEnter()
    UI.PlaySound("Main_Menu_Mouse_Over")
end
