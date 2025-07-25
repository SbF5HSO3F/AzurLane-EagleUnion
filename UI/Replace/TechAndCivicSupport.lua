-- ===========================================================================
--	Support functions for formatting of Tech and Civic areas which are used
--	within their "Choosers" and their panel version within the "World Tracker"
-- ===========================================================================

include("InstanceManager")
include("SupportFunctions")
include("Civ6Common")

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================

local DATA_FIELD_UNLOCK_IM       = "_UnlockIM"
local MAX_BEFORE_TRUNC_BOOST_MSG = 220 -- Size in which boost messages will be truncated and tooltipified
local SIZE_ICON_CIVIC_LARGE      = 38
local SIZE_ICON_RESEARCH_LARGE   = 38
local MAX_ICONS_BEFORE_OVERFLOW  = 6

-- ===========================================================================
--	MEMBERS
--	These are instanced for each file that adds this support file.
-- ===========================================================================
local m_kGovernmentData -- Used to cache government info.
local m_kCivicsData     -- Used to cache civics info.
local m_kTechsData      -- Used to cache tech info.

-- Utility Methods

function GetUnlockablesForCivic_Cached(civicType, playerId)
	--Set player ID to -1 if it is invalid in any way.
	local playerIndex = playerId
	if playerIndex == nil then playerIndex = -1 end

	if m_kCivicsData == nil or table.count(m_kCivicsData) == 0 then
		m_kCivicsData = {}
		for i = 0, GameDefines.MAX_PLAYERS, 1 do
			m_kCivicsData[i] = {}
		end
	end

	if m_kCivicsData[playerIndex][civicType] ~= nil then
		return m_kCivicsData[playerIndex][civicType]
	end

	local results = GetUnlockablesForCivic(civicType, playerId)
	m_kCivicsData[playerIndex][civicType] = results
	return results
end

-- ===================================================================================================================================
--	Get the unlockables for a tech, through the 'cached' table.
--	If the entry in the table is not initialized, it will be added.
--	This optionally accepts a database generated table of all the player's unlockables, this
--	should only be passed in when generating the cache.  While the game is running, the cache should contain all the
--	necessary entries.
-- ===================================================================================================================================
function GetUnlockablesForTech_Cached(techType, playerId, playerUnlockables)
	--Set player ID to -1 if it is invalid in any way.
	local playerIndex = playerId
	if playerIndex == nil then playerIndex = -1 end

	if m_kTechsData == nil or table.count(m_kTechsData) == 0 then
		m_kTechsData = {}
		for i = 0, GameDefines.MAX_PLAYERS - 1, 1 do
			m_kTechsData[i] = {}
		end
	end

	if m_kTechsData[playerIndex][techType] ~= nil then
		return m_kTechsData[playerIndex][techType]
	end

	local results = GetUnlockablesForTech(techType, playerId, playerUnlockables)
	m_kTechsData[playerIndex][techType] = results
	return results
end

