-- EagleUnion_Leader_AllenMSumner
-- Author: HSbF6HSO3F
-- DateCreated: 2023/11/10 21:59:45
--------------------------------------------------------------
CREATE TEMPORARY TABLE temp_Allen_Table (
     ModifierId TEXT,
     DistrictType TEXT
);

INSERT INTO temp_Allen_Table
		(ModifierId,						DistrictType)
SELECT	'ALLEN_ADD_CULTURE_' || DistrictType,	DistrictType
FROM Districts WHERE DistrictType NOT IN (SELECT CivUniqueDistrictType FROM DistrictReplaces);

INSERT INTO TraitModifiers
		(TraitType,							ModifierId)
SELECT	'TRAIT_LEADER_SHOOTING_GUN_STAR',	ModifierId
FROM temp_Allen_Table;

INSERT INTO Modifiers
		(ModifierId,ModifierType)
SELECT	ModifierId,	'MODIFIER_PLAYER_CITIES_DISTRICT_ADJACENCY'
FROM temp_Allen_Table;

INSERT INTO ModifierArguments
		(ModifierId,	Name,			Value)
SELECT	ModifierId,		'Amount',		2
FROM temp_Allen_Table;

INSERT INTO ModifierArguments
		(ModifierId,	Name,			Value)
SELECT	ModifierId,		'Description',	'LOC_Allen_Culture_Adjacency_From_District'
FROM temp_Allen_Table;

INSERT INTO ModifierArguments
		(ModifierId,	Name,			Value)
SELECT	ModifierId,		'DistrictType',	DistrictType
FROM temp_Allen_Table;

INSERT INTO ModifierArguments
		(ModifierId,	Name,			Value)
SELECT	ModifierId,		'TilesRequired',1
FROM temp_Allen_Table;

INSERT INTO ModifierArguments
		(ModifierId,	Name,			Value)
SELECT	ModifierId,		'YieldType',	'YIELD_CULTURE'
FROM temp_Allen_Table;