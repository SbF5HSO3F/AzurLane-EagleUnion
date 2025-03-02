-- EagleUnion_Core
-- Author: HSbF6HSO3F
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

--数字不小于其1位小数处理 (GamePlay, UI)
function EagleCore.Ceil(num)
    return math.ceil(num * 10) / 10
end

--数字不大于其1位小数处理 (GamePlay, UI)
function EagleCore.Floor(num)
    return math.floor(num * 10) / 10
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

--判断单元格是否可以放置指定单位 (GamePlay, UI)
function EagleCore.CanHaveUnit(plot, unitdef)
    if plot == nil then return false end
    local canHave = true
    for _, unit in ipairs(Units.GetUnitsInPlot(plot)) do
        if unit then
            local unitInfo = GameInfo.Units[unit:GetType()]
            if unitInfo then
                if unitInfo.IgnoreMoves == false then
                    if unitInfo.Domain == unitdef.Domain and unitInfo.FormationClass == unitdef.FormationClass then
                        canHave = false
                    end
                end
            end
        end
    end
    return canHave
end

--规范每回合价值显示 (GamePlay, UI)
function EagleCore.FormatValue(value)
    if value == 0 then
        return Locale.ToNumber(value)
    else
        return Locale.Lookup("{1: number +#,###.#;-#,###.#}", value)
    end
end

--数字百分比修正 (GamePlay, UI)
function EagleCore:ModifyByPercent(num, percent)
    return self.Round(num * (1 + percent / 100))
end

--获取玩家的区域数量 (GamePlay, UI)
function EagleCore.GetPlayerDistrictCount(playerID, index)
    local pPlayer, count = Players[playerID], 0
    if not pPlayer then return count end
    local districts = pPlayer:GetDistricts()
    for _, district in districts:Members() do
        if district:GetType() == index and district:IsComplete() and (not district:IsPillaged()) then
            count = count + 1
        end
    end
    return count
end

--检查单位是否是军事单位 (GamePlay, UI)
function EagleCore.IsMilitary(unit)
    if unit == nil then return false end
    local unitInfo = GameInfo.Units[unit:GetType()]
    if unitInfo == nil then return false end
    local unitFormation = unitInfo.FormationClass
    return unitFormation == 'FORMATION_CLASS_LAND_COMBAT'
        or unitFormation == 'FORMATION_CLASS_NAVAL'
        or unitFormation == 'FORMATION_CLASS_AIR'
end

--||=====================GamePlay=======================||--

--随机数生成器，范围为[1,num+1] (GamePlay)
function EagleCore.tableRandom(num)
    return Game.GetRandNum and (Game.GetRandNum(num) + 1) or 1
end

--对单位造成伤害，超出生命值则死亡并返回true。 (GamePlay)
function EagleCore.DamageUnit(unit, damage)
    local maxDamage = unit:GetMaxDamage()
    if (unit:GetDamage() + damage) >= maxDamage then
        unit:SetDamage(maxDamage)
        UnitManager.Kill(unit, false)
        return true
    else
        unit:ChangeDamage(damage)
        return false
    end
end

--||=========================UI=========================||--