-- ===================================================================================================================================
--	RETURNS the string name of an unlocked icon based on the type passed in
-- ===================================================================================================================================
function GetUnlockIcon(typeName)
	local icon     = "ICON_TECHUNLOCK_0"
	local typeInfo = GameInfo.Types[typeName]
	if (typeInfo) then
		local icons_by_kind = {
			KIND_PROJECT     = "ICON_TECHUNLOCK_0",
			KIND_WONDER      = "ICON_TECHUNLOCK_0",
			KIND_BUILDING    = "ICON_TECHUNLOCK_1",
			KIND_DISTRICT    = "ICON_TECHUNLOCK_2",
			KIND_IMPROVEMENT = "ICON_TECHUNLOCK_3",
			KIND_UNIT        = "ICON_TECHUNLOCK_4",
			KIND_RESOURCE    = "ICON_TECHUNLOCK_5",
			KIND_GOVERNMENT  = "ICON_TECHUNLOCK_6",
			KIND_ROUTE       = "ICON_TECHUNLOCK_3",
			KIND_AGREEMENT   = "ICON_TECHUNLOCK_8",
			KIND_POLICY      = "ICON_TECHUNLOCK_9",
		}

		if (typeInfo.Kind == "KIND_POLICY") then
			local policy = GameInfo.Policies[typeName]
			local slotType = policy and policy.GovernmentSlotType or nil

			if (slotType == "SLOT_MILITARY") then
				icon = "ICON_TECHUNLOCK_10"
			elseif (slotType == "SLOT_DIPLOMATIC") then
				icon = "ICON_TECHUNLOCK_11"
			elseif (slotType == "SLOT_ECONOMIC") then
				icon = "ICON_TECHUNLOCK_12"
			elseif (slotType == "SLOT_WILDCARD" or slotType == "SLOT_GREAT_PERSON") then
				icon = "ICON_TECHUNLOCK_9"
			else
				icon = icons_by_kind["KIND_POLICY"]
			end
		else
			if typeInfo.Kind == "KIND_BUILDING" then
				for row in GameInfo.Buildings() do
					if row.BuildingType == typeInfo.Type then
						if row.IsWonder ~= nil and row.IsWonder == true then
							return icons_by_kind["KIND_WONDER"]
						else
							return icons_by_kind[typeInfo.Kind]
						end
					end
				end
			else
				if (typeInfo.Kind == "KIND_DIPLOMATIC_ACTION") then
					icon = "ICON_TECHUNLOCK_8"
				else
					icon = icons_by_kind[typeInfo.Kind]
				end
			end
		end
	end
	return icon
end

-- ===========================================================================
--
-- ===========================================================================
function GetGovernmentData()
	if m_kGovernmentData == nil or table.count(m_kGovernmentData) == 0 then
		m_kGovernmentData = {}
		for row in GameInfo.Governments() do
			local governmentType = row.GovernmentType
			local slotMilitary   = 0
			local slotEconomic   = 0
			local slotDiplomatic = 0
			local slotWildcard   = 0
			for entry in GameInfo.Government_SlotCounts() do
				if (governmentType == entry.GovernmentType) then
					local slotType = entry.GovernmentSlotType
					if (slotType == "SLOT_MILITARY") then
						slotMilitary = slotMilitary + entry.NumSlots
					elseif (slotType == "SLOT_ECONOMIC") then
						slotEconomic = slotEconomic + entry.NumSlots
					elseif (slotType == "SLOT_DIPLOMATIC") then
						slotDiplomatic = slotDiplomatic + entry.NumSlots
					elseif (slotType == "SLOT_WILDCARD" or slotType == "SLOT_GREAT_PERSON") then
						slotWildcard = slotWildcard + entry.NumSlots
					end
				end
			end

			m_kGovernmentData[governmentType] = {
				Name              = row.Name,
				NumSlotMilitary   = slotMilitary,
				NumSlotEconomic   = slotEconomic,
				NumSlotDiplomatic = slotDiplomatic,
				NumSlotWildcard   = slotWildcard
			}
		end
	end
	return m_kGovernmentData
end

function ResetOverflowArrow(kItemInstance)
	if kItemInstance == nil then
		return
	end
	if kItemInstance.PageTurnerImage == nil then
		return
	end
	kItemInstance.PageTurnerImage:FlipX(false)
	kItemInstance.UnlockPageTurner:SetHide(true)
	kItemInstance.UnlockPageTurner:ClearCallback(Mouse.eLClick)
end

function OnOverflowArrowPressed(kItemInstance, nUnlockableOffset)
	local unlockables  = kItemInstance.UnlockStack:GetChildren()
	local overflowPage = kItemInstance.PageTurnerImage:IsFlippedHorizontal()
	kItemInstance.PageTurnerImage:FlipX(not overflowPage)
	for i = nUnlockableOffset + 1, #unlockables, 1 do
		unlockables[i]:SetHide(not unlockables[i]:IsHidden())
	end
	kItemInstance.UnlockStack:ReprocessAnchoring()
