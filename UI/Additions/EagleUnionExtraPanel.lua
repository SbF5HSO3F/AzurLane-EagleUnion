-- EagleUnion_ExtraPanel
-- Author: HSbF6HSO3F
-- DateCreated: 2024/12/26 8:27:59
--------------------------------------------------------------
--||=======================include========================||--
include('InstanceManager')
include('TechAndCivicSupport')
include('AnimSidePanelSupport')
include('ToolTipHelper')


include('EagleUnionCore')
include('EagleUnionPoint')

--||=======================Constants======================||--

local SIZE_ICON_SMALL  = 38

--||====================loacl variables===================||--

local Utils            = ExposedMembers.EagleUnion

local m_kSlideAnimator = {}
local m_PanelIsOpen    = false
local m_TechsListIM    = InstanceManager:new("TechSlot", "ButtonContainer", Controls.TechsStack)
local m_CivicsListIM   = InstanceManager:new("CivicSlot", "ButtonContainer", Controls.CivicsStack)
local m_CitiesListIM   = InstanceManager:new("CitySlot", "ButtonContainer", Controls.CitiesStack)
local m_chooseTechs    = true
local m_chooseCivics   = false
local m_chooseCities   = false

--||====================base functions====================||--

--获取科技、市政和城市生产的数据
function GetData()
    --设置Data表
    local data = { Techs = {}, Civics = {}, Cities = {} }
    --获取玩家
    local loaclId = Game.GetLocalPlayer()
    local player = Players[loaclId]
    if not player then return data end
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

            --城市生产进度
            cityDetail.Cost = cityData.TotalCost
            cityDetail.Progress = cityData.Progress
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
                cityDetail.Need = math.ceil((cityDetail.Need / multiplier) - salvage)
            end
            --添加城市生产细节
            table.insert(data.Cities, cityDetail)
        end
    end
    --排序科技、市政、城市生产数据
    table.sort(data.Techs, function(a, b) return a.Need < b.Need end)
    table.sort(data.Civics, function(a, b) return a.Need < b.Need end)
    table.sort(data.Cities, function(a, b) return a.Need < b.Need end)
    --返回数据
    return data
end

--打开面板
function Open()
    TopRefresh()
    if m_chooseTechs then
        ChooseTechsTab()
    elseif m_chooseCivics then
        ChooseCivicsTab()
    elseif m_chooseCities then
        ChooseCitiesTab()
    end
    Realize()
    UI.PlaySound("Tech_Tray_Slide_Open")
    m_PanelIsOpen = true
    m_kSlideAnimator.Show()
end

--关闭面板
function Close()
    UI.PlaySound("Tech_Tray_Slide_Close")
    m_PanelIsOpen = false
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
    --获取每回合获得的研究点数
    local perTurnPoint = EaglePointManager:GetPerTurnPoint(playerID, true)
    Controls.FaithLabel:SetText(perTurnPoint)
    --获取每回合获得的研究点数tooltip
    local tooltip = Locale.Lookup('LOC_EAGLE_POINT_PER_TURN', perTurnPoint)
    tooltip = tooltip .. '[NEWLINE]' .. EaglePointManager:GetPerTurnPointTooltip(playerID)
    Controls.FaithLabel:SetToolTipString(tooltip)
end

--设置Tab选中状态
function SetTechsTabState(IsSelected)
    Controls.TechButton:SetSelected(IsSelected)
    local hiden = not IsSelected
    Controls.TechSelectButton:SetHide(hiden)
    Controls.TechsStack:SetHide(hiden)
    m_chooseTechs = IsSelected
end

function SetCivicsTabState(IsSelected)
    Controls.CivicButton:SetSelected(IsSelected)
    local hiden = not IsSelected
    Controls.CivicSelectButton:SetHide(hiden)
    Controls.CivicsStack:SetHide(hiden)
    m_chooseCivics = IsSelected
end

function SetCitiesTabState(IsSelected)
    Controls.CityButton:SetSelected(IsSelected)
    local hiden = not IsSelected
    Controls.CitySelectButton:SetHide(hiden)
    Controls.CitiesStack:SetHide(hiden)
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
    --科技数据
    for _, tech in ipairs(data.Techs) do
        local instance = m_TechsListIM:GetInstance()
        --获取科技是否选中

        --获取科技定义
        local techDef = GameInfo.Technologies[tech.Index]
        --设置科技名称
        instance.Name:SetText(Locale.Lookup(techDef.Name))
        --设置回调函数
        --设置tooltip
        local tooltip = ToolTipHelper.GetToolTip(techDef.TechnologyType, playerID)
        instance.Button:LocalizeAndSetToolTip(tooltip)
        --设置科技图标
        RealizeIcon(instance.Icon, techDef.TechnologyType, SIZE_ICON_SMALL)
        --设置科技进度
        local progress = math.clamp(tech.Progress / tech.Cost, 0, 1.0)
        instance.ProgressMeter:SetPercent(progress)
        --设置科技花费
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
        --获取市政是否选中

        --获取市政定义
        local civicDef = GameInfo.Civics[civic.Index]
        --设置市政名称
        instance.Name:SetText(Locale.Lookup(civicDef.Name))
        --设置回调函数
        --设置tooltip
        local tooltip = ToolTipHelper.GetToolTip(civicDef.CivicType, playerID)
        instance.Button:LocalizeAndSetToolTip(tooltip)
        --设置市政图标
        RealizeIcon(instance.Icon, civicDef.CivicType, SIZE_ICON_SMALL)
        --设置市政进度
        local progress = math.clamp(civic.Progress / civic.Cost, 0, 1.0)
        instance.ProgressMeter:SetPercent(progress)
        --设置市政花费
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
        --获取城市
        local city = CityManager.GetCity(playerID, v_city.ID)
        --设置首都
        instance.CapitalIcon:SetHide(not city:IsCapital())
        --设置城市名称
        instance.CityName:SetText(Locale.Lookup(city:GetName()))
        --设置生产名称
        instance.CurrentProductionName:SetText(v_city.Name)
        --设置生产图标
        local iconName = 'ICON_' .. v_city.Type
        instance.ProductionIcon:TrySetIcon(iconName)
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
    ------------------LuaEvents-----------------
    LuaEvents.EagleUnionTopButton_TogglePopup.Add(Toggle)
    --------------------------------------------
    print("Initialize success!")
end

include('EagleUnionExtraPanel_', true)

Initialize()
