-- EagleUnion_ExtraPanel
-- Author: HSbF6HSO3F
-- DateCreated: 2024/12/26 8:27:59
--------------------------------------------------------------
--||=======================include========================||--
include('InstanceManager')
include('TechAndCivicSupport')
include('AnimSidePanelSupport')
include('ToolTipHelper')
include("PortraitSupport")

include('EagleUnionCore')
include('EagleUnionPoint')

--||=======================Constants======================||--

SIZE_ICON_SMALL        = 30
SIZE_ICON_MEDIUM       = 38

--||====================loacl variables===================||--

local Utils            = ExposedMembers.EagleUnion

local m_kSlideAnimator = {}
local m_PanelIsOpen    = false
local m_TechsListIM    = InstanceManager:new("TechSlot", "ButtonContainer", Controls.TechsStack)
local m_SelectedTechs  = {}
local m_CivicsListIM   = InstanceManager:new("CivicSlot", "ButtonContainer", Controls.CivicsStack)
local m_SelectedCivics = {}
local m_CitiesListIM   = InstanceManager:new("CitySlot", "ButtonContainer", Controls.CitiesStack)
local m_SelectedCities = {}
local m_chooseTechs    = true
local m_chooseCivics   = false
local m_chooseCities   = false

--||====================base functions====================||--

--获取单位的头像
function GetUnitIcons(playerID, unitDef)
    local prefix             = GetUnitPortraitPrefix(playerID) .. unitDef.UnitType;
    local suffix             = GetUnitPortraitEraSuffix(playerID)
    --定义图标
    local iconName           = prefix .. suffix;
    local prefixOnlyIconName = prefix .. "_PORTRAIT";
    local eraOnlyIconName    = "ICON_" .. unitDef.UnitType .. suffix;
    local fallbackIconName   = "ICON_" .. unitDef.UnitType .. "_PORTRAIT";

    return { iconName, prefixOnlyIconName, eraOnlyIconName, fallbackIconName }
end

--计算点数花费
function CalculateSelectedCost(playerID)
    --总花费，总科技、市政和城市花费
    local cost, c_techs, c_civics, c_cities = 0, 0, 0, 0
    --总科技、市政和城市数量
    local s_techs, s_civics, s_cities = 0, 0, 0
    --获取玩家的点数减免
    local reduction = -EaglePointManager:GetReduction(playerID)
    for _, tech in pairs(m_SelectedTechs) do
        local techCost = EagleCore:ModifyByPercent(tech, reduction)
        --总花费
        cost = cost + techCost
        --总科技花费
        c_techs = c_techs + techCost
        --总科技数量
        s_techs = s_techs + 1
    end
    for _, civic in pairs(m_SelectedCivics) do
        local civicCost = EagleCore:ModifyByPercent(civic, reduction)
        --总花费
        cost = cost + civicCost
        --总科技花费
        c_civics = c_civics + civicCost
        --总科技数量
        s_civics = s_civics + 1
    end
    for _, city in pairs(m_SelectedCities) do
        local cityCost = EagleCore:ModifyByPercent(city, reduction)
        --总花费
        cost = cost + cityCost
        --总城市花费
        c_cities = c_cities + cityCost
        --总城市数量
        s_cities = s_cities + 1
    end
    local techs = { Num = s_techs, Cost = c_techs }
    local civics = { Num = s_civics, Cost = c_civics }
    local cities = { Num = s_cities, Cost = c_cities }
    return cost, techs, civics, cities
end