end

function HandleOverflow(numUnlockables, kItemInstance, numMaxVisible, numMaxPerPage)
	if kItemInstance == nil then return nil end

	kItemInstance.UnlockPageTurner:SetHide(true)

	if numUnlockables <= numMaxVisible then return end

	local unlockables = kItemInstance.UnlockStack:GetChildren()
	-- Stack may contain hidden controls due to InstanceManager use.
	-- Luckily, they should all be pushed to the back of the list due to reparenting.
	-- So, only toggle the visibility states of the last numUnlockables unlocks!
	local nUnlockableOffset = #unlockables - numUnlockables

	kItemInstance.UnlockPageTurner:SetHide(false)
	kItemInstance.UnlockPageTurner:RegisterCallback(Mouse.eLClick,
		function()
			OnOverflowArrowPressed(kItemInstance, nUnlockableOffset)
		end)

	for i = nUnlockableOffset + numMaxPerPage + 1, #unlockables, 1 do
		unlockables[i]:SetHide(true)
	end
	kItemInstance.UnlockStack:ReprocessAnchoring()
end

-- ===========================================================================
--
-- ===========================================================================
function PopulateUnlockablesForCivic(playerID, civicID, kItemIM, kGovernmentIM, callback, hideDescriptionIcon)
	local kCivicData = GameInfo.Civics[civicID]
	if kCivicData == nil then
		UI.DataError("Unable to find a civic type in the database with an ID value of #" .. tostring(civicID))
		return
	end

	local governmentData = GetGovernmentData()
	local civicType = kCivicData.CivicType

	-- Unlockables is an array of {type, name}
	local numIcons = 0
	local unlockables = GetUnlockablesForCivic_Cached(civicType, playerID)

	if (unlockables and #unlockables > 0) then
		for i, v in ipairs(unlockables) do
			local typeName = v[1]
			local civilopediaKey = v[3]
			local typeInfo = GameInfo.Types[typeName]

			if (kGovernmentIM and typeInfo and typeInfo.Kind == "KIND_GOVERNMENT") then
				local unlock = kGovernmentIM:GetInstance()

				local government = governmentData[typeName]
				if (government) then
					unlock.MilitaryPolicyLabel:SetText(tostring(government.NumSlotMilitary))
					unlock.EconomicPolicyLabel:SetText(tostring(government.NumSlotEconomic))
					unlock.DiplomaticPolicyLabel:SetText(tostring(government.NumSlotDiplomatic))
					unlock.WildcardPolicyLabel:SetText(tostring(government.NumSlotWildcard))
					unlock.GovernmentName:SetText(Locale.Lookup(government.Name))
				end
				local toolTip = ToolTipHelper.GetToolTip(typeName, playerID)
				unlock.GovernmentInstanceGrid:LocalizeAndSetToolTip(toolTip)

				unlock.GovernmentInstanceGrid:RegisterCallback(Mouse.eLClick, callback)

				if (not IsTutorialRunning()) then
					unlock.GovernmentInstanceGrid:RegisterCallback(Mouse.eRClick, function()
						LuaEvents.OpenCivilopedia(civilopediaKey)
					end)
				end
			else
				local unlockIcon = kItemIM:GetInstance()

				local iconName   = GetUnlockIcon(typeName)
				unlockIcon.Icon:SetHide(not unlockIcon.Icon:SetIcon("ICON_" .. typeName)) -- Hide if an icon isn't found with that type.

				local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(iconName, 38)
				if textureSheet ~= nil then
					unlockIcon.UnlockIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet)
				end

				local toolTip = ToolTipHelper.GetToolTip(typeName, playerID)

				unlockIcon.UnlockIcon:LocalizeAndSetToolTip(toolTip)

				if callback ~= nil then
					unlockIcon.UnlockIcon:RegisterCallback(Mouse.eLClick, callback)
				else
					unlockIcon.UnlockIcon:ClearCallback(Mouse.eLClick)
				end

				if (not IsTutorialRunning()) then
					unlockIcon.UnlockIcon:RegisterCallback(Mouse.eRClick, function()
						LuaEvents.OpenCivilopedia(civilopediaKey)
					end)
				end
				numIcons = numIcons + 1
			end
		end
	end

	if (kCivicData.Description and hideDescriptionIcon ~= true) then
		local unlockIcon = kItemIM:GetInstance()
		unlockIcon.Icon:SetHide(true) -- foreground icon unnecessary in this case
		local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas("ICON_TECHUNLOCK_13", 38)
		if textureSheet ~= nil then
			unlockIcon.UnlockIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet)
		end
		unlockIcon.UnlockIcon:LocalizeAndSetToolTip(kCivicData.Description)
		if callback ~= nil then
			unlockIcon.UnlockIcon:RegisterCallback(Mouse.eLClick, callback)
		else
			unlockIcon.UnlockIcon:ClearCallback(Mouse.eLClick)
		end

		if (not IsTutorialRunning()) then
			unlockIcon.UnlockIcon:RegisterCallback(Mouse.eRClick, function()
				LuaEvents.OpenCivilopedia(civicType)
			end)
		end
		numIcons = numIcons + 1
	end

	kItemIM.m_ParentControl:CalculateSize()

	return numIcons
