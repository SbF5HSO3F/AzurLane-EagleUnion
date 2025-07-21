-- EagleUnion_TopButton
-- Author: HSbF6HSO3F
-- DateCreated: 2024/12/26 8:28:10
--------------------------------------------------------------
--||=======================include========================||--
include('EagleCore')

--||====================loacl variables===================||--

local m_EagleLaunchButtonInstance = {}

--||====================base functions====================||--

function EagleUnionTogglePopup()
    LuaEvents.EagleUnionTopButton_TogglePopup()
end

--刷新
function EagleRefreshLaunchButton()
    --获取本地玩家
    local localPlayer = Game.GetLocalPlayer()
    --判断玩家是否匹配
    if EagleCore.CheckCivMatched(localPlayer, 'CIVILIZATION_EAGLE_UNION') then
        --显示按钮
        m_EagleLaunchButtonInstance.EagleUnionButton:SetHide(false)
        m_EagleLaunchButtonInstance.EagleUnionButton:SetHide(false)
    end
end

--添加按钮
function EagleAttachLaunchButton()
    --get the parent
    local buttonStack = ContextPtr:LookUpControl("/InGame/LaunchBar/ButtonStack")
    --create the instance
    ContextPtr:BuildInstanceForControl("EagleUnionItem", m_EagleLaunchButtonInstance, buttonStack)
    m_EagleLaunchButtonInstance.EagleUnionButton:RegisterCallback(Mouse.eLClick, EagleUnionTogglePopup)
    m_EagleLaunchButtonInstance.EagleUnionButton:RegisterCallback(Mouse.eMouseEnter, EagleUnionEnter)
    ContextPtr:BuildInstanceForControl("EagleUnionPinInstance", {}, buttonStack)
    -- Resize.
    buttonStack:CalculateSize()

    local backing = ContextPtr:LookUpControl("/InGame/LaunchBar/LaunchBacking")
    backing:SetSizeX(buttonStack:GetSizeX() + 116)

    local backingTile = ContextPtr:LookUpControl("/InGame/LaunchBar/LaunchBackingTile")
    backingTile:SetSizeX(buttonStack:GetSizeX() - 20)

    LuaEvents.LaunchBar_Resize(buttonStack:GetSizeX())
end

--||======================initialize======================||--

function Initialize()
    if EagleCore.CheckCivMatched(Game.GetLocalPlayer(), 'CIVILIZATION_EAGLE_UNION') then
        Events.LoadGameViewStateDone.Add(EagleAttachLaunchButton)
        print("Initialize success!")
    end
end

include('EagleUnionTopButton_', true)

Initialize()