--获取科技、市政和城市生产的数据
function GetData()
    --设置Data表
    local data = { Techs = {}, Civics = {}, Cities = {}, Point = 0 }
    --获取玩家
    local loaclId = Game.GetLocalPlayer()
    local player = Players[loaclId]
    if not player then return data end
    --获取玩家拥有的点数
    local eaglePoint = EaglePointManager.GetEaglePoint(loaclId)
    local cost = CalculateSelectedCost(loaclId)
    data.Point = eaglePoint - cost
    --简单的自定义函数，获取成本与进度之差
    local function GetNeed(table)
        return table.Cost - table.Progress
    end
    --获取科技数据
    local techs = player:GetTechs()
    for row in GameInfo.Technologies() do
        if (not techs:HasTech(row.Index)) or row.Repeatable == true then
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
        if (not civics:HasCivic(row.Index)) or row.Repeatable == true then
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
            --城市生产名称
            cityDetail.Name = cityData.ItemName
            cityDetail.Type = cityData.ItemType
            --城市生产图标
            cityDetail.Icons = {}
            local iconName = 'ICON_' .. cityData.ItemType
            if cityData.IsUnit then
                --获取单位定义
                local unitDef = GameInfo.Units[cityData.ItemIndex]
                --获取单位图标
                cityDetail.Icons = GetUnitIcons(loaclId, unitDef)
                table.insert(cityDetail.Icons, iconName .. '_PORTRAIT')
            else
                table.insert(cityDetail.Icons, iconName)
            end
            --功能性提示
            if cityData.IsBuilding then
                tooltip = ToolTipHelper.GetBuildingToolTip(cityData.Hash, loaclId, city)
            elseif cityData.IsDistrict then
                tooltip = ToolTipHelper.GetDistrictToolTip(cityData.Hash)
            elseif cityData.IsUnit then
                --获取城市生产队列
                local cityBuildQueue = city:GetBuildQueue()
                local militaryFormationType = cityBuildQueue:GetCurrentProductionTypeModifier()
                tooltip = ToolTipHelper.GetUnitToolTip(cityData.Hash, militaryFormationType, cityBuildQueue)
            elseif cityData.IsProject then
                tooltip = ToolTipHelper.GetProjectToolTip(cityData.Hash)
            end
            --设置tooltip
            cityDetail.Tooltip = tooltip
            --城市生产进度
            cityDetail.Cost = cityData.TotalCost
            cityDetail.Progress = cityData.Progress
            cityDetail.TurnsLeft = cityData.TurnsLeft
            --城市生产所需
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
                cityDetail.Need = math.max(0, math.ceil((cityDetail.Need / multiplier) - salvage))
            end
            --添加城市生产细节
            table.insert(data.Cities, cityDetail)
        end
    end
    --排序科技、市政、城市生产数据
    table.sort(data.Techs, function(a, b) return a.Need < b.Need end)
    table.sort(data.Civics, function(a, b) return a.Need < b.Need end)
    --table.sort(data.Cities, function(a, b) return a.Need < b.Need end)
    --返回数据
    return data
end

--打开面板
function Open()
    --设置面版状态
    m_PanelIsOpen = true
    Refresh(Game.GetLocalPlayer())
    --选中科技、市政、城市
    if m_chooseTechs then
        ChooseTechsTab()
    elseif m_chooseCivics then
        ChooseCivicsTab()
    elseif m_chooseCities then
        ChooseCitiesTab()
    end
    UI.PlaySound("Tech_Tray_Slide_Open")
    m_kSlideAnimator.Show()
end

--关闭面板
function Close()
    --设置面版状态
    m_PanelIsOpen    = false
    --取消选中科技、市政、城市
    m_SelectedTechs  = {}
    m_SelectedCivics = {}
    m_SelectedCities = {}
    UI.PlaySound("Tech_Tray_Slide_Close")
    m_kSlideAnimator.Hide()
end

--面板切换
function Toggle()
    if ContextPtr:IsHidden() then
        Open()
    else
        Close()
    end
end

