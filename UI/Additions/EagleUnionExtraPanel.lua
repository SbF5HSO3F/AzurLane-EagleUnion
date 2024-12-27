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
local m_TechsListIM    = InstanceManager:new("TechSlot", "ButtonContainer", Controls.TechsStack)
local m_CivicsListIM   = InstanceManager:new("CivicSlot", "ButtonContainer", Controls.CivicsStack)
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
        if (not techs:HasCivic(row.Index)) or row.Repeatable == true then
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
        if (not civics:HasTech(row.Index)) or row.Repeatable == true then
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
    UI.PlaySound("Tech_Tray_Slide_Open")
    m_kSlideAnimator.Show()
end

--关闭面板
function Close()
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
    Controls.TechSelectButton:SetHide(not IsSelected)
    m_chooseTechs = IsSelected
end

function SetCivicsTabState(IsSelected)
    Controls.CivicButton:SetSelected(IsSelected)
    Controls.CivicSelectButton:SetHide(not IsSelected)
    m_chooseCivics = IsSelected
end

function SetCitiesTabState(IsSelected)
    Controls.CityButton:SetSelected(IsSelected)
    Controls.CitySelectButton:SetHide(not IsSelected)
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