end

-- ===========================================================================
--
-- ===========================================================================
function PopulateUnlockablesForTech(playerID, techID, instanceManager, callback)
	local kTechData = GameInfo.Technologies[techID]
	if kTechData == nil then
		UI.DataError("Unable to find a tech type in the database with an ID value of #" .. tostring(techID))
		return
	end

	local techType = kTechData.TechnologyType


	-- Unlockables is an array of {type, name}
	local numIcons = 0
	local unlockables = GetUnlockablesForTech_Cached(techType, playerID)

	-- Hard-coded goodness.
	if unlockables and table.count(unlockables) > 0 then
		for i, v in ipairs(unlockables) do
			local typeName       = v[1]
			local civilopediaKey = v[3]
			local unlockIcon     = instanceManager:GetInstance()

			local iconName       = GetUnlockIcon(typeName)
			unlockIcon.Icon:SetHide(not unlockIcon.Icon:SetIcon("ICON_" .. typeName)) -- Hide if an icon isn't found with that type.

			local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(iconName, 38)
			if textureSheet ~= nil then
				unlockIcon.UnlockIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet)
			end

			local toolTip = ToolTipHelper.GetToolTip(typeName, playerID, nil)
			unlockIcon.UnlockIcon:LocalizeAndSetToolTip(toolTip)
			if callback ~= nil then
				unlockIcon.UnlockIcon:RegisterCallback(Mouse.eLClick, callback)
			else
				unlockIcon.UnlockIcon:ClearCallback(Mouse.eLClick)
			end

			if (not IsTutorialRunning()) then
				unlockIcon.UnlockIcon:RegisterCallback(Mouse.eRClick, function()
					LuaEvents.OpenCivilopedia(civilopediaKey)
				end)
			end
			numIcons = numIcons + 1
		end
	end

	if kTechData.Description then
		local unlockIcon = instanceManager:GetInstance()
		unlockIcon.Icon:SetHide(true) -- foreground icon unnecessary in this case
		local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas("ICON_TECHUNLOCK_13", 38)
		if textureSheet ~= nil then
			unlockIcon.UnlockIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet)
		end
		unlockIcon.UnlockIcon:LocalizeAndSetToolTip(kTechData.Description)
		if callback ~= nil then
			unlockIcon.UnlockIcon:RegisterCallback(Mouse.eLClick, callback)
		else
			unlockIcon.UnlockIcon:ClearCallback(Mouse.eLClick)
		end

		if (not IsTutorialRunning()) then
			unlockIcon.UnlockIcon:RegisterCallback(Mouse.eRClick, function()
				LuaEvents.OpenCivilopedia(kTechData.TechnologyType)
			end)
		end
		numIcons = numIcons + 1
	end

	return numIcons
