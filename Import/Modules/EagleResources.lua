-- EagleResources
-- Author: HSbF6HSO3F
-- DateCreated: 2025/3/2 9:33:12
--------------------------------------------------------------
--||=======================include========================||--
include('EagleImprovements')
include('EagleYields')

--||======================MetaTable=======================||--

--------------------------------------------------------------
-- EagleResource是有关资源的类，它允许更加简单的获取资源的可放置条件。
EagleResource = {
    Index        = -1,
    Type         = '',
    Class        = '',
    Name         = '',
    Icon         = '',
    Terrains     = {},
    Remove       = true,
    Features     = {},
    Improvements = {},
    Yields       = {}
}

--创建新实例，根据资源定义
function EagleResource:newByDef(resourceDef)
    --错误处理
    if not resourceDef then return nil end
    --创建新实例
    local object = {}
    setmetatable(object, self)
    self.__index    = self
    local resource  = resourceDef.ResourceType
    object.Type     = resource
    object.Index    = resourceDef.Index
    object.Class    = resourceDef.ResourceClassType
    object.Name     = resourceDef.Name
    --图标设置
    object.Icon     = '[ICON_' .. resource .. ']'
    --遍历允许地形
    object.Terrains = {}
    for row in GameInfo.Resource_ValidTerrains() do
        if row.ResourceType == resource then
            local terrainDef = GameInfo.Terrains[row.TerrainType]
            local terrain = { Index = terrainDef.Index, Name = terrainDef.Name }
            table.insert(object.Terrains, terrain)
        end
    end
    --遍历允许地貌
    object.Features = {}
    for row in GameInfo.Resource_ValidFeatures() do
        if row.ResourceType == resource then
            local featureDef = GameInfo.Features[row.FeatureType]
            local feature = { Index = featureDef.Index, Name = featureDef.Name }
            table.insert(object.Features, feature)
        end
    end
    --改良是否必须移除地貌
    object.Remove = true
    --提升用改良设施
    object.Improvements = {}
    --遍历改良设施允许资源表
    for row in GameInfo.Improvement_ValidResources() do
        if row.ResourceType == resource then
            if row.MustRemoveFeature == false then
                object.Remove = false
            end
            if not (object.Remove and row.MustRemoveFeature) then
                local improveDef = GameInfo.Improvements[row.ImprovementType]
                local improvement = EagleImprovement:new(improveDef)
                table.insert(object.Improvements, improvement)
            end
        end
    end
    --遍历资源产出
    object.Yields = {}
    for row in GameInfo.Resource_YieldChanges() do
        if row.ResourceType == resource then
            -- 添加资源产出
            local yieldType = row.YieldType
            local yield = object.Yields[yieldType] or 0
            yield = yield + row.YieldChange
            object.Yields[yieldType] = yield
        end
    end
    return object
end

--创建新实例，根据资源类型
function EagleResource:new(resourceType)
    --错误处理
    if not resourceType then return nil end
    --获取资源定义
    local def = GameInfo.Resources[resourceType]
    return self:newByDef(def)
end

--创建新实例，根据资源定义但没有限制
function EagleResource:newByDefNoValid(resourceDef)
    --错误处理
    if not resourceDef then return nil end
    --创建新实例
    local object = {}
    setmetatable(object, self)
    self.__index        = self
    local type          = resourceDef.ResourceType
    object.Type         = type
    object.Index        = resourceDef.Index
    object.Class        = resourceDef.ResourceClassType
    object.Name         = resourceDef.Name
    --图标设置
    object.Icon         = '[ICON_' .. type .. ']'
    --地形和地貌
    object.Terrains     = {}
    object.Remove       = true
    object.Features     = {}
    object.Improvements = {}
    object.Yields       = {}
    return object
end

--||====================Based functions===================||--

--获取单元格是否可放置该资源
function EagleResource:GetPlaceable(plot)
    local improveable = false
    --检查改良设施
    for _, improvement in ipairs(self.Improvements) do
        if improvement:GetPlaceable(plot, self.Index) then
            improveable = true
            break
        end
    end
    if not improveable then return false end
    --检查地貌
    local featureType = plot:GetFeatureType()
    for _, feature in ipairs(self.Features) do
        if featureType == feature.Index then return true end
    end
    --检查地形
    local terrainType = plot:GetTerrainType()
    for _, terrain in ipairs(self.Terrains) do
        if terrainType == terrain.Index then return true end
    end
    return false
end

--获取资源可用改良设施
function EagleResource:GetImprovement(plot)
    for _, improvement in ipairs(self.Improvements) do
        if improvement:GetPlaceable(plot) then return improvement end
    end
    return false
end