--顶部刷新
function TopRefresh()
    --获取本地玩家
    local playerID = Game.GetLocalPlayer()
    --获得玩家拥有的研究点数
    local researchPoints = EaglePointManager.GetEaglePoint(playerID, true)
    Controls.PointBalance:SetText(Locale.ToNumber(researchPoints, "#,###.#"))
    --获取每回合获得的研究点数
    local perTurnPoint = EaglePointManager:GetPerTurnPoint(playerID, true)
    Controls.PointPerTurn:SetText(EagleCore.FormatValue(perTurnPoint))
    --获取每回合获得的研究点数tooltip
    -- local tooltip = Locale.Lookup('LOC_EAGLE_POINT_PER_TURN', perTurnPoint)
    -- tooltip = tooltip .. '[NEWLINE]' .. EaglePointManager:GetPerTurnPointTooltip(playerID)
    Controls.PointBacking:SetToolTipString(EaglePointManager:GetPerTurnPointTooltip(playerID))
    --获取消耗和选择项数量
    local cost, techs, civics, cities = CalculateSelectedCost(playerID)
    --选择项目数量
    local s_techs, s_civics, s_cities = techs.Num, civics.Num, cities.Num
    --项目花费
    local techCost, civicCost, cityCost = techs.Cost, civics.Cost, cities.Cost
    --设置按钮tooltip
    local costTooltip = Locale.Lookup('LOC_EAGLE_POINT_TOTAL_COST', cost)
    --设置消耗
    if cost > 0 then
        Controls.PointCostBalance:SetText(Locale.Lookup('LOC_EAGLE_POINT_COST', cost))
    else
        Controls.PointCostBalance:SetText(Locale.Lookup('LOC_EAGLE_POINT_NO_COST'))
    end
    --设置选择项数量
    if s_techs > 0 then
        Controls.TechsLabel:SetText(Locale.Lookup('LOC_EAGLE_POINT_SELECT', s_techs))
        costTooltip = costTooltip .. '[NEWLINE]' .. Locale.Lookup('LOC_EAGLE_POINT_TECHS_COST', techCost, s_techs)
    else
        Controls.TechsLabel:SetText(Locale.Lookup('LOC_EAGLE_POINT_NO_SELECTED'))
    end
    if s_civics > 0 then
        Controls.CivicsLabel:SetText(Locale.Lookup('LOC_EAGLE_POINT_SELECT', s_civics))
        costTooltip = costTooltip .. '[NEWLINE]' .. Locale.Lookup('LOC_EAGLE_POINT_CIVICS_COST', civicCost, s_civics)
    else
        Controls.CivicsLabel:SetText(Locale.Lookup('LOC_EAGLE_POINT_NO_SELECTED'))
    end
    if s_cities > 0 then
        Controls.CitiesLabel:SetText(Locale.Lookup('LOC_EAGLE_POINT_SELECT', s_cities))
        costTooltip = costTooltip .. '[NEWLINE]' .. Locale.Lookup('LOC_EAGLE_POINT_CITIES_COST', cityCost, s_cities)
    else
        Controls.CitiesLabel:SetText(Locale.Lookup('LOC_EAGLE_POINT_NO_SELECTED'))
    end
    --设置减免tooltip
    local reductionTooltip = EaglePointManager:GetReductionTooltip(playerID)
    if reductionTooltip ~= '' then
        --获取消耗减免和上限
        local reduction = -EaglePointManager:GetReduction(playerID)
        local limit = -EaglePointManager:GetReductionLimit(playerID)
        --设置减免tooltip
        costTooltip = costTooltip .. '[NEWLINE][NEWLINE]' ..
            Locale.Lookup('LOC_EAGLE_POINT_TOTAL_REDUCTION', reduction, limit)
            .. reductionTooltip
    end
    --设置消耗tooltip
    Controls.PointCostBacking:SetToolTipString(costTooltip)
end

--设置Tab选中状态
function SetTechsTabState(IsSelected)
    Controls.TechButton:SetSelected(IsSelected)
    local hidden = not IsSelected
    Controls.TechSelectButton:SetHide(hidden)
    Controls.TechsStack:SetHide(hidden)
    m_chooseTechs = IsSelected
end

function SetCivicsTabState(IsSelected)
    Controls.CivicButton:SetSelected(IsSelected)
    local hidden = not IsSelected
    Controls.CivicSelectButton:SetHide(hidden)
    Controls.CivicsStack:SetHide(hidden)
    m_chooseCivics = IsSelected
end

function SetCitiesTabState(IsSelected)
    Controls.CityButton:SetSelected(IsSelected)
    local hidden = not IsSelected
    Controls.CitySelectButton:SetHide(hidden)
    Controls.CitiesStack:SetHide(hidden)
    m_chooseCities = IsSelected
end

--交换科技、市政、城市生产数据
function ChooseTechsTab()
    --是否选中其他Tab
    if not Controls.TechButton:IsSelected() then
        --取消选中市政
        SetCivicsTabState(false)
        --取消选中城市
        SetCitiesTabState(false)
    end
    --选中科技
    SetTechsTabState(true)
    ConfirmRefresh()
end