end

-- ===========================================================================
--	Obtain the "active" data, either what is currently being worked on or
--	what just completed.
--	RETURN: active data or NIL
-- ===========================================================================
function GetActiveData(kData)
	for _, data in ipairs(kData) do
		if data.IsCurrent or data.IsLastCompleted then
			return data
		end
	end
	return nil
end

-- ===========================================================================
--	Returns a custom instance manager for unlocks that will exist in a control.
-- ===========================================================================
function GetUnlockIM(kControl)
	local unlockIM = kControl[DATA_FIELD_UNLOCK_IM]
	if unlockIM ~= nil then
		unlockIM:ResetInstances()
	else
		-- Create
		unlockIM = InstanceManager:new("UnlockIconInstance", "UnlockIcon", kControl.UnlockStack)
		kControl[DATA_FIELD_UNLOCK_IM] = unlockIM
	end
	return unlockIM
end

-- ===========================================================================
--	Show the meters and boost information for a given tech.
-- ===========================================================================
function RealizeMeterAndBoosts(kControl, kData)
	local progress = kData.Progress

	if kData.Boostable then
		local boostString = "[NEWLINE]" .. Locale.Lookup(kData.TriggerDesc)
		if kData.BoostTriggered then
			boostString = Locale.Lookup("LOC_TECH_HAS_BEEN_BOOSTED") .. boostString -- Same whether tech/civic
			kControl.IconHasBeenBoosted:SetToolTipString(boostString)
			progress = math.clamp(progress, 0, 1.0)
		else
			boostString = Locale.Lookup("LOC_TECH_CAN_BE_BOOSTED") .. boostString -- Same whether tech/civic
			kControl.IconCanBeBoosted:SetToolTipString(boostString)
			local boostAmount = math.min((kData.Progress + kData.BoostAmount), 1.0)
			kControl.BoostMeter:SetPercent(boostAmount)
		end

		TruncateStringWithTooltip(kControl.BoostLabel, MAX_BEFORE_TRUNC_BOOST_MSG, Locale.Lookup(kData.TriggerDesc))
	end

	if kData.IsLastCompleted then
		progress = 1.0
	end

	kControl.IconCanBeBoosted:SetHide((not (kData.Boostable and not kData.BoostTrigger)) or kData.IsLastCompleted)
	kControl.IconHasBeenBoosted:SetHide((not kData.BoostTriggered) or kData.IsLastCompleted)
	kControl.ProgressMeter:SetPercent(progress)
	kControl.BoostLabel:SetHide((not kData.Boostable) or kData.IsLastCompleted)
	kControl.BoostMeter:SetHide((not kData.Boostable) or kData.IsLastCompleted or (kData.BoostTriggered))
end

-- ===========================================================================
--
-- ===========================================================================
function RealizeIcon(kIconControl, typeName, size)
	local textureString                                = "ICON_" .. typeName
	local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(textureString, size)
	if textureSheet ~= nil then
		kIconControl:SetTexture(textureOffsetX, textureOffsetY, textureSheet)
	else
		UI.DataError("Missing icon '" .. tostring(textureString) .. "' at size " .. tostring(size))
	end
end

-- ===========================================================================
--
-- ===========================================================================
function RealizeTurnsLeft(kControl, kData)
	local turnsLeft = (kData == nil) and -1 or kData.TurnsLeft

	-- The UI was only designed to show up to 3 characters in this label
	if turnsLeft > 999 then turnsLeft = 999 end

	local isLastCompleted = false
	local isRepeatable    = false

	if kData ~= nil then
		isLastCompleted = kData.IsLastCompleted
		isRepeatable = kData.Repeatable
		if isLastCompleted and not isRepeatable then
			kControl.TurnsLeft:SetText(Locale.Lookup("LOC_RESEARCH_CHOOSER_JUST_COMPLETED"))
		else
			if kData.TurnsLeft ~= -1 then
				kControl.TurnsLeft:SetText("[ICON_Turn]" .. tostring(turnsLeft))
			else
				kControl.TurnsLeft:SetText("")
			end
		end
	else
		kControl.TurnsLeft:SetText("")
	end

	-- Label only exists in the big version:
	if kControl.TurnsLeftLabel ~= nil then
		kControl.TurnsLeftLabel:SetHide(isLastCompleted or turnsLeft < 0)
	end