--获取城市生产详细信息 (UI)
function EagleCore.GetProductionDetail(city)
    local details = { --城市生产详细信息
        --项目哈希值
        Hash       = 0,
        --城市是否进行生产
        Producting = false,
        --是否是建筑
        IsBuilding = false,
        --是否是奇观
        IsWonder   = false,
        --是否是区域
        IsDistrict = false,
        --是否是单位
        IsUnit     = false,
        --是否是项目
        IsProject  = false,
        --生产项目类型
        ItemType   = 'NONE',
        --生产项目名字
        ItemName   = 'NONE',
        --生产项目索引
        ItemIndex  = -1,
        --生产进度
        Progress   = 0,
        --生产成本
        TotalCost  = 0,
        --生产所需回合
        TurnsLeft  = 0
    }; if not city then return details end
    --获取城市生产队列，判断是否在生产
    local cityBuildQueue = city:GetBuildQueue()
    local productionHash = cityBuildQueue:GetCurrentProductionTypeHash()
    if productionHash ~= 0 then
        details.Hash       = productionHash
        details.Producting = true
        --建筑、区域、单位、项目
        local pBuildingDef = GameInfo.Buildings[productionHash]
        local pDistrictDef = GameInfo.Districts[productionHash]
        local pUnitDef     = GameInfo.Units[productionHash]
        local pProjectDef  = GameInfo.Projects[productionHash]
        --判断城市当前进行的生产
        if pBuildingDef ~= nil then
            --获取索引，方便后续获取进度和总成本
            local index = pBuildingDef.Index
            --城市正在生产建筑
            details.IsBuilding = true
            --城市生产的建筑是奇观还是普通建筑
            details.IsWonder = pBuildingDef.IsWonder
            --城市生产的建筑类型
            details.ItemType = pBuildingDef.BuildingType
            --城市生产的建筑名称
            details.ItemName = Locale.Lookup(pBuildingDef.Name)
            --城市生产的建筑索引
            details.ItemIndex = index
            --生产进度和总成本
            details.Progress = cityBuildQueue:GetBuildingProgress(index)
            details.TotalCost = cityBuildQueue:GetBuildingCost(index)
        elseif pDistrictDef ~= nil then
            --获取索引，方便后续获取进度和总成本
            local index = pDistrictDef.Index
            --城市正在生产区域
            details.IsDistrict = true
            --城市生产的区域类型
            details.ItemType = pDistrictDef.DistrictType
            --城市生产的区域名称
            details.ItemName = Locale.Lookup(pDistrictDef.Name)
            --城市生产的区域索引
            details.ItemIndex = index
            --生产进度和总成本
            details.Progress = cityBuildQueue:GetDistrictProgress(index)
            details.TotalCost = cityBuildQueue:GetDistrictCost(index)
        elseif pUnitDef ~= nil then
            --获取索引，方便后续获取进度和总成本
            local index = pUnitDef.Index
            --城市正在生产单位
            details.IsUnit = true
            --城市生产的单位类型
            details.ItemType = pUnitDef.UnitType
            --城市生产的单位名称
            details.ItemName = Locale.Lookup(pUnitDef.Name)
            --城市生产的单位索引
            details.ItemIndex = index
            --生产进度
            details.Progress = cityBuildQueue:GetUnitProgress(index)
            --获取当前单位的军事形式，计算总成本
            local formation = cityBuildQueue:GetCurrentProductionTypeModifier()
            --是标准
            if formation == MilitaryFormationTypes.STANDARD_FORMATION then
                details.TotalCost = cityBuildQueue:GetUnitCost(index)
                --是军团
            elseif formation == MilitaryFormationTypes.CORPS_FORMATION then
                details.TotalCost = cityBuildQueue:GetUnitCorpsCost(index)
                --更新单位名称
                if pUnitDef.Domain == 'DOMAIN_SEA' then
                    details.ItemName = details.ItemName .. " " .. Locale.Lookup("LOC_UNITFLAG_FLEET_SUFFIX")
                else
                    details.ItemName = details.ItemName .. " " .. Locale.Lookup("LOC_UNITFLAG_CORPS_SUFFIX")
                end
                --是军队
            elseif formation == MilitaryFormationTypes.ARMY_FORMATION then
                details.TotalCost = cityBuildQueue:GetUnitArmyCost(index)
                --更新单位名称
                if pUnitDef.Domain == 'DOMAIN_SEA' then
                    details.ItemName = details.ItemName .. " " .. Locale.Lookup("LOC_UNITFLAG_ARMADA_SUFFIX")
                else
                    details.ItemName = details.ItemName .. " " .. Locale.Lookup("LOC_UNITFLAG_ARMY_SUFFIX")
                end
            end
        elseif pProjectDef ~= nil then
            --获取索引，方便后续获取进度和总成本
            local index = pProjectDef.Index
            --城市正在生产项目
            details.IsProject = true
            --城市生产的项目类型
            details.ItemType = pProjectDef.ProjectType
            --城市生产的项目名称
            details.ItemName = Locale.Lookup(pProjectDef.Name)
            --城市生产的项目索引
            details.ItemIndex = index
            --生产进度和总成本
            details.Progress = cityBuildQueue:GetProjectProgress(index)
            details.TotalCost = cityBuildQueue:GetProjectCost(index)
        end
        --生产所需回合
        details.TurnsLeft = cityBuildQueue:GetTurnsLeft()
    end
    return details
end

--mouse enter the button (UI)
function EagleUnionEnter()
    UI.PlaySound("Main_Menu_Mouse_Over")
end

--||========================Test========================||--

--test function
function EagleCore:PrintTable(t, indent)
    indent = indent or 0
    for k, v in pairs(t) do
        if type(v) == "table" then
            print(string.rep(" ", indent) .. k .. ": {")
            self:PrintTable(v, indent + 4)
            print(string.rep(" ", indent) .. "}")
        else
            print(string.rep(" ", indent) .. k .. ": " .. tostring(v))
        end
    end
end