function ChooseCivicsTab()
    --是否选中其他Tab
    if not Controls.CivicButton:IsSelected() then
        --取消选中科技
        SetTechsTabState(false)
        --取消选中城市
        SetCitiesTabState(false)
    end
    --选中市政
    SetCivicsTabState(true)
    ConfirmRefresh()
end

function ChooseCitiesTab()
    --是否选中其他Tab
    if not Controls.CityButton:IsSelected() then
        --取消选中科技
        SetTechsTabState(false)
        --取消选中市政
        SetCivicsTabState(false)
    end
    --选中城市
    SetCitiesTabState(true)
    ConfirmRefresh()
end

--设置选中回调函数
function SelectTech(techIndex, Need, playerID)
    if m_SelectedTechs[techIndex] ~= nil then
        m_SelectedTechs[techIndex] = nil
    else
        m_SelectedTechs[techIndex] = Need
    end
    Refresh(playerID)
end

function SelectCivic(civicIndex, Need, playerID)
    if m_SelectedCivics[civicIndex] ~= nil then
        m_SelectedCivics[civicIndex] = nil
    else
        m_SelectedCivics[civicIndex] = Need
    end
    Refresh(playerID)
end

function SelectCity(cityID, Need, playerID)
    if m_SelectedCities[cityID] ~= nil then
        m_SelectedCities[cityID] = nil
    else
        m_SelectedCities[cityID] = Need
    end
    Refresh(playerID)
end