end

-- ===========================================================================
--	Obtain a single research/tech item.
-- ===========================================================================
function GetResearchData(localPlayer, pPlayerTechs, kTech)
	if kTech == nil then -- Immediate return if there is no tech to inspect likely first turn.
		return nil
	end

	local iTech        = kTech.Index
	local isBoostable  = false
	local boostAmount  = 0
	local isRepeatable = kTech.Repeatable
	local researchCost = pPlayerTechs:GetResearchCost(iTech)
	local techType     = kTech.TechnologyType
	local triggerDesc  = ""

	for row in GameInfo.Boosts() do
		if row.TechnologyType == techType then
			isBoostable = true
			boostAmount = (row.Boost * .01) *
				researchCost --Convert the boost value to decimal and determine the actual boost amount.
			triggerDesc = row.TriggerDescription
			break
		end
	end

	local kData = {
		ID              = iTech,
		Boostable       = isBoostable,
		BoostAmount     = boostAmount / researchCost,
		BoostTriggered  = pPlayerTechs:HasBoostBeenTriggered(iTech),
		Hash            = kTech.Hash,
		Name            = Locale.Lookup(kTech.Name),
		IsCurrent       = false, -- caller needs to update upon return
		IsLastCompleted = false, -- caller needs to update upon return
		Repeatable      = isRepeatable,
		ResearchCost    = researchCost,
		Progress        = pPlayerTechs:GetResearchProgress(iTech) / researchCost,
		TechType        = techType,
		ToolTip         = ToolTipHelper.GetToolTip(techType, localPlayer),
		TriggerDesc     = triggerDesc,
		TurnsLeft       = pPlayerTechs:GetTurnsToResearch(iTech)
	}

	return kData
end

-- ===========================================================================
--	Realize content at the top of a list which is one of the following:
--	the current research, the recently completed research or NIL if player
--	has just started the game.
-- ===========================================================================
function RealizeCurrentResearch(playerID, kData, kControl)
	-- If a control instance is passed in, use that for the controls, otherwise
	-- assume the control exists off of the main control set of the context.
	if kControl == nil then
		kControl = Controls
	end

	kControl.MainPanel:ClearMouseEnterCallback()
	kControl.MainPanel:ClearMouseExitCallback()

	local isNonActive = false
	local techUnlockIM = GetUnlockIM(kControl) -- Use this context's "Controls" table for the currnet IM

	if kData ~= nil then
		local techType = kData.TechType
		local numUnlockables
		kControl.TitleButton:SetText(Locale.ToUpper(kData.Name))

		if (not IsTutorialRunning()) then
			kControl.TitleButton:RegisterCallback(Mouse.eRClick, function() LuaEvents.OpenCivilopedia(techType) end)
		end

		kControl.MainPanel:RegisterMouseEnterCallback(function() kControl.MainGearAnim:Play() end)
		kControl.MainPanel:RegisterMouseExitCallback(function() kControl.MainGearAnim:Stop() end)

		RealizeMeterAndBoosts(kControl, kData)
		RealizeIcon(kControl.Icon, kData.TechType, SIZE_ICON_RESEARCH_LARGE)

		numUnlockables = PopulateUnlockablesForTech(playerID, kData.ID, techUnlockIM, nil)
		if numUnlockables ~= nil and kControl ~= nil then
			HandleOverflow(numUnlockables, kControl, MAX_ICONS_BEFORE_OVERFLOW, MAX_ICONS_BEFORE_OVERFLOW - 1)
		end

		-- Show/Hide Recommended Icon
		if kControl.RecommendedIcon then
			if kData.IsRecommended and kData.AdvisorType then
				kControl.RecommendedIcon:SetIcon(kData.AdvisorType)
				kControl.RecommendedIcon:SetHide(false)
				kControl.TitleStack:ReprocessAnchoring()
			else
				kControl.RecommendedIcon:SetHide(true)
			end
		end
	else
		-- Nothing has been researched yet.
		kControl.TitleButton:ClearCallback(Mouse.eRClick)
		kControl.BoostMeter:SetPercent(0)
		kControl.ProgressMeter:SetPercent(0)
		kControl.BoostLabel:SetHide(true)
		kControl.IconCanBeBoosted:SetHide(true)
		kControl.IconHasBeenBoosted:SetHide(true)
		if kControl.RecommendedIcon then
			kControl.RecommendedIcon:SetHide(true)
		end
		isNonActive = true
	end

	RealizeTurnsLeft(kControl, kData)
	kControl.TitleButton:SetHide(isNonActive)
	kControl.Icon:SetHide(isNonActive)
