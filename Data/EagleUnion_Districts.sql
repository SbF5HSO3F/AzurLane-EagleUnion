-- EagleUnion_Districts
-- Author: HSbF6HSO3F
-- DateCreated: 2024/12/31 9:30:32
--------------------------------------------------------------
--Create Table
CREATE TEMPORARY TABLE temp_EagleUnion_Modifier_Table (
    ModifierId TEXT,
	YieldType TEXT
);

INSERT INTO temp_EagleUnion_Modifier_Table
		(ModifierId,														    YieldType)
SELECT	'MODIFIER_IVY_' || REPLACE(YieldType,'YIELD_','') || '_GRANT_SCIENCE',	YieldType
FROM Yields;
--Trait
INSERT INTO DistrictModifiers
		(DistrictType,			ModifierId)
SELECT	'DISTRICT_IVY_LEAGUE',	ModifierId
FROM temp_EagleUnion_Modifier_Table;

--Modifier
INSERT INTO Modifiers
		(ModifierId,ModifierType,                                                                   SubjectRequirementSetId)
SELECT	ModifierId,	'MODIFIER_EAGLE_UNION_PLAYER_DISTRICTS_ADJUST_YIELD_BASED_ON_ADJACENCY_BONUS',  'EAGLE_UNION_PLOT_NEXT_IVY'
FROM temp_EagleUnion_Modifier_Table;

--Modifier Arguments
INSERT INTO ModifierArguments
		(ModifierId,	Name,				Value)
SELECT	ModifierId,		'YieldTypeToGrant',	'YIELD_SCIENCE'
FROM temp_EagleUnion_Modifier_Table
UNION ALL
SELECT	ModifierId,		'YieldTypeToMirror',YieldType
FROM temp_EagleUnion_Modifier_Table;