--选中项实现
function Realize()
    --获取玩家
    local playerID = Game.GetLocalPlayer()
    --重设置科技、市政、城市生产数据列表
    m_TechsListIM:ResetInstances()
    m_CivicsListIM:ResetInstances()
    m_CitiesListIM:ResetInstances()
    --获取数据
    local data = GetData()
    --获取花费减免
    local reduction = -EaglePointManager:GetReduction(playerID)
    --科技数据
    for _, tech in ipairs(data.Techs) do
        local instance = m_TechsListIM:GetInstance()
        local techIndex = tech.Index
        --获取科技是否选中
        local isSelected = m_SelectedTechs[techIndex] ~= nil
        --科技花费
        local cost = EagleCore:ModifyByPercent(tech.Need, reduction)
        if data.Point < cost and not isSelected then
            instance.Button:SetDisabled(true)
            instance.Button:SetAlpha(0.6)
        else
            instance.Button:SetDisabled(false)
            instance.Button:SetAlpha(1)
        end
        --获取科技定义
        local techDef = GameInfo.Technologies[techIndex]
        --设置科技名称
        instance.Name:SetText(Locale.Lookup(techDef.Name))
        --设置回调函数
        instance.Button:RegisterCallback(Mouse.eLClick,
            function()
                SelectTech(techIndex, tech.Need, playerID)
            end)
        --设置tooltip
        local tooltip = ToolTipHelper.GetToolTip(techDef.TechnologyType, playerID)
        instance.Button:LocalizeAndSetToolTip(tooltip)
        --设置科技图标
        RealizeIcon(instance.Icon, techDef.TechnologyType, SIZE_ICON_SMALL)
        --设置科技进度
        local progress = math.clamp(tech.Progress / tech.Cost, 0, 1.0)
        instance.ProgressMeter:SetPercent(progress)
        --设置科技花费
        instance.Cost:SetText(Locale.ToNumber(cost, "#,###.#"))
        instance.CostStack:SetHide(isSelected)
        instance.Select:SetHide(not isSelected)
        --关于科技进度
        local progressStr = Locale.ToNumber(tech.Progress, "#,###.#") .. '/' .. Locale.ToNumber(tech.Cost, "#,###.#")
        instance.Progress:SetText(progressStr)
        --关于科技提升
        if tech.CanTrigger then
            instance.IconCanBeBoosted:SetHide(tech.HasTrigger)
            instance.IconHasBeenBoosted:SetHide(not tech.HasTrigger)
            instance.BoostLabel:SetText(Locale.Lookup(
                tech.HasTrigger and "LOC_EAGLE_POINT_UNLOCK_CAN_BOOST" or "LOC_EAGLE_POINT_UNLOCK_HAS_BOOST")
            )
        else
            instance.IconCanBeBoosted:SetHide(true)
            instance.IconHasBeenBoosted:SetHide(true)
            instance.BoostLabel:SetText("")
        end
        --设置解锁项目
        local unlockIM = GetUnlockIM(instance)
        --获取科技解锁的项目
        local unlockNum = PopulateUnlockablesForTech(playerID, tech.Index, unlockIM)
        --如果有太多项目，处理溢出
        if unlockNum ~= nil then
            HandleOverflow(unlockNum, instance, 6, 6)
        end
    end
    --市政数据
    for _, civic in ipairs(data.Civics) do
        local instance = m_CivicsListIM:GetInstance()
        local civicIndex = civic.Index
        --市政花费
        local cost = EagleCore:ModifyByPercent(civic.Need, reduction)
        --获取市政是否选中
        local isSelected = m_SelectedCivics[civicIndex] ~= nil
        if data.Point < cost and not isSelected then
            instance.Button:SetDisabled(true)
            instance.Button:SetAlpha(0.6)
        else
            instance.Button:SetDisabled(false)
            instance.Button:SetAlpha(1)
        end
        --获取市政定义
        local civicDef = GameInfo.Civics[civicIndex]
        --设置市政名称
        instance.Name:SetText(Locale.Lookup(civicDef.Name))
        --设置回调函数
        instance.Button:RegisterCallback(Mouse.eLClick,
            function()
                SelectCivic(civicIndex, civic.Need, playerID)
            end)
        --设置tooltip
        local tooltip = ToolTipHelper.GetToolTip(civicDef.CivicType, playerID)
        instance.Button:LocalizeAndSetToolTip(tooltip)
        --设置市政图标（fuck you, Firaxis Games. 怎么没给市政图标也做一套30的）
        RealizeIcon(instance.Icon, civicDef.CivicType, SIZE_ICON_MEDIUM)
        --设置市政进度
        local progress = math.clamp(civic.Progress / civic.Cost, 0, 1.0)
        instance.ProgressMeter:SetPercent(progress)
        --设置市政花费
        instance.Cost:SetText(Locale.ToNumber(cost, "#,###.#"))
        instance.CostStack:SetHide(isSelected)
        instance.Select:SetHide(not isSelected)
        --关于市政进度
        local progressStr = Locale.ToNumber(civic.Progress, "#,###.#") .. '/' .. Locale.ToNumber(civic.Cost, "#,###.#")
        instance.Progress:SetText(progressStr)
        --关于市政提升
        if civic.CanTrigger then
            instance.IconCanBeBoosted:SetHide(civic.HasTrigger)
            instance.IconHasBeenBoosted:SetHide(not civic.HasTrigger)
            instance.BoostLabel:SetText(Locale.Lookup(
                civic.HasTrigger and "LOC_EAGLE_POINT_UNLOCK_CAN_BOOST" or "LOC_EAGLE_POINT_UNLOCK_HAS_BOOST")
            )
        else
            instance.IconCanBeBoosted:SetHide(true)
            instance.IconHasBeenBoosted:SetHide(true)
            instance.BoostLabel:SetText("")
        end
        --设置解锁项目
        local unlockIM = GetUnlockIM(instance)
        --获取市政解锁的项目
        local unlockNum = PopulateUnlockablesForCivic(playerID, civic.Index, unlockIM)
        --如果有太多项目，处理溢出
        if unlockNum ~= nil then
            HandleOverflow(unlockNum, instance, 6, 6)
        end
    end
    --城市数据
    for _, v_city in ipairs(data.Cities) do
        local instance = m_CitiesListIM:GetInstance()
        local cityID = v_city.ID
        --城市花费
        local cost = EagleCore:ModifyByPercent(v_city.Need, reduction)
        --获取城市是否选中
        local isSelected = m_SelectedCities[cityID] ~= nil
        if data.Point < cost and not isSelected then
            instance.Button:SetDisabled(true)
            instance.Button:SetAlpha(0.6)
        else
            instance.Button:SetDisabled(false)
            instance.Button:SetAlpha(1)
        end
        --获取城市
        local city = CityManager.GetCity(playerID, cityID)
        --设置城市名称
        instance.CityName:SetText(Locale.Lookup(city:GetName()))
        --设置回调函数
        instance.Button:RegisterCallback(Mouse.eLClick,
            function()
                SelectCity(cityID, v_city.Need, playerID)
            end)
        --设置生产名称
        instance.ProductionName:SetText(v_city.Name)
        --设置生产图标
        for _, icon in ipairs(v_city.Icons) do
            if icon ~= nil and instance.ProductionIcon:TrySetIcon(icon) then
                break
            end
        end
        --设置tooltip
        instance.ProductionIcon:SetToolTipString(Locale.Lookup(v_city.Tooltip))
        --设置城市生产进度
        local prodTurnsLeft = v_city.TurnsLeft
        if prodTurnsLeft == -1 then prodTurnsLeft = "∞" end
        instance.ProductionCost:SetText("[ICON_Turn]" .. prodTurnsLeft)
        instance.ProductionProgressString:SetText("[ICON_Production]" .. v_city.Progress .. " / " .. v_city.Cost)
        --计算百分比
        local percentComplete = math.clamp(v_city.Progress / v_city.Cost, 0, 1.0)
        local percentCompleteNextTurn = (1 - percentComplete) / prodTurnsLeft
        percentCompleteNextTurn = percentComplete + percentCompleteNextTurn
        --设置城市生产进度条
        instance.ProductionProgress:SetPercent(math.max(percentComplete, 0));
        instance.ProductionProgress:SetShadowPercent(math.max(percentCompleteNextTurn, 0));
        --设置城市花费
        instance.Cost:SetText(Locale.ToNumber(cost, "#,###.#"))
        instance.CostStack:SetHide(isSelected)
        instance.Select:SetHide(not isSelected)
    end