end

-- ===========================================================================
--	Determine the current data.
-- ===========================================================================
function GetCivicData(localPlayer, pPlayerCulture, kCivic)
	if kCivic == nil then -- Immediate return if there is no tech to inspect likely first turn.
		return nil
	end

	local iCivic       = kCivic.Index
	local isBoostable  = false
	local boostAmount  = 0
	local isRepeatable = kCivic.Repeatable
	local progressCost = pPlayerCulture:GetCultureCost(iCivic)
	local civicType    = kCivic.CivicType
	local triggerDesc  = ""

	for row in GameInfo.Boosts() do
		if row.CivicType == civicType then
			isBoostable = true
			boostAmount = (row.Boost * .01) *
				progressCost --Convert the boost value to decimal and determine the actual boost amount.
			triggerDesc = row.TriggerDescription
			break
		end
	end

	local kData = {
		ID              = iCivic,
		Boostable       = isBoostable,
		BoostAmount     = boostAmount / progressCost,
		BoostTriggered  = pPlayerCulture:HasBoostBeenTriggered(iCivic),
		Cost            = progressCost,
		Hash            = kCivic.Hash,
		Name            = Locale.Lookup(kCivic.Name),
		IsCurrent       = false, -- caller needs to update upon return
		IsLastCompleted = false, -- caller needs to update upon return
		Repeatable      = isRepeatable,
		Progress        = (pPlayerCulture:GetCulturalProgress(iCivic) / progressCost),
		CivicType       = civicType,
		ToolTip         = ToolTipHelper.GetToolTip(civicType, localPlayer),
		TriggerDesc     = triggerDesc,
		TurnsLeft       = pPlayerCulture:GetTurnsToProgressCivic(iCivic)
	}

	return kData
end

