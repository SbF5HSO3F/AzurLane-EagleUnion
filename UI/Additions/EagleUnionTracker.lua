-- EagleUnionTracker
-- Author: HSbF6HSO3F
-- DateCreated: 2024/12/28 21:35:34
--------------------------------------------------------------
--||=======================include========================||--
include('EagleCore')
include('EagleUnionPoint')

--||======================MetaTable=======================||--

EagleUnionTracker = {
    --点数追踪
    Point = {
        --刷新
        Reset = function()
            --获取本地玩家
            local loaclPlayerID = Game.GetLocalPlayer()
            if EagleCore.CheckCivMatched(loaclPlayerID, 'CIVILIZATION_EAGLE_UNION') then
                Controls.EagleTrackerGrid:SetHide(false)
                --获取点数
                local point = EaglePointManager.GetEaglePoint(loaclPlayerID, true)
                --更新点数显示
                Controls.PointBalance:SetText(Locale.ToNumber(point, "#,###.#"))
                --获取每回合获得的研究点数
                local perTurnPoint = EaglePointManager:GetPerTurnPoint(loaclPlayerID, true)
                Controls.PointPerTurn:SetText(EagleCore.FormatValue(perTurnPoint))
                --获取每回合获得的研究点数tooltip
                local perTurnPointTooltip = EaglePointManager:GetPerTurnPointTooltip(loaclPlayerID)
                -- local tooltip = Locale.Lookup('LOC_EAGLE_POINT_PER_TURN', perTurnPoint)
                -- tooltip = tooltip .. '[NEWLINE]' .. perTurnPointTooltip
                Controls.EagleTrackerPoint:SetToolTipString(perTurnPointTooltip)
            else
                Controls.EagleTrackerGrid:SetHide(true)
            end
        end,
        --回调函数
        Callback = function(self)
            self.Reset()
            LuaEvents.EagleUnionTopButton_TogglePopup()
        end,
        --注册
        Register = function(self)
            Controls.EagleTrackerPoint:RegisterCallback(Mouse.eLClick, function() self:Callback() end)
            Controls.EagleTrackerPoint:RegisterCallback(Mouse.eMouseEnter, EagleUnionEnter)
        end,
    }
}

--||====================base functions====================||--

function EagleTrackerReset()
    EagleUnionTracker.Point.Reset()
end

function EagleTrackerInit()
    local parent = ContextPtr:LookUpControl("/InGame/WorldTracker/PanelStack")
    if parent ~= nil then
        Controls.EagleTrackerGrid:ChangeParent(parent)
        parent:AddChildAtIndex(Controls.EagleTrackerGrid, 1)
        --注册
        EagleUnionTracker.Point:Register()
        parent:CalculateSize()
        parent:ReprocessAnchoring()
        --刷新
        EagleTrackerReset()
    end
end

--||======================initialize======================||--

--initialization function
function Initialize()
    -----------------------Events-----------------------
    Events.LoadGameViewStateDone.Add(EagleTrackerInit)
    -------------------Resets-------------------
    --城市和城市生产
    Events.CityAddedToMap.Add(EagleTrackerReset)
    Events.CityPopulationChanged.Add(EagleTrackerReset)
    Events.CityProductionQueueChanged.Add(EagleTrackerReset)
    Events.CityProductionUpdated.Add(EagleTrackerReset)
    Events.CityProductionChanged.Add(EagleTrackerReset)
    Events.CityProductionCompleted.Add(EagleTrackerReset)
    Events.CityRemovedFromMap.Add(EagleTrackerReset)
    --科技
    Events.ResearchChanged.Add(EagleTrackerReset)
    Events.ResearchCompleted.Add(EagleTrackerReset)
    Events.ResearchYieldChanged.Add(EagleTrackerReset)
    Events.TechBoostTriggered.Add(EagleTrackerReset)
    --市政
    Events.CivicChanged.Add(EagleTrackerReset)
    Events.CivicCompleted.Add(EagleTrackerReset)
    Events.CultureYieldChanged.Add(EagleTrackerReset)
    Events.CivicBoostTriggered.Add(EagleTrackerReset)
    --本地玩家变化
    Events.LocalPlayerChanged.Add(EagleTrackerReset)
    --每回合开始
    Events.PlayerTurnActivated.Add(EagleTrackerReset)
    --GameProperty变化
    Events.GamePropertyChanged.Add(EagleTrackerReset)
    ---------------------GameEvents---------------------
    --ExposedMembers.Flasher.Reset = FlasherResetPanel
    ----------------------LuaEvents---------------------
    ----------------------------------------------------
    print('Initial success!')
end

include('EagleUnionTracker_', true)

Initialize()