end

--确认按钮刷新
function ConfirmRefresh()
    --确定按钮
    local hasSelection = next(m_SelectedTechs)
        or next(m_SelectedCivics)
        or next(m_SelectedCities)
    Controls.ConfirmButton:SetDisabled(not hasSelection)
    Controls.ConfirmButton:SetAlpha(hasSelection and 1 or 0.7)
    --重新选择按钮
    local isTech = Controls.TechButton:IsSelected() and next(m_SelectedTechs)
    local isCivic = Controls.CivicButton:IsSelected() and next(m_SelectedCivics)
    local isCity = Controls.CityButton:IsSelected() and next(m_SelectedCities)
    --是否可以取消
    local canCancel = isTech or isCivic or isCity
    Controls.CancelButton:SetDisabled(not canCancel)
    Controls.CancelButton:SetAlpha(canCancel and 1 or 0.7)
end

--点击确认按钮后
function OnConfirmClicked()
    local playerID = Game.GetLocalPlayer()
    local pointCost = CalculateSelectedCost(playerID)
    UI.RequestPlayerOperation(playerID,
        PlayerOperations.EXECUTE_SCRIPT, {
            Techs   = m_SelectedTechs,
            Civics  = m_SelectedCivics,
            Cities  = m_SelectedCities,
            Cost    = pointCost,
            OnStart = 'EagleUnionPointUnlock'
        }
    ); UI.PlaySound("Purchase_With_Gold"); Close()
    Network.BroadcastPlayerInfo()
end

--点击重新选择按钮后
function OnCancelClicked()
    if Controls.TechButton:IsSelected() then
        m_SelectedTechs = {}
    elseif Controls.CivicButton:IsSelected() then
        m_SelectedCivics = {}
    elseif Controls.CityButton:IsSelected() then
        m_SelectedCities = {}
    end
    Refresh(Game.GetLocalPlayer())
    UI.PlaySound("Confirm_Production")
end

--总刷新
function Refresh(playerID)
    if m_PanelIsOpen and EagleCore.CheckCivMatched(
            playerID, 'CIVILIZATION_EAGLE_UNION'
        ) and Game.GetLocalPlayer() == playerID then
        --顶部刷新
        TopRefresh()
        --选项刷新
        Realize()
        --确认按钮刷新
        ConfirmRefresh()
    end
end

--||======================ContextPtr======================||--

--On input handler
function OnInputHandler(pInputStruct)
    if pInputStruct:GetMessageType() == KeyEvents.KeyUp and pInputStruct:GetKey() == Keys.VK_ESCAPE then
        Close()
        return true
    end
    return false
end

--||======================initialize======================||--