-- ===========================================================================
--	Realize content at the top of a list which is one of the following:
--	the current research, the recently completed research or NIL if player
--	has just started the game.
-- ===========================================================================
function RealizeCurrentCivic(playerID, kData, kControl, cachedModifiers)
	-- If a control instance is passed in, use that for the controls, otherwise
	-- assume the control exists off of the main control set of the context.
	if kControl == nil then
		kControl = Controls
	end

	kControl.MainPanel:ClearMouseEnterCallback()
	kControl.MainPanel:ClearMouseExitCallback()

	local isNonActive = false
	local unlockIM = GetUnlockIM(kControl) -- Use this context's "Controls" table for the currnet IM


	if kData ~= nil then
		local techType = kData.CivicType
		local numUnlockables = 0
		kControl.TitleButton:SetText(Locale.ToUpper(kData.Name))

		if (not IsTutorialRunning()) then
			kControl.TitleButton:RegisterCallback(Mouse.eRClick, function() LuaEvents.OpenCivilopedia(techType) end)
		end

		kControl.MainPanel:RegisterMouseEnterCallback(function() kControl.MainGearAnim:Play() end)
		kControl.MainPanel:RegisterMouseExitCallback(function() kControl.MainGearAnim:Stop() end)

		RealizeMeterAndBoosts(kControl, kData)
		RealizeIcon(kControl.Icon, kData.CivicType, SIZE_ICON_CIVIC_LARGE)

		-- Include extra icons in total unlocks
		local extraUnlocks = {}
		local hideDescriptionIcon = false
		local civicModifiers = cachedModifiers[kData.CivicType]
		if (civicModifiers) then
			for _, tModifier in ipairs(civicModifiers) do
				local tIconData = g_ExtraIconData[tModifier.ModifierType]
				if (tIconData) then
					hideDescriptionIcon = hideDescriptionIcon or tIconData.HideDescriptionIcon
					table.insert(extraUnlocks, { IconData = tIconData, ModifierTable = tModifier })
				end
			end
		end

		numUnlockables = numUnlockables +
			PopulateUnlockablesForCivic(playerID, kData.ID, unlockIM, nil, nil, hideDescriptionIcon)

		-- Initialize extra icons
		for _, tUnlock in pairs(extraUnlocks) do
			tUnlock.IconData:Initialize(kControl.UnlockStack, tUnlock.ModifierTable)
			numUnlockables = numUnlockables + 1
		end

		HandleOverflow(numUnlockables, kControl, MAX_ICONS_BEFORE_OVERFLOW, MAX_ICONS_BEFORE_OVERFLOW - 1)

		-- Show/Hide Recommended Icon
		if kControl.RecommendedIcon then
			if kData.IsRecommended and kData.AdvisorType then
				kControl.RecommendedIcon:SetIcon(kData.AdvisorType)
				kControl.RecommendedIcon:SetHide(false)
				kControl.TitleStack:ReprocessAnchoring()
			else
				kControl.RecommendedIcon:SetHide(true)
			end
		end
	else
		-- Nothing has been researched yet.
		kControl.TitleButton:ClearCallback(Mouse.eRClick)
		kControl.BoostMeter:SetPercent(0)
		kControl.ProgressMeter:SetPercent(0)
		kControl.BoostLabel:SetHide(true)
		kControl.IconCanBeBoosted:SetHide(true)
		kControl.IconHasBeenBoosted:SetHide(true)
		kControl.TurnsLeftLabel:SetHide(true)
		isNonActive = true
	end

	RealizeTurnsLeft(kControl, kData)
	kControl.TitleButton:SetHide(isNonActive)
	kControl.Icon:SetHide(isNonActive)
end

-- Returns a table: strCivicType -> Array of Modifiers
-- Each modifier is a table containing ModifierType, ModifierId, and an optional ModifierValue
function TechAndCivicSupport_BuildCivicModifierCache()
	-- Collect modifiers into list
	local tModCache = {} -- ModifierId -> table of modifier data
	for tModInfo in GameInfo.Modifiers() do
		tModCache[tModInfo.ModifierId] = {
			ModifierId = tModInfo.ModifierId,
			ModifierType = tModInfo.ModifierType,
		}
	end

	-- Collect modifier arguments, add to relevant modifier table
	for tModArgs in GameInfo.ModifierArguments() do
		-- ModifierValue should be changed into an array if we must track multiple args per modifier.
		tModCache[tModArgs.ModifierId].ModifierValue = tModArgs.Value
	end

	-- Collect modifiers used by civics
	local tCache = {} -- strCivicType -> Array of Modifiers
	for tCivicMod in GameInfo.CivicModifiers() do
		local tCivicCache = tCache[tCivicMod.CivicType]
		if (not tCivicCache) then
			tCivicCache = {}
			tCache[tCivicMod.CivicType] = tCivicCache
		end

		local tModInfo = tModCache[tCivicMod.ModifierId]
		assert(tModInfo)
		table.insert(tCivicCache, tModInfo)
	end

	return tCache
end

include('TechAndCivicSupport_', true)
