-- EagleMath
-- Author: HSbF6HSO3F
-- DateCreated: 2025/7/21 10:20:34
--------------------------------------------------------------
--||======================MetaTable=======================||--

-- EagleMath 用于数学相关的处理
EagleMath = {}

--||====================Based functions===================||--

--数字不小于其1位小数处理 (GamePlay, UI)
function EagleMath.Ceil(num, dot)
    if dot == true then
        return math.ceil(num)
    else
        if type(dot) ~= 'number' then dot = 1 end
        dot = math.pow(10, dot)
        dot = math.max(dot, 1)
        return math.ceil(num * dot) / dot
    end
end

--数字不大于其1位小数处理 (GamePlay, UI)
function EagleMath.Floor(num, dot)
    if dot == true then
        return math.floor(num)
    else
        if type(dot) ~= 'number' then dot = 1 end
        dot = math.pow(10, dot)
        dot = math.max(dot, 1)
        return math.floor(num * dot) / dot
    end
end

-- 数字四舍五入 (GamePlay, UI)
function EagleMath.Round(num, dot)
    if dot == true then
        return math.floor(num + 0.5)
    else
        if type(dot) ~= 'number' then dot = 1 end
        dot = math.pow(10, dot)
        dot = math.max(dot, 1)
        return math.floor((num * dot + 0.5)) / dot
    end
end

--||====================Modify functions==================||--

-- 将输入的数字按照百分比进行修正 (GamePlay, UI)
function EagleMath:ModifyByPercent(num, percent, effect)
    return self.Round(num * (effect and percent or (100 + percent)) / 100)
end

-- 将输入的数字按照当前游戏速度进行修正 (GamePlay, UI)
function EagleMath:ModifyBySpeed(num)
    local gameSpeed = GameInfo.GameSpeeds[GameConfiguration.GetGameSpeedType()]
    if gameSpeed then num = self.Round(num * gameSpeed.CostMultiplier / 100) end
    return num
end

--||====================Random functions==================||--

-- 随机数生成器，范围为[1,num] (GamePlay)
function EagleMath.GetRandNum(num)
    return Game.GetRandNum and (Game.GetRandNum(num) + 1) or 1
end

-- 随机数生成器，范围为[x,y] (GamePlay)
function EagleMath:GetRandom(x, y)
    y = math.max(x, y)
    if x == y then return x end
    local a = x - 1
    local n = y - a
    return self.GetRandNum(n) + a
end

-- 概率检查 (GamePlay)
function EagleMath:CheckProbability(percent)
    local random = self.GetRandNum(100)
    return random <= percent
end

--||=======================include========================||--
include('EagleMath_', true)