function Initialize()
    --设置滑动动画
    m_kSlideAnimator = CreateScreenAnimation(Controls.EagleChooserSlideAnim)
    -------------------Closed-------------------
    LuaEvents.DiplomacyActionView_HideIngameUI.Add(Close)
    LuaEvents.EndGameMenu_Shown.Add(Close)
    LuaEvents.FullscreenMap_Shown.Add(Close)
    LuaEvents.NaturalWonderPopup_Shown.Add(Close)
    LuaEvents.ProjectBuiltPopup_Shown.Add(Close)
    LuaEvents.Tutorial_ToggleInGameOptionsMenu.Add(Close)
    LuaEvents.WonderBuiltPopup_Shown.Add(Close)
    LuaEvents.NaturalDisasterPopup_Shown.Add(Close)
    LuaEvents.RockBandMoviePopup_Shown.Add(Close)
    LuaEvents.CivicsTree_OpenCivicsTree.Add(Close)
    LuaEvents.Government_OpenGovernment.Add(Close)
    LuaEvents.GovernorPanel_Opened.Add(Close)
    LuaEvents.GreatPeople_OpenGreatPeople.Add(Close)
    LuaEvents.GreatWorks_OpenGreatWorks.Add(Close)
    LuaEvents.HistoricMoments_Opened.Add(Close)
    LuaEvents.Religion_OpenReligion.Add(Close)
    LuaEvents.PantheonChooser_OpenReligion.Add(Close)
    LuaEvents.TechTree_OpenTechTree.Add(Close)
    LuaEvents.ClimateScreen_Opened.Add(Close)
    ------------------UI Event------------------
    ContextPtr:SetInputHandler(OnInputHandler, true)
    ------------------Register------------------
    --顶部关闭按钮
    Controls.CloseButton:RegisterCallback(Mouse.eLClick, Close)
    Controls.CloseButton:RegisterCallback(Mouse.eMouseEnter, EagleUnionEnter)
    --科技按钮
    Controls.TechButton:RegisterCallback(Mouse.eLClick, ChooseTechsTab)
    Controls.TechButton:RegisterCallback(Mouse.eMouseEnter, EagleUnionEnter)
    --市政按钮
    Controls.CivicButton:RegisterCallback(Mouse.eLClick, ChooseCivicsTab)
    Controls.CivicButton:RegisterCallback(Mouse.eMouseEnter, EagleUnionEnter)
    --城市按钮
    Controls.CityButton:RegisterCallback(Mouse.eLClick, ChooseCitiesTab)
    Controls.CityButton:RegisterCallback(Mouse.eMouseEnter, EagleUnionEnter)
    --确认按钮
    Controls.ConfirmButton:RegisterCallback(Mouse.eLClick, OnConfirmClicked)
    Controls.ConfirmButton:RegisterCallback(Mouse.eMouseEnter, EagleUnionEnter)
    --重新选择按钮
    Controls.CancelButton:RegisterCallback(Mouse.eLClick, OnCancelClicked)
    Controls.CancelButton:RegisterCallback(Mouse.eMouseEnter, EagleUnionEnter)
    -------------------Resets-------------------
    --城市和城市生产
    Events.CityAddedToMap.Add(Refresh)
    Events.CityPopulationChanged.Add(Refresh)
    Events.CityProductionQueueChanged.Add(Refresh)
    Events.CityProductionUpdated.Add(Refresh)
    Events.CityProductionChanged.Add(Refresh)
    Events.CityProductionCompleted.Add(Refresh)
    Events.CityRemovedFromMap.Add(Refresh)
    --科技
    Events.ResearchChanged.Add(Refresh)
    Events.ResearchCompleted.Add(Refresh)
    Events.ResearchYieldChanged.Add(Refresh)
    Events.TechBoostTriggered.Add(Refresh)
    --市政
    Events.CivicChanged.Add(Refresh)
    Events.CivicCompleted.Add(Refresh)
    Events.CultureYieldChanged.Add(Refresh)
    Events.CivicBoostTriggered.Add(Refresh)
    --本地玩家变化
    Events.LocalPlayerChanged.Add(Refresh)
    --每回合开始
    Events.PlayerTurnActivated.Add(Refresh)
    ------------------LuaEvents-----------------
    LuaEvents.EagleUnionTopButton_TogglePopup.Add(Toggle)
    --------------------------------------------
    print("Initialize success!")
end

include('EagleUnionExtraPanel_', true)

Initialize()