--获取资源可放置条件功能性文本
function EagleResource:GetConditionsTooltip()
    local tooltip = Locale.Lookup("LOC_AZURLANE_RESOURCE_CONDITIONS")
    if self.Remove then
        tooltip = tooltip .. Locale.Lookup('LOC_AZURLANE_RESOURCE_NO_FEATURE')
    end
    tooltip = tooltip .. Locale.Lookup('LOC_AZURLANE_RESOURCE_TERRAIN')
    for _, terrain in ipairs(self.Terrains) do
        tooltip = tooltip .. Locale.Lookup('LOC_AZURLANE_RESOURCE_VAILD_TERRAIN', terrain.Name)
    end
    tooltip = tooltip .. Locale.Lookup('LOC_AZURLANE_RESOURCE_FEATURE')
    for _, feature in ipairs(self.Terrains) do
        tooltip = tooltip .. Locale.Lookup('LOC_AZURLANE_RESOURCE_VAILD_FEATURE', feature.Name)
    end
    return tooltip
end

-- 获取资源改变tooltip
function EagleResource:GetChangeYieldsTooltip()
    local tooltip = Locale.Lookup('LOC_AZURLANE_RESOURCE_CHANGE')
    for key, val in pairs(self.Yields) do
        local tip = 'LOC_AZURLANE_RESOURCE_' .. key
        tooltip = tooltip .. Locale.Lookup(tip, val)
    end
    return tooltip
end

-- 获取收获资源的产出
function EagleResource:GetHarvestYields(playerId, value)
    local percent = EagleCore:GetPlayerProgress(playerId)
    local amount = 20 * (1 + 9 * percent / 100) * value
    return math.ceil(EagleCore:ModifyBySpeed(amount))
end

-- 获得收获资源产出
function EagleResource:GrantHarvestYields(playerId, x, y)
    for key, val in pairs(self.Yields) do
        local amount = self:GetHarvestYields(playerId, val)
        EagleYields:GrantYieldAtXY(playerId, key, amount, x, y)
    end
end

-- 获得收获资源产出tooltip
function EagleResource:GetHarvestYieldsTooltip(playerId)
    local tooltip = ''
    for key, val in pairs(self.Yields) do
        -- 获取产出tooltip
        local yield = EagleYields:GetYield(key)
        local num = self:GetHarvestYields(playerId, val)
        tooltip = tooltip .. yield:GetTooltip(num)
    end
    return tooltip
end

--||======================MetaTable=======================||--

--------------------------------------------------------------
---EagleResources是AzurLaneCoreCode的资源管理类
---它允许按照要求检索GameInfo的资源信息，并通过一次性创建多个资源实例来提高效率。
EagleResources = { Resources = {} }

--创建新实例，根据资源类型列表
function EagleResources:new(resourceReq)
    local object = {}
    setmetatable(object, self)
    self.__index = self
    --初始化资源列表
    object.Resources = {}
    --遍历资源类型列表
    for def in GameInfo.Resources() do
        local match = false
        if def.Frequency ~= 0 or def.SeaFrequency ~= 0 then
            if resourceReq == true then
                match = true
            else
                if resourceReq[def.ResourceType] then
                    match = true
                end
                if resourceReq[def.ResourceClassType] then
                    match = true
                end
            end
        end
        if match then
            local resource = EagleResource:newByDefNoValid(def)
            object.Resources[def.ResourceType] = resource
        end
    end
    --创建地形和地貌限制
    for row in GameInfo.Resource_ValidTerrains() do
        local resource = object.Resources[row.ResourceType]
        if resource then
            local terrainDef = GameInfo.Terrains[row.TerrainType]
            local terrain = { Index = terrainDef.Index, Name = terrainDef.Name }
            table.insert(resource.Terrains, terrain)
        end
    end
    for row in GameInfo.Resource_ValidFeatures() do
        local resource = object.Resources[row.ResourceType]
        if resource then
            local featureDef = GameInfo.Features[row.FeatureType]
            local feature = { Index = featureDef.Index, Name = featureDef.Name }
            table.insert(resource.Features, feature)
        end
    end
    local improvements = EagleImprovements:new()
    --改良是否必须移除地貌
    for row in GameInfo.Improvement_ValidResources() do
        local resource = object.Resources[row.ResourceType]
        if resource then
            if row.MustRemoveFeature == false then
                resource.Remove = false
            end
            local improvement = improvements:GetImprovement(row.ImprovementType)
            table.insert(resource.Improvements, improvement)
        end
    end
    --改良资源产出
    for row in GameInfo.Resource_YieldChanges() do
        local resource = object.Resources[row.ResourceType]
        if resource then
            -- 添加资源产出
            local yieldType = row.YieldType
            local yield = resource.Yields[yieldType] or 0
            yield = yield + row.YieldChange
            resource.Yields[yieldType] = yield
        end
    end
    return object
end

--||====================Based functions===================||--

--获取资源实例
function EagleResources:GetResource(resourceType)
    return self.Resources[resourceType]
end

--获取该单元格可以放置的资源列表
function EagleResources:GetPlaceableResources(plot)
    local list = {}
    --地形
    for _, resource in pairs(self.Resources) do
        if resource:GetPlaceable(plot) then
            table.insert(list, resource)
        end
    end; return list
end